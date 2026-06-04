//! Entry point: set up the allocator and app state, silence GTK's noisy
//! warnings, and run the libadwaita application. Everything else lives in the
//! dedicated modules:
//!   - game.zig    pure roulette logic (test root, GUI-free)
//!   - gtk.zig     hand-written GTK/Adwaita/Cairo/GLib bindings
//!   - wheel.zig   wheel geometry and spin easing
//!   - app.zig     shared AppState and its types
//!   - render.zig  Cairo draw functions
//!   - ui.zig      widget construction, callbacks, and refresh

const std = @import("std");
const gtk = @import("gtk.zig");
const app = @import("app.zig");
const ui = @import("ui.zig");

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit();
    const allocator = debug_allocator.allocator();

    const app_state = try app.AppState.init(allocator);
    defer app_state.deinit();

    _ = gtk.g_log_set_handler("Gtk", gtk.G_LOG_LEVEL_WARNING, @ptrCast(&quietGtkWarning), null);
    gtk.g_log_set_writer_func(@ptrCast(&quietGtkWarningWriter), null, null);
    gtk.gtk_window_set_default_icon_name("dev.instazdll.ZigRoulette");

    const application = gtk.adw_application_new("dev.instazdll.ZigRoulette", gtk.G_APPLICATION_DEFAULT_FLAGS);
    defer gtk.g_object_unref(application);

    _ = gtk.g_signal_connect_data(application, "activate", @ptrCast(&activate), app_state, null, 0);
    const status = gtk.g_application_run(@ptrCast(application), 0, null);
    if (status != 0) return error.ApplicationFailed;
}

fn quietGtkWarning(_: [*:0]const u8, _: c_uint, _: [*:0]const u8, _: ?*anyopaque) callconv(.c) void {}

fn quietGtkWarningWriter(log_level: c_uint, _: ?*const anyopaque, _: usize, _: ?*anyopaque) callconv(.c) c_int {
    if ((log_level & gtk.G_LOG_LEVEL_MASK) == gtk.G_LOG_LEVEL_WARNING) {
        return gtk.G_LOG_WRITER_HANDLED;
    }
    return gtk.G_LOG_WRITER_UNHANDLED;
}

fn activate(application: *gtk.GtkApplication, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    ui.installCss();

    const window = gtk.adw_application_window_new(@ptrCast(application));
    state.window = window;
    gtk.gtk_widget_add_css_class(window, "roulette-window");
    gtk.gtk_window_set_title(@ptrCast(window), "Zig Roulette");
    gtk.gtk_window_set_default_size(@ptrCast(window), 1180, 760);

    const toolbar = gtk.adw_toolbar_view_new();
    gtk.gtk_widget_add_css_class(toolbar, "roulette-root");
    const header = gtk.adw_header_bar_new();
    gtk.adw_toolbar_view_add_top_bar(@ptrCast(toolbar), header);

    const title = gtk.adw_window_title_new("Zig Roulette", "Roulette europeenne GTK4/libadwaita");
    gtk.adw_header_bar_set_title_widget(@ptrCast(header), title);

    const menu = ui.buildMenu(state, toolbar);
    state.menu_content = menu;
    gtk.adw_application_window_set_content(@ptrCast(window), menu);

    ui.refreshUi(state);
    gtk.gtk_window_present(@ptrCast(window));
}
