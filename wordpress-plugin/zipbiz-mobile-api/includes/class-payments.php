<?php
if (!defined('ABSPATH')) {
    exit;
}

class ZipBiz_Payments {

    public function register_routes() {
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/payment/create-order', array(
            'methods'  => 'POST',
            'callback' => array($this, 'create_razorpay_order'),
            'permission_callback' => array($this, 'check_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/payment/verify', array(
            'methods'  => 'POST',
            'callback' => array($this, 'verify_razorpay_payment'),
            'permission_callback' => array($this, 'check_auth'),
        ));
    }

    public function check_auth($request) {
        $user = ZipBiz_REST_API::authenticate_user($request);
        return !is_wp_error($user);
    }

    /**
     * Create Razorpay order server-side
     */
    public function create_razorpay_order($request) {
        global $wpdb;
        $user = wp_get_current_user();
        $params = $request->get_json_params();
        $booking_id = intval($params['booking_id'] ?? 0);

        if (!$booking_id) {
            return ZipBiz_REST_API::error_response('INVALID_BOOKING_ID', 'Booking ID is required', 400);
        }

        // Fetch booking
        $table_name = $wpdb->prefix . 'bookings';
        $row = null;
        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $row = $wpdb->get_row($wpdb->prepare("SELECT * FROM $table_name WHERE id = %d", $booking_id), ARRAY_A);
        }

        if (!$row) {
            $post = get_post($booking_id);
            if ($post && $post->post_type === 'booking') {
                $row = array(
                    'id'              => $booking_id,
                    'bookings_author' => $post->post_author,
                    'price'           => get_post_meta($booking_id, '_price', true),
                );
            }
        }

        if (!$row) {
            return ZipBiz_REST_API::error_response('NOT_FOUND', 'Booking not found', 404);
        }

        if ($row['bookings_author'] != $user->ID && !current_user_can('manage_options')) {
            return ZipBiz_REST_API::error_response('FORBIDDEN', 'Access denied to this booking', 403);
        }

        $amount = floatval($row['price']);
        if ($amount <= 0) {
            $amount = 299; // Fallback
        }
        $amount_in_paise = intval(round($amount * 100));

        $key_id = get_option('zipbiz_razorpay_key_id');
        $key_secret = get_option('zipbiz_razorpay_key_secret');

        if (empty($key_id) || empty($key_secret)) {
            // Check if WooCommerce Razorpay plugin has keys configured
            $woo_gateways = get_option('woocommerce_razorpay_settings', array());
            if (!empty($woo_gateways['key_id']) && !empty($woo_gateways['key_secret'])) {
                $key_id = $woo_gateways['key_id'];
                $key_secret = $woo_gateways['key_secret'];
            }
        }

        if (empty($key_id) || empty($key_secret)) {
            return ZipBiz_REST_API::error_response('GATEWAY_CONFIG_MISSING', 'Razorpay credentials not configured in WordPress settings.', 500);
        }

        // Call Razorpay Orders API
        $response = wp_remote_post('https://api.razorpay.com/v1/orders', array(
            'headers' => array(
                'Authorization' => 'Basic ' . base64_encode($key_id . ':' . $key_secret),
                'Content-Type'  => 'application/json',
            ),
            'body' => json_encode(array(
                'amount'   => $amount_in_paise,
                'currency' => 'INR',
                'receipt'  => 'booking_' . $booking_id,
                'notes'    => array(
                    'booking_id' => strval($booking_id),
                    'user_id'    => strval($user->ID),
                ),
            )),
            'timeout' => 20,
        ));

        if (is_wp_error($response)) {
            return ZipBiz_REST_API::error_response('RAZORPAY_API_ERROR', $response->get_error_message(), 502);
        }

        $body = json_decode(wp_remote_retrieve_body($response), true);
        if (empty($body['id'])) {
            $err_msg = $body['error']['description'] ?? 'Failed to create Razorpay order';
            return ZipBiz_REST_API::error_response('RAZORPAY_ORDER_FAILED', $err_msg, 500);
        }

        $razorpay_order_id = $body['id'];

        // Store Razorpay order ID in booking comment/meta
        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $comment_data = json_decode($row['comment'], true) ?: array();
            $comment_data['razorpay_order_id'] = $razorpay_order_id;
            $wpdb->update($table_name, array('comment' => json_encode($comment_data)), array('id' => $booking_id));
        }

        return ZipBiz_REST_API::success_response(array(
            'booking_id'        => $booking_id,
            'razorpay_order_id' => $razorpay_order_id,
            'amount'            => $amount,
            'amount_paise'      => $amount_in_paise,
            'currency'          => 'INR',
            'key_id'            => $key_id,
        ), 'Razorpay order generated');
    }

    /**
     * Server-side HMAC-SHA256 signature verification
     */
    public function verify_razorpay_payment($request) {
        global $wpdb;
        $user = wp_get_current_user();
        $params = $request->get_json_params();

        $booking_id          = intval($params['booking_id'] ?? 0);
        $razorpay_order_id   = sanitize_text_field($params['razorpay_order_id'] ?? '');
        $razorpay_payment_id = sanitize_text_field($params['razorpay_payment_id'] ?? '');
        $razorpay_signature  = sanitize_text_field($params['razorpay_signature'] ?? '');

        if (!$booking_id || empty($razorpay_order_id) || empty($razorpay_payment_id) || empty($razorpay_signature)) {
            return ZipBiz_REST_API::error_response('MISSING_FIELDS', 'Missing payment verification credentials', 400);
        }

        $key_secret = get_option('zipbiz_razorpay_key_secret');
        if (empty($key_secret)) {
            $woo_gateways = get_option('woocommerce_razorpay_settings', array());
            $key_secret = $woo_gateways['key_secret'] ?? '';
        }

        if (empty($key_secret)) {
            return ZipBiz_REST_API::error_response('SERVER_CONFIG_ERROR', 'Key secret not configured', 500);
        }

        // Cryptographic HMAC-SHA256 verification
        $generated_signature = hash_hmac('sha256', $razorpay_order_id . '|' . $razorpay_payment_id, $key_secret);

        if (!hash_equals($generated_signature, $razorpay_signature)) {
            error_log("[ZipBiz Security] Payment signature mismatch for Booking #{$booking_id}. Potential forgery attempt.");
            return ZipBiz_REST_API::error_response('PAYMENT_SIGNATURE_MISMATCH', 'Cryptographic payment verification failed', 400);
        }

        // Signature is valid! Update Listeo booking to 'confirmed'
        $table_name = $wpdb->prefix . 'bookings';
        $listing_id = 0;
        $owner_id = 0;

        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $row = $wpdb->get_row($wpdb->prepare("SELECT * FROM $table_name WHERE id = %d", $booking_id), ARRAY_A);
            if ($row) {
                $listing_id = $row['listing_id'];
                $comment_data = json_decode($row['comment'], true) ?: array();
                $comment_data['payment_status'] = 'paid';
                $comment_data['razorpay_payment_id'] = $razorpay_payment_id;
                $comment_data['razorpay_verified_at'] = current_time('mysql');

                $wpdb->update($table_name, array(
                    'status'  => 'confirmed',
                    'comment' => json_encode($comment_data),
                ), array('id' => $booking_id));
            }
        }

        $listing = get_post($listing_id);
        if ($listing) {
            $owner_id = $listing->post_author;
        }

        // Send push notifications
        ZipBiz_Notifications::send_push_notification(
            $user->ID,
            'Booking Confirmed! 🎉',
            "Your payment of ₹" . ($row['price'] ?? '') . " for {$listing->post_title} was successful!",
            array('type' => 'payment_success', 'booking_id' => $booking_id)
        );

        if ($owner_id) {
            ZipBiz_Notifications::send_push_notification(
                $owner_id,
                'Payment Received! 💰',
                "Customer has paid online for booking #{$booking_id} ({$listing->post_title}).",
                array('type' => 'booking_paid', 'booking_id' => $booking_id)
            );
        }

        return ZipBiz_REST_API::success_response(array(
            'booking_id' => $booking_id,
            'status'     => 'confirmed',
            'payment_id' => $razorpay_payment_id,
            'verified'   => true,
        ), 'Payment verified and booking confirmed successfully');
    }
}
