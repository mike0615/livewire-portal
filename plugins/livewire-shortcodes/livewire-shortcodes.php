<?php
/**
 * Plugin Name: LiveWire Shortcodes
 * Description: Unified shortcodes for embeds and dashboard.
 * Version: 1.0
 */

function livewire_register_shortcodes() {
    add_shortcode('livewire_dashboard', 'livewire_dashboard_cb');
    add_shortcode('livewire_chat', 'livewire_chat_cb');
    add_shortcode('livewire_mail', 'livewire_mail_cb');
    add_shortcode('livewire_files', 'livewire_files_cb');
}
add_action('init', 'livewire_register_shortcodes');

function livewire_dashboard_cb() {
    return '<div class="portal-dashboard">
        <div class="tool-card"><h3>💬 Chat</h3><p>Team XMPP</p></div>
        <div class="tool-card"><h3>📁 Files</h3><p>Share & download</p></div>
        <div class="tool-card"><h3>✉️ Mail</h3><p>Roundcube</p></div>
        <div class="tool-card"><h3>🔧 Tools</h3><p>All links</p></div>
    </div>';
}

function livewire_chat_cb() {
    return '<iframe class="embed-frame" src="https://xmpp.example.com/converse/" title="Chat"></iframe>';
}

function livewire_mail_cb() {
    return '<iframe class="embed-frame" src="https://mail.example.com/roundcube/" title="Mail"></iframe>';
}

function livewire_files_cb() {
    return do_shortcode('[shared_files]');
}