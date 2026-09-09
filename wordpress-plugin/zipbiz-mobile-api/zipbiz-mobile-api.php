<?php
/**
 * Plugin Name: ZipBiz Mobile API
 * Plugin URI: https://zipbiz.in
 * Description: Production-grade REST API bridge for the ZipBiz Native Flutter mobile marketplace. Integrates Listeo listings, bookings, availability, server-side Razorpay payment verification, vendor partner portal, and FCM push notifications.
 * Version: 1.0.0
 * Author: ZipBiz Engineering
 * Author URI: https://zipbiz.in
 * Text Domain: zipbiz-mobile-api
 * License: GPL-2.0+
 */

if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly
}

define('ZIPBIZ_API_VERSION', '1.0.0');
define('ZIPBIZ_API_DIR', plugin_dir_path(__FILE__));
define('ZIPBIZ_API_URL', plugin_dir_url(__FILE__));
define('ZIPBIZ_API_NAMESPACE', 'zipbiz/v1');

// Include core classes
require_once ZIPBIZ_API_DIR . 'includes/class-rest-api.php';
require_once ZIPBIZ_API_DIR . 'includes/class-bookings.php';
require_once ZIPBIZ_API_DIR . 'includes/class-payments.php';
require_once ZIPBIZ_API_DIR . 'includes/class-vendor.php';
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
