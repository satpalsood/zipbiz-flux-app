<?php
if (!defined('ABSPATH')) {
    exit;
}

class ZipBiz_Messages {

    private $table_name;

    public function __construct() {
        global $wpdb;
        $this->table_name = $wpdb->prefix . 'zipbiz_messages';
        $this->maybe_create_table();
    }

    /**
     * Create messages table if it does not exist
     */
    public function maybe_create_table() {
        global $wpdb;
        $charset_collate = $wpdb->get_charset_collate();

        $sql = "CREATE TABLE IF NOT EXISTS {$this->table_name} (
            id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            sender_id bigint(20) unsigned NOT NULL,
            recipient_id bigint(20) unsigned NOT NULL,
            listing_id bigint(20) unsigned DEFAULT 0,
            message text NOT NULL,
            read_status tinyint(1) NOT NULL DEFAULT 0,
            created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY  (id),
            KEY sender_id (sender_id),
            KEY recipient_id (recipient_id),
            KEY listing_id (listing_id)
        ) $charset_collate;";

        require_once(ABSPATH . 'wp-admin/includes/upgrade.php');
        dbDelta($sql);
    }

    public function register_routes() {
        // 1. Get conversation list for current user
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/messages/conversations', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_conversations'),
            'permission_callback' => array($this, 'check_auth'),
        ));

        // 2. Get message thread with a specific recipient
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/messages/(?P<recipient_id>\d+)', array(
            'methods'  => 'GET',
            'callback' => array($this, 'get_messages'),
            'permission_callback' => array($this, 'check_auth'),
            'args' => array(
                'recipient_id' => array(
                    'validate_callback' => function($param) { return is_numeric($param); }
                ),
            ),
        ));

        // 3. Send a message
        register_rest_route(ZIPBIZ_API_NAMESPACE, '/messages/send', array(
            'methods'  => 'POST',
            'callback' => array($this, 'send_message'),
            'permission_callback' => array($this, 'check_auth'),
        ));
    }

    public function check_auth($request) {
        $user = ZipBiz_REST_API::authenticate_user($request);
        return !is_wp_error($user);
    }

    /**
     * Get all active conversations for current user
     */
    public function get_conversations($request) {
        global $wpdb;
        $user = wp_get_current_user();
        $user_id = (int)$user->ID;

        // Ensure table exists
        $this->maybe_create_table();

        // Find unique partner IDs
        $sql = $wpdb->prepare(
            "SELECT DISTINCT 
                CASE 
                    WHEN sender_id = %d THEN recipient_id 
                    ELSE sender_id 
                END AS partner_id
            FROM {$this->table_name}
            WHERE sender_id = %d OR recipient_id = %d",
            $user_id, $user_id, $user_id
        );

        $partner_ids = $wpdb->get_col($sql);
        $conversations = array();

        if (!empty($partner_ids)) {
            foreach ($partner_ids as $pid) {
                $pid = (int)$pid;
                $partner_user = get_userdata($pid);
                if (!$partner_user) {
                    continue;
                }

                // Get latest message in thread
                $latest = $wpdb->get_row($wpdb->prepare(
                    "SELECT * FROM {$this->table_name}
                     WHERE (sender_id = %d AND recipient_id = %d)
                        OR (sender_id = %d AND recipient_id = %d)
                     ORDER BY created_at DESC
                     LIMIT 1",
                    $user_id, $pid, $pid, $user_id
                ));

                // Count unread messages from this partner
                $unread = (int)$wpdb->get_var($wpdb->prepare(
                    "SELECT COUNT(*) FROM {$this->table_name}
                     WHERE sender_id = %d AND recipient_id = %d AND read_status = 0",
                    $pid, $user_id
                ));

                $listing_title = '';
                if (!empty($latest->listing_id)) {
                    $listing_title = get_the_title($latest->listing_id);
                }

                // Check partner role
                $is_vendor = in_array('vendor', (array)$partner_user->roles) 
                    || in_array('seller', (array)$partner_user->roles)
                    || in_array('owner', (array)$partner_user->roles)
                    || count_user_posts($pid, 'listing') > 0;

                $conversations[] = array(
                    'id'            => (string)$pid,
                    'user_id'       => $pid,
                    'name'          => $partner_user->display_name ?: $partner_user->user_login,
                    'avatar'        => get_avatar_url($pid, array('size' => 120)),
                    'service'       => $listing_title ?: ($is_vendor ? 'ZipBiz Verified Partner' : 'Customer Request'),
                    'last_message'  => $latest ? $latest->message : '',
                    'time'          => $latest ? $latest->created_at : '',
                    'unread'        => $unread,
                    'is_vendor'     => $is_vendor,
                    'listing_id'    => $latest ? (int)$latest->listing_id : 0,
                );
            }

            // Sort conversations by latest time DESC
            usort($conversations, function($a, $b) {
                return strtotime($b['time']) - strtotime($a['time']);
            });
        }

        return ZipBiz_REST_API::success_response($conversations, 'Conversations retrieved successfully');
    }

    /**
     * Get message thread with a specific partner
     */
    public function get_messages($request) {
        global $wpdb;
        $user = wp_get_current_user();
        $user_id = (int)$user->ID;
        $recipient_id = (int)$request->get_param('recipient_id');

        $this->maybe_create_table();

        // Mark incoming messages from this recipient as read
        $wpdb->query($wpdb->prepare(
            "UPDATE {$this->table_name}
             SET read_status = 1
             WHERE sender_id = %d AND recipient_id = %d AND read_status = 0",
            $recipient_id, $user_id
        ));

        // Fetch thread messages
        $rows = $wpdb->get_results($wpdb->prepare(
            "SELECT * FROM {$this->table_name}
             WHERE (sender_id = %d AND recipient_id = %d)
                OR (sender_id = %d AND recipient_id = %d)
             ORDER BY created_at ASC",
            $user_id, $recipient_id, $recipient_id, $user_id
        ));

        $messages = array();
        foreach ($rows as $row) {
            $messages[] = array(
                'id'           => (int)$row->id,
                'sender_id'    => (int)$row->sender_id,
                'recipient_id' => (int)$row->recipient_id,
                'listing_id'   => (int)$row->listing_id,
                'message'      => $row->message,
                'read_status'  => (int)$row->read_status,
                'created_at'   => $row->created_at,
                'is_me'        => ((int)$row->sender_id === $user_id),
            );
        }

        $recipient_user = get_userdata($recipient_id);

        return ZipBiz_REST_API::success_response(array(
            'partner' => array(
                'id'     => $recipient_id,
                'name'   => $recipient_user ? ($recipient_user->display_name ?: $recipient_user->user_login) : 'User',
                'avatar' => get_avatar_url($recipient_id, array('size' => 120)),
            ),
            'messages' => $messages,
        ), 'Messages loaded');
    }

    /**
     * Send a message
     */
    public function send_message($request) {
        global $wpdb;
        $user = wp_get_current_user();
        $user_id = (int)$user->ID;
        $params = $request->get_json_params();

        $recipient_id = (int)($params['recipient_id'] ?? $params['vendor_id'] ?? 0);
        $listing_id   = (int)($params['listing_id'] ?? 0);
        $message_text = sanitize_textarea_field($params['message'] ?? '');

        if (!$recipient_id || empty($message_text)) {
            return ZipBiz_REST_API::error_response('INVALID_INPUT', 'Recipient ID and message cannot be empty', 400);
        }

        $this->maybe_create_table();

        $now = current_time('mysql');
        $inserted = $wpdb->insert(
            $this->table_name,
            array(
                'sender_id'    => $user_id,
                'recipient_id' => $recipient_id,
                'listing_id'   => $listing_id,
                'message'      => $message_text,
                'read_status'  => 0,
                'created_at'   => $now,
            ),
            array('%d', '%d', '%d', '%s', '%d', '%s')
        );

        if (!$inserted) {
            return ZipBiz_REST_API::error_response('DB_ERROR', 'Failed to save message', 500);
        }

        $msg_id = $wpdb->insert_id;

        // Send push notification to recipient
        ZipBiz_Notifications::send_push_notification(
            $recipient_id,
            'New message from ' . ($user->display_name ?: 'ZipBiz User'),
            wp_trim_words($message_text, 12, '...'),
            array(
                'type'         => 'chat_message',
                'sender_id'    => (string)$user_id,
                'listing_id'   => (string)$listing_id,
                'message_id'   => (string)$msg_id,
            )
        );

        return ZipBiz_REST_API::success_response(array(
            'id'           => $msg_id,
            'sender_id'    => $user_id,
            'recipient_id' => $recipient_id,
            'listing_id'   => $listing_id,
            'message'      => $message_text,
            'read_status'  => 0,
            'created_at'   => $now,
            'is_me'        => true,
        ), 'Message sent successfully');
    }
}
