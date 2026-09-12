<?php
/**
 * Plugin Name: ZipBiz Mobile API
 * Plugin URI: https://zipbiz.in
 * Description: Production-grade REST API bridge for the ZipBiz Native Flutter mobile marketplace. Integrates Listeo listings, bookings, availability, server-side Razorpay payment verification, vendor partner portal, and FCM push notifications.
 * Version: 1.2.0
 * Author: ZipBiz Engineering
 * Author URI: https://zipbiz.in
 * Text Domain: zipbiz-mobile-api
 * License: GPL-2.0+
 */

if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly
}

define('ZIPBIZ_API_VERSION', '1.2.0');
define('ZIPBIZ_API_DIR', plugin_dir_path(__FILE__));
define('ZIPBIZ_API_URL', plugin_dir_url(__FILE__));
define('ZIPBIZ_API_NAMESPACE', 'zipbiz/v1');

// Include core classes
require_once ZIPBIZ_API_DIR . 'includes/class-rest-api.php';
require_once ZIPBIZ_API_DIR . 'includes/class-bookings.php';
require_once ZIPBIZ_API_DIR . 'includes/class-payments.php';
require_once ZIPBIZ_API_DIR . 'includes/class-vendor.php';
require_once ZIPBIZ_API_DIR . 'includes/class-messages.php';
require_once ZIPBIZ_API_DIR . 'includes/class-notifications.php';
require_once ZIPBIZ_API_DIR . 'admin/settings.php';

/**
 * Initialize the ZipBiz Mobile API plugin
 */
function zipbiz_mobile_api_init() {
    $rest_api = new ZipBiz_REST_API();
    $rest_api->init();

    $settings = new ZipBiz_Admin_Settings();
    $settings->init();
}
add_action('plugins_loaded', 'zipbiz_mobile_api_init');

/**
 * Plugin activation hook
 */
register_activation_hook(__FILE__, 'zipbiz_mobile_api_activate');
function zipbiz_mobile_api_activate() {
    if (!get_option('zipbiz_razorpay_key_id')) {
        update_option('zipbiz_razorpay_key_id', '');
    }
    if (!get_option('zipbiz_razorpay_key_secret')) {
        update_option('zipbiz_razorpay_key_secret', '');
    }
    if (!get_option('zipbiz_fcm_server_key')) {
        update_option('zipbiz_fcm_server_key', '');
    }
}

/**
 * Register roles so WordPress recognizes guest and provider
 */
add_action('init', 'zipbiz_ensure_roles_exist');
function zipbiz_ensure_roles_exist() {
    if (!get_role('guest')) {
        add_role('guest', 'Guest', array('read' => true));
    }
    if (!get_role('provider')) {
        add_role('provider', 'Provider', array(
            'read'          => true,
            'upload_files'  => true,
            'publish_posts' => true,
            'edit_posts'    => true,
        ));
    }
    if (!get_role('owner')) {
        add_role('owner', 'Owner', array(
            'read'          => true,
            'upload_files'  => true,
            'publish_posts' => true,
            'edit_posts'    => true,
        ));
    }
}

/**
 * Automatically assign role on registration:
 * Vendors get 'provider' + 'owner' role, customers get 'guest' + 'customer' role
 */
add_action('user_register', 'zipbiz_assign_user_role_on_register', 10, 1);
function zipbiz_assign_user_role_on_register($user_id) {
    $user = get_user_by('id', $user_id);
    if (!$user) return;

    zipbiz_ensure_roles_exist();

    $requested_role = isset($_REQUEST['role']) ? sanitize_text_field($_REQUEST['role']) : '';
    $is_vendor = (!empty($_REQUEST['is_vendor']) && $_REQUEST['is_vendor'] !== 'false' && $_REQUEST['is_vendor'] !== false);

    if ($requested_role === 'owner' || $requested_role === 'provider' || $requested_role === 'vendor' || $requested_role === 'seller' || $is_vendor) {
        $user->set_role('owner');
        $user->add_role('provider');
    } else {
        if (!in_array('administrator', (array)$user->roles)) {
            $user->set_role('guest');
            $user->add_role('customer');
        }
    }
}

/**
 * Ensure featured image and custom form fields are exposed in REST API
 */
add_filter('rest_prepare_listing', 'zipbiz_rest_prepare_listing_meta', 10, 3);
function zipbiz_rest_prepare_listing_meta($response, $post, $request) {
    if (!is_object($response) || !method_exists($response, 'get_data')) {
        return $response;
    }
    $data = $response->get_data();
    $listing_id = $post->ID;

    // Ensure featured image URL is populated
    $featured_url = get_the_post_thumbnail_url($listing_id, 'full');
    if (empty($featured_url)) {
        $featured_url = get_post_meta($listing_id, '_featured_image_url', true);
    }
    if (empty($featured_url)) {
        $gallery = get_post_meta($listing_id, '_gallery', true);
        if (is_array($gallery) && !empty($gallery)) {
            $first = reset($gallery);
            $featured_url = is_numeric($first) ? wp_get_attachment_url($first) : strval($first);
        }
    }
    if (!empty($featured_url)) {
        $data['featured_image'] = $featured_url;
        $data['featured_image_url'] = $featured_url;
        $data['image'] = $featured_url;
        if (!isset($data['listing_data']) || !is_array($data['listing_data'])) {
            $data['listing_data'] = array();
        }
        $data['listing_data']['_featured_image_url'] = $featured_url;
    }

    // Ensure gallery images are resolved to URLs
    $gallery_raw = get_post_meta($listing_id, '_gallery', true);
    if (!empty($gallery_raw)) {
        $gallery_urls = array();
        if (is_array($gallery_raw)) {
            foreach ($gallery_raw as $gid => $gitem) {
                if (is_numeric($gid) && !empty($gitem) && is_string($gitem) && (strpos($gitem, 'http') === 0)) {
                    $gallery_urls[] = $gitem;
                } elseif (is_numeric($gitem)) {
                    $url = wp_get_attachment_url($gitem);
                    if ($url) $gallery_urls[] = $url;
                } elseif (is_string($gitem) && (strpos($gitem, 'http') === 0)) {
                    $gallery_urls[] = $gitem;
                }
            }
        } elseif (is_string($gallery_raw)) {
            $decoded_g = json_decode($gallery_raw, true);
            if (is_array($decoded_g)) {
                foreach ($decoded_g as $gitem) {
                    if (is_string($gitem) && strpos($gitem, 'http') === 0) {
                        $gallery_urls[] = $gitem;
                    } elseif (is_numeric($gitem)) {
                        $url = wp_get_attachment_url($gitem);
                        if ($url) $gallery_urls[] = $url;
                    }
                }
            }
        }
        if (!empty($gallery_urls)) {
            $data['gallery'] = $gallery_urls;
            $data['gallery_images'] = $gallery_urls;
            $data['_gallery'] = $gallery_urls;
            if (!isset($data['listing_data']) || !is_array($data['listing_data'])) {
                $data['listing_data'] = array();
            }
            $data['listing_data']['_gallery'] = $gallery_urls;
            $data['listing_data']['gallery'] = $gallery_urls;
            $data['listing_data']['gallery_images'] = $gallery_urls;
            if (empty($featured_url) && !empty($gallery_urls[0])) {
                $data['featured_image'] = $gallery_urls[0];
                $data['featured_image_url'] = $gallery_urls[0];
                $data['image'] = $gallery_urls[0];
                $data['listing_data']['_featured_image_url'] = $gallery_urls[0];
            }
        }
    }

    // Slots meta
    $slots = get_post_meta($listing_id, '_slots', true);
    if (!empty($slots)) {
        $decoded_slots = is_string($slots) ? json_decode($slots, true) : $slots;
        $data['slots'] = $decoded_slots;
        $data['_slots'] = $decoded_slots;
        if (!isset($data['listing_data']) || !is_array($data['listing_data'])) {
            $data['listing_data'] = array();
        }
        $data['listing_data']['_slots'] = $decoded_slots;
    }
    $slots_status = get_post_meta($listing_id, '_slots_status', true);
    if (!empty($slots_status)) {
        $data['slots_status'] = $slots_status;
        $data['_slots_status'] = $slots_status;
        if (!isset($data['listing_data']) || !is_array($data['listing_data'])) {
            $data['listing_data'] = array();
        }
        $data['listing_data']['_slots_status'] = $slots_status;
    }

    // FAQs meta
    $faq = get_post_meta($listing_id, '_faq', true);
    if (!empty($faq)) {
        $data['faq'] = $faq;
        $data['_faq'] = $faq;
        if (!isset($data['listing_data']) || !is_array($data['listing_data'])) {
            $data['listing_data'] = array();
        }
        $data['listing_data']['_faq'] = $faq;
    }

    // Visiting fee & custom pricing meta (with fallbacks)
    $visiting_fee = get_post_meta($listing_id, '_visiting_fee', true);
    if ($visiting_fee === '') {
        $visiting_fee = get_post_meta($listing_id, 'visiting_fee', true);
    }
    if ($visiting_fee === '') {
        $visiting_fee = get_post_meta($listing_id, '_visiting_charges', true);
    }
    if ($visiting_fee === '') {
        $visiting_fee = get_post_meta($listing_id, 'visiting_charges', true);
    }
    if ($visiting_fee !== '') {
        $data['visiting_fee'] = $visiting_fee;
        $data['_visiting_fee'] = $visiting_fee;
        $data['visiting_charges'] = $visiting_fee;
        $data['_visiting_charges'] = $visiting_fee;
        if (!isset($data['listing_data']) || !is_array($data['listing_data'])) {
            $data['listing_data'] = array();
        }
        $data['listing_data']['_visiting_fee'] = $visiting_fee;
        $data['listing_data']['visiting_fee'] = $visiting_fee;
        $data['listing_data']['_visiting_charges'] = $visiting_fee;
        $data['listing_data']['visiting_charges'] = $visiting_fee;
    }

    $inspection_fee = get_post_meta($listing_id, '_inspection_fee', true);
    if ($inspection_fee === '') {
        $inspection_fee = get_post_meta($listing_id, 'inspection_fee', true);
    }
    if ($inspection_fee !== '') {
        $data['inspection_fee'] = $inspection_fee;
        $data['_inspection_fee'] = $inspection_fee;
        if (!isset($data['listing_data']) || !is_array($data['listing_data'])) {
            $data['listing_data'] = array();
        }
        $data['listing_data']['_inspection_fee'] = $inspection_fee;
        $data['listing_data']['inspection_fee'] = $inspection_fee;
    }

    $add_label = get_post_meta($listing_id, '_additional_fee_label', true);
    if (empty($add_label)) {
        $add_label = get_post_meta($listing_id, 'additional_fee_label', true);
    }
    if (!empty($add_label)) {
        $data['additional_fee_label'] = $add_label;
        $data['_additional_fee_label'] = $add_label;
        if (!isset($data['listing_data']) || !is_array($data['listing_data'])) {
            $data['listing_data'] = array();
        }
        $data['listing_data']['_additional_fee_label'] = $add_label;
        $data['listing_data']['additional_fee_label'] = $add_label;
    }

    $add_amount = get_post_meta($listing_id, '_additional_fee_amount', true);
    if (empty($add_amount)) {
        $add_amount = get_post_meta($listing_id, 'additional_fee_amount', true);
    }
    if (!empty($add_amount)) {
        $data['additional_fee_amount'] = $add_amount;
        $data['_additional_fee_amount'] = $add_amount;
        if (!isset($data['listing_data']) || !is_array($data['listing_data'])) {
            $data['listing_data'] = array();
        }
        $data['listing_data']['_additional_fee_amount'] = $add_amount;
        $data['listing_data']['additional_fee_amount'] = $add_amount;
    }

    $min_booking = get_post_meta($listing_id, '_min_booking_value', true);
    if (empty($min_booking)) {
        $min_booking = get_post_meta($listing_id, 'min_booking_value', true);
    }
    if (!empty($min_booking)) {
        $data['min_booking_value'] = $min_booking;
        $data['_min_booking_value'] = $min_booking;
        if (!isset($data['listing_data']) || !is_array($data['listing_data'])) {
            $data['listing_data'] = array();
        }
        $data['listing_data']['_min_booking_value'] = $min_booking;
        $data['listing_data']['min_booking_value'] = $min_booking;
    }

    // Expose all custom post meta fields dynamically
    $all_custom_meta = get_post_custom($listing_id);
    if (!empty($all_custom_meta) && is_array($all_custom_meta)) {
        if (!isset($data['listing_data']) || !is_array($data['listing_data'])) {
            $data['listing_data'] = array();
        }
        foreach ($all_custom_meta as $meta_k => $meta_v_arr) {
            $meta_v = is_array($meta_v_arr) ? reset($meta_v_arr) : $meta_v_arr;
            if (!isset($data[$meta_k])) {
                $data[$meta_k] = $meta_v;
            }
            if (!isset($data['listing_data'][$meta_k])) {
                $data['listing_data'][$meta_k] = $meta_v;
            }
            $clean_k = ltrim($meta_k, '_');
            if (!isset($data[$clean_k])) {
                $data[$clean_k] = $meta_v;
            }
            if (!isset($data['listing_data'][$clean_k])) {
                $data['listing_data'][$clean_k] = $meta_v;
            }
        }
    }

    // Verified and featured flags
    $is_verified = get_post_meta($listing_id, '_verified', true);
    $data['verified'] = ($is_verified === 'on' || $is_verified === '1' || $is_verified === true || $is_verified === 'claimed');
    $data['_verified'] = $data['verified'] ? 'on' : 'off';
    
    $is_featured = get_post_meta($listing_id, '_featured', true);
    $data['featured'] = ($is_featured === 'on' || $is_featured === '1' || $is_featured === true);
    $data['_featured'] = $data['featured'] ? 'on' : 'off';

    // Show coupons toggle
    $show_coupons = get_post_meta($listing_id, '_show_coupons', true) ?: get_post_meta($listing_id, 'show_coupons', true) ?: 'on';
    $data['show_coupons'] = ($show_coupons === 'on' || $show_coupons === '1' || $show_coupons === true);
    $data['_show_coupons'] = $data['show_coupons'] ? 'on' : 'off';

    // Coupons for listing
    $available_coupons = array();
    if ($data['show_coupons']) {
        $listing_post = get_post($listing_id);
        $author_id = $listing_post ? $listing_post->post_author : 0;
        if ($author_id) {
            $user_coupons = get_user_meta($author_id, '_zipbiz_vendor_coupons', true) ?: array();
            if (is_array($user_coupons)) {
                foreach ($user_coupons as $uc) {
                    $available_coupons[] = $uc;
                }
            }
            $wc_coupons = get_posts(array(
                'post_type'      => 'shop_coupon',
                'post_status'    => 'publish',
                'posts_per_page' => 10,
                'meta_query'     => array(
                    array(
                        'key'   => '_vendor_id',
                        'value' => $author_id,
                    ),
                ),
            ));
            if (!empty($wc_coupons)) {
                foreach ($wc_coupons as $cp) {
                    $c_code = $cp->post_title;
                    $already = false;
                    foreach ($available_coupons as $ac) {
                        if (isset($ac['code']) && strcasecmp($ac['code'], $c_code) === 0) {
                            $already = true;
                            break;
                        }
                    }
                    if (!$already) {
                        $available_coupons[] = array(
                            'id'            => $cp->ID,
                            'code'          => $c_code,
                            'amount'        => floatval(get_post_meta($cp->ID, 'coupon_amount', true) ?: 0),
                            'discount_type' => get_post_meta($cp->ID, 'discount_type', true) ?: 'percent',
                            'description'   => $cp->post_excerpt ?: 'Promotional Discount Coupon',
                        );
                    }
                }
            }
        }
    }
    $data['coupons'] = $available_coupons;
    if (isset($data['listing_data']) && is_array($data['listing_data'])) {
        $data['listing_data']['coupons'] = $available_coupons;
    }

    $response->set_data($data);
    return $response;
}

