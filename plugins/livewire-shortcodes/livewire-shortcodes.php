<?php
/**
 * Plugin Name: LiveWire Shortcodes
 * Description: Unified shortcodes for embeds and dashboard.
 * Version: 1.1.2
 *
 * Dashboard is data-driven: edit plugins/livewire-shortcodes/tools.json
 * to add/remove tool cards without touching PHP.
 *
 * Site-local defaults use *.acc.local. Override with filters:
 *   livewire_xmpp_url, livewire_mail_url
 * or define LIVEWIRE_XMPP_URL / LIVEWIRE_MAIL_URL before plugins load.
 */

if (!defined('LIVEWIRE_XMPP_URL')) {
    define('LIVEWIRE_XMPP_URL', 'https://xmpp.acc.local/converse/');
}
if (!defined('LIVEWIRE_MAIL_URL')) {
    define('LIVEWIRE_MAIL_URL', 'https://mail.acc.local/roundcube/');
}

function livewire_register_shortcodes() {
    add_shortcode('livewire_dashboard', 'livewire_dashboard_cb');
    add_shortcode('livewire_chat', 'livewire_chat_cb');
    add_shortcode('livewire_mail', 'livewire_mail_cb');
    add_shortcode('livewire_files', 'livewire_files_cb');
}
add_action('init', 'livewire_register_shortcodes');

/**
 * Load tool definitions from tools.json (falls back to built-in defaults).
 */
function livewire_load_tools() {
    static $json_warned = false;
    $json_path = plugin_dir_path(__FILE__) . 'tools.json';
    if (file_exists($json_path)) {
        $raw = file_get_contents($json_path);
        $tools = json_decode($raw, true);
        if (is_array($tools)) {
            return $tools;
        }
        if (!$json_warned) {
            $json_warned = true;
            if (function_exists('error_log')) {
                error_log('livewire-shortcodes: tools.json is invalid JSON; using built-in defaults.');
            }
            add_action('admin_notices', 'livewire_tools_json_admin_notice');
        }
    }
    return array(
        array('icon' => '💬', 'title' => 'Chat', 'desc' => 'Team XMPP', 'url' => 'https://portal.acc.local/#chat'),
        array('icon' => '📁', 'title' => 'Files', 'desc' => 'Share & download', 'url' => 'https://portal.acc.local/#files'),
        array('icon' => '✉️', 'title' => 'Mail', 'desc' => 'Roundcube', 'url' => 'https://mail.acc.local/roundcube/'),
        array('icon' => '🔧', 'title' => 'Tools', 'desc' => 'All links', 'url' => 'https://portal.acc.local/#tools'),
    );
}

function livewire_tools_json_admin_notice() {
    if (!current_user_can('manage_options')) {
        return;
    }
    echo '<div class="notice notice-warning"><p>';
    echo esc_html('LiveWire Shortcodes: tools.json is invalid JSON. Using built-in defaults until it is fixed.');
    echo '</p></div>';
}

function livewire_dashboard_cb() {
    $tools = livewire_load_tools();
    ob_start();
    echo '<div class="portal-dashboard">';
    foreach ($tools as $t) {
        $icon  = isset($t['icon'])  ? esc_html($t['icon'])  : '';
        $title = isset($t['title']) ? esc_html($t['title']) : '';
        $desc  = isset($t['desc'])  ? esc_html($t['desc'])  : '';
        $url   = isset($t['url'])   ? esc_url($t['url'])    : '#';
        echo '<a class="tool-card" href="' . $url . '">';
        echo '<h3>' . $icon . ' ' . $title . '</h3>';
        echo '<p>' . $desc . '</p>';
        echo '</a>';
    }
    echo '</div>';
    return ob_get_clean();
}

function livewire_chat_cb() {
    $url = esc_url(apply_filters('livewire_xmpp_url', LIVEWIRE_XMPP_URL));
    return '<iframe class="embed-frame" src="' . $url . '" title="Chat"></iframe>';
}

function livewire_mail_cb() {
    $url = esc_url(apply_filters('livewire_mail_url', LIVEWIRE_MAIL_URL));
    return '<iframe class="embed-frame" src="' . $url . '" title="Mail"></iframe>';
}

function livewire_files_cb() {
    return do_shortcode('[shared_files]');
}
