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

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/customer/has-confirmed-booking', array(
            'methods'  => 'GET',
            'callback' => array($this, 'check_has_confirmed_booking'),
            'permission_callback' => array($this, 'check_auth'),
        ));

        register_rest_route('wp/v2', '/get-bookings', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_customer_bookings'),
            'permission_callback' => '__return_true',
        ));

        register_rest_route('wp/v2', '/booking', array(
            'methods'  => 'POST',
            'callback' => array($this, 'create_booking'),
            'permission_callback' => '__return_true',
        ));

        register_rest_route('wp/v2', '/check-availability', array(
            'methods'  => array('GET', 'POST'),
            'callback' => array($this, 'get_availability'),
            'permission_callback' => '__return_true',
        ));

        // User Bookmarks
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/user/bookmarks', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_user_bookmarks'),
            'permission_callback' => array($this, 'check_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/user/bookmarks/toggle', array(
            'methods'  => 'POST',
            'callback' => array($this, 'toggle_user_bookmark'),
            'permission_callback' => array($this, 'check_auth'),
        ));

        // User Profile Management & Password Change
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/user/profile', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_user_profile'),
            'permission_callback' => array($this, 'check_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/user/profile', array(
            'methods'  => 'POST',
            'callback' => array($this, 'update_user_profile'),
            'permission_callback' => array($this, 'check_auth'),
        ));
    }

    public function check_auth($request) {
        $user = ZipBiz_REST_API::authenticate_user($request);
        return !is_wp_error($user);
    }

    public static function get_bookings_table() {
        global $wpdb;
        $calendar_table = $wpdb->prefix . 'bookings_calendar';
        if ($wpdb->get_var("SHOW TABLES LIKE '$calendar_table'") === $calendar_table) {
            return $calendar_table;
        }
        $bookings_table = $wpdb->prefix . 'bookings';
        if ($wpdb->get_var("SHOW TABLES LIKE '$bookings_table'") === $bookings_table) {
            return $bookings_table;
        }
        return $calendar_table;
    }

    /**
     * Locate booking across calendar, bookings table, and custom posts
     */
    public static function find_booking($booking_id) {
        global $wpdb;
        $booking_id = intval($booking_id);
        if ($booking_id <= 0) {
            return null;
        }

        $tables = array();
        $calendar_table = $wpdb->prefix . 'bookings_calendar';
        if ($wpdb->get_var("SHOW TABLES LIKE '$calendar_table'") === $calendar_table) {
            $tables[] = $calendar_table;
        }
        $bookings_table = $wpdb->prefix . 'bookings';
        if ($wpdb->get_var("SHOW TABLES LIKE '$bookings_table'") === $bookings_table && !in_array($bookings_table, $tables)) {
            $tables[] = $bookings_table;
        }

        // 1. Search by row ID in calendar and bookings tables
        foreach ($tables as $t) {
            $row = $wpdb->get_row($wpdb->prepare("SELECT * FROM $t WHERE id = %d", $booking_id), ARRAY_A);
            if ($row) {
                return array('row' => $row, 'table' => $t, 'is_post' => false);
            }
        }

        // 2. Search by order_id in calendar and bookings tables
        foreach ($tables as $t) {
            $row = $wpdb->get_row($wpdb->prepare("SELECT * FROM $t WHERE order_id = %d", $booking_id), ARRAY_A);
            if ($row) {
                return array('row' => $row, 'table' => $t, 'is_post' => false);
            }
        }

        // 3. Check custom post type 'booking'
        $post = get_post($booking_id);
        if ($post && $post->post_type === 'booking') {
            $data = get_post_meta($booking_id, '_booking_data', true) ?: array();
            $status = get_post_meta($booking_id, '_status', true) ?: $post->post_status;
            $price = get_post_meta($booking_id, '_price', true) ?: '0';
            $listing_id = get_post_meta($booking_id, '_listing_id', true) ?: 0;
            $row = array(
                'id'              => $post->ID,
                'bookings_author' => $post->post_author,
                'owner_id'        => get_post_field('post_author', $listing_id) ?: 0,
                'listing_id'      => $listing_id,
                'status'          => $status,
                'price'           => $price,
                'comment'         => is_array($data) ? json_encode($data) : $data,
                'date_start'      => $data['date_start'] ?? $post->post_date,
                'date_end'        => $data['date_end'] ?? $post->post_date,
                'order_id'        => get_post_meta($booking_id, '_order_id', true) ?: 0,
            );
            return array('row' => $row, 'table' => $wpdb->posts, 'is_post' => true);
        }

        return null;
    }

    /**
     * Create a booking with server-side price calculation and race condition protection
     */
    public function create_booking($request) {
        global $wpdb;
        $user = ZipBiz_REST_API::authenticate_user($request);
        if (is_wp_error($user) || !$user || !$user->ID) {
            $user = wp_get_current_user();
        }
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
        $table_name = self::get_bookings_table();
        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $existing = $wpdb->get_var($wpdb->prepare(
                "SELECT COUNT(*) FROM $table_name 
                 WHERE listing_id = %d AND DATE(date_start) = %s 
                 AND status NOT IN ('cancelled', 'rejected', 'expired') 
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

        // Fetch custom fee from vendor listing (as configured on website)
        $custom_fee_amount = floatval(get_post_meta($listing_id, '_additional_fee_amount', true) ?: get_post_meta($listing_id, 'additional_fee_amount', true) ?: get_post_meta($listing_id, '_visiting_fee', true) ?: 0);
        $custom_fee_label = get_post_meta($listing_id, '_additional_fee_label', true) ?: get_post_meta($listing_id, 'additional_fee_label', true) ?: 'Service Fee';
        $tax_and_fee = $custom_fee_amount; // No platform fee, only vendor custom fee
        $final_total = $total_price + $tax_and_fee;

        // 3. Status Determination
        $initial_status = ($payment_method === 'razorpay') ? 'pending' : 'waiting';

        // 4. Create Booking in Listeo
        $booking_id = 0;
        $order_id = 0;

        if (function_exists('wc_create_order')) {
            try {
                $order = wc_create_order(array('customer_id' => $user->ID));
                if ($order && !is_wp_error($order)) {
                    $item_name = $listing->post_title;
                    if (!empty($item_details)) {
                        $names = array_map(function($i) { return $i['name']; }, $item_details);
                        $item_name .= ' (' . implode(', ', $names) . ')';
                    }
                    if (class_exists('WC_Order_Item_Fee')) {
                        $item_fee = new WC_Order_Item_Fee();
                        $item_fee->set_name($item_name);
                        $item_fee->set_amount($total_price);
                        $item_fee->set_total($total_price);
                        $order->add_item($item_fee);

                        if ($tax_and_fee > 0) {
                            $cust_fee_item = new WC_Order_Item_Fee();
                            $cust_fee_item->set_name($custom_fee_label);
                            $cust_fee_item->set_amount($tax_and_fee);
                            $cust_fee_item->set_total($tax_and_fee);
                            $order->add_item($cust_fee_item);
                        }
                    }
                    $order->set_payment_method($payment_method === 'razorpay' ? 'razorpay' : 'cod');
                    $order->set_payment_method_title($payment_method === 'razorpay' ? 'Razorpay Online' : 'Cash on Delivery');
                    $order->set_status($payment_method === 'razorpay' ? 'pending' : 'processing');
                    $order->calculate_totals();
                    $order->save();
                    $order_id = $order->get_id();
                }
            } catch (Exception $e) {}
        }

        $slot_parts = explode(' - ', $time_slot);
        $start_time = !empty($slot_parts[0]) ? trim($slot_parts[0]) : '09:00:00';
        $end_time = !empty($slot_parts[1]) ? trim($slot_parts[1]) : '18:00:00';
        $start_dt = date('Y-m-d H:i:s', strtotime($date . ' ' . $start_time));
        $end_dt = date('Y-m-d H:i:s', strtotime($date . ' ' . $end_time));

        // Structured booking details
        $customer_first = $user->first_name ?: $user->display_name;
        $customer_last = $user->last_name ?: '';
        $customer_phone = get_user_meta($user->ID, 'billing_phone', true) ?: ($address['phone'] ?? '');

        $booking_data = array(
            'first_name'     => $customer_first,
            'last_name'      => $customer_last,
            'name'           => $user->display_name,
            'customer_name'  => $user->display_name,
            'email'          => $user->user_email,
            'customer_email' => $user->user_email,
            'phone'          => $customer_phone,
            'customer_phone' => $customer_phone,
            'service'        => !empty($item_details) ? $item_details : $selected_services,
            'slot'           => $time_slot,
            'time_slot'      => $time_slot,
            'date'           => $date,
            'listing_id'     => $listing_id,
            'owner_id'       => $owner_id,
            'user_id'        => $user->ID,
            'date_start'     => $start_dt,
            'date_end'       => $end_dt,
            'price'          => $final_total,
            'base_price'     => $total_price,
            'tax_fee'        => $tax_and_fee,
            'status'         => $initial_status,
            'payment_method' => $payment_method,
            'address'        => $address,
            'notes'          => $notes,
            'message'        => $notes,
            'items'          => $item_details,
            'created'        => current_time('mysql'),
        );

        // Save in Listeo table if table exists
        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $insert_data = array(
                'bookings_author' => $user->ID,
                'owner_id'        => $owner_id,
                'listing_id'      => $listing_id,
                'date_start'      => $start_dt,
                'date_end'        => $end_dt,
                'comment'         => json_encode($booking_data),
                'type'            => 'reservation',
                'order_id'        => $order_id,
                'status'          => $initial_status,
                'price'           => $final_total,
                'created'         => current_time('mysql'),
            );
            $wpdb->insert($table_name, $insert_data);
            $booking_id = $wpdb->insert_id;

            // Trigger Listeo native booking calendar workflow
            if ($booking_id && class_exists('Listeo_Core_Bookings_Calendar') && method_exists('Listeo_Core_Bookings_Calendar', 'set_booking_status')) {
                Listeo_Core_Bookings_Calendar::set_booking_status($booking_id, $initial_status);
            }
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

        // Trigger Listeo native booking notification hooks
        $owner_info = get_userdata($owner_id);
        if ($owner_info) {
            $mail_to_owner_args = array(
                'email'   => $owner_info->user_email,
                'booking' => $booking_data,
            );
            do_action('listeo_mail_to_owner_new_reservation', $mail_to_owner_args);
        }
        $mail_to_user_args = array(
            'email'   => $user->user_email,
            'booking' => $booking_data,
        );
        do_action('listeo_mail_to_user_waiting_approval', $mail_to_user_args);

        // Notify Vendor of New Booking Request via FCM Push
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
        $booking_data['listing_image'] = get_the_post_thumbnail_url($listing_id, 'medium') ?: (get_post_meta($listing_id, '_featured_image_url', true) ?: '');

        return ZipBiz_REST_API::success_response($booking_data, 'Booking created successfully', 201);
    }

    /**
     * Get booking details
     */
    public function get_booking_detail($request) {
        global $wpdb;
        $user = wp_get_current_user();
        $booking_id = intval($request['id']);

        $table_name = self::get_bookings_table();
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
        global $wpdb;
        $listing_id = intval($request->get_param('listing_id'));
        $date = sanitize_text_field($request->get_param('date') ?: date('Y-m-d'));

        if (!$listing_id || get_post_type($listing_id) !== 'listing') {
            return ZipBiz_REST_API::error_response('INVALID_LISTING', 'Invalid listing ID', 400);
        }

        // Day matching keys
        $dayofweek = intval(date('w', strtotime($date))); // 0=Sun..6=Sat
        $actual_day = ($dayofweek == 0) ? 6 : ($dayofweek - 1); // 0=Mon..6=Sun
        $iso_day = intval(date('N', strtotime($date))); // 1=Mon..7=Sun
        $day_name = strtolower(date('l', strtotime($date)));
        $day_short = substr($day_name, 0, 3);

        $decoded_slots = null;
        if (class_exists('Listeo_Core_Bookings_Calendar') && method_exists('Listeo_Core_Bookings_Calendar', 'get_slots_from_meta')) {
            $listeo_raw = Listeo_Core_Bookings_Calendar::get_slots_from_meta($listing_id);
            if (!empty($listeo_raw)) {
                $decoded_slots = json_decode(json_encode($listeo_raw), true);
            }
        }

        if (!$decoded_slots) {
            $un_slots = get_post_meta($listing_id, '_slots', true) ?: get_post_meta($listing_id, 'slots', true);
            if (is_string($un_slots)) {
                $decoded_slots = json_decode($un_slots, true);
                if (!is_array($decoded_slots) && function_exists('maybe_unserialize')) {
                    $decoded_slots = maybe_unserialize($un_slots);
                }
            } else {
                $decoded_slots = $un_slots;
            }
        }

        $standard_slots = array();
        $day_slots = null;
        $has_configured_slots = false;

        if (is_array($decoded_slots) && !empty($decoded_slots)) {
            $possible_keys = array(
                $actual_day,
                strval($actual_day),
                $dayofweek,
                strval($dayofweek),
                $iso_day,
                strval($iso_day),
                $day_name,
                ucfirst($day_name),
                $day_short,
                ucfirst($day_short),
            );
            foreach ($possible_keys as $k) {
                if (isset($decoded_slots[$k]) && !empty($decoded_slots[$k])) {
                    $day_slots = $decoded_slots[$k];
                    $has_configured_slots = true;
                    break;
                }
            }
        }

        $max_slots = intval(get_post_meta($listing_id, '_slot_limit', true) ?: 3);
        $slot_interval = floatval($request->get_param('interval') ?: get_post_meta($listing_id, '_slot_interval', true) ?: 1);

        if (is_array($day_slots) && !empty($day_slots)) {
            foreach ($day_slots as $slot_item) {
                if (is_string($slot_item)) {
                    $parts = explode('|', $slot_item);
                    if (!empty($parts[0])) {
                        $standard_slots[] = array(
                            'time'     => trim($parts[0]),
                            'capacity' => (!empty($parts[1]) && intval($parts[1]) > 0) ? intval($parts[1]) : $max_slots,
                        );
                    }
                } elseif (is_array($slot_item)) {
                    $time_str = $slot_item['time'] ?? $slot_item['slot'] ?? '';
                    if (empty($time_str) && !empty($slot_item['from']) && !empty($slot_item['to'])) {
                        $time_str = trim($slot_item['from']) . ' - ' . trim($slot_item['to']);
                    }
                    if (!empty($time_str)) {
                        $parts = explode('|', $time_str);
                        $standard_slots[] = array(
                            'time'     => trim($parts[0]),
                            'capacity' => intval($slot_item['capacity'] ?? (!empty($parts[1]) ? $parts[1] : $max_slots)),
                        );
                    }
                }
            }
        }

        // Check opening hours if no custom slot intervals
        if (empty($standard_slots)) {
            $opening_hours = get_post_meta($listing_id, '_opening_hours', true) ?: get_post_meta($listing_id, 'opening_hours', true);
            if (is_string($opening_hours)) {
                $opening_hours = json_decode($opening_hours, true) ?: maybe_unserialize($opening_hours);
            }
            $open_time = null;
            $close_time = null;
            if (is_array($opening_hours)) {
                $open_keys = array("{$day_name}_opening", "_{$day_name}_opening", "{$day_short}_opening", "open");
                $close_keys = array("{$day_name}_closing", "_{$day_name}_closing", "{$day_short}_closing", "close");
                foreach ($open_keys as $ok) {
                    if (!empty($opening_hours[$ok])) { $open_time = $opening_hours[$ok]; break; }
                }
                foreach ($close_keys as $ck) {
                    if (!empty($opening_hours[$ck])) { $close_time = $opening_hours[$ck]; break; }
                }
            }
            if (!empty($open_time) && !empty($close_time)) {
                $step = max(1, intval($slot_interval > 0 ? $slot_interval : 3));
                $start_ts = strtotime("$date $open_time");
                $end_ts = strtotime("$date $close_time");
                while ($start_ts + ($step * 3600) <= $end_ts) {
                    $slot_label = date("h:i A", $start_ts) . ' - ' . date("h:i A", $start_ts + ($step * 3600));
                    $standard_slots[] = array(
                        'time'     => $slot_label,
                        'capacity' => $max_slots,
                    );
                    $start_ts += ($step * 3600);
                }
            }
        }

        // Default slots: 3-hour intervals with 5 slots per day: 08:00 AM to 11:00 PM
        if (empty($standard_slots)) {
            $default_times = array(
                '08:00 AM - 11:00 AM',
                '11:00 AM - 02:00 PM',
                '02:00 PM - 05:00 PM',
                '05:00 PM - 08:00 PM',
                '08:00 PM - 11:00 PM',
            );
            $max_slots = intval(get_post_meta($listing_id, '_slot_limit', true) ?: 5);
            foreach ($default_times as $dt) {
                $standard_slots[] = array(
                    'time'     => $dt,
                    'capacity' => $max_slots,
                );
            }
        }

        // Exclude slots that have already passed if date is today
        $today = current_time('Y-m-d');
        if ($date === $today && !empty($standard_slots)) {
            $current_time = current_time('H:i');
            $filtered_slots = array();
            foreach ($standard_slots as $slot) {
                $slot_time_parts = explode(' - ', $slot['time']);
                $slot_start_hour = date('H:i', strtotime($slot_time_parts[0]));
                if ($slot_start_hour > $current_time) {
                    $filtered_slots[] = $slot;
                }
            }
            $standard_slots = $filtered_slots;
        }

        $table_name = self::get_bookings_table();
        $booked_slots = array();

        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $results = $wpdb->get_results($wpdb->prepare(
                "SELECT date_start, date_end, comment FROM $table_name 
                 WHERE listing_id = %d 
                 AND DATE(date_start) = %s 
                 AND type = 'reservation' 
                 AND status NOT IN ('cancelled', 'rejected', 'expired')",
                $listing_id, $date
            ), ARRAY_A);

            if (!empty($results)) {
                foreach ($results as $row) {
                    $decoded = json_decode($row['comment'] ?? '{}', true);
                    if (!empty($decoded['time_slot'])) {
                        $booked_slots[] = trim($decoded['time_slot']);
                    } else if (!empty($row['date_start']) && !empty($row['date_end'])) {
                        $start_fmt = date("h:i A", strtotime($row['date_start']));
                        $end_fmt = date("h:i A", strtotime($row['date_end']));
                        $booked_slots[] = "$start_fmt - $end_fmt";
                    }
                }
            }
        }

        $slot_counts = array_count_values($booked_slots);
        $slots_out = array();
        $is_today = ($date === date('Y-m-d'));
        $current_hour = intval(date('H'));
        $current_minute = intval(date('i'));

        foreach ($standard_slots as $slot_obj) {
            $slot_str = $slot_obj['time'];
            $capacity = $slot_obj['capacity'];
            $count = isset($slot_counts[$slot_str]) ? $slot_counts[$slot_str] : 0;
            $remaining = max(0, $capacity - $count);
            $is_available = ($remaining > 0);

            // Check if slot has already passed today
            if ($is_today) {
                $hours = explode(' - ', $slot_str);
                $slot_start_time = strtotime($hours[0]);
                if ($slot_start_time !== false) {
                    $slot_hour = intval(date('H', $slot_start_time));
                    $slot_minute = intval(date('i', $slot_start_time));
                    if ($slot_hour < $current_hour || ($slot_hour === $current_hour && $slot_minute <= $current_minute)) {
                        $is_available = false;
                        $remaining = 0;
                    }
                }
            }

            $slots_out[] = array(
                'time'      => $slot_str,
                'available' => $is_available,
                'capacity'  => $capacity,
                'remaining' => $remaining,
            );
        }

        return ZipBiz_REST_API::success_response(array(
            'date'          => $date,
            'slot_interval' => $slot_interval,
            'slot_limit'    => $max_slots,
            'slots'         => $slots_out,
        ));
    }


    /**
     * Cancel a booking
     */
    public function cancel_booking($request) {
        global $wpdb;
        $user = ZipBiz_REST_API::authenticate_user($request);
        if (is_wp_error($user) || !$user || !$user->ID) {
            $user = wp_get_current_user();
        }
        $user_id = ($user && $user->ID) ? $user->ID : intval($request->get_param('user_id') ?: $request->get_header('X-User-ID'));
        if (!$user_id) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'User not authenticated', 401);
        }

        $booking_id = intval($request['id']);

        $found = self::find_booking($booking_id);
        if (!$found || empty($found['row'])) {
            return ZipBiz_REST_API::error_response('NOT_FOUND', 'Booking not found', 404);
        }

        $row = $found['row'];
        $table_name = $found['table'];
        $actual_id = intval($row['id']);

        $listing = get_post($row['listing_id']);
        $owner_id = $listing ? $listing->post_author : ($row['owner_id'] ?? 0);

        if ($user_id > 0 && $row['bookings_author'] != $user_id && $owner_id != $user_id && !current_user_can('manage_options')) {
            return ZipBiz_REST_API::error_response('FORBIDDEN', 'Cannot cancel this booking', 403);
        }

        // Customer cancellation restriction: must be at least 1 hour before scheduled start
        if ($user_id > 0 && $row['bookings_author'] == $user_id && !current_user_can('manage_options')) {
            $start_timestamp = strtotime($row['date_start']);
            if ($start_timestamp && ($start_timestamp - time() < 3600)) {
                return ZipBiz_REST_API::error_response('CANNOT_CANCEL', 'Bookings can only be cancelled up to 1 hour before scheduled start time. Please contact support.', 400);
            }
        }

        if ($found['is_post']) {
            update_post_meta($actual_id, '_status', 'cancelled');
            wp_update_post(array('ID' => $actual_id, 'post_status' => 'cancelled'));
        } else {
            if (class_exists('Listeo_Core_Bookings_Calendar') && method_exists('Listeo_Core_Bookings_Calendar', 'set_booking_status')) {
                Listeo_Core_Bookings_Calendar::set_booking_status($actual_id, 'cancelled');
            }
            $wpdb->update($table_name, array('status' => 'cancelled'), array('id' => $actual_id));
        }

        // Update comment json status if present
        if (!empty($row['comment'])) {
            $cmt = is_array($row['comment']) ? $row['comment'] : json_decode($row['comment'], true);
            if (is_array($cmt)) {
                $cmt['status'] = 'cancelled';
                if ($found['is_post']) {
                    update_post_meta($actual_id, '_booking_data', $cmt);
                } else {
                    $wpdb->update($table_name, array('comment' => json_encode($cmt)), array('id' => $actual_id));
                }
            }
        }

        // If WooCommerce order is attached, update order status to cancelled
        if (!empty($row['order_id']) && intval($row['order_id']) > 0 && function_exists('wc_get_order')) {
            $order = wc_get_order(intval($row['order_id']));
            if ($order) {
                $order->update_status('cancelled', 'Booking cancelled via ZipBiz app.');
            }
        }

        // Notify other party
        $notify_target = ($user_id == $row['bookings_author']) ? $owner_id : $row['bookings_author'];
        ZipBiz_Notifications::send_push_notification(
            $notify_target,
            'Booking Cancelled',
            "Booking #{$actual_id} has been cancelled.",
            array('type' => 'booking_cancelled', 'booking_id' => $actual_id)
        );

        return ZipBiz_REST_API::success_response(array('booking_id' => $actual_id, 'status' => 'cancelled'), 'Booking successfully cancelled');
    }

    /**
     * Get all bookings made by customer
     */
    public function get_customer_bookings($request) {
        global $wpdb;
        $user_id = intval($request->get_param('user_id'));
        if (!$user_id) {
            $user_id = intval($request->get_header('X-User-ID'));
        }
        if (!$user_id) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'User not authenticated', 401);
        }

        $table_name = self::get_bookings_table();
        $status = sanitize_text_field($request->get_param('status') ?: 'all');
        $page = max(1, intval($request->get_param('page') ?: 1));
        $per_page = min(50, max(1, intval($request->get_param('per_page') ?: 20)));
        $offset = ($page - 1) * $per_page;

        // Auto-cancellation sweep for customer bookings
        $wpdb->query(
            "UPDATE $table_name 
             SET status = 'cancelled' 
             WHERE status IN ('waiting', 'pending') 
             AND (
                 (created IS NOT NULL AND created != '0000-00-00 00:00:00' AND created < DATE_SUB(NOW(), INTERVAL 24 HOUR))
                 OR
                 (date_start IS NOT NULL AND date_start != '0000-00-00 00:00:00' AND date_start < NOW())
             )"
        );

        $where = "WHERE bookings_author = $user_id";
        if ($status !== 'all') {
            if ($status === 'upcoming') {
                $where .= " AND status IN ('confirmed', 'waiting', 'pending', 'in_progress', 'paid')";
            } elseif ($status === 'completed') {
                $where .= " AND status IN ('completed', 'finished')";
            } elseif ($status === 'cancelled') {
                $where .= " AND status IN ('cancelled', 'rejected', 'expired')";
            } else {
                $where .= $wpdb->prepare(" AND status = %s", $status);
            }
        }

        $items = array();
        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $rows = $wpdb->get_results("SELECT * FROM $table_name $where ORDER BY id DESC LIMIT $offset, $per_page", ARRAY_A);
            foreach ($rows as $r) {
                $listing = get_post($r['listing_id']);
                $raw_comment = $r['comment'] ?? '';
                $comment_data = is_string($raw_comment) ? json_decode($raw_comment, true) : array();
                if (!is_array($comment_data)) {
                    $comment_data = array();
                }
                $feat_img = $listing ? (get_the_post_thumbnail_url($listing->ID, 'medium') ?: (get_post_meta($listing->ID, '_featured_image_url', true) ?: '')) : '';
                $comment_str = (!empty($raw_comment) && is_string($raw_comment) && strpos($raw_comment, '{') !== false)
                    ? $raw_comment
                    : json_encode($comment_data ?: array('adults' => '1', 'service' => array()));

                $b_id = intval($r['id']);
                $start_otp = $comment_data['start_otp'] ?? strval((($b_id * 31 + 1729) % 9000) + 1000);
                $finish_otp = $comment_data['finish_otp'] ?? strval((($b_id * 47 + 2468) % 9000) + 1000);

                $items[] = array_merge($comment_data, array(
                    'id'             => $b_id,
                    'booking_id'     => $b_id,
                    'order_id'       => $r['order_id'] ?? 0,
                    'status'         => $r['status'],
                    'price'          => strval($r['price']),
                    'price_amount'   => floatval($r['price']),
                    'created'        => $r['created'],
                    'created_date'   => date('d M Y, h:i A', strtotime($r['created'])),
                    'date_start'     => $r['date_start'],
                    'date_end'       => $r['date_end'],
                    'listing_id'     => intval($r['listing_id']),
                    'title'          => $listing ? $listing->post_title : 'Home Service',
                    'listing_title'  => $listing ? $listing->post_title : 'Home Service',
                    'featured_image' => $feat_img,
                    'comment'        => $comment_str,
                    'start_otp'      => $start_otp,
                    'finish_otp'     => $finish_otp,
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
                $feat_img = $listing ? (get_the_post_thumbnail_url($listing->ID, 'medium') ?: (get_post_meta($listing->ID, '_featured_image_url', true) ?: '')) : '';
                $comment_str = json_encode($b_data ?: array('adults' => '1', 'service' => array()));

                $items[] = array_merge($b_data, array(
                    'id'             => $p->ID,
                    'booking_id'     => $p->ID,
                    'status'         => get_post_meta($p->ID, '_status', true) ?: 'waiting',
                    'price'          => strval(get_post_meta($p->ID, '_price', true) ?: '499'),
                    'price_amount'   => floatval(get_post_meta($p->ID, '_price', true) ?: 499),
                    'created'        => $p->post_date,
                    'created_date'   => date('d M Y, h:i A', strtotime($p->post_date)),
                    'title'          => $listing ? $listing->post_title : $p->post_title,
                    'featured_image' => $feat_img,
                    'comment'        => $comment_str,
                ));
            }
        }

        if (strpos($request->get_route(), 'get-bookings') !== false) {
            return new WP_REST_Response($items, 200);
        }

        return ZipBiz_REST_API::success_response($items);
    }


    /**
     * Check if customer has an approved/confirmed booking with vendor or for a listing
     */
    public function check_has_confirmed_booking($request) {
        global $wpdb;
        $user = wp_get_current_user();
        if (!$user || !$user->ID) {
            return ZipBiz_REST_API::success_response(array('has_confirmed' => false));
        }

        $vendor_id = intval($request->get_param('vendor_id'));
        $listing_id = intval($request->get_param('listing_id'));

        $table_name = self::get_bookings_table();
        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $query = "SELECT b.id FROM $table_name b 
                      LEFT JOIN {$wpdb->posts} p ON b.listing_id = p.ID 
                      WHERE b.bookings_author = %d 
                      AND b.status IN ('confirmed', 'paid', 'approved', 'in_progress', 'completed')";
            $params = array($user->ID);

            if ($listing_id > 0) {
                $query .= " AND b.listing_id = %d";
                $params[] = $listing_id;
            }
            if ($vendor_id > 0) {
                $query .= " AND p.post_author = %d";
                $params[] = $vendor_id;
            }
            $query .= " LIMIT 1";

            $found = $wpdb->get_var($wpdb->prepare($query, ...$params));
            if ($found) {
                return ZipBiz_REST_API::success_response(array('has_confirmed' => true, 'booking_id' => intval($found)));
            }
        }

        // Post type 'booking' fallback
        $meta_query = array(
            array('key' => '_booking_user_id', 'value' => $user->ID),
            array('key' => '_booking_status', 'value' => array('confirmed', 'paid', 'approved', 'in_progress', 'completed'), 'compare' => 'IN'),
        );
        if ($listing_id > 0) {
            $meta_query[] = array('key' => '_listing_id', 'value' => $listing_id);
        }
        $posts = get_posts(array(
            'post_type'      => 'booking',
            'meta_query'     => $meta_query,
            'posts_per_page' => 1,
            'fields'         => 'ids',
        ));

        return ZipBiz_REST_API::success_response(array(
            'has_confirmed' => !empty($posts),
            'booking_id'    => !empty($posts) ? $posts[0] : null,
        ));
    }

    /**
     * Get user bookmarks
     */
    public function get_user_bookmarks($request) {
        $user = wp_get_current_user();
        if (!$user || !$user->ID) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'Please log in to view bookmarks', 401);
        }

        $bookmark_ids = get_user_meta($user->ID, '_zipbiz_user_bookmarks', true) ?: array();
        if (!is_array($bookmark_ids)) {
            $bookmark_ids = array();
        }

        $items = array();
        if (!empty($bookmark_ids)) {
            $posts = get_posts(array(
                'post_type'      => 'listing',
                'post__in'       => array_map('intval', $bookmark_ids),
                'posts_per_page' => 100,
                'post_status'    => 'publish',
            ));

            foreach ($posts as $p) {
                $feat_img = get_the_post_thumbnail_url($p->ID, 'medium') ?: (get_post_meta($p->ID, '_featured_image_url', true) ?: '');
                $rating = floatval(get_post_meta($p->ID, '_overall_rating', true) ?: 4.9);
                $price = get_post_meta($p->ID, '_pricing', true) ?: (get_post_meta($p->ID, '_price', true) ?: '399');
                $tagline = get_post_meta($p->ID, '_tagline', true) ?: '';
                $address = get_post_meta($p->ID, '_friendly_address', true) ?: (get_post_meta($p->ID, '_address', true) ?: 'Mohali / Chandigarh');

                $items[] = array(
                    'id'             => $p->ID,
                    'title'          => $p->post_title,
                    'featured_image' => $feat_img,
                    'rating'         => $rating,
                    'price'          => $price,
                    'tagline'        => $tagline,
                    'address'        => $address,
                );
            }
        }

        return ZipBiz_REST_API::success_response(array(
            'bookmarks' => array_values(array_map('strval', $bookmark_ids)),
            'items'     => $items,
        ));
    }

    /**
     * Toggle user bookmark
     */
    public function toggle_user_bookmark($request) {
        $user = wp_get_current_user();
        if (!$user || !$user->ID) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'Please log in to bookmark businesses', 401);
        }

        $params = $request->get_json_params() ?: array();
        $listing_id = intval($params['listing_id'] ?? ($request->get_param('listing_id') ?? 0));
        if ($listing_id <= 0) {
            return ZipBiz_REST_API::error_response('INVALID_ID', 'Valid business ID is required', 400);
        }

        $bookmark_ids = get_user_meta($user->ID, '_zipbiz_user_bookmarks', true) ?: array();
        if (!is_array($bookmark_ids)) {
            $bookmark_ids = array();
        }

        $str_id = strval($listing_id);
        $int_id = intval($listing_id);
        $is_bookmarked = in_array($int_id, $bookmark_ids) || in_array($str_id, $bookmark_ids);

        $current_count = intval(get_post_meta($listing_id, '_bookmark_count', true) ?: get_post_meta($listing_id, '_bookmarks_count', true) ?: 0);

        if ($is_bookmarked) {
            $bookmark_ids = array_values(array_filter($bookmark_ids, function($v) use ($int_id, $str_id) {
                return $v != $int_id && $v != $str_id;
            }));
            $current_count = max(0, $current_count - 1);
            $new_status = false;
            $msg = 'Bookmark removed';
        } else {
            $bookmark_ids[] = $int_id;
            $current_count += 1;
            $new_status = true;
            $msg = 'Bookmark added';
        }

        update_user_meta($user->ID, '_zipbiz_user_bookmarks', $bookmark_ids);
        update_post_meta($listing_id, '_bookmark_count', $current_count);
        update_post_meta($listing_id, '_bookmarks_count', $current_count);

        return ZipBiz_REST_API::success_response(array(
            'listing_id'    => $listing_id,
            'is_bookmarked' => $new_status,
            'total_count'   => $current_count,
            'bookmarks'     => array_values(array_map('strval', $bookmark_ids)),
        ), $msg);
    }

    /**
     * Get user profile
     */
    public function get_user_profile($request) {
        $user = wp_get_current_user();
        if (!$user || !$user->ID) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'Please log in to view profile', 401);
        }

        $phone = get_user_meta($user->ID, 'billing_phone', true) ?: (get_user_meta($user->ID, 'phone', true) ?: '');
        return ZipBiz_REST_API::success_response(array(
            'id'           => $user->ID,
            'username'     => $user->user_login,
            'display_name' => $user->display_name,
            'first_name'   => $user->first_name,
            'last_name'    => $user->last_name,
            'email'        => $user->user_email,
            'phone'        => $phone,
        ));
    }

    /**
     * Update user profile & change password
     */
    public function update_user_profile($request) {
        $user = wp_get_current_user();
        if (!$user || !$user->ID) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'Please log in to update profile', 401);
        }

        $params = $request->get_json_params() ?: array();

        $userdata = array('ID' => $user->ID);
        if (isset($params['first_name'])) {
            $userdata['first_name'] = sanitize_text_field($params['first_name']);
        }
        if (isset($params['last_name'])) {
            $userdata['last_name'] = sanitize_text_field($params['last_name']);
        }
        if (isset($params['display_name'])) {
            $userdata['display_name'] = sanitize_text_field($params['display_name']);
        } elseif (isset($params['first_name'])) {
            $userdata['display_name'] = trim(sanitize_text_field(($params['first_name'] ?? '') . ' ' . ($params['last_name'] ?? '')));
        }
        if (!empty($params['email'])) {
            $email = sanitize_email($params['email']);
            if (is_email($email)) {
                $email_exists = email_exists($email);
                if ($email_exists && $email_exists != $user->ID) {
                    return ZipBiz_REST_API::error_response('EMAIL_EXISTS', 'Email address is already in use by another account.', 400);
                }
                $userdata['user_email'] = $email;
            }
        }

        // Handle password change if requested
        if (!empty($params['new_password'])) {
            $current_pw = $params['current_password'] ?? '';
            if (empty($current_pw)) {
                return ZipBiz_REST_API::error_response('CURRENT_PW_REQUIRED', 'Current password is required to set a new password.', 400);
            }
            if (!wp_check_password($current_pw, $user->user_pass, $user->ID)) {
                return ZipBiz_REST_API::error_response('INVALID_CURRENT_PW', 'Current password entered is incorrect.', 400);
            }
            $userdata['user_pass'] = $params['new_password'];
        }

        $res = wp_update_user($userdata);
        if (is_wp_error($res)) {
            return ZipBiz_REST_API::error_response('UPDATE_FAILED', $res->get_error_message(), 400);
        }

        // Phone meta
        if (isset($params['phone'])) {
            $phone = sanitize_text_field($params['phone']);
            update_user_meta($user->ID, 'billing_phone', $phone);
            update_user_meta($user->ID, 'phone', $phone);
        }

        $updated_user = get_user_by('id', $user->ID);
        return ZipBiz_REST_API::success_response(array(
            'id'           => $updated_user->ID,
            'username'     => $updated_user->user_login,
            'display_name' => $updated_user->display_name,
            'first_name'   => $updated_user->first_name,
            'last_name'    => $updated_user->last_name,
            'email'        => $updated_user->user_email,
            'phone'        => get_user_meta($updated_user->ID, 'billing_phone', true),
        ), 'Profile updated successfully');
    }
}
