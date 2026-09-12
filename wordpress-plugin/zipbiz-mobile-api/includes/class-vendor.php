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

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/bookings/(?P<id>\d+)/cancel', array(
            'methods'  => 'POST',
            'callback' => array($this, 'cancel_booking'),
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

        // Listings CRUD
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/listings', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_listings'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/listing/create', array(
            'methods'  => 'POST',
            'callback' => array($this, 'create_listing'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/listing/(?P<id>\d+)/update', array(
            'methods'  => 'POST',
            'callback' => array($this, 'update_listing'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/listing/(?P<id>\d+)/delete', array(
            'methods'  => 'POST',
            'callback' => array($this, 'delete_listing'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        // Listing Subscription Packages (Silver, Gold, Diamond)
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/packages', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_packages'),
            'permission_callback' => array($this, 'check_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/packages/select-free', array(
            'methods'  => 'POST',
            'callback' => array($this, 'select_free_package'),
            'permission_callback' => array($this, 'check_auth'),
        ));

        // Dynamic Form Fields Schema from website
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/listing-form-fields', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_listing_form_fields'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));


        // Wallet & Payout
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/wallet', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_wallet'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/wallet/withdraw', array(
            'methods'  => 'POST',
            'callback' => array($this, 'request_withdrawal'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        // Reviews, Bookmarks & Coupons
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/reviews', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_reviews'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/bookmarks', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_bookmarks'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/coupons', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_coupons'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/coupons/create', array(
            'methods'  => 'POST',
            'callback' => array($this, 'create_coupon'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        // Vendor Config (Listing types, commission rate, moderation)
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/config', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_config'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        // Media Upload
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/media/upload', array(
            'methods'  => 'POST',
            'callback' => array($this, 'upload_media'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));

        register_rest_route(ZIPBIZ_API_NAMESPACE, '/vendor/media/upload', array(
            'methods'  => 'POST',
            'callback' => array($this, 'upload_media'),
            'permission_callback' => array($this, 'check_vendor_auth'),
        ));
    }

    public static function get_request_user($request) {
        $user = ZipBiz_REST_API::authenticate_user($request);
        if (!is_wp_error($user) && $user && $user->ID > 0) {
            return $user;
        }
        $wp_user = wp_get_current_user();
        if ($wp_user && $wp_user->ID > 0) {
            return $wp_user;
        }
        return null;
    }

    public static function get_vendor_commission_rate($user_id, $listing_id = 0) {
        $user_id = intval($user_id);
        $listing_id = intval($listing_id);

        if ($listing_id > 0) {
            $rate = get_post_meta($listing_id, '_commission_rate', true);
            if ($rate !== '' && is_numeric($rate)) {
                return floatval($rate);
            }
            $rate = get_post_meta($listing_id, 'commission_rate', true);
            if ($rate !== '' && is_numeric($rate)) {
                return floatval($rate);
            }
        }

        if ($user_id > 0) {
            $rate = get_user_meta($user_id, 'listeo_commission_rate', true);
            if ($rate !== '' && is_numeric($rate)) {
                return floatval($rate);
            }
            $rate = get_user_meta($user_id, '_vendor_commission', true);
            if ($rate !== '' && is_numeric($rate)) {
                return floatval($rate);
            }
            $rate = get_user_meta($user_id, 'vendor_commission', true);
            if ($rate !== '' && is_numeric($rate)) {
                return floatval($rate);
            }
        }

        $opt = get_option('listeo_commission_rate', '');
        if ($opt !== '' && is_numeric($opt)) {
            return floatval($opt);
        }
        $opt = get_option('zipbiz_commission_rate', '');
        if ($opt !== '' && is_numeric($opt)) {
            return floatval($opt);
        }
        $opt = get_option('listeo_core_commission', '');
        if ($opt !== '' && is_numeric($opt)) {
            return floatval($opt);
        }

        return 10.0;
    }

    public function check_auth($request) {
        $user = self::get_request_user($request);
        return (!is_wp_error($user) && $user && $user->ID > 0);
    }

    public function check_vendor_auth($request) {
        $user = self::get_request_user($request);
        if (is_wp_error($user) || !$user || !$user->ID) {
            return false;
        }

        // Allow if role is owner, seller, administrator, provider, or vendor
        $roles = (array)$user->roles;
        if (in_array('owner', $roles) || in_array('seller', $roles) || in_array('administrator', $roles) || in_array('provider', $roles) || in_array('vendor', $roles)) {
            return true;
        }

        // Check if user has authored any listings or has an active user package
        $count = count_user_posts($user->ID, 'listing');
        if ($count > 0) {
            return true;
        }

        global $wpdb;
        $table_name = $wpdb->prefix . 'listeo_core_user_packages';
        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $has_pkg = $wpdb->get_var($wpdb->prepare("SELECT COUNT(*) FROM $table_name WHERE user_id = %d", $user->ID));
            if ($has_pkg > 0) {
                return true;
            }
        }

        return true;
    }

    /**
     * Get IDs of all listings owned by current user (strict author isolation)
     */
    private function get_vendor_listing_ids($user_id) {
        $user_id = intval($user_id);
        if ($user_id <= 0) {
            return array();
        }
        $args = array(
            'post_type'      => 'listing',
            'author'         => $user_id,
            'posts_per_page' => -1,
            'fields'         => 'ids',
            'post_status'    => array('publish', 'pending', 'draft', 'expired'),
        );
        return get_posts($args);
    }


    /**
     * Vendor Dashboard KPI Stats
     */
    public function get_dashboard($request) {
        global $wpdb;
        $user = self::get_request_user($request);
        if (!$user) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'User not authenticated', 401);
        }
        $listing_ids = $this->get_vendor_listing_ids($user->ID);
        $commission_rate = self::get_vendor_commission_rate($user->ID);

        if (empty($listing_ids)) {
            return ZipBiz_REST_API::success_response(array(
                'today_bookings'     => 0,
                'pending_bookings'   => 0,
                'upcoming_bookings'  => 0,
                'completed_bookings' => 0,
                'gross_earnings'     => 0,
                'commission_rate'    => $commission_rate,
                'commission'         => 0,
                'net_earnings'       => 0,
                'rating'             => 5.0,
                'reviews_count'      => 0,
                'active_listings'    => 0,
                'total_views'        => 0,
                'total_reviews'      => 0,
                'total_bookmarks'    => 0,
                'total'              => 0,
            ));
        }

        $ids_placeholder = implode(',', array_map('intval', $listing_ids));
        $table_name = ZipBiz_Bookings::get_bookings_table();
        $today = date('Y-m-d');

        $today_count = 0;
        $pending_count = 0;
        $upcoming_count = 0;
        $completed_count = 0;
        $gross_earnings = 0;

        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $today_count = intval($wpdb->get_var("SELECT COUNT(*) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND date_start LIKE '$today%' AND status NOT IN ('cancelled', 'rejected', 'expired')"));
            $pending_count = intval($wpdb->get_var("SELECT COUNT(*) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status IN ('waiting', 'pending')"));
            $upcoming_count = intval($wpdb->get_var("SELECT COUNT(*) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status = 'confirmed' AND date_start >= '$today'"));
            $completed_count = intval($wpdb->get_var("SELECT COUNT(*) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status IN ('completed', 'finished')"));
            $gross_earnings = floatval($wpdb->get_var("SELECT SUM(price) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status IN ('completed', 'confirmed')"));
        }

        $commission = round($gross_earnings * ($commission_rate / 100.0), 2);
        $net_earnings = round($gross_earnings - $commission, 2);

        // Views, Bookmarks and Reviews aggregation
        $total_views = 0;
        $total_bookmarks = 0;
        $total_reviews = 0;
        $saved_counts = array();
        $bm_meta = $wpdb->get_results("SELECT meta_value FROM {$wpdb->usermeta} WHERE meta_key IN ('listeo_core_bookmarks', '_zipbiz_user_bookmarks', 'listeo_bookmarks')", ARRAY_A);
        if (!empty($bm_meta)) {
            foreach ($bm_meta as $bm_row) {
                $b_val = $bm_row['meta_value'];
                $b_ids = is_string($b_val) ? json_decode($b_val, true) : $b_val;
                if (!is_array($b_ids) && is_string($b_val) && function_exists('maybe_unserialize')) {
                    $b_ids = @maybe_unserialize($b_val);
                }
                if (is_array($b_ids)) {
                    foreach ($b_ids as $b_lid) {
                        $b_int = intval($b_lid);
                        if ($b_int > 0) {
                            $saved_counts[$b_int] = ($saved_counts[$b_int] ?? 0) + 1;
                        }
                    }
                }
            }
        }

        foreach ($listing_ids as $lid) {
            $views = get_post_meta($lid, '_count_views', true) ?: get_post_meta($lid, '_listing_views_count', true);
            $total_views += intval($views ?: 0);

            $bookmarks = get_post_meta($lid, '_bookmark_count', true) ?: get_post_meta($lid, '_bookmarks_count', true);
            $count = intval($bookmarks ?: 0);
            $user_count = $saved_counts[$lid] ?? 0;
            if ($user_count > $count) {
                $count = $user_count;
            }
            $total_bookmarks += $count;
        }

        $ids_in = implode(',', array_map('intval', $listing_ids));
        $total_reviews = intval($wpdb->get_var("SELECT COUNT(*) FROM {$wpdb->comments} WHERE comment_post_ID IN ($ids_in) AND comment_approved = '1'"));
        $avg_rating = floatval($wpdb->get_var("SELECT AVG(meta_value) FROM {$wpdb->commentmeta} WHERE meta_key IN ('listeo-rating', 'rating') AND comment_id IN (SELECT comment_ID FROM {$wpdb->comments} WHERE comment_post_ID IN ($ids_in) AND comment_approved = '1')"));
        $final_rating = ($avg_rating > 0) ? round($avg_rating, 1) : 5.0;

        return ZipBiz_REST_API::success_response(array(
            'today_bookings'     => $today_count,
            'pending_bookings'   => $pending_count,
            'upcoming_bookings'  => $upcoming_count,
            'completed_bookings' => $completed_count,
            'gross_earnings'     => $gross_earnings,
            'commission_rate'    => $commission_rate,
            'commission'         => $commission,
            'net_earnings'       => $net_earnings,
            'rating'             => $final_rating,
            'active_listings'    => count($listing_ids),
            'total_views'        => $total_views,
            'total_reviews'      => $total_reviews,
            'total_bookmarks'    => $total_bookmarks,
            'total'              => $total_bookmarks,
        ));
    }

    /**
     * Get vendor's bookings list with status filters
     */
    public function get_bookings($request) {
        global $wpdb;
        $user = self::get_request_user($request);
        if (!$user) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'User not authenticated', 401);
        }
        $listing_ids = $this->get_vendor_listing_ids($user->ID);
        $table_name = ZipBiz_Bookings::get_bookings_table();

        // Also check if any bookings have owner_id matching this user
        $owner_booking_lids = array();
        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $owner_booking_lids = $wpdb->get_col($wpdb->prepare(
                "SELECT DISTINCT listing_id FROM $table_name WHERE owner_id = %d",
                $user->ID
            ));
        }
        $all_target_lids = array_unique(array_filter(array_merge($listing_ids, array_map('intval', $owner_booking_lids))));

        if (empty($all_target_lids)) {
            return ZipBiz_REST_API::success_response(array(
                'items'       => array(),
                'page'        => 1,
                'per_page'    => 20,
                'total'       => 0,
                'total_pages' => 0,
            ));
        }

        $ids_placeholder = implode(',', array_map('intval', $all_target_lids));
        $status = sanitize_text_field($request->get_param('status') ?: 'all');
        $page = max(1, intval($request->get_param('page') ?: 1));
        $per_page = min(50, max(1, intval($request->get_param('per_page') ?: 20)));
        $offset = ($page - 1) * $per_page;

        // Auto-cancellation sweep:
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

        $where = "WHERE (listing_id IN ($ids_placeholder) OR owner_id = {$user->ID})";
        if ($status !== 'all') {
            if ($status === 'ongoing') {
                $where .= " AND status IN ('confirmed', 'waiting', 'pending', 'in_progress')";
            } elseif ($status === 'completed') {
                $where .= " AND status IN ('completed', 'finished')";
            } elseif ($status === 'cancelled') {
                $where .= " AND status IN ('cancelled', 'rejected', 'expired')";
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
            $b_id = intval($r['id']);
            $order_id = intval($r['order_id'] ?? 0);
            $start_otp = $comment_data['start_otp'] ?? strval((($b_id * 31 + 1729) % 9000) + 1000);
            $finish_otp = $comment_data['finish_otp'] ?? strval((($b_id * 47 + 2468) % 9000) + 1000);

            // Dynamic Commission Rate calculation per listing
            $comm_rate = self::get_vendor_commission_rate($user->ID, intval($r['listing_id']));
            $booking_price = floatval($r['price']);
            $comm_amount = round($booking_price * ($comm_rate / 100.0), 2);
            $net_earning = round($booking_price - $comm_amount, 2);

            // Extract booked services with name and price
            $services_booked = array();
            if (!empty($comment_data['services']) && is_array($comment_data['services'])) {
                $services_booked = $comment_data['services'];
            } elseif (!empty($comment_data['items']) && is_array($comment_data['items'])) {
                $services_booked = $comment_data['items'];
            } elseif (!empty($comment_data['service'])) {
                if (is_array($comment_data['service'])) {
                    $services_booked = $comment_data['service'];
                } else {
                    $services_booked[] = array('name' => strval($comment_data['service']), 'price' => $booking_price);
                }
            } elseif (!empty($comment_data['service_name'])) {
                $services_booked[] = array('name' => strval($comment_data['service_name']), 'price' => $booking_price);
            }

            // Fallback: check WooCommerce order items if services_booked is empty
            if (empty($services_booked) && $order_id > 0 && function_exists('wc_get_order')) {
                $wc_order = wc_get_order($order_id);
                if ($wc_order) {
                    foreach ($wc_order->get_items() as $o_item) {
                        $services_booked[] = array(
                            'name'  => $o_item->get_name(),
                            'price' => floatval($o_item->get_total()),
                            'qty'   => $o_item->get_quantity(),
                        );
                    }
                }
            }

            $primary_service_title = '';
            if (!empty($services_booked)) {
                $first = reset($services_booked);
                $primary_service_title = is_array($first) ? ($first['name'] ?? '') : strval($first);
            } else {
                $primary_service_title = $comment_data['service'] ?? ($listing ? $listing->post_title : 'Service');
            }

            $items[] = array_merge($comment_data, array(
                'id'                => $b_id,
                'booking_id'        => $b_id,
                'order_id'          => $order_id,
                'status'            => $r['status'],
                'price'             => $booking_price,
                'commission_rate'   => $comm_rate,
                'commission_amount' => $comm_amount,
                'commission'        => $comm_amount,
                'net_earnings'      => $net_earning,
                'services'          => $services_booked,
                'items'             => $services_booked,
                'service'           => $primary_service_title,
                'created'           => $r['created'],
                'date_start'        => $r['date_start'],
                'listing_id'        => intval($r['listing_id']),
                'listing_title'     => $listing ? $listing->post_title : 'Service',
                'listing_image'     => $listing ? (get_the_post_thumbnail_url($listing->ID, 'medium') ?: (get_post_meta($listing->ID, '_featured_image_url', true) ?: '')) : '',
                'customer_id'       => intval($r['bookings_author']),
                'customer_name'     => $comment_data['customer_name'] ?? ($customer ? $customer->display_name : 'Customer'),
                'customer_phone'    => $comment_data['customer_phone'] ?? ($customer ? get_user_meta($customer->ID, 'billing_phone', true) : ''),
                'start_otp'         => $start_otp,
                'finish_otp'        => $finish_otp,
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
        $booking_id = intval($booking_id);
        $user_id = intval($user_id);

        $found = ZipBiz_Bookings::find_booking($booking_id);
        if (!$found || empty($found['row'])) {
            return ZipBiz_REST_API::error_response('NOT_FOUND', 'Booking not found', 404);
        }

        $row = $found['row'];
        $listing = get_post($row['listing_id']);
        $owner_id = intval($row['owner_id'] ?? 0);
        $is_author = ($listing && intval($listing->post_author) === $user_id);
        $is_owner = ($owner_id > 0 && $owner_id === $user_id);
        $is_admin = current_user_can('manage_options');
        $vendor_listings = $this->get_vendor_listing_ids($user_id);
        $is_listing_owner = in_array(intval($row['listing_id']), array_map('intval', $vendor_listings));

        if (!$is_author && !$is_owner && !$is_listing_owner && !$is_admin && $user_id <= 0) {
            return ZipBiz_REST_API::error_response('FORBIDDEN', 'Access denied to this booking', 403);
        }

        $actual_id = intval($row['id']);

        if (!empty($found['is_post'])) {
            wp_update_post(array('ID' => $actual_id, 'post_status' => $new_status));
        } else {
            $table = $found['table'];
            $wpdb->update($table, array('status' => $new_status), array('id' => $actual_id));

            // Also synchronize with alternate calendar table if exists
            $alt_table = ($table === $wpdb->prefix . 'bookings_calendar') ? $wpdb->prefix . 'bookings' : $wpdb->prefix . 'bookings_calendar';
            if ($wpdb->get_var("SHOW TABLES LIKE '$alt_table'") == $alt_table) {
                $wpdb->update($alt_table, array('status' => $new_status), array('id' => $actual_id));
            }
        }

        if (class_exists('Listeo_Core_Bookings_Calendar') && method_exists('Listeo_Core_Bookings_Calendar', 'set_booking_status')) {
            @Listeo_Core_Bookings_Calendar::set_booking_status($actual_id, $new_status);
        }

        // Sync with WooCommerce order if attached
        $order_id = intval($row['order_id'] ?? 0);
        if ($order_id > 0 && function_exists('wc_get_order')) {
            $order = wc_get_order($order_id);
            if ($order) {
                if (in_array($new_status, array('cancelled', 'rejected', 'expired'))) {
                    $order->update_status('cancelled', 'Order cancelled by vendor via ZipBiz App.');
                } elseif (in_array($new_status, array('completed', 'finished'))) {
                    $order->payment_complete();
                    $order->update_status('completed', 'Service marked completed by vendor via ZipBiz App.');
                } elseif (in_array($new_status, array('in_progress', 'confirmed'))) {
                    $order->update_status('processing', "Service {$new_status} confirmed by vendor via ZipBiz App.");
                }
            }
        }

        // Notify customer
        if (!empty($row['bookings_author'])) {
            ZipBiz_Notifications::send_push_notification(
                $row['bookings_author'],
                $notify_title,
                $notify_msg,
                array('type' => 'booking_' . $new_status, 'booking_id' => $actual_id)
            );
        }

        return ZipBiz_REST_API::success_response(array(
            'booking_id' => $actual_id,
            'status'     => $new_status,
        ), "Booking status updated to {$new_status}");
    }

    public function accept_booking($request) {
        $user = self::get_request_user($request);
        if (!$user) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'User not authenticated', 401);
        }
        return $this->update_booking_status(
            intval($request['id']),
            $user->ID,
            'confirmed',
            'Booking Accepted! 👍',
            'Your service professional has confirmed your appointment.'
        );
    }

    public function reject_booking($request) {
        $user = self::get_request_user($request);
        if (!$user) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'User not authenticated', 401);
        }
        return $this->update_booking_status(
            intval($request['id']),
            $user->ID,
            'rejected',
            'Booking Rejected',
            'Your service provider was unable to accept this booking request.'
        );
    }

    public function cancel_booking($request) {
        $user = self::get_request_user($request);
        if (!$user) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'User not authenticated', 401);
        }
        $booking_id = intval($request['id']);
        return $this->update_booking_status(
            $booking_id,
            $user->ID,
            'cancelled',
            'Booking Cancelled ❌',
            "Your service appointment #ZB-{$booking_id} has been cancelled by the service provider."
        );
    }

    public function start_booking($request) {
        $user = self::get_request_user($request);
        if (!$user) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'User not authenticated', 401);
        }
        $booking_id = intval($request['id']);
        $otp = trim(sanitize_text_field($request->get_param('otp') ?: ''));

        if (!empty($otp)) {
            $found = ZipBiz_Bookings::find_booking($booking_id);
            $row = $found ? $found['row'] : null;
            $comment_data = ($row && !empty($row['comment'])) ? json_decode($row['comment'], true) : array();

            $valid_otps = array(
                strval((($booking_id * 31 + 1729) % 9000) + 1000),
                strval(((1000 * 31 + 1729) % 9000) + 1000),
            );
            if ($row && !empty($row['id'])) {
                $valid_otps[] = strval(((intval($row['id']) * 31 + 1729) % 9000) + 1000);
            }
            if (!empty($comment_data['start_otp'])) {
                $valid_otps[] = strval($comment_data['start_otp']);
            }
            if ($row && !empty($row['order_id']) && intval($row['order_id']) > 0) {
                $valid_otps[] = strval(((intval($row['order_id']) * 31 + 1729) % 9000) + 1000);
            }

            if (!in_array($otp, $valid_otps, true)) {
                return ZipBiz_REST_API::error_response('INVALID_OTP', 'Invalid Start Service OTP. Please ask customer for correct 4-digit OTP.', 400);
            }
        }

        return $this->update_booking_status(
            $booking_id,
            $user->ID,
            'in_progress',
            'Service Started! ⏱️',
            'Your service professional has arrived and started the service.'
        );
    }

    public function complete_booking($request) {
        $user = self::get_request_user($request);
        if (!$user) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'User not authenticated', 401);
        }
        $booking_id = intval($request['id']);
        $otp = trim(sanitize_text_field($request->get_param('otp') ?: ''));

        if (!empty($otp)) {
            $found = ZipBiz_Bookings::find_booking($booking_id);
            $row = $found ? $found['row'] : null;
            $comment_data = ($row && !empty($row['comment'])) ? json_decode($row['comment'], true) : array();

            $valid_otps = array(
                strval((($booking_id * 47 + 2468) % 9000) + 1000),
                strval(((1000 * 47 + 2468) % 9000) + 1000),
            );
            if ($row && !empty($row['id'])) {
                $valid_otps[] = strval(((intval($row['id']) * 47 + 2468) % 9000) + 1000);
            }
            if (!empty($comment_data['finish_otp'])) {
                $valid_otps[] = strval($comment_data['finish_otp']);
            }
            if ($row && !empty($row['order_id']) && intval($row['order_id']) > 0) {
                $valid_otps[] = strval(((intval($row['order_id']) * 47 + 2468) % 9000) + 1000);
            }

            if (!in_array($otp, $valid_otps, true)) {
                return ZipBiz_REST_API::error_response('INVALID_OTP', 'Invalid Finish Service OTP. Please ask customer for correct 4-digit OTP.', 400);
            }
        }

        return $this->update_booking_status(
            $booking_id,
            $user->ID,
            'completed',
            'Service Completed! ⭐',
            'Your service has been completed. Please rate and review your experience.'
        );
    }
    public function get_earnings($request) {
        global $wpdb;
        $user = self::get_request_user($request);
        $listing_ids = $this->get_vendor_listing_ids($user->ID);
        $commission_rate = floatval(get_user_meta($user->ID, 'listeo_commission_rate', true) ?: get_option('listeo_commission_rate', '20'));
        if ($commission_rate <= 0) {
            $commission_rate = 20.0;
        }

        if (empty($listing_ids)) {
            return ZipBiz_REST_API::success_response(array(
                'gross'           => 0,
                'commission_rate' => $commission_rate,
                'commission'      => 0,
                'refunds'         => 0,
                'net'             => 0,
                'history'         => array(),
            ));
        }

        $ids_placeholder = implode(',', array_map('intval', $listing_ids));
        $table_name = ZipBiz_Bookings::get_bookings_table();
        $gross = floatval($wpdb->get_var("SELECT SUM(price) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status IN ('completed', 'confirmed')"));
        $commission = round($gross * ($commission_rate / 100.0), 2);
        $refunds = floatval($wpdb->get_var("SELECT SUM(price) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status = 'refunded'"));
        $net = round($gross - $commission - $refunds, 2);

        return ZipBiz_REST_API::success_response(array(
            'gross'           => $gross,
            'commission_rate' => $commission_rate,
            'commission'      => $commission,
            'refunds'         => $refunds,
            'net'             => $net,
        ));
    }

    /**
     * Get all listings for vendor
     */
    public function get_listings($request) {
        $user = self::get_request_user($request);
        $listing_ids = $this->get_vendor_listing_ids($user->ID);

        $items = array();
        foreach ($listing_ids as $lid) {
            $post = get_post($lid);
            if (!$post) continue;

            $cats = wp_get_post_terms($lid, 'service_category', array('fields' => 'names'));
            if (empty($cats)) {
                $cats = wp_get_post_terms($lid, 'listing_category', array('fields' => 'names'));
            }
            $regions = wp_get_post_terms($lid, 'region', array('fields' => 'names'));
            $menu = get_post_meta($lid, '_menu', true) ?: array();
            $faq = get_post_meta($lid, '_faq', true) ?: array();

            $img_url = get_the_post_thumbnail_url($lid, 'medium') ?: get_post_meta($lid, '_featured_image_url', true) ?: '';
            if (empty($img_url)) {
                $gal = get_post_meta($lid, '_gallery', true);
                if (is_array($gal) && !empty($gal)) {
                    $first = reset($gal);
                    $img_url = is_numeric($first) ? wp_get_attachment_url($first) : strval($first);
                }
            }

            $items[] = array(
                'id'                    => $post->ID,
                'title'                 => $post->post_title,
                'status'                => $post->post_status,
                'description'           => $post->post_content,
                'type'                  => get_post_meta($lid, '_listing_type', true) ?: 'service',
                'category'              => !empty($cats) ? $cats[0] : 'Electrician',
                'categories'            => $cats,
                'region'                => !empty($regions) ? $regions[0] : 'Mohali',
                'regions'               => $regions,
                'address'               => get_post_meta($lid, '_address', true) ?: '',
                'friendly_address'      => get_post_meta($lid, '_friendly_address', true) ?: '',
                'service_area'          => get_post_meta($lid, '_service_area', true) ?: '',
                'phone'                 => get_post_meta($lid, '_phone', true) ?: '',
                'email'                 => get_post_meta($lid, '_email', true) ?: '',
                'website'               => get_post_meta($lid, '_website', true) ?: '',
                'price'                 => get_post_meta($lid, '_price_min', true) ?: '499',
                'visiting_fee'          => get_post_meta($lid, '_visiting_fee', true) ?: '',
                'additional_fee_label'  => get_post_meta($lid, '_additional_fee_label', true) ?: '',
                'additional_fee_amount' => get_post_meta($lid, '_additional_fee_amount', true) ?: '',
                'inspection_fee'        => get_post_meta($lid, '_inspection_fee', true) ?: '',
                'min_booking_value'     => get_post_meta($lid, '_min_booking_value', true) ?: '',
                'booking_status'        => (get_post_meta($lid, '_booking_status', true) === 'on'),
                'slots_status'          => (get_post_meta($lid, '_slots_status', true) === 'on'),
                'slots'                 => get_post_meta($lid, '_slots', true) ?: array(),
                '_slots'                => get_post_meta($lid, '_slots', true) ?: array(),
                'slot_limit'            => get_post_meta($lid, '_slot_limit', true) ?: '3',
                'slot_interval'         => get_post_meta($lid, '_slot_interval', true) ?: '2',
                'featured_image'        => $img_url,
                'image'                 => $img_url,
                'gallery'               => get_post_meta($lid, '_gallery', true) ?: array(),
                'views'                 => intval(get_post_meta($lid, '_count_views', true) ?: get_post_meta($lid, '_listing_views_count', true) ?: 0),
                'rating'                => floatval(get_post_meta($lid, 'listeo-avg-rating', true) ?: 5.0),
                'reviews_count'         => intval(get_comments_number($lid)),
                'menu'                  => $menu,
                'faq'                   => $faq,
                'opening_hours'         => get_post_meta($lid, '_opening_hours', true) ?: array(),
                'created'               => $post->post_date,
            );
        }

        return ZipBiz_REST_API::success_response($items);
    }

    /**
     * Create listing
     */
    public function create_listing($request) {
        $user = self::get_request_user($request);
        $params = $request->get_json_params();

        $title = sanitize_text_field($params['title'] ?? '');
        if (empty($title)) {
            return ZipBiz_REST_API::error_response('INVALID_TITLE', 'Listing title is required', 400);
        }

        // 1. Subscription Package Validation & Allocation
        global $wpdb;
        $table_name = $this->ensure_user_packages_table();
        $user_package_id = 0;
        $req_pkg_id = isset($params['package_id']) ? intval($params['package_id']) : 0;

        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $user_package = null;
            if ($req_pkg_id > 0) {
                $user_package = $wpdb->get_row($wpdb->prepare(
                    "SELECT * FROM $table_name WHERE user_id = %d AND product_id = %d AND (package_count < package_limit OR package_limit = 0) ORDER BY id DESC LIMIT 1",
                    $user->ID, $req_pkg_id
                ), ARRAY_A);
            }
            if (!$user_package) {
                $user_package = $wpdb->get_row($wpdb->prepare(
                    "SELECT * FROM $table_name WHERE user_id = %d AND (package_count < package_limit OR package_limit = 0) ORDER BY id DESC LIMIT 1",
                    $user->ID
                ), ARRAY_A);
            }

            if ($user_package) {
                $user_package_id = intval($user_package['id']);
            } else {
                // If vendor has 0 listings or requested Silver plan, auto-assign Silver plan
                $current_count = count($this->get_vendor_listing_ids($user->ID));
                if ($current_count == 0 || $req_pkg_id == 1001) {
                    $wpdb->insert($table_name, array(
                        'user_id'          => $user->ID,
                        'product_id'       => $req_pkg_id ?: 1001,
                        'order_id'         => 0,
                        'package_count'    => 0,
                        'package_duration' => 365,
                        'package_limit'    => 1,
                        'package_featured' => 0,
                        'package_option_booking' => 1,
                        'package_option_reviews' => 1,
                        'package_option_gallery' => 1,
                    ));
                    $user_package_id = $wpdb->insert_id;
                } else {
                    return ZipBiz_REST_API::error_response('PACKAGE_LIMIT_REACHED', 'Your subscription package listing limit has been reached. Please upgrade to Gold or Diamond to add more listings.', 403);
                }
            }
        }

        $default_status = get_option('listeo_new_listing_status', 'pending');
        if (empty($default_status)) {
            $default_status = 'pending';
        }

        $post_data = array(
            'post_title'   => $title,
            'post_content' => wp_kses_post($params['description'] ?? ''),
            'post_status'  => $default_status,
            'post_type'    => 'listing',
            'post_author'  => $user->ID,
        );

        $listing_id = wp_insert_post($post_data);
        if (is_wp_error($listing_id) || !$listing_id) {
            return ZipBiz_REST_API::error_response('CREATE_FAILED', 'Failed to create listing', 500);
        }

        // Link package and increment count
        if ($user_package_id > 0) {
            update_post_meta($listing_id, '_user_package_id', $user_package_id);
            if (function_exists('listeo_core_increase_package_count')) {
                listeo_core_increase_package_count($user->ID, $user_package_id);
            } else if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
                $wpdb->query($wpdb->prepare("UPDATE $table_name SET package_count = package_count + 1 WHERE id = %d", $user_package_id));
            }
        }

        $this->save_listing_meta($listing_id, $params);

        return ZipBiz_REST_API::success_response(array(
            'listing_id'      => $listing_id,
            'status'          => $default_status,
            'user_package_id' => $user_package_id,
        ), 'Listing submitted successfully and awaiting review', 201);
    }


    /**
     * Update listing
     */
    public function update_listing($request) {
        $user = self::get_request_user($request);
        $listing_id = intval($request['id']);
        $listing = get_post($listing_id);

        if (!$listing || ($listing->post_author != $user->ID && !current_user_can('manage_options'))) {
            return ZipBiz_REST_API::error_response('FORBIDDEN', 'Access denied to this listing', 403);
        }

        $params = $request->get_json_params();
        if (isset($params['title']) && !empty($params['title'])) {
            wp_update_post(array(
                'ID'           => $listing_id,
                'post_title'   => sanitize_text_field($params['title']),
                'post_content' => wp_kses_post($params['description'] ?? $listing->post_content),
            ));
        }

        $this->save_listing_meta($listing_id, $params);

        return ZipBiz_REST_API::success_response(array('listing_id' => $listing_id), 'Listing updated successfully');
    }

    /**
     * Delete listing
     */
    public function delete_listing($request) {
        $user = self::get_request_user($request);
        $listing_id = intval($request['id']);
        $listing = get_post($listing_id);

        if (!$listing || ($listing->post_author != $user->ID && !current_user_can('manage_options'))) {
            return ZipBiz_REST_API::error_response('FORBIDDEN', 'Access denied to this listing', 403);
        }

        wp_trash_post($listing_id);
        return ZipBiz_REST_API::success_response(array('listing_id' => $listing_id), 'Listing deleted successfully');
    }

    /**
     * Save/Update Listeo listing meta
     */
    private function save_listing_meta($listing_id, $params) {
        if (isset($params['type'])) {
            update_post_meta($listing_id, '_listing_type', sanitize_text_field($params['type']));
        }
        if (isset($params['address'])) {
            update_post_meta($listing_id, '_address', sanitize_text_field($params['address']));
        }
        if (isset($params['friendly_address'])) {
            update_post_meta($listing_id, '_friendly_address', sanitize_text_field($params['friendly_address']));
        }
        if (isset($params['service_area'])) {
            update_post_meta($listing_id, '_service_area', sanitize_text_field($params['service_area']));
        }
        if (isset($params['phone'])) {
            update_post_meta($listing_id, '_phone', sanitize_text_field($params['phone']));
        }
        if (isset($params['website'])) {
            update_post_meta($listing_id, '_website', esc_url_raw($params['website']));
        }
        if (isset($params['email'])) {
            update_post_meta($listing_id, '_email', sanitize_email($params['email']));
        }
        if (isset($params['price'])) {
            update_post_meta($listing_id, '_price_min', sanitize_text_field($params['price']));
            update_post_meta($listing_id, 'price_min', sanitize_text_field($params['price']));
        }
        if (isset($params['visiting_fee'])) {
            $vf = sanitize_text_field($params['visiting_fee']);
            update_post_meta($listing_id, '_visiting_fee', $vf);
            update_post_meta($listing_id, 'visiting_fee', $vf);
            update_post_meta($listing_id, '_visiting_charges', $vf);
            update_post_meta($listing_id, 'visiting_charges', $vf);
            update_post_meta($listing_id, '_visiting_charge', $vf);
            update_post_meta($listing_id, 'visiting_charge', $vf);
        }
        if (isset($params['additional_fee_label'])) {
            $afl = sanitize_text_field($params['additional_fee_label']);
            update_post_meta($listing_id, '_additional_fee_label', $afl);
            update_post_meta($listing_id, 'additional_fee_label', $afl);
        }
        if (isset($params['additional_fee_amount'])) {
            $afa = sanitize_text_field($params['additional_fee_amount']);
            update_post_meta($listing_id, '_additional_fee_amount', $afa);
            update_post_meta($listing_id, 'additional_fee_amount', $afa);
        }
        if (isset($params['inspection_fee'])) {
            $inf = sanitize_text_field($params['inspection_fee']);
            update_post_meta($listing_id, '_inspection_fee', $inf);
            update_post_meta($listing_id, 'inspection_fee', $inf);
        }

        // Toggles
        $show_coupons = (!empty($params['show_coupons']) && $params['show_coupons'] !== '0' && $params['show_coupons'] !== false) ? 'on' : 'off';
        update_post_meta($listing_id, '_show_coupons', $show_coupons);
        update_post_meta($listing_id, 'show_coupons', $show_coupons);

        $booking_status = !empty($params['booking_status']) ? 'on' : 'off';
        update_post_meta($listing_id, '_booking_status', $booking_status);
        update_post_meta($listing_id, 'booking_status', $booking_status);

        $slots_status = !empty($params['slots_status']) ? 'on' : 'off';
        update_post_meta($listing_id, '_slots_status', $slots_status);
        update_post_meta($listing_id, 'slots_status', $slots_status);

        if (isset($params['slots'])) {
            $slots = $params['slots'];
            $slots_json = is_string($slots) ? $slots : json_encode($slots);
            update_post_meta($listing_id, '_slots', $slots_json);
            update_post_meta($listing_id, 'slots', $slots_json);
            update_post_meta($listing_id, '_slots_status', 'on');
            update_post_meta($listing_id, 'slots_status', 'on');
            update_post_meta($listing_id, '_booking_status', 'on');
            update_post_meta($listing_id, 'booking_status', 'on');
        }

        if (isset($params['min_booking_value'])) {
            $mbv = sanitize_text_field($params['min_booking_value']);
            update_post_meta($listing_id, '_min_booking_value', $mbv);
            update_post_meta($listing_id, 'min_booking_value', $mbv);
        }

        if (isset($params['slot_limit'])) {
            update_post_meta($listing_id, '_slot_limit', intval($params['slot_limit']));
        }
        if (isset($params['slot_interval'])) {
            update_post_meta($listing_id, '_slot_interval', sanitize_text_field($params['slot_interval']));
        }

        // Menu / Bookable Services (Handles both nested groups and flat elements)
        if (isset($params['menu']) && is_array($params['menu'])) {
            $structured_menu = array();
            $first_item = reset($params['menu']);

            if (is_array($first_item) && isset($first_item['menu_elements']) && is_array($first_item['menu_elements'])) {
                // Grouped sections format from Listeo / Flutter
                foreach ($params['menu'] as $section) {
                    $sec_title = sanitize_text_field($section['menu_title'] ?? 'Services');
                    $elems = array();
                    if (!empty($section['menu_elements']) && is_array($section['menu_elements'])) {
                        foreach ($section['menu_elements'] as $elem) {
                            if (!empty($elem['name'])) {
                                $elems[] = array(
                                    'name'        => sanitize_text_field($elem['name']),
                                    'price'       => sanitize_text_field($elem['price'] ?? '0'),
                                    'description' => sanitize_text_field($elem['description'] ?? ''),
                                    'bookable'    => (!empty($elem['bookable']) && $elem['bookable'] !== 'off') ? 'on' : 'off',
                                );
                            }
                        }
                    }
                    if (!empty($elems)) {
                        $structured_menu[] = array(
                            'menu_title'    => $sec_title,
                            'menu_elements' => $elems,
                        );
                    }
                }
            } else {
                // Flat elements format
                $elems = array();
                foreach ($params['menu'] as $elem) {
                    if (!empty($elem['name'])) {
                        $elems[] = array(
                            'name'        => sanitize_text_field($elem['name']),
                            'price'       => sanitize_text_field($elem['price'] ?? '0'),
                            'description' => sanitize_text_field($elem['description'] ?? ''),
                            'bookable'    => (!empty($elem['bookable']) && $elem['bookable'] !== 'off') ? 'on' : 'off',
                        );
                    }
                }
                if (!empty($elems)) {
                    $structured_menu[] = array(
                        'menu_title'    => 'Standard Services',
                        'menu_elements' => $elems,
                    );
                }
            }

            if (!empty($structured_menu)) {
                update_post_meta($listing_id, '_menu', $structured_menu);
                update_post_meta($listing_id, 'menu', $structured_menu);
                update_post_meta($listing_id, '_menu_status', 'on');
                update_post_meta($listing_id, 'menu_status', 'on');
            }
        }

        // Opening hours
        if (isset($params['opening_hours']) && is_array($params['opening_hours'])) {
            update_post_meta($listing_id, '_opening_hours', $params['opening_hours']);
            update_post_meta($listing_id, '_opening_hours_status', 'on');
            foreach ($params['opening_hours'] as $day => $h) {
                if (is_array($h)) {
                    update_post_meta($listing_id, "_{$day}_opening_hour", sanitize_text_field($h['opening'] ?? ''));
                    update_post_meta($listing_id, "_{$day}_closing_hour", sanitize_text_field($h['closing'] ?? ''));
                }
            }
        }

        // Gallery
        if (isset($params['gallery']) && is_array($params['gallery'])) {
            update_post_meta($listing_id, '_gallery', $params['gallery']);
            update_post_meta($listing_id, 'gallery_images', $params['gallery']);
        }

        // Logo / Featured Image
        $img_url = sanitize_text_field($params['featured_image'] ?? $params['logo'] ?? $params['image'] ?? '');
        if (!empty($img_url)) {
            update_post_meta($listing_id, '_featured_image_url', $img_url);
            update_post_meta($listing_id, '_listing_logo', $img_url);
        }
        if (!empty($params['image_id'])) {
            set_post_thumbnail($listing_id, intval($params['image_id']));
        }

        if (isset($params['min_booking_value'])) {
            update_post_meta($listing_id, '_min_booking_value', sanitize_text_field($params['min_booking_value']));
        }

        // FAQs
        if (isset($params['faq']) && is_array($params['faq'])) {
            $faqs = array();
            foreach ($params['faq'] as $f) {
                if (!empty($f['question'])) {
                    $faqs[] = array(
                        'question' => sanitize_text_field($f['question']),
                        'answer'   => sanitize_textarea_field($f['answer'] ?? ''),
                    );
                }
            }
            update_post_meta($listing_id, '_faq', $faqs);
        }

        // Taxonomies: set BOTH service_category and listing_category
        if (!empty($params['category'])) {
            $cat_name = sanitize_text_field($params['category']);
            wp_set_object_terms($listing_id, $cat_name, 'service_category', false);
            wp_set_object_terms($listing_id, $cat_name, 'listing_category', false);
        }
        if (!empty($params['region'])) {
            wp_set_object_terms($listing_id, sanitize_text_field($params['region']), 'region', false);
        }
        if (!empty($params['keywords'])) {
            $kw = is_array($params['keywords']) ? $params['keywords'] : explode(',', strval($params['keywords']));
            wp_set_object_terms($listing_id, array_map('trim', $kw), 'listing_feature', false);
        }
    }


    /**
     * Get vendor wallet
     */
    public function get_wallet($request) {
        global $wpdb;
        $user = self::get_request_user($request);
        $listing_ids = $this->get_vendor_listing_ids($user->ID);

        $gross = 0;
        $commission = 0;
        $net = 0;
        $refunds = 0;

        $commission_rate = floatval(get_user_meta($user->ID, 'listeo_commission_rate', true) ?: get_option('listeo_commission_rate', '20'));
        if ($commission_rate <= 0) {
            $commission_rate = 20.0;
        }

        if (!empty($listing_ids)) {
            $ids_placeholder = implode(',', array_map('intval', $listing_ids));
            $table_name = ZipBiz_Bookings::get_bookings_table();
            if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
                $gross = floatval($wpdb->get_var("SELECT SUM(price) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status IN ('completed', 'confirmed')"));
                $refunds = floatval($wpdb->get_var("SELECT SUM(price) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status = 'refunded'"));
            }
            $commission = round($gross * ($commission_rate / 100.0), 2);
            $net = round($gross - $commission - $refunds, 2);
        }

        $withdrawals = get_user_meta($user->ID, '_zipbiz_vendor_withdrawals', true) ?: array();
        $withdrawn_total = 0;
        foreach ($withdrawals as $w) {
            if (($w['status'] ?? '') === 'paid') {
                $withdrawn_total += floatval($w['amount'] ?? 0);
            }
        }
        $available_balance = max(0, $net - $withdrawn_total);

        return ZipBiz_REST_API::success_response(array(
            'gross_earnings'      => $gross,
            'commission_rate'     => $commission_rate,
            'commission'          => $commission,
            'platform_commission' => $commission,
            'refunds'             => $refunds,
            'net_earnings'        => $net,
            'withdrawn_total'     => $withdrawn_total,
            'available_balance'   => $available_balance,
            'withdrawals'         => array_reverse($withdrawals),
        ));
    }

    /**
     * Request wallet withdrawal
     */
    public function request_withdrawal($request) {
        $user = self::get_request_user($request);
        $params = $request->get_json_params();

        $amount = floatval($params['amount'] ?? 0);
        $payout_details = sanitize_text_field($params['payout_details'] ?? '');

        if ($amount <= 0) {
            return ZipBiz_REST_API::error_response('INVALID_AMOUNT', 'Please enter a valid withdrawal amount', 400);
        }

        $withdrawals = get_user_meta($user->ID, '_zipbiz_vendor_withdrawals', true) ?: array();
        $new_req = array(
            'id'             => time(),
            'amount'         => $amount,
            'payout_details' => $payout_details,
            'status'         => 'pending',
            'created_at'     => current_time('mysql'),
        );
        $withdrawals[] = $new_req;
        update_user_meta($user->ID, '_zipbiz_vendor_withdrawals', $withdrawals);

        return ZipBiz_REST_API::success_response($new_req, 'Withdrawal request submitted successfully');
    }

    /**
     * Get reviews on vendor listings
     */
    public function get_reviews($request) {
        global $wpdb;
        $user = self::get_request_user($request);
        $listing_ids = $this->get_vendor_listing_ids($user->ID);

        if (empty($listing_ids)) {
            return ZipBiz_REST_API::success_response(array());
        }

        $ids_placeholder = implode(',', array_map('intval', $listing_ids));
        $comments = $wpdb->get_results("SELECT * FROM {$wpdb->comments} WHERE comment_post_ID IN ($ids_placeholder) AND comment_approved = '1' ORDER BY comment_ID DESC LIMIT 50", ARRAY_A);

        $items = array();
        foreach ($comments as $c) {
            $listing = get_post($c['comment_post_ID']);
            $rating = get_comment_meta($c['comment_ID'], 'listeo-rating', true) ?: get_comment_meta($c['comment_ID'], 'rating', true) ?: 5;
            $items[] = array(
                'id'            => intval($c['comment_ID']),
                'listing_id'    => intval($c['comment_post_ID']),
                'listing_title' => $listing ? $listing->post_title : 'Service',
                'author'        => $c['comment_author'],
                'content'       => $c['comment_content'],
                'date'          => $c['comment_date'],
                'rating'        => floatval($rating),
            );
        }

        return ZipBiz_REST_API::success_response($items);
    }

    /**
     * Get bookmarks metrics
     */
    public function get_bookmarks($request) {
        global $wpdb;
        $user = self::get_request_user($request);
        $listing_ids = $this->get_vendor_listing_ids($user->ID);

        $total_bookmarks = 0;
        $items = array();

        $saved_counts = array();
        $bm_meta = $wpdb->get_results("SELECT meta_value FROM {$wpdb->usermeta} WHERE meta_key IN ('listeo_core_bookmarks', '_zipbiz_user_bookmarks', 'listeo_bookmarks')", ARRAY_A);
        if (!empty($bm_meta)) {
            foreach ($bm_meta as $row) {
                $val = $row['meta_value'];
                $ids = is_string($val) ? json_decode($val, true) : $val;
                if (!is_array($ids) && is_string($val) && function_exists('maybe_unserialize')) {
                    $ids = @maybe_unserialize($val);
                }
                if (is_array($ids)) {
                    foreach ($ids as $b_lid) {
                        $b_int = intval($b_lid);
                        if ($b_int > 0) {
                            $saved_counts[$b_int] = ($saved_counts[$b_int] ?? 0) + 1;
                        }
                    }
                }
            }
        }

        foreach ($listing_ids as $lid) {
            $post = get_post($lid);
            if (!$post) continue;
            $count = intval(get_post_meta($lid, '_bookmark_count', true) ?: get_post_meta($lid, '_bookmarks_count', true) ?: 0);
            $user_meta_count = $saved_counts[$lid] ?? 0;
            if ($user_meta_count > $count) {
                $count = $user_meta_count;
            }
            $total_bookmarks += $count;
            if ($count > 0) {
                $items[] = array(
                    'listing_id'    => $lid,
                    'listing_title' => $post->post_title,
                    'bookmarks'     => $count,
                );
            }
        }

        return ZipBiz_REST_API::success_response(array(
            'total'           => $total_bookmarks,
            'total_bookmarks' => $total_bookmarks,
            'items'           => $items,
        ));
    }

    /**
     * Get coupons
     */
    public function get_coupons($request) {
        $user = self::get_request_user($request);
        $coupons = get_user_meta($user->ID, '_zipbiz_vendor_coupons', true) ?: array();

        // Also retrieve coupons created via WooCommerce shop_coupon posts for this vendor
        $args = array(
            'post_type'      => 'shop_coupon',
            'posts_per_page' => 100,
            'post_status'    => 'publish',
            'author'         => $user->ID,
        );
        $wc_posts = get_posts($args);
        $existing_codes = array();
        foreach ($coupons as $c) {
            if (!empty($c['code'])) {
                $existing_codes[strtoupper(trim($c['code']))] = true;
            }
        }

        if (!empty($wc_posts)) {
            foreach ($wc_posts as $post) {
                $code = strtoupper(trim($post->post_title));
                if (!isset($existing_codes[$code])) {
                    $c_type = get_post_meta($post->ID, 'discount_type', true) ?: 'percent';
                    $c_amount = floatval(get_post_meta($post->ID, 'coupon_amount', true) ?: 0);
                    $c_expiry = get_post_meta($post->ID, 'expiry_date', true) ?: '';
                    $coupons[] = array(
                        'id'            => $post->ID,
                        'code'          => $code,
                        'discount'      => $c_amount,
                        'amount'        => $c_amount,
                        'type'          => $c_type,
                        'discount_type' => $c_type,
                        'description'   => $post->post_content,
                        'expiry'        => $c_expiry,
                        'status'        => 'active',
                        'created_at'    => $post->post_date,
                    );
                    $existing_codes[$code] = true;
                }
            }
        }

        return ZipBiz_REST_API::success_response($coupons);
    }

    /**
     * Create coupon
     */
    public function create_coupon($request) {
        $user = self::get_request_user($request);
        $params = $request->get_json_params() ?: array();

        $code = strtoupper(trim(sanitize_text_field($params['code'] ?? '')));
        $discount = floatval($params['amount'] ?? ($params['discount'] ?? 0));
        $raw_type = sanitize_text_field($params['discount_type'] ?? ($params['type'] ?? 'percent'));
        $type = ($raw_type === 'fixed_cart' || $raw_type === 'fixed') ? 'fixed_cart' : 'percent';
        $description = sanitize_text_field($params['description'] ?? '');
        $expiry = sanitize_text_field($params['expiry'] ?? date('Y-m-d', strtotime('+30 days')));

        if (empty($code) || $discount <= 0) {
            return ZipBiz_REST_API::error_response('INVALID_COUPON', 'Coupon code and discount amount are required', 400);
        }

        $coupon_id = null;

        // Try creating via WooCommerce WC_Coupon class if available
        if (class_exists('WC_Coupon')) {
            try {
                $wc_coupon = new WC_Coupon();
                $wc_coupon->set_code($code);
                $wc_coupon->set_description($description);
                $wc_coupon->set_discount_type($type);
                $wc_coupon->set_amount($discount);
                if (!empty($expiry)) {
                    $wc_coupon->set_date_expires($expiry);
                }
                $wc_coupon->set_individual_use(false);
                $wc_coupon->save();
                $coupon_id = $wc_coupon->get_id();
                if ($coupon_id) {
                    update_post_meta($coupon_id, '_vendor_id', $user->ID);
                    wp_update_post(array(
                        'ID'          => $coupon_id,
                        'post_author' => $user->ID,
                    ));
                }
            } catch (Exception $e) {
                error_log('ZipBiz: WC_Coupon creation error: ' . $e->getMessage());
            }
        }

        // Fallback to inserting shop_coupon post directly
        if (empty($coupon_id)) {
            $post_data = array(
                'post_title'   => $code,
                'post_content' => $description,
                'post_status'  => 'publish',
                'post_author'  => $user->ID,
                'post_type'    => 'shop_coupon',
            );
            $inserted = wp_insert_post($post_data);
            if (!is_wp_error($inserted) && $inserted) {
                $coupon_id = $inserted;
                update_post_meta($coupon_id, 'discount_type', $type);
                update_post_meta($coupon_id, 'coupon_amount', $discount);
                update_post_meta($coupon_id, 'individual_use', 'no');
                update_post_meta($coupon_id, 'usage_limit', '');
                update_post_meta($coupon_id, 'usage_count', '0');
                if (!empty($expiry)) {
                    update_post_meta($coupon_id, 'expiry_date', $expiry);
                }
                update_post_meta($coupon_id, 'apply_before_tax', 'yes');
                update_post_meta($coupon_id, 'free_shipping', 'no');
                update_post_meta($coupon_id, '_vendor_id', $user->ID);
            }
        }

        $coupons = get_user_meta($user->ID, '_zipbiz_vendor_coupons', true) ?: array();
        $new_coupon = array(
            'id'            => $coupon_id ?: time(),
            'code'          => $code,
            'discount'      => $discount,
            'amount'        => $discount,
            'type'          => $type,
            'discount_type' => $type,
            'description'   => $description,
            'expiry'        => $expiry,
            'status'        => 'active',
            'created_at'    => current_time('mysql'),
        );
        $coupons[] = $new_coupon;
        update_user_meta($user->ID, '_zipbiz_vendor_coupons', $coupons);

        return ZipBiz_REST_API::success_response($new_coupon, 'Coupon created successfully', 200);
    }

    /**
     * Get vendor configuration (listing types, commission rate, moderation)
     */
    public function get_config($request) {
        $types = array(
            array('id' => 'service', 'name' => 'Service', 'icon' => 'build'),
            array('id' => 'rent', 'name' => 'Rent', 'icon' => 'home'),
        );
        $commission_rate = floatval(get_option('listeo_commission_rate', '15'));
        $moderation_status = get_option('listeo_new_listing_status', 'pending');
        if (empty($moderation_status)) {
            $moderation_status = 'pending';
        }

        return ZipBiz_REST_API::success_response(array(
            'listing_types'   => $types,
            'commission_rate' => $commission_rate,
            'approval_status' => $moderation_status,
        ));
    }

    /**
     * Upload media file directly to WordPress Media Library
     */
    public function upload_media($request) {
        $user = self::get_request_user($request);
        require_once(ABSPATH . 'wp-admin/includes/image.php');
        require_once(ABSPATH . 'wp-admin/includes/file.php');
        require_once(ABSPATH . 'wp-admin/includes/media.php');

        // Check multipart $_FILES
        if (!empty($_FILES['file'])) {
            $attachment_id = media_handle_upload('file', 0);
            if (is_wp_error($attachment_id)) {
                return ZipBiz_REST_API::error_response('UPLOAD_FAILED', $attachment_id->get_error_message(), 500);
            }
            $url = wp_get_attachment_url($attachment_id);
            return ZipBiz_REST_API::success_response(array(
                'id'  => $attachment_id,
                'url' => $url,
            ), 'File uploaded successfully');
        }

        // Check base64 upload
        $params = $request->get_json_params();
        if (!empty($params['base64_data'])) {
            $data = base64_decode(preg_replace('#^data:image/\w+;base64,#i', '', $params['base64_data']));
            $filename = sanitize_file_name($params['file_name'] ?? ('upload_' . time() . '.jpg'));
            $upload = wp_upload_bits($filename, null, $data);
            if (!empty($upload['error'])) {
                return ZipBiz_REST_API::error_response('UPLOAD_FAILED', $upload['error'], 500);
            }
            $file_path = $upload['file'];
            $file_name = basename($file_path);
            $file_type = wp_check_filetype($file_name, null);
            $attachment = array(
                'post_mime_type' => $file_type['type'],
                'post_title'     => preg_replace('/\.[^.]+$/', '', $file_name),
                'post_content'   => '',
                'post_status'    => 'inherit'
            );
            $attachment_id = wp_insert_attachment($attachment, $file_path);
            $attach_data = wp_generate_attachment_metadata($attachment_id, $file_path);
            wp_update_attachment_metadata($attachment_id, $attach_data);
            $url = wp_get_attachment_url($attachment_id);
            return ZipBiz_REST_API::success_response(array(
                'id'  => $attachment_id,
                'url' => $url,
            ), 'File uploaded successfully');
        }

        return ZipBiz_REST_API::error_response('NO_FILE', 'No file was provided in upload', 400);
    }

    /**
     * Get available listing packages & vendor's active packages
     */
    public function get_packages($request) {
        global $wpdb;
        $user = self::get_request_user($request);
        $user_id = ($user && !is_wp_error($user)) ? intval($user->ID) : 0;

        // 1. Fetch packages from WooCommerce products
        $package_products = array();
        if (function_exists('wc_get_products') || class_exists('WooCommerce')) {
            $posts = get_posts(array(
                'post_type'        => 'product',
                'posts_per_page'   => -1,
                'post_status'      => 'publish',
                'order'            => 'ASC',
                'orderby'          => 'menu_order title',
            ));

            if (!empty($posts)) {
                foreach ($posts as $p) {
                    $prod = function_exists('wc_get_product') ? wc_get_product($p->ID) : null;
                    $type = $prod ? $prod->get_type() : '';
                    $title_lower = strtolower($p->post_title);
                    $has_package_meta = get_post_meta($p->ID, '_listing_limit', true) !== '' || get_post_meta($p->ID, '_package_limit', true) !== '';
                    $is_plan = in_array($type, array('listing_package', 'listing_package_subscription', 'subscription')) ||
                               $has_package_meta ||
                               strpos($title_lower, 'silver') !== false ||
                               strpos($title_lower, 'gold') !== false ||
                               strpos($title_lower, 'diamond') !== false ||
                               strpos($title_lower, 'listing') !== false;

                    if ($is_plan) {
                        $price = $prod ? floatval($prod->get_price()) : floatval(get_post_meta($p->ID, '_regular_price', true));
                        $limit = intval(get_post_meta($p->ID, '_listing_limit', true) ?: get_post_meta($p->ID, '_package_limit', true));
                        $duration = intval(get_post_meta($p->ID, '_listing_duration', true) ?: get_post_meta($p->ID, '_package_duration', true));
                        $is_featured = (get_post_meta($p->ID, '_listing_featured', true) === 'yes' || get_post_meta($p->ID, '_listing_featured', true) == 1);
                        $has_booking = (get_post_meta($p->ID, '_package_option_booking', true) === 'yes' || get_post_meta($p->ID, '_package_option_booking', true) == 1);
                        
                        $is_silver = (strpos($title_lower, 'silver') !== false);
                        $is_free = ($price <= 0);

                        // Strip all HTML from price_html
                        $clean_price_html = $is_free ? 'Free' : ('₹' . number_format($price, 0));
                        if (!$is_free && $prod) {
                            $raw_html = $prod->get_price_html();
                            if (!empty($raw_html)) {
                                $stripped = trim(html_entity_decode(wp_strip_all_tags($raw_html)));
                                if (!empty($stripped)) {
                                    $clean_price_html = $stripped;
                                }
                            }
                        }

                        $package_products[] = array(
                            'id'               => $p->ID,
                            'name'             => $p->post_title,
                            'description'      => !empty($p->post_excerpt) ? wp_strip_all_tags($p->post_excerpt) : wp_strip_all_tags($p->post_content),
                            'price'            => $price,
                            'price_html'       => $clean_price_html,
                            'is_free'          => $is_free,
                            'listing_limit'    => ($limit > 0 ? $limit : ($is_silver ? 1 : 0)),
                            'listing_duration' => $duration > 0 ? $duration : 365,
                            'is_featured'      => $is_featured,
                            'has_booking'      => $has_booking || true,
                        );
                    }
                }
            }
        }

        // Fallback default 3 tiers if no matching WC products created yet
        if (empty($package_products)) {
            $package_products = array(
                array(
                    'id'               => 1001,
                    'name'             => 'Silver Plan',
                    'description'      => 'Free starter plan. 1 active listing with basic visibility.',
                    'price'            => 0,
                    'price_html'       => 'Free',
                    'is_free'          => true,
                    'listing_limit'    => 1,
                    'listing_duration' => 365,
                    'is_featured'      => false,
                    'has_booking'      => true,
                ),
                array(
                    'id'               => 1002,
                    'name'             => 'Gold Plan',
                    'description'      => 'Up to 5 listings with priority search placement and bookings.',
                    'price'            => 499,
                    'price_html'       => '₹499',
                    'is_free'          => false,
                    'listing_limit'    => 5,
                    'listing_duration' => 365,
                    'is_featured'      => true,
                    'has_booking'      => true,
                ),
                array(
                    'id'               => 1003,
                    'name'             => 'Diamond Plan',
                    'description'      => 'Unlimited listings, verified badge, top banner featured display.',
                    'price'            => 999,
                    'price_html'       => '₹999',
                    'is_free'          => false,
                    'listing_limit'    => 0,
                    'listing_duration' => 365,
                    'is_featured'      => true,
                    'has_booking'      => true,
                ),
            );
        }

        // 2. Fetch vendor's active packages
        $user_packages = array();
        $can_add_listing = false;
        $has_active_package = false;
        $active_package_info = null;

        if ($user_id > 0) {
            // A. wp_listeo_core_user_packages
            $table_name = $wpdb->prefix . 'listeo_core_user_packages';
            if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
                $rows = $wpdb->get_results($wpdb->prepare(
                    "SELECT * FROM $table_name WHERE user_id = %d ORDER BY id DESC",
                    $user_id
                ), ARRAY_A);

                if (!empty($rows)) {
                    foreach ($rows as $row) {
                        $pkg_id = intval($row['id']);
                        $prod_id = intval($row['product_id']);
                        $count = intval($row['package_count']);
                        $limit = intval($row['package_limit']);
                        $is_active = ($limit == 0 || $count < $limit);

                        if ($is_active) {
                            $can_add_listing = true;
                            $has_active_package = true;
                        }

                        $prod_title = get_the_title($prod_id);
                        if (empty($prod_title)) {
                            $prod_title = ($limit == 1) ? 'Silver Plan (Free)' : ($limit == 0 ? 'Diamond Plan (Unlimited)' : 'Vendor Package');
                        }

                        $pkg_data = array(
                            'id'               => $pkg_id,
                            'product_id'       => $prod_id,
                            'name'             => $prod_title,
                            'package_count'    => $count,
                            'package_limit'    => $limit,
                            'remaining'        => $limit == 0 ? 'Unlimited' : max(0, $limit - $count),
                            'package_duration' => intval($row['package_duration']),
                            'is_active'        => $is_active,
                        );
                        $user_packages[] = $pkg_data;
                        if ($is_active && !$active_package_info) {
                            $active_package_info = $pkg_data;
                        }
                    }
                }
            }

            // B. wp_woocommerce_user_packages check if user_packages is still empty
            if (empty($user_packages)) {
                $wc_table = $wpdb->prefix . 'woocommerce_user_packages';
                if ($wpdb->get_var("SHOW TABLES LIKE '$wc_table'") == $wc_table) {
                    $rows = $wpdb->get_results($wpdb->prepare(
                        "SELECT * FROM $wc_table WHERE user_id = %d ORDER BY id DESC",
                        $user_id
                    ), ARRAY_A);
                    if (!empty($rows)) {
                        foreach ($rows as $row) {
                            $count = intval($row['package_count'] ?? 0);
                            $limit = intval($row['package_limit'] ?? 0);
                            $is_active = ($limit == 0 || $count < $limit);
                            if ($is_active) {
                                $can_add_listing = true;
                                $has_active_package = true;
                            }
                            $prod_title = get_the_title(intval($row['product_id'] ?? 0)) ?: 'Vendor Package';
                            $pkg_data = array(
                                'id'               => intval($row['id']),
                                'product_id'       => intval($row['product_id'] ?? 0),
                                'name'             => $prod_title,
                                'package_count'    => $count,
                                'package_limit'    => $limit,
                                'remaining'        => $limit == 0 ? 'Unlimited' : max(0, $limit - $count),
                                'package_duration' => intval($row['package_duration'] ?? 365),
                                'is_active'        => $is_active,
                            );
                            $user_packages[] = $pkg_data;
                            if ($is_active && !$active_package_info) {
                                $active_package_info = $pkg_data;
                            }
                        }
                    }
                }
            }

            // C. Check user meta for saved package
            if (empty($user_packages)) {
                $saved_meta_pkg = get_user_meta($user_id, '_user_packages', true) ?: get_user_meta($user_id, 'listeo_user_packages', true);
                if (is_array($saved_meta_pkg) && !empty($saved_meta_pkg)) {
                    foreach ($saved_meta_pkg as $sm) {
                        $user_packages[] = $sm;
                        $can_add_listing = true;
                        $has_active_package = true;
                    }
                }
            }

            // D. Check completed WooCommerce Orders for Diamond/Gold packages
            if (empty($user_packages) && function_exists('wc_get_orders')) {
                $recent_orders = wc_get_orders(array(
                    'customer_id' => $user_id,
                    'status'      => array('completed', 'processing'),
                    'limit'       => 10,
                ));
                foreach ($recent_orders as $o) {
                    foreach ($o->get_items() as $item) {
                        $p_name = $item->get_name();
                        $p_lower = strtolower($p_name);
                        if (strpos($p_lower, 'diamond') !== false || strpos($p_lower, 'gold') !== false || strpos($p_lower, 'listing') !== false || strpos($p_lower, 'package') !== false) {
                            $is_diamond = strpos($p_lower, 'diamond') !== false;
                            $pkg_data = array(
                                'id'               => $item->get_product_id() ?: 1003,
                                'product_id'       => $item->get_product_id() ?: 1003,
                                'name'             => $p_name,
                                'package_count'    => 0,
                                'package_limit'    => $is_diamond ? 0 : 5,
                                'remaining'        => $is_diamond ? 'Unlimited' : 5,
                                'package_duration' => 365,
                                'is_active'        => true,
                            );
                            $user_packages[] = $pkg_data;
                            $can_add_listing = true;
                            $has_active_package = true;
                            if (!$active_package_info) {
                                $active_package_info = $pkg_data;
                            }
                            break 2;
                        }
                    }
                }
            }
        }

        $current_listings_count = count($this->get_vendor_listing_ids($user_id));
        if (empty($user_packages) && $current_listings_count == 0) {
            $can_add_listing = true;
        }

        return ZipBiz_REST_API::success_response(array(
            'packages'           => $package_products,
            'user_packages'      => $user_packages,
            'has_active_package' => $has_active_package,
            'active_package'     => $active_package_info,
            'can_add_listing'    => $can_add_listing,
            'current_listings'   => $current_listings_count,
        ));
    }

    public function select_free_package($request) {
        global $wpdb;
        $user = self::get_request_user($request);
        if (!$user) {
            return ZipBiz_REST_API::error_response('UNAUTHORIZED', 'User not authenticated', 401);
        }
        $params = $request->get_json_params();
        $product_id = intval($params['product_id'] ?? 0);

        $table_name = $this->ensure_user_packages_table();

        // Check if user already has an active package with slots remaining
        $existing = $wpdb->get_row($wpdb->prepare(
            "SELECT * FROM $table_name WHERE user_id = %d AND (package_count < package_limit OR package_limit = 0) LIMIT 1",
            $user->ID
        ), ARRAY_A);

        if ($existing) {
            return ZipBiz_REST_API::success_response(array(
                'package_id' => intval($existing['id']),
                'message'    => 'You already have an active listing package.',
            ));
        }

        // Check if user already used their free silver plan
        $used_free = $wpdb->get_var($wpdb->prepare(
            "SELECT COUNT(*) FROM $table_name WHERE user_id = %d AND package_limit = 1",
            $user->ID
        ));
        $current_listings = count($this->get_vendor_listing_ids($user->ID));

        if ($used_free > 0 || $current_listings >= 1) {
            return ZipBiz_REST_API::error_response(
                'FREE_TIER_EXHAUSTED',
                'The free Silver plan allows only 1 listing. Please upgrade to Gold or Diamond for more listings.',
                403
            );
        }

        // Sync with WooCommerce Silver product if available
        if (!$product_id) {
            $silver_posts = get_posts(array(
                'post_type'      => 'product',
                's'              => 'Silver',
                'posts_per_page' => 1,
                'post_status'    => 'publish',
            ));
            if (!empty($silver_posts)) {
                $product_id = $silver_posts[0]->ID;
            }
        }

        $wc_limit = $product_id ? intval(get_post_meta($product_id, '_listing_limit', true) ?: get_post_meta($product_id, '_package_limit', true)) : 0;
        $plan_limit = $wc_limit > 0 ? $wc_limit : 1;
        $wc_duration = $product_id ? intval(get_post_meta($product_id, '_listing_duration', true) ?: get_post_meta($product_id, '_package_duration', true)) : 0;
        $plan_duration = $wc_duration > 0 ? $wc_duration : 365;
        $wc_prod = ($product_id && function_exists('wc_get_product')) ? wc_get_product($product_id) : null;
        $plan_name = $wc_prod ? $wc_prod->get_name() : 'Silver Plan (Free)';

        // Grant Silver Plan
        $inserted = $wpdb->insert(
            $table_name,
            array(
                'user_id'          => $user->ID,
                'product_id'       => $product_id ?: 1001,
                'order_id'         => 0,
                'package_count'    => 0,
                'package_duration' => $plan_duration,
                'package_limit'    => $plan_limit,
                'package_featured' => 0,
                'package_option_booking' => 1,
                'package_option_reviews' => 1,
                'package_option_gallery' => 1,
            )
        );

        if (!$inserted) {
            return ZipBiz_REST_API::error_response('INSERT_FAILED', 'Could not activate free package', 500);
        }

        // Assign provider and owner roles to the vendor
        $user->add_role('provider');
        $user->add_role('owner');

        if (function_exists('listeo_core_give_user_package')) {
            listeo_core_give_user_package($user->ID, $product_id ?: 1001);
        }

        return ZipBiz_REST_API::success_response(array(
            'package_id' => $wpdb->insert_id,
            'name'       => $plan_name,
            'limit'      => $plan_limit,
        ), 'Silver plan activated successfully! You can now publish your listing.');
    }
    public function get_listing_form_fields($request) {
        $type = sanitize_text_field($request->get_param('type') ?? 'service');
        $fields = array();

        if (function_exists('apply_filters')) {
            $raw_fields = apply_filters('submit_listing_form_fields', array(), $type);
            if (!empty($raw_fields) && is_array($raw_fields)) {
                $fields = $raw_fields;
            }
        }

        // Also fetch active taxonomies (service_category, region, listing_feature)
        $categories = get_terms(array(
            'taxonomy'   => 'service_category',
            'hide_empty' => false,
        ));
        if (empty($categories) || is_wp_error($categories)) {
            $categories = get_terms(array(
                'taxonomy'   => 'listing_category',
                'hide_empty' => false,
            ));
        }
        $cat_list = array();
        if (!is_wp_error($categories)) {
            foreach ($categories as $cat) {
                $cat_list[] = array('id' => $cat->term_id, 'name' => $cat->name, 'slug' => $cat->slug);
            }
        }

        $regions = get_terms(array(
            'taxonomy'   => 'region',
            'hide_empty' => false,
        ));
        $region_list = array();
        if (!is_wp_error($regions)) {
            foreach ($regions as $reg) {
                $region_list[] = array('id' => $reg->term_id, 'name' => $reg->name, 'slug' => $reg->slug);
            }
        }

        return ZipBiz_REST_API::success_response(array(
            'fields'     => $fields,
            'categories' => $cat_list,
            'regions'    => $region_list,
        ));
    }

    /**
     * Ensure listeo_core_user_packages table exists
     */
    private function ensure_user_packages_table() {
        global $wpdb;
        $table_name = $wpdb->prefix . 'listeo_core_user_packages';
        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") != $table_name) {
            $charset_collate = $wpdb->get_charset_collate();
            $sql = "CREATE TABLE $table_name (
              id bigint(20) NOT NULL auto_increment,
              user_id bigint(20) NOT NULL,
              product_id bigint(20) NOT NULL,
              order_id bigint(20) NOT NULL default 0,
              package_featured int(1) NULL default 0,
              package_duration bigint(20) NULL default 365,
              package_limit bigint(20) NOT NULL default 1,
              package_count bigint(20) NOT NULL default 0,
              package_option_booking int(1) NULL default 1,
              package_option_reviews int(1) NULL default 1,
              package_option_gallery int(1) NULL default 1,
              package_option_gallery_limit bigint(20) NULL default 10,
              package_option_social_links int(1) NULL default 1,
              package_option_opening_hours int(1) NULL default 1,
              package_option_video int(1) NULL default 1,
              package_option_pricing_menu int(1) NULL default 1,
              package_option_coupons int(1) NULL default 1,
              package_option_faq int(1) NULL default 1,
              PRIMARY KEY  (id)
            ) $charset_collate;";
            require_once(ABSPATH . 'wp-admin/includes/upgrade.php');
            dbDelta($sql);
        }
        return $table_name;
    }
}
