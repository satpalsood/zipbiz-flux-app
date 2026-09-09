<?php
if (!defined('ABSPATH')) {
    exit;
}

class ZipBiz_Notifications {

    public function register_routes() {
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/device-token', array(
            'methods'  => 'POST',
            'callback' => array($this, 'register_device_token'),
            'permission_callback' => array($this, 'check_auth'),
        ));
    }

    public function check_auth($request) {
        $user = ZipBiz_REST_API::authenticate_user($request);
        return !is_wp_error($user);
    }

    /**
     * Save user device token for push notifications
     */
    public function register_device_token($request) {
        $user = wp_get_current_user();
        $params = $request->get_json_params();

        $token = sanitize_text_field($params['token'] ?? '');
        $platform = sanitize_text_field($params['platform'] ?? 'android');
        $app_version = sanitize_text_field($params['app_version'] ?? '1.0.0');

        if (empty($token)) {
            return ZipBiz_REST_API::error_response('INVALID_TOKEN', 'Device token cannot be empty', 400);
        }

        $existing_tokens = get_user_meta($user->ID, '_zipbiz_fcm_tokens', true);
        if (!is_array($existing_tokens)) {
            $existing_tokens = array();
        }

        // Add or update token
        $existing_tokens[$token] = array(
            'platform'    => $platform,
            'app_version' => $app_version,
            'updated'     => current_time('mysql'),
        );

        // Keep at most 5 active devices per user
        if (count($existing_tokens) > 5) {
            $existing_tokens = array_slice($existing_tokens, -5, 5, true);
        }

        update_user_meta($user->ID, '_zipbiz_fcm_tokens', $existing_tokens);

        return ZipBiz_REST_API::success_response(array('registered' => true), 'Device token registered successfully');
    }

    /**
     * Send FCM push notification to a user
     */
    public static function send_push_notification($user_id, $title, $body, $data = array()) {
        if (!$user_id) return false;

        $tokens = get_user_meta($user_id, '_zipbiz_fcm_tokens', true);
        if (empty($tokens) || !is_array($tokens)) {
            return false;
        }

        $server_key = get_option('zipbiz_fcm_server_key');
        if (empty($server_key)) {
            return false;
        }

        $registration_ids = array_keys($tokens);

        $payload = array(
            'registration_ids' => $registration_ids,
            'notification'     => array(
                'title' => $title,
                'body'  => $body,
                'sound' => 'default',
            ),
            'data'             => array_merge($data, array(
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                'title'        => $title,
                'body'         => $body,
            )),
            'priority'         => 'high',
        );

        $response = wp_remote_post('https://fcm.googleapis.com/fcm/send', array(
            'headers' => array(
                'Authorization' => 'key=' . $server_key,
                'Content-Type'  => 'application/json',
            ),
            'body'    => json_encode($payload),
            'timeout' => 15,
        ));

        return !is_wp_error($response);
    }
}
