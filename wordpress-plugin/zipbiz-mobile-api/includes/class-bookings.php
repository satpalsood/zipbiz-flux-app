<?php
if (!defined('ABSPATH')) {
    exit;
}

class ZipBiz_Bookings {

    public function register_routes() {
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/booking/create', array(
            'methods'  => 'POST',
            'callback' => array($this, 'create_booking'),
            'permission_callback' => array($this, 'check_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/booking/(?P<id>\d+)', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_booking_detail'),
            'permission_callback' => array($this, 'check_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/booking/availability', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_availability'),
            'permission_callback' => '__return_true',
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/booking/(?P<id>\d+)/cancel', array(
            'methods'  => 'POST',
            'callback' => array($this, 'cancel_booking'),
            'permission_callback' => array($this, 'check_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/customer/bookings', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_customer_bookings'),
            'permission_callback' => array($this, 'check_auth'),
        ));

        register_rest_route('wp/v2', '/get-bookings', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_customer_bookings'),
            'permission_callback' => '__return_true',
        ));
    }

    public function check_auth($request) {
        $user = ZipBiz_REST_API::authenticate_user($request);
        return !is_wp_error($user);
    }

    /**
     * Create a booking with server-side price calculation and race condition protection
     */
    public function create_booking($request) {
        global $wpdb;
        $user = wp_get_current_user();
        if (!$user || !$user->ID) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'User not authenticated', 401);
        }

        $params = $request->get_json_params();
        $listing_id = isset($params['listing_id']) ? intval($params['listing_id']) : 0;
        $date = sanitize_text_field(isset($params['date']) ? $params['date'] : '');
        $time_slot = sanitize_text_field(isset($params['time_slot']) ? $params['time_slot'] : '');
        $selected_services = isset($params['services']) ? (array)$params['services'] : array();
        $address = isset($params['address']) ? (array)$params['address'] : array();
        $notes = sanitize_textarea_field(isset($params['notes']) ? $params['notes'] : '');
        $payment_method = sanitize_text_field(isset($params['payment_method']) ? $params['payment_method'] : 'cod');

        // Validation
        if (!$listing_id || get_post_type($listing_id) !== 'listing') {
            return ZipBiz_REST_API::error_response('INVALID_LISTING', 'Invalid or missing listing ID', 400);
        }
        if (empty($date)) {
            return ZipBiz_REST_API::error_response('INVALID_DATE', 'Please select a service date', 400);
        }

        $listing = get_post($listing_id);
        $owner_id = $listing->post_author;

        // 1. Race Condition / Availability Check
        $table_name = $wpdb->prefix . 'bookings';
        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $existing = $wpdb->get_var($wpdb->prepare(
                "SELECT COUNT(*) FROM $table_name 
                 WHERE listing_id = %d AND date_start = %s 
                 AND status NOT IN ('cancelled', 'rejected') 
                 AND (comment LIKE %s OR comment LIKE %s)",
                $listing_id, $date, '%' . $wpdb->esc_like($time_slot) . '%', '%"slot":"' . $wpdb->esc_like($time_slot) . '"%'
            ));
            $max_slots = get_post_meta($listing_id, '_slot_limit', true) ?: 3;
            if ($existing >= $max_slots) {
                return ZipBiz_REST_API::error_response('BOOKING_SLOT_UNAVAILABLE', 'This time slot is no longer available. Please choose another slot.', 409);
            }
        }

        // 2. Server-Side Price Calculation
        $base_price = floatval(get_post_meta($listing_id, '_price_min', true) ?: 0);
        $menu_items = get_post_meta($listing_id, '_menu', true);
        $total_price = $base_price;
        $item_details = array();

        if (!empty($selected_services) && is_array($menu_items)) {
            $selected_total = 0;
            foreach ($selected_services as $svc_req) {
                $req_name = is_array($svc_req) ? ($svc_req['name'] ?? '') : strval($svc_req);
                foreach ($menu_items as $menu_group) {
                    if (isset($menu_group['menu_elements']) && is_array($menu_group['menu_elements'])) {
                        foreach ($menu_group['menu_elements'] as $elem) {
                            if (strcasecmp(trim($elem['name']), trim($req_name)) === 0) {
                                $item_price = floatval($elem['price'] ?? 0);
                                $selected_total += $item_price;
                                $item_details[] = array(
                                    'name'  => $elem['name'],
                                    'price' => $item_price,
                                );
                            }
                        }
                    }
                }
            }
            if ($selected_total > 0) {
                $total_price = $selected_total;
            }
        }

        if ($total_price <= 0) {
            $total_price = floatval(get_post_meta($listing_id, '_price_min', true) ?: 299);
        }

        $tax_and_fee = round($total_price * 0.05, 2); // 5% platform fee
        $final_total = $total_price + $tax_and_fee;

        // 3. Status Determination
        $initial_status = ($payment_method === 'razorpay') ? 'pending' : 'waiting';

        // 4. Create Booking in Listeo
        $booking_id = 0;
        $order_id = 0;

        // Structured booking details
        $booking_data = array(
            'listing_id'     => $listing_id,
            'owner_id'       => $owner_id,
            'user_id'        => $user->ID,
            'customer_name'  => $user->display_name,
            'customer_email' => $user->user_email,
            'customer_phone' => get_user_meta($user->ID, 'billing_phone', true) ?: ($address['phone'] ?? ''),
            'date_start'     => $date . ' 00:00:00',
            'date_end'       => $date . ' 23:59:59',
            'time_slot'      => $time_slot,
            'price'          => $final_total,
            'base_price'     => $total_price,
            'tax_fee'        => $tax_and_fee,
            'status'         => $initial_status,
            'payment_method' => $payment_method,
            'address'        => $address,
            'notes'          => $notes,
            'items'          => $item_details,
            'created'        => current_time('mysql'),
        );

        // Save in Listeo table if table exists
        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $wpdb->insert($table_name, array(
                'bookings_author' => $user->ID,
                'listing_id'      => $listing_id,
                'date_start'      => $date . ' 00:00:00',
                'date_end'        => $date . ' 23:59:59',
                'comment'         => json_encode($booking_data),
                'order_id'        => 0,
                'status'          => $initial_status,
                'price'           => $final_total,
                'created'         => current_time('mysql'),
            ));
            $booking_id = $wpdb->insert_id;
        } else {
            // Fallback to custom post type 'booking'
            $booking_id = wp_insert_post(array(
                'post_type'    => 'booking',
                'post_title'   => 'Booking #' . $listing->post_title,
                'post_status'  => 'publish',
                'post_author'  => $user->ID,
            ));
            update_post_meta($booking_id, '_booking_data', $booking_data);
            update_post_meta($booking_id, '_listing_id', $listing_id);
            update_post_meta($booking_id, '_status', $initial_status);
            update_post_meta($booking_id, '_price', $final_total);
        }

        // Store address in user meta for future autofill
        if (!empty($address)) {
            update_user_meta($user->ID, '_zipbiz_last_service_address', $address);
        }

        // Notify Vendor of New Booking Request
        ZipBiz_Notifications::send_push_notification(
            $owner_id,
            'New Booking Request! 🔔',
            "New appointment booked for {$listing->post_title} on {$date} ({$time_slot})",
            array(
                'type'       => 'booking_new',
                'booking_id' => $booking_id,
                'listing_id' => $listing_id,
            )
        );

        $booking_data['booking_id'] = $booking_id;
        $booking_data['listing_title'] = $listing->post_title;
        $booking_data['listing_image'] = get_the_post_thumbnail_url($listing_id, 'medium') ?: '';

        return ZipBiz_REST_API::success_response($booking_data, 'Booking created successfully', 201);
    }

    /**
     * Get booking details
     */
    public function get_booking_detail($request) {
        global $wpdb;
        $user = wp_get_current_user();
        $booking_id = intval($request['id']);

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
                    'listing_id'      => get_post_meta($booking_id, '_listing_id', true),
                    'price'           => get_post_meta($booking_id, '_price', true),
                    'status'          => get_post_meta($booking_id, '_status', true),
                    'comment'         => json_encode(get_post_meta($booking_id, '_booking_data', true)),
                    'created'         => $post->post_date,
                );
            }
        }

        if (!$row) {
            return ZipBiz_REST_API::error_response('NOT_FOUND', 'Booking not found', 404);
        }

        $listing = get_post($row['listing_id']);
        $owner_id = $listing ? $listing->post_author : 0;

        // Security check: only the booking author, listing owner, or admin can view
        if ($row['bookings_author'] != $user->ID && $owner_id != $user->ID && !current_user_can('manage_options')) {
            return ZipBiz_REST_API::error_response('FORBIDDEN', 'You do not have permission to view this booking', 403);
        }

        $comment_data = json_decode($row['comment'], true) ?: array();
        $response_data = array_merge($comment_data, array(
            'booking_id'    => intval($row['id']),
            'status'        => $row['status'],
            'price'         => floatval($row['price']),
            'created'       => $row['created'],
            'listing_id'    => intval($row['listing_id']),
            'listing_title' => $listing ? $listing->post_title : 'Service',
            'listing_image' => $listing ? (get_the_post_thumbnail_url($listing->ID, 'medium') ?: '') : '',
            'listing_phone' => get_post_meta($row['listing_id'], '_phone', true) ?: '',
            'listing_address' => get_post_meta($row['listing_id'], '_address', true) ?: '',
        ));

        return ZipBiz_REST_API::success_response($response_data);
    }

    /**
     * Get availability slots for a given date
     */
    public function get_availability($request) {
        $listing_id = intval($request->get_param('listing_id'));
        $date = sanitize_text_field($request->get_param('date') ?: date('Y-m-d'));

        if (!$listing_id || get_post_type($listing_id) !== 'listing') {
            return ZipBiz_REST_API::error_response('INVALID_LISTING', 'Invalid listing ID', 400);
        }

        // Standard ZipBiz time slots
        $standard_slots = array(
            '09:00 AM - 11:00 AM',
            '11:00 AM - 01:00 PM',
            '02:00 PM - 04:00 PM',
            '04:00 PM - 06:00 PM',
            '06:00 PM - 08:00 PM',
        );

        global $wpdb;
        $table_name = $wpdb->prefix . 'bookings';
        $booked_slots = array();

        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $results = $wpdb->get_col($wpdb->prepare(
                "SELECT comment FROM $table_name 
                 WHERE listing_id = %d AND date_start LIKE %s 
                 AND status NOT IN ('cancelled', 'rejected')",
                $listing_id, $date . '%'
            ));
            foreach ($results as $c) {
                $decoded = json_decode($c, true);
                if (!empty($decoded['time_slot'])) {
                    $booked_slots[] = $decoded['time_slot'];
                }
            }
        }

        $slots_out = array();
        $is_today = ($date === date('Y-m-d'));
        $current_hour = intval(date('H'));

        foreach ($standard_slots as $slot) {
            $is_available = true;
            if (in_array($slot, $booked_slots)) {
                $is_available = false;
            }
            // Check if slot has already passed today
            if ($is_today) {
                $start_hour = intval(substr($slot, 0, 2));
                if (strpos($slot, 'PM') !== false && $start_hour < 12) {
                    $start_hour += 12;
                }
                if ($start_hour <= $current_hour) {
                    $is_available = false;
                }
            }
            $slots_out[] = array(
                'time'      => $slot,
                'available' => $is_available,
            );
        }

        return ZipBiz_REST_API::success_response(array(
            'date'  => $date,
            'slots' => $slots_out,
        ));
    }

    /**
     * Cancel a booking
     */
    public function cancel_booking($request) {
        global $wpdb;
        $user = wp_get_current_user();
        $booking_id = intval($request['id']);

        $table_name = $wpdb->prefix . 'bookings';
        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $row = $wpdb->get_row($wpdb->prepare("SELECT * FROM $table_name WHERE id = %d", $booking_id), ARRAY_A);
            if (!$row) {
                return ZipBiz_REST_API::error_response('NOT_FOUND', 'Booking not found', 404);
            }

            $listing = get_post($row['listing_id']);
            $owner_id = $listing ? $listing->post_author : 0;

            if ($row['bookings_author'] != $user->ID && $owner_id != $user->ID && !current_user_can('manage_options')) {
                return ZipBiz_REST_API::error_response('FORBIDDEN', 'Cannot cancel this booking', 403);
            }

            $wpdb->update($table_name, array('status' => 'cancelled'), array('id' => $booking_id));
        }

        // Notify other party
        $comment_data = json_decode($row['comment'] ?? '{}', true);
        $notify_target = ($user->ID == $row['bookings_author']) ? ($listing->post_author ?? 0) : $row['bookings_author'];
        ZipBiz_Notifications::send_push_notification(
            $notify_target,
            'Booking Cancelled',
            "Booking #{$booking_id} has been cancelled.",
            array('type' => 'booking_cancelled', 'booking_id' => $booking_id)
        );

        return ZipBiz_REST_API::success_response(array('booking_id' => $booking_id, 'status' => 'cancelled'), 'Booking successfully cancelled');
    }

    /**
     * Get all bookings made by customer
     */
    public function get_customer_bookings($request) {
        global $wpdb;
        $user_id = intval($request->get_param('user_id'));
        if (!$user_id) {
            $user = wp_get_current_user();
            $user_id = ($user && $user->ID) ? $user->ID : 0;
        }

        if (!$user_id) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'User not authenticated', 401);
        }

        $table_name = $wpdb->prefix . 'bookings';
        $status = sanitize_text_field($request->get_param('status') ?: 'all');
        $page = max(1, intval($request->get_param('page') ?: 1));
        $per_page = min(50, max(1, intval($request->get_param('per_page') ?: 20)));
        $offset = ($page - 1) * $per_page;

        $where = "WHERE bookings_author = $user_id";
        if ($status !== 'all') {
            if ($status === 'upcoming') {
                $where .= " AND status IN ('confirmed', 'waiting', 'pending', 'in_progress', 'paid')";
            } elseif ($status === 'completed') {
                $where .= " AND status IN ('completed', 'finished')";
            } elseif ($status === 'cancelled') {
                $where .= " AND status IN ('cancelled', 'rejected')";
            } else {
                $where .= $wpdb->prepare(" AND status = %s", $status);
            }
        }

        $items = array();
        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $rows = $wpdb->get_results("SELECT * FROM $table_name $where ORDER BY id DESC LIMIT $offset, $per_page", ARRAY_A);
            foreach ($rows as $r) {
                $listing = get_post($r['listing_id']);
                $comment_data = json_decode($r['comment'], true) ?: array();
                $items[] = array_merge($comment_data, array(
                    'id'             => intval($r['id']),
                    'booking_id'     => intval($r['id']),
                    'order_id'       => $r['order_id'] ?? 0,
                    'status'         => $r['status'],
                    'price'          => floatval($r['price']),
                    'created'        => $r['created'],
                    'created_date'   => date('d M Y, h:i A', strtotime($r['created'])),
                    'date_start'     => $r['date_start'],
                    'date_end'       => $r['date_end'],
                    'listing_id'     => intval($r['listing_id']),
                    'title'          => $listing ? $listing->post_title : 'Home Service',
                    'listing_title'  => $listing ? $listing->post_title : 'Home Service',
                    'featured_image' => $listing ? (get_the_post_thumbnail_url($listing->ID, 'medium') ?: '') : '',
                ));
            }
        } else {
            $args = array(
                'post_type'      => 'booking',
                'author'         => $user_id,
                'posts_per_page' => $per_page,
                'paged'          => $page,
                'orderby'        => 'date',
                'order'          => 'DESC',
            );
            $posts = get_posts($args);
            foreach ($posts as $p) {
                $b_data = get_post_meta($p->ID, '_booking_data', true) ?: array();
                $lid = get_post_meta($p->ID, '_listing_id', true);
                $listing = get_post($lid);
                $items[] = array_merge($b_data, array(
                    'id'             => $p->ID,
                    'booking_id'     => $p->ID,
                    'status'         => get_post_meta($p->ID, '_status', true) ?: 'waiting',
                    'price'          => floatval(get_post_meta($p->ID, '_price', true) ?: 499),
                    'created'        => $p->post_date,
                    'created_date'   => date('d M Y, h:i A', strtotime($p->post_date)),
                    'title'          => $listing ? $listing->post_title : $p->post_title,
                    'featured_image' => $listing ? (get_the_post_thumbnail_url($listing->ID, 'medium') ?: '') : '',
                ));
            }
        }

        if (strpos($request->get_route(), 'get-bookings') !== false) {
            return new WP_REST_Response($items, 200);
        }

        return ZipBiz_REST_API::success_response($items);
    }
}
