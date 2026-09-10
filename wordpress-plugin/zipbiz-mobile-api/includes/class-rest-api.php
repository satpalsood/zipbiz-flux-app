<?php
if (!defined('ABSPATH')) {
    exit;
}

class ZipBiz_REST_API {

    public function init() {
        add_action('rest_api_init', array($this, 'register_routes'));
        add_action('rest_api_init', array($this, 'handle_cors'), 15);
    }

    /**
     * Enable Cross-Origin Resource Sharing (CORS) for Flutter Web testing
     */
    public function handle_cors() {
        remove_filter('rest_pre_serve_request', 'rest_send_cors_headers');
        add_filter('rest_pre_serve_request', function($value) {
            header('Access-Control-Allow-Origin: *');
            header('Access-Control-Allow-Methods: POST, GET, OPTIONS, PUT, DELETE');
            header('Access-Control-Allow-Headers: Authorization, Content-Type, User-Cookie, X-User-ID, X-WP-Nonce, X-Requested-With');
            if (isset($_SERVER['REQUEST_METHOD']) && 'OPTIONS' === $_SERVER['REQUEST_METHOD']) {
                status_header(200);
                exit();
            }
            return $value;
        });
    }

    public function register_routes() {
        $bookings = new ZipBiz_Bookings();
        $bookings->register_routes();

        $payments = new ZipBiz_Payments();
        $payments->register_routes();

        $vendor = new ZipBiz_Vendor();
        $vendor->register_routes();

        $messages = new ZipBiz_Messages();
        $messages->register_routes();

        $notifications = new ZipBiz_Notifications();
        $notifications->register_routes();

        // Health check route
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/health', array(
            'methods'  => 'GET',
            'callback' => array($this, 'health_check'),
            'permission_callback' => '__return_true',
        ));
    }

    public function health_check() {
        return self::success_response(array(
            'status'  => 'online',
            'version' => ZIPBIZ_API_VERSION,
            'listeo'  => class_exists('Listeo_Core') || post_type_exists('listing'),
            'timestamp' => current_time('mysql'),
        ), 'ZipBiz Mobile API is active and operational');
    }

    /**
     * Authenticate request using MStore cookie, Bearer token, or WP session
     *
     * @param WP_REST_Request $request
     * @return WP_User|WP_Error
     */
    public static function authenticate_user($request) {
        // 1. Check if already logged in via standard WordPress session
        if (is_user_logged_in()) {
            return wp_get_current_user();
        }

        // 2. Check for User-Cookie header or cookie query/body param (MStore format)
        $cookie = $request->get_header('User-Cookie');
        if (empty($cookie)) {
            $auth_header = $request->get_header('Authorization');
            if (!empty($auth_header) && preg_match('/Bearer\s+(.*)$/i', $auth_header, $matches)) {
                $cookie = $matches[1];
            }
        }
        if (empty($cookie)) {
            $cookie = $request->get_param('cookie');
        }

        if (!empty($cookie)) {
            // Try raw cookie
            $user_id = wp_validate_auth_cookie($cookie, 'logged_in');
            if (!$user_id) {
                // Try URL decoded cookie
                $user_id = wp_validate_auth_cookie(urldecode($cookie), 'logged_in');
            }
            if (!$user_id) {
                // Try Base64 decoded cookie (used by some MStore versions)
                $decoded = base64_decode($cookie);
                if ($decoded && strpos($decoded, '|') !== false) {
                    $user_id = wp_validate_auth_cookie($decoded, 'logged_in');
                }
            }

            if ($user_id) {
                wp_set_current_user($user_id);
                return get_user_by('id', $user_id);
            }
        }

        // 3. Check X-User-ID header or user_id param
        $header_uid = intval($request->get_header('X-User-ID') ?: $request->get_param('user_id'));
        if ($header_uid > 0) {
            $user = get_user_by('id', $header_uid);
            if ($user && $user->ID) {
                wp_set_current_user($user->ID);
                return $user;
            }
        }

        return new WP_Error('unauthorized', 'Authentication required. Please provide a valid session token.', array('status' => 401));
    }


    /**
     * Standardized Success JSON
     */
    public static function success_response($data = null, $message = 'Success', $status = 200) {
        return new WP_REST_Response(array(
            'success' => true,
            'code'    => 'OK',
            'message' => $message,
            'data'    => $data,
        ), $status);
    }

    /**
     * Standardized Error JSON
     */
    public static function error_response($code, $message, $status = 400) {
        return new WP_REST_Response(array(
            'success' => false,
            'code'    => $code,
            'message' => $message,
            'data'    => null,
        ), $status);
    }
}
