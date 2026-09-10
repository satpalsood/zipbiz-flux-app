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
                'total_views'        => 0,
                'total_reviews'      => 0,
                'total_bookmarks'    => 0,
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

        // Views, Bookmarks and Reviews aggregation
        $total_views = 0;
        $total_bookmarks = 0;
        $total_reviews = 0;
        foreach ($listing_ids as $lid) {
            $views = get_post_meta($lid, '_count_views', true) ?: get_post_meta($lid, '_listing_views_count', true);
            $total_views += intval($views ?: 0);

            $bookmarks = get_post_meta($lid, '_bookmark_count', true) ?: get_post_meta($lid, '_bookmarks_count', true);
            $total_bookmarks += intval($bookmarks ?: 0);
        }
        if (!empty($listing_ids)) {
            $ids_in = implode(',', array_map('intval', $listing_ids));
            $total_reviews = intval($wpdb->get_var("SELECT COUNT(*) FROM {$wpdb->comments} WHERE comment_post_ID IN ($ids_in) AND comment_approved = '1'"));
        }

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
            'total_views'        => $total_views,
            'total_reviews'      => $total_reviews,
            'total_bookmarks'    => $total_bookmarks,
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

    /**
     * Get all listings for vendor
     */
    public function get_listings($request) {
        $user = wp_get_current_user();
        $listing_ids = $this->get_vendor_listing_ids($user->ID);

        $items = array();
        foreach ($listing_ids as $lid) {
            $post = get_post($lid);
            if (!$post) continue;

            $cats = wp_get_post_terms($lid, 'listing_category', array('fields' => 'names'));
            $regions = wp_get_post_terms($lid, 'region', array('fields' => 'names'));
            $menu = get_post_meta($lid, '_menu', true) ?: array();
            $faq = get_post_meta($lid, '_faq', true) ?: array();

            $items[] = array(
                'id'               => $post->ID,
                'title'            => $post->post_title,
                'status'           => $post->post_status,
                'description'      => $post->post_content,
                'type'             => get_post_meta($lid, '_listing_type', true) ?: 'service',
                'category'         => !empty($cats) ? $cats[0] : 'General',
                'categories'       => $cats,
                'region'           => !empty($regions) ? $regions[0] : 'Mohali / Chandigarh',
                'regions'          => $regions,
                'address'          => get_post_meta($lid, '_address', true) ?: '',
                'friendly_address' => get_post_meta($lid, '_friendly_address', true) ?: '',
                'service_area'     => get_post_meta($lid, '_service_area', true) ?: '',
                'phone'            => get_post_meta($lid, '_phone', true) ?: '',
                'email'            => get_post_meta($lid, '_email', true) ?: '',
                'website'          => get_post_meta($lid, '_website', true) ?: '',
                'price'            => get_post_meta($lid, '_price_min', true) ?: '499',
                'visiting_fee'     => get_post_meta($lid, '_visiting_fee', true) ?: '',
                'inspection_fee'   => get_post_meta($lid, '_inspection_fee', true) ?: '',
                'booking_status'   => get_post_meta($lid, '_booking_status', true) === 'on',
                'slots_status'     => get_post_meta($lid, '_slots_status', true) === 'on',
                'slot_limit'       => get_post_meta($lid, '_slot_limit', true) ?: '3',
                'image'            => get_the_post_thumbnail_url($lid, 'medium') ?: '',
                'gallery'          => get_post_meta($lid, '_gallery', true) ?: array(),
                'views'            => intval(get_post_meta($lid, '_count_views', true) ?: get_post_meta($lid, '_listing_views_count', true) ?: 0),
                'rating'           => floatval(get_post_meta($lid, 'listeo-avg-rating', true) ?: 5.0),
                'reviews_count'    => intval(get_comments_number($lid)),
                'menu'             => $menu,
                'faq'              => $faq,
                'opening_hours'    => get_post_meta($lid, '_opening_hours', true) ?: array(),
                'created'          => $post->post_date,
            );
        }

        return ZipBiz_REST_API::success_response($items);
    }

    /**
     * Create listing
     */
    public function create_listing($request) {
        $user = wp_get_current_user();
        $params = $request->get_json_params();

        $title = sanitize_text_field($params['title'] ?? '');
        if (empty($title)) {
            return ZipBiz_REST_API::error_response('INVALID_TITLE', 'Listing title is required', 400);
        }

        $post_data = array(
            'post_title'   => $title,
            'post_content' => wp_kses_post($params['description'] ?? ''),
            'post_status'  => 'publish',
            'post_type'    => 'listing',
            'post_author'  => $user->ID,
        );

        $listing_id = wp_insert_post($post_data);
        if (is_wp_error($listing_id) || !$listing_id) {
            return ZipBiz_REST_API::error_response('CREATE_FAILED', 'Failed to create listing', 500);
        }

        $this->save_listing_meta($listing_id, $params);

        return ZipBiz_REST_API::success_response(array('listing_id' => $listing_id), 'Listing created successfully', 201);
    }

    /**
     * Update listing
     */
    public function update_listing($request) {
        $user = wp_get_current_user();
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
        $user = wp_get_current_user();
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
        }
        if (isset($params['visiting_fee'])) {
            update_post_meta($listing_id, '_visiting_fee', sanitize_text_field($params['visiting_fee']));
        }
        if (isset($params['inspection_fee'])) {
            update_post_meta($listing_id, '_inspection_fee', sanitize_text_field($params['inspection_fee']));
        }

        // Toggles
        $booking_status = !empty($params['booking_status']) ? 'on' : 'off';
        update_post_meta($listing_id, '_booking_status', $booking_status);

        $slots_status = !empty($params['slots_status']) ? 'on' : 'off';
        update_post_meta($listing_id, '_slots_status', $slots_status);

        if (isset($params['slot_limit'])) {
            update_post_meta($listing_id, '_slot_limit', intval($params['slot_limit']));
        }

        // Menu / Bookable Services
        if (isset($params['menu']) && is_array($params['menu'])) {
            $menu_elements = array();
            foreach ($params['menu'] as $elem) {
                if (!empty($elem['name'])) {
                    $menu_elements[] = array(
                        'name'        => sanitize_text_field($elem['name']),
                        'price'       => sanitize_text_field($elem['price'] ?? '0'),
                        'description' => sanitize_text_field($elem['description'] ?? ''),
                        'bookable'    => (!empty($elem['bookable']) && $elem['bookable'] !== 'off') ? 'on' : 'off',
                    );
                }
            }
            $menu_data = array(
                array(
                    'menu_title'    => 'Standard Services',
                    'menu_elements' => $menu_elements,
                )
            );
            update_post_meta($listing_id, '_menu', $menu_data);
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
        if (!empty($params['logo']) || !empty($params['image'])) {
            $img_url = sanitize_text_field($params['logo'] ?? $params['image']);
            update_post_meta($listing_id, '_featured_image_url', $img_url);
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

        // Taxonomies
        if (!empty($params['category'])) {
            wp_set_object_terms($listing_id, sanitize_text_field($params['category']), 'listing_category', false);
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
        $user = wp_get_current_user();
        $listing_ids = $this->get_vendor_listing_ids($user->ID);

        $gross = 0;
        $commission = 0;
        $net = 0;
        $refunds = 0;

        if (!empty($listing_ids)) {
            $ids_placeholder = implode(',', array_map('intval', $listing_ids));
            $table_name = $wpdb->prefix . 'bookings';
            if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
                $gross = floatval($wpdb->get_var("SELECT SUM(price) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status IN ('completed', 'confirmed')"));
                $refunds = floatval($wpdb->get_var("SELECT SUM(price) FROM $table_name WHERE listing_id IN ($ids_placeholder) AND status = 'refunded'"));
            }
            $commission = round($gross * 0.10, 2);
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
            'gross_earnings'    => $gross,
            'commission'        => $commission,
            'refunds'           => $refunds,
            'net_earnings'      => $net,
            'withdrawn_total'   => $withdrawn_total,
            'available_balance' => $available_balance,
            'withdrawals'       => array_reverse($withdrawals),
        ));
    }

    /**
     * Request wallet withdrawal
     */
    public function request_withdrawal($request) {
        $user = wp_get_current_user();
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
        $user = wp_get_current_user();
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
        $user = wp_get_current_user();
        $listing_ids = $this->get_vendor_listing_ids($user->ID);

        $total_bookmarks = 0;
        $items = array();
        foreach ($listing_ids as $lid) {
            $post = get_post($lid);
            if (!$post) continue;
            $count = intval(get_post_meta($lid, '_bookmark_count', true) ?: get_post_meta($lid, '_bookmarks_count', true) ?: 0);
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
            'total_bookmarks' => $total_bookmarks,
            'items'           => $items,
        ));
    }

    /**
     * Get coupons
     */
    public function get_coupons($request) {
        $user = wp_get_current_user();
        $coupons = get_user_meta($user->ID, '_zipbiz_vendor_coupons', true) ?: array();
        return ZipBiz_REST_API::success_response($coupons);
    }

    /**
     * Create coupon
     */
    public function create_coupon($request) {
        $user = wp_get_current_user();
        $params = $request->get_json_params();

        $code = strtoupper(sanitize_text_field($params['code'] ?? ''));
        $discount = floatval($params['discount'] ?? 0);
        $description = sanitize_text_field($params['description'] ?? '');

        if (empty($code) || $discount <= 0) {
            return ZipBiz_REST_API::error_response('INVALID_COUPON', 'Coupon code and discount are required', 400);
        }

        $coupons = get_user_meta($user->ID, '_zipbiz_vendor_coupons', true) ?: array();
        $new_coupon = array(
            'id'          => time(),
            'code'        => $code,
            'discount'    => $discount,
            'type'        => sanitize_text_field($params['type'] ?? 'percentage'),
            'description' => $description,
            'expiry'      => sanitize_text_field($params['expiry'] ?? date('Y-m-d', strtotime('+30 days'))),
            'status'      => 'active',
            'created_at'  => current_time('mysql'),
        );
        $coupons[] = $new_coupon;
        update_user_meta($user->ID, '_zipbiz_vendor_coupons', $coupons);

        return ZipBiz_REST_API::success_response($new_coupon, 'Coupon created successfully', 201);
    }
}
