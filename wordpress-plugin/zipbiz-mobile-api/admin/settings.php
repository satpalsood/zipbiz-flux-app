<?php
if (!defined('ABSPATH')) {
    exit;
}

class ZipBiz_Admin_Settings {

    public function init() {
        add_action('admin_menu', array($this, 'add_settings_menu'));
        add_action('admin_init', array($this, 'register_settings'));
    }

    public function add_settings_menu() {
        add_options_page(
            'ZipBiz Mobile API Settings',
            'ZipBiz Mobile API',
            'manage_options',
            'zipbiz-mobile-api',
            array($this, 'render_settings_page')
        );
    }

    public function register_settings() {
        register_setting('zipbiz_settings_group', 'zipbiz_razorpay_key_id');
        register_setting('zipbiz_settings_group', 'zipbiz_razorpay_key_secret');
        register_setting('zipbiz_settings_group', 'zipbiz_fcm_server_key');
        register_setting('zipbiz_settings_group', 'zipbiz_commission_rate');
    }

    public function render_settings_page() {
        ?>
        <div class="wrap">
            <h1>ZipBiz Native Mobile API Configuration</h1>
            <p>Configure Razorpay credentials and Firebase Cloud Messaging for the native Flutter mobile marketplace application.</p>
            <hr />

            <form method="post" action="options.php">
                <?php settings_fields('zipbiz_settings_group'); ?>
                <?php do_settings_sections('zipbiz_settings_group'); ?>

                <table class="form-table">
                    <tr valign="top">
                        <th scope="row">Razorpay Key ID</th>
                        <td>
                            <input type="text" name="zipbiz_razorpay_key_id" value="<?php echo esc_attr(get_option('zipbiz_razorpay_key_id')); ?>" class="regular-text" placeholder="rzp_live_... or rzp_test_..." />
                            <p class="description">Live/Test Key ID from your Razorpay Dashboard.</p>
                        </td>
                    </tr>

                    <tr valign="top">
                        <th scope="row">Razorpay Key Secret</th>
                        <td>
                            <input type="password" name="zipbiz_razorpay_key_secret" value="<?php echo esc_attr(get_option('zipbiz_razorpay_key_secret')); ?>" class="regular-text" />
                            <p class="description">Razorpay Key Secret used for server-side HMAC-SHA256 signature verification.</p>
                        </td>
                    </tr>

                    <tr valign="top">
                        <th scope="row">Firebase Cloud Messaging (FCM) Server Key</th>
                        <td>
                            <input type="password" name="zipbiz_fcm_server_key" value="<?php echo esc_attr(get_option('zipbiz_fcm_server_key')); ?>" class="large-text" />
                            <p class="description">Cloud Messaging API Server Key from Firebase Console &gt; Project Settings &gt; Cloud Messaging.</p>
                        </td>
                    </tr>

                    <tr valign="top">
                        <th scope="row">Platform Commission Rate (%)</th>
                        <td>
                            <input type="number" step="0.5" name="zipbiz_commission_rate" value="<?php echo esc_attr(get_option('zipbiz_commission_rate', '10')); ?>" class="small-text" /> %
                            <p class="description">Default marketplace commission percentage for listing providers.</p>
                        </td>
                    </tr>
                </table>

                <?php submit_button('Save ZipBiz Settings'); ?>
            </form>

            <div style="margin-top: 30px; background: #fff; padding: 20px; border-radius: 8px; border-left: 4px solid #ff6b00; max-width: 800px;">
                <h3>Active Mobile Endpoints</h3>
                <ul>
                    <li><code>GET /wp-json/zipbiz/v1/health</code> - API Status check</li>
                    <li><code>POST /wp-json/zipbiz/v1/booking/create</code> - Create booking with race condition lock &amp; server pricing</li>
                    <li><code>GET /wp-json/zipbiz/v1/booking/{id}</code> - Get booking detail &amp; status</li>
                    <li><code>GET /wp-json/zipbiz/v1/booking/availability</code> - Live date/time slot availability</li>
                    <li><code>POST /wp-json/zipbiz/v1/payment/create-order</code> - Server-side Razorpay order generation</li>
                    <li><code>POST /wp-json/zipbiz/v1/payment/verify</code> - Cryptographic HMAC-SHA256 signature check</li>
                    <li><code>GET /wp-json/zipbiz/v1/vendor/dashboard</code> - Vendor KPI stats</li>
                    <li><code>GET /wp-json/zipbiz/v1/vendor/bookings</code> - Vendor bookings management</li>
                    <li><code>POST /wp-json/zipbiz/v1/vendor/bookings/{id}/accept</code> - Accept booking</li>
                    <li><code>POST /wp-json/zipbiz/v1/vendor/bookings/{id}/reject</code> - Reject booking</li>
                    <li><code>POST /wp-json/zipbiz/v1/device-token</code> - FCM device token sync</li>
                </ul>
            </div>
        </div>
        <?php
    }
}
