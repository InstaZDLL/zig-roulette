//! Hand-written GTK4 / libadwaita / Cairo / GLib bindings.
//!
//! There is no `@cImport` in this project: every C symbol the app touches is
//! declared here as an `extern fn`. When you need a function that is not yet
//! bound, add its declaration to this file.

pub const gboolean = c_int;
pub const gint = c_int;
pub const guint = c_uint;
pub const gdouble = f64;
pub const gulong = c_ulong;

pub const TRUE: gboolean = 1;
pub const FALSE: gboolean = 0;
pub const G_APPLICATION_DEFAULT_FLAGS: c_uint = 0;
pub const G_LOG_LEVEL_WARNING: c_uint = 1 << 4;
pub const G_LOG_LEVEL_MASK: c_uint = 0x3f;
pub const G_LOG_WRITER_UNHANDLED: c_int = 0;
pub const G_LOG_WRITER_HANDLED: c_int = 1;
pub const GTK_ALIGN_START: c_int = 1;
pub const GTK_ALIGN_END: c_int = 2;
pub const GTK_ALIGN_CENTER: c_int = 3;
pub const GTK_ORIENTATION_HORIZONTAL: c_int = 0;
pub const GTK_ORIENTATION_VERTICAL: c_int = 1;
pub const GTK_POLICY_ALWAYS: c_int = 0;
pub const GTK_POLICY_AUTOMATIC: c_int = 1;
pub const GTK_POLICY_NEVER: c_int = 2;
pub const CAIRO_FONT_SLANT_NORMAL: c_int = 0;
pub const CAIRO_FONT_WEIGHT_BOLD: c_int = 1;

pub const AdwApplication = opaque {};
pub const GtkApplication = opaque {};
pub const GApplication = opaque {};
pub const GtkWidget = opaque {};
pub const GtkWindow = opaque {};
pub const AdwApplicationWindow = opaque {};
pub const AdwToolbarView = opaque {};
pub const AdwHeaderBar = opaque {};
pub const GtkBox = opaque {};
pub const GtkLabel = opaque {};
pub const GtkDrawingArea = opaque {};
pub const GtkGestureClick = opaque {};
pub const GtkGestureSingle = opaque {};
pub const GtkEventController = opaque {};
pub const GtkSpinButton = opaque {};
pub const GtkButton = opaque {};
pub const GtkListBox = opaque {};
pub const GtkScrolledWindow = opaque {};
pub const GtkImage = opaque {};
pub const GtkPicture = opaque {};
pub const GtkCssProvider = opaque {};
pub const GtkStyleProvider = opaque {};
pub const GBytes = opaque {};
pub const GError = opaque {};
pub const GdkDisplay = opaque {};
pub const GdkPaintable = opaque {};
pub const GdkTexture = opaque {};
pub const cairo_t = opaque {};

pub const cairo_text_extents_t = extern struct {
    x_bearing: f64,
    y_bearing: f64,
    width: f64,
    height: f64,
    x_advance: f64,
    y_advance: f64,
};

pub extern fn adw_application_new(application_id: [*:0]const u8, flags: c_uint) *AdwApplication;
pub extern fn adw_application_window_new(app: *GtkApplication) *GtkWidget;
pub extern fn adw_application_window_set_content(self: *AdwApplicationWindow, content: *GtkWidget) void;
pub extern fn adw_toolbar_view_new() *GtkWidget;
pub extern fn adw_toolbar_view_add_top_bar(self: *AdwToolbarView, widget: *GtkWidget) void;
pub extern fn adw_toolbar_view_set_content(self: *AdwToolbarView, content: *GtkWidget) void;
pub extern fn adw_header_bar_new() *GtkWidget;
pub extern fn adw_header_bar_set_title_widget(self: *AdwHeaderBar, title_widget: *GtkWidget) void;
pub extern fn adw_window_title_new(title: [*:0]const u8, subtitle: [*:0]const u8) *GtkWidget;

pub extern fn g_application_run(application: *GApplication, argc: c_int, argv: ?*?[*:0]u8) c_int;
pub extern fn g_get_real_time() i64;
pub extern fn g_object_unref(object: *anyopaque) void;
pub extern fn g_log_set_handler(log_domain: [*:0]const u8, log_levels: c_uint, log_func: *const anyopaque, user_data: ?*anyopaque) guint;
pub extern fn g_log_set_writer_func(func: *const anyopaque, user_data: ?*anyopaque, user_data_free: ?*const anyopaque) void;
pub extern fn g_signal_connect_data(instance: *anyopaque, detailed_signal: [*:0]const u8, c_handler: *const anyopaque, data: ?*anyopaque, destroy_data: ?*const anyopaque, connect_flags: c_int) gulong;
pub extern fn g_timeout_add(interval: guint, function: *const anyopaque, data: ?*anyopaque) guint;
pub extern fn g_bytes_new_static(data: *const anyopaque, size: usize) *GBytes;
pub extern fn g_bytes_unref(bytes: *GBytes) void;

pub extern fn gtk_window_set_title(window: *GtkWindow, title: [*:0]const u8) void;
pub extern fn gtk_window_set_default_size(window: *GtkWindow, width: c_int, height: c_int) void;
pub extern fn gtk_window_set_default_icon_name(name: [*:0]const u8) void;
pub extern fn gtk_window_present(window: *GtkWindow) void;
pub extern fn gtk_box_new(orientation: c_int, spacing: c_int) *GtkWidget;
pub extern fn gtk_box_append(box: *GtkBox, child: *GtkWidget) void;
pub extern fn gtk_box_remove(box: *GtkBox, child: *GtkWidget) void;
pub extern fn gtk_widget_set_margin_top(widget: *GtkWidget, margin: c_int) void;
pub extern fn gtk_widget_set_margin_bottom(widget: *GtkWidget, margin: c_int) void;
pub extern fn gtk_widget_set_margin_start(widget: *GtkWidget, margin: c_int) void;
pub extern fn gtk_widget_set_margin_end(widget: *GtkWidget, margin: c_int) void;
pub extern fn gtk_widget_set_hexpand(widget: *GtkWidget, expand: gboolean) void;
pub extern fn gtk_widget_set_vexpand(widget: *GtkWidget, expand: gboolean) void;
pub extern fn gtk_widget_set_halign(widget: *GtkWidget, alignment: c_int) void;
pub extern fn gtk_widget_set_size_request(widget: *GtkWidget, width: c_int, height: c_int) void;
pub extern fn gtk_widget_add_css_class(widget: *GtkWidget, css_class: [*:0]const u8) void;
pub extern fn gtk_widget_set_sensitive(widget: *GtkWidget, sensitive: gboolean) void;
pub extern fn gtk_widget_queue_draw(widget: *GtkWidget) void;
pub extern fn gtk_widget_get_first_child(widget: *GtkWidget) ?*GtkWidget;
pub extern fn gtk_widget_add_controller(widget: *GtkWidget, controller: *GtkEventController) void;
pub extern fn gtk_drawing_area_new() *GtkWidget;
pub extern fn gtk_drawing_area_set_draw_func(area: *GtkDrawingArea, draw_func: *const anyopaque, user_data: ?*anyopaque, destroy: ?*const anyopaque) void;
pub extern fn gtk_gesture_click_new() *GtkWidget;
pub extern fn gtk_gesture_single_set_button(gesture: *GtkGestureSingle, button: guint) void;
pub extern fn gtk_label_new(str: [*:0]const u8) *GtkWidget;
pub extern fn gtk_label_set_text(label: *GtkLabel, str: [*:0]const u8) void;
pub extern fn gtk_label_set_xalign(label: *GtkLabel, xalign: f32) void;
pub extern fn gtk_label_set_wrap(label: *GtkLabel, wrap: gboolean) void;
pub extern fn gtk_spin_button_new_with_range(min: f64, max: f64, step: f64) *GtkWidget;
pub extern fn gtk_spin_button_set_value(spin_button: *GtkSpinButton, value: f64) void;
pub extern fn gtk_spin_button_get_value(spin_button: *GtkSpinButton) f64;
pub extern fn gtk_button_new_with_label(label: [*:0]const u8) *GtkWidget;
pub extern fn gtk_button_set_label(button: *GtkButton, label: [*:0]const u8) void;
pub extern fn gtk_image_new_from_icon_name(icon_name: [*:0]const u8) *GtkWidget;
pub extern fn gtk_image_set_pixel_size(image: *GtkImage, pixel_size: c_int) void;
pub extern fn gtk_picture_new_for_paintable(paintable: *GdkPaintable) *GtkWidget;
pub extern fn gtk_picture_set_can_shrink(self: *GtkPicture, can_shrink: gboolean) void;
pub extern fn gtk_picture_set_keep_aspect_ratio(self: *GtkPicture, keep_aspect_ratio: gboolean) void;
pub extern fn gtk_list_box_new() *GtkWidget;
pub extern fn gtk_list_box_append(box: *GtkListBox, child: *GtkWidget) void;
pub extern fn gtk_list_box_remove(box: *GtkListBox, child: *GtkWidget) void;
pub extern fn gtk_scrolled_window_new() *GtkWidget;
pub extern fn gtk_scrolled_window_set_child(scrolled_window: *GtkScrolledWindow, child: ?*GtkWidget) void;
pub extern fn gtk_scrolled_window_set_policy(scrolled_window: *GtkScrolledWindow, hscrollbar_policy: c_int, vscrollbar_policy: c_int) void;
pub extern fn gtk_css_provider_new() *GtkCssProvider;
pub extern fn gtk_css_provider_load_from_string(css_provider: *GtkCssProvider, string: [*:0]const u8) void;
pub extern fn gtk_style_context_add_provider_for_display(display: *GdkDisplay, provider: *GtkStyleProvider, priority: guint) void;
pub extern fn gdk_display_get_default() ?*GdkDisplay;
pub extern fn gdk_texture_new_from_bytes(bytes: *GBytes, error_: ?*?*GError) ?*GdkTexture;

pub extern fn cairo_set_source_rgb(cr: *cairo_t, red: f64, green: f64, blue: f64) void;
pub extern fn cairo_set_source_rgba(cr: *cairo_t, red: f64, green: f64, blue: f64, alpha: f64) void;
pub extern fn cairo_paint(cr: *cairo_t) void;
pub extern fn cairo_save(cr: *cairo_t) void;
pub extern fn cairo_restore(cr: *cairo_t) void;
pub extern fn cairo_translate(cr: *cairo_t, tx: f64, ty: f64) void;
pub extern fn cairo_rotate(cr: *cairo_t, angle: f64) void;
pub extern fn cairo_move_to(cr: *cairo_t, x: f64, y: f64) void;
pub extern fn cairo_arc(cr: *cairo_t, xc: f64, yc: f64, radius: f64, angle1: f64, angle2: f64) void;
pub extern fn cairo_close_path(cr: *cairo_t) void;
pub extern fn cairo_fill(cr: *cairo_t) void;
pub extern fn cairo_fill_preserve(cr: *cairo_t) void;
pub extern fn cairo_set_line_width(cr: *cairo_t, width: f64) void;
pub extern fn cairo_stroke(cr: *cairo_t) void;
pub extern fn cairo_rectangle(cr: *cairo_t, x: f64, y: f64, width: f64, height: f64) void;
pub extern fn cairo_select_font_face(cr: *cairo_t, family: [*:0]const u8, slant: c_int, weight: c_int) void;
pub extern fn cairo_set_font_size(cr: *cairo_t, size: f64) void;
pub extern fn cairo_text_extents(cr: *cairo_t, utf8: [*:0]const u8, extents: *cairo_text_extents_t) void;
pub extern fn cairo_show_text(cr: *cairo_t, utf8: [*:0]const u8) void;
