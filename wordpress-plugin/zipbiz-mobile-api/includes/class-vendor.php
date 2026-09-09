<?php
if (!defined('ABSPATH')) {
    exit;
}

class ZipBiz_Vendor {

    public function register_routes() {
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/dashboard', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_dashboard'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/bookings', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_bookings'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/bookings/(?P<id>\d+)/accept', array(
            'methods'  => 'POST',
            'callback' => array($this, 'accept_booking'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/bookings/(?P<id>\d+)/reject', array(
            'methods'  => 'POST',
            'callback' => array($this, 'reject_booking'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/bookings/(?P<id>\d+)/start', array(
            'methods'  => 'POST',
            'callback' => array($this, 'start_booking'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/bookings/(?P<id>\d+)/complete', array(
            'methods'  => 'POST',
            'callback' => array($this, 'complete_booking'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/earnings', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_earnings'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));
    }

    public function check_vendor_auth($request) {
        $user = ZipBiz_REST_API::authenticate_user($request);
        if (is_wp_error($user) || !$user || !$user->ID) {
            return false;
        }

        // Allow if role is owner, seller, administrator or has listings
        $roles = (array)$user->roles;
        if (in_array('owner', $roles) || in_array('seller', $roles) || in_array('administrator', $roles)) {
            return true;
        }

        // Check if user has authored any listings
        $count = count_user_posts($user->ID, 'listing');
        return ($count > 0);
    }

    /**
     * Get IDs of all listings owned by current user
     */
    private function get_vendor_listing_ids($user_id) {
        if (current_user_can('manage_options')) {
            // Admin can see all or own
            $args = array(
                'post_type'      => 'listing',
                'posts_per_page' => -1,
                'fields'         => 'ids',
            );
        } else {
            $args = array(
                'post_type'      => 'listing',
                'author'         => $user_id,
                'posts_per_page' => -1,
                'fields'         => 'ids',
            );
        }
        return get_posts($args);
    }

    /**
     * Vendor Dashboard KPI Stats
     */
    public function get_dashboard($request) {
        global $wpdb;
        $user = wp_get_current_user();
        $listing_ids = $this->get_vendor_listing_ids($user->ID);

        if (empty($listing_ids)) {
            return ZipBiz_REST_API::success_response(array(
                'today_bookings'     => 0,
                'pending_bookings'   => 0,
                'upcoming_bookings'  => 0,
                'completed_bookings' => 0,
                'gross_earnings'     => 0,
                'commission'         => 0,
                'net_earnings'       => 0,
                'rating'             => 5.0,
                'reviews_count'      => 0,
                'active_listings'    => 0,
            ));
        }

        $ids_placeholder = implode(',', array_map('intval', $listing_ids));
        $table_name = $wpdb->prefix . 'bookings';
        $today = date('Y-m-d');

        $today_count = 0;
        $pending_count = 0;
        $upcoming_count = 0;
        $completed_count = 0;
        $gross_earnings = 0;

        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $today_count = intval($wpdb->get_var("SELECT COUNT(*) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND date_start LIKE '$today%' AND status NOT IN ('cancelled', 'rejected')"));
            $pending_count = intval($wpdb->get_var("SELECT COUNT(*) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status IN ('waiting', 'pending')"));
            $upcoming_count = intval($wpdb->get_var("SELECT COUNT(*) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status = 'confirmed' AND date_start >= '$today'"));
            $completed_count = intval($wpdb->get_var("SELECT COUNT(*) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status IN ('completed', 'finished')"));
            $gross_earnings = floatval($wpdb->get_var("SELECT SUM(price) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status IN ('completed', 'confirmed')"));
        }

        $commission_rate = 0.10; // 10% platform commission
        $commission = round($gross_earnings * $commission_rate, 2);
        $net_earnings = round($gross_earnings - $commission, 2);

        // Average rating across vendor's listings
        $avg_rating = 0;
        $rating_count = 0;
        foreach ($listing_ids as $lid) {
            $r = get_post_meta($lid, 'listeo-avg-rating', true);
            if ($r !== '') {
                $avg_rating += floatval($r);
                $rating_count++;
            }
        }
        $final_rating = ($rating_count > 0) ? round($avg_rating / $rating_count, 1) : 5.0;

        return ZipBiz_REST_API::success_response(array(
            'today_bookings'     => $today_count,
            'pending_bookings'   => $pending_count,
            'upcoming_bookings'  => $upcoming_count,
            'completed_bookings' => $completed_count,
            'gross_earnings'     => $gross_earnings,
            'commission'         => $commission,
            'net_earnings'       => $net_earnings,
            'rating'             => $final_rating,
            'active_listings'    => count($listing_ids),
        ));
    }

    /**
     * Get vendor's bookings list with status filters
     */
    public function get_bookings($request) {
        global $wpdb;
        $user = wp_get_current_user();
        $listing_ids = $this->get_vendor_listing_ids($user->ID);

        if (empty($listing_ids)) {
            return ZipBiz_REST_API::success_response(array(
                'items'       => array(),
                'page'        => 1,
                'per_page'    => 20,
                'total'       => 0,
                'total_pages' => 0,
            ));
        }

        $ids_placeholder = implode(',', array_map('intval', $listing_ids));
        $table_name = $wpdb->prefix . 'bookings';
        $status = sanitize_text_field($request->get_param('status') ?: 'all');
        $page = max(1, intval($request->get_param('page') ?: 1));
        $per_page = min(50, max(1, intval($request->get_param('per_page') ?: 20)));
        $offset = ($page - 1) * $per_page;

        $where = "WHERE listing_id IN ($ids_placeholder)";
        if ($status !== 'all') {
            if ($status === 'ongoing') {
                $where .= " AND status IN ('confirmed', 'waiting', 'pending', 'in_progress')";
            } elseif ($status === 'completed') {
                $where .= " AND status IN ('completed', 'finished')";
            } elseif ($status === 'cancelled') {
                $where .= " AND status IN ('cancelled', 'rejected')";
            } else {
                $where .= $wpdb->prepare(" AND status = %s", $status);
            }
        }

        $total = intval($wpdb->get_var("SELECT COUNT(*) FROM $table_name $where"));
        $rows = $wpdb->get_results("SELECT * FROM $table_name $where ORDER BY id DESC LIMIT $offset, $per_page", ARRAY_A);

        $items = array();
        foreach ($rows as $r) {
            $listing = get_post($r['listing_id']);
            $comment_data = json_decode($r['comment'], true) ?: array();
            $customer = get_user_by('id', $r['bookings_author']);

            $items[] = array_merge($comment_data, array(
                'booking_id'     => intval($r['id']),
                'status'         => $r['status'],
                'price'          => floatval($r['price']),
                'created'        => $r['created'],
                'date_start'     => $r['date_start'],
                'listing_id'     => intval($r['listing_id']),
                'listing_title'  => $listing ? $listing->post_title : 'Service',
                'listing_image'  => $listing ? (get_the_post_thumbnail_url($listing->ID, 'medium') ?: '') : '',
                'customer_id'    => intval($r['bookings_author']),
                'customer_name'  => $comment_data['customer_name'] ?? ($customer ? $customer->display_name : 'Customer'),
                'customer_phone' => $comment_data['customer_phone'] ?? ($customer ? get_user_meta($customer->ID, 'billing_phone', true) : ''),
            ));
        }

        return ZipBiz_REST_API::success_response(array(
            'items'       => $items,
            'page'        => $page,
            'per_page'    => $per_page,
            'total'       => $total,
            'total_pages' => ceil($total / $per_page),
        ));
    }

    /**
     * Helper to verify booking ownership and update status
     */
    private function update_booking_status($booking_id, $user_id, $new_status, $notify_title, $notify_msg) {
        global $wpdb;
        $table_name = $wpdb->prefix . 'bookings';
        $row = $wpdb->get_row($wpdb->prepare("SELECT * FROM $table_name WHERE id = %d", $booking_id), ARRAY_A);

        if (!$row) {
            return ZipBiz_REST_API::error_response('NOT_FOUND', 'Booking not found', 404);
        }

        $listing = get_post($row['listing_id']);
        if (!$listing || ($listing->post_author != $user_id && !current_user_can('manage_options'))) {
            return ZipBiz_REST_API::error_response('FORBIDDEN', 'Access denied to this booking', 403);
        }

        $wpdb->update($table_name, array('status' => $new_status), array('id' => $booking_id));

        // Notify customer
        ZipBiz_Notifications::send_push_notification(
            $row['bookings_author'],
            $notify_title,
            $notify_msg,
            array('type' => 'booking_' . $new_status, 'booking_id' => $booking_id)
        );

        return ZipBiz_REST_API::success_response(array(
            'booking_id' => $booking_id,
            'status'     => $new_status,
        ), "Booking status updated to {$new_status}");
    }

    public function accept_booking($request) {
        $user = wp_get_current_user();
        return $this->update_booking_status(
            intval($request['id']),
            $user->ID,
            'confirmed',
            'Booking Accepted! 👍',
            'Your service professional has confirmed your appointment.'
        );
    }

    public function reject_booking($request) {
        $user = wp_get_current_user();
        return $this->update_booking_status(
            intval($request['id']),
            $user->ID,
            'rejected',
            'Booking Rejected',
            'Your service provider was unable to accept this booking request.'
        );
    }

    public function start_booking($request) {
        $user = wp_get_current_user();
        return $this->update_booking_status(
            intval($request['id']),
            $user->ID,
            'in_progress',
            'Service Started! ⏱️',
            'Your service professional has arrived and started the service.'
        );
    }

    public function complete_booking($request) {
        $user = wp_get_current_user();
        return $this->update_booking_status(
            intval($request['id']),
            $user->ID,
            'completed',
            'Service Completed! ⭐',
            'Your service has been completed. Please rate and review your experience.'
        );
    }

    public function get_earnings($request) {
        global $wpdb;
        $user = wp_get_current_user();
        $listing_ids = $this->get_vendor_listing_ids($user->ID);
        if (empty($listing_ids)) {
            return ZipBiz_REST_API::success_response(array(
                'gross'      => 0,
                'commission' => 0,
                'refunds'    => 0,
                'net'        => 0,
                'history'    => array(),
            ));
        }

        $ids_placeholder = implode(',', array_map('intval', $listing_ids));
        $table_name = $wpdb->prefix . 'bookings';
        $gross = floatval($wpdb->get_var("SELECT SUM(price) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status IN ('completed', 'confirmed')"));
        $commission = round($gross * 0.10, 2);
        $refunds = floatval($wpdb->get_var("SELECT SUM(price) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status = 'refunded'"));
        $net = round($gross - $commission - $refunds, 2);

        return ZipBiz_REST_API::success_response(array(
            'gross'      => $gross,
            'commission' => $commission,
            'refunds'    => $refunds,
            'net'        => $net,
        ));
    }
}
