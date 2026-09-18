<?php
/**
 * LiveWire Child Theme functions
 */
function livewire_enqueue_styles() {
    wp_enqueue_style('parent-style', get_template_directory_uri() . '/style.css');
    wp_enqueue_style('livewire-child', get_stylesheet_directory_uri() . '/style.css', array('parent-style'), '1.0');
}
add_action('wp_enqueue_scripts', 'livewire_enqueue_styles');

// Shortcode for dashboard cards
function livewire_dashboard_shortcode($atts) {
    $atts = shortcode_atts(array(
        'title' => 'Tools',
        'links' => ''
    ), $atts);
    ob_start();
    echo '<div class="portal-dashboard">';
    // Parse links or hardcode
    echo '<div class="tool-card"><h3>Chat</h3><p>Embedded XMPP</p></div>';
    echo '<div class="tool-card"><h3>Files</h3><p>Upload & share</p></div>';
    echo '<div class="tool-card"><h3>Mail</h3><p>Roundcube</p></div>';
    echo '</div>';
    return ob_get_clean();
}
add_shortcode('livewire_dashboard', 'livewire_dashboard_shortcode');

// Shortcode for Converse.js embed
function livewire_chat_shortcode() {
    return '<div id="converse-root"></div>
<script src="https://cdn.conversejs.org/dist/converse.min.js"></script>
<script>
converse.initialize({
    bosh_service_url: "https://xmpp.example.com:5280/http-bind/",
    websocket_url: "wss://xmpp.example.com:5281/xmpp-websocket/",
    theme: "livewire",
    auto_login: true
});
</script>';
}
add_shortcode('livewire_chat', 'livewire_chat_shortcode');