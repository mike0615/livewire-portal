<?php
/**
 * LiveWire Child Theme functions
 *
 * Shortcodes (livewire_dashboard, livewire_chat, livewire_mail, livewire_files)
 * are owned by the livewire-shortcodes plugin. Do not re-register them here.
 */
function livewire_enqueue_styles() {
    wp_enqueue_style('parent-style', get_template_directory_uri() . '/style.css');
    wp_enqueue_style('livewire-child', get_stylesheet_directory_uri() . '/style.css', array('parent-style'), '1.0');
}
add_action('wp_enqueue_scripts', 'livewire_enqueue_styles');
