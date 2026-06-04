const std = @import("std");
const game = @import("game.zig");

const gtk = struct {
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
    pub const GTK_ORIENTATION_HORIZONTAL: c_int = 0;
    pub const GTK_ORIENTATION_VERTICAL: c_int = 1;
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
    pub const GtkCssProvider = opaque {};
    pub const GtkStyleProvider = opaque {};
    pub const GdkDisplay = opaque {};
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

    pub extern fn gtk_window_set_title(window: *GtkWindow, title: [*:0]const u8) void;
    pub extern fn gtk_window_set_default_size(window: *GtkWindow, width: c_int, height: c_int) void;
    pub extern fn gtk_window_set_default_icon_name(name: [*:0]const u8) void;
    pub extern fn gtk_window_present(window: *GtkWindow) void;
    pub extern fn gtk_box_new(orientation: c_int, spacing: c_int) *GtkWidget;
    pub extern fn gtk_box_append(box: *GtkBox, child: *GtkWidget) void;
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
    pub extern fn gtk_list_box_new() *GtkWidget;
    pub extern fn gtk_list_box_append(box: *GtkListBox, child: *GtkWidget) void;
    pub extern fn gtk_list_box_remove(box: *GtkListBox, child: *GtkWidget) void;
    pub extern fn gtk_css_provider_new() *GtkCssProvider;
    pub extern fn gtk_css_provider_load_from_string(css_provider: *GtkCssProvider, string: [*:0]const u8) void;
    pub extern fn gtk_style_context_add_provider_for_display(display: *GdkDisplay, provider: *GtkStyleProvider, priority: guint) void;
    pub extern fn gdk_display_get_default() ?*GdkDisplay;

    pub extern fn cairo_set_source_rgb(cr: *cairo_t, red: f64, green: f64, blue: f64) void;
    pub extern fn cairo_paint(cr: *cairo_t) void;
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
};

const WheelOrder = [_]u8{ 0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26 };
const HistoryLimit = 12;
const BetLimit = 48;

const AppCss =
    \\headerbar,
    \\windowhandle,
    \\windowcontrols {
    \\  background: #121514;
    \\  color: #f4efdf;
    \\  border-color: #242927;
    \\}
    \\headerbar label,
    \\windowhandle label {
    \\  color: #f4efdf;
    \\}
    \\.roulette-window {
    \\  background: #121514;
    \\  color: #f4efdf;
    \\}
    \\.roulette-root {
    \\  background: #121514;
    \\  color: #f4efdf;
    \\}
    \\.roulette-sidebar {
    \\  background: #202322;
    \\  color: #f4efdf;
    \\  border-radius: 8px;
    \\  padding: 12px;
    \\}
    \\.roulette-list {
    \\  background: #151817;
    \\  color: #f4efdf;
    \\  border-radius: 6px;
    \\}
    \\.roulette-sidebar label {
    \\  color: #f4efdf;
    \\}
    \\.roulette-sidebar spinbutton,
    \\.roulette-sidebar spinbutton {
    \\  color: #211f1c;
    \\}
    \\.roulette-sidebar button {
    \\  background: #303532;
    \\  color: #f4efdf;
    \\  border-color: #565e58;
    \\}
    \\.roulette-sidebar button label {
    \\  color: #f4efdf;
    \\}
    \\.roulette-sidebar button.suggested-action {
    \\  background: #2f7df6;
    \\  color: #ffffff;
    \\  border-color: #2f7df6;
    \\}
    \\.roulette-sidebar button.suggested-action label {
    \\  color: #ffffff;
    \\}
    \\.history-row,
    \\.bet-row {
    \\  padding: 6px;
    \\  border-radius: 6px;
    \\}
    \\.history-row {
    \\  background: #181c1a;
    \\}
    \\.bet-row {
    \\  background: #151817;
    \\}
    \\.muted-label {
    \\  color: #bbb5a5;
    \\}
    \\.profit-positive {
    \\  color: #75d878;
    \\}
    \\.profit-negative {
    \\  color: #ff7b72;
    \\}
    \\.profit-neutral {
    \\  color: #d6c99b;
    \\}
;

const HitZone = struct {
    x: f64,
    y: f64,
    w: f64,
    h: f64,
    kind: game.BetKind,
};

const HistoryEntry = struct {
    summary: [:0]u8,
    details: [:0]u8,
    profit: i64,
};

const AppState = struct {
    allocator: std.mem.Allocator,
    game_state: game.GameState,
    rng: std.Random.DefaultPrng,
    amount: i64 = 25,
    selected: ?game.BetKind = null,
    last_number: ?u8 = null,
    spin_target: u8 = 0,
    spin_ticks: u32 = 0,
    spin_total: u32 = 0,
    spin_start_wheel_angle: f64 = 0,
    spin_start_ball_angle: f64 = 0,
    spin_end_wheel_angle: f64 = 0,
    spin_end_ball_angle: f64 = 0,
    wheel_angle: f64 = 0,
    ball_angle: f64 = 0,
    spinning: bool = false,
    hit_zones: std.array_list.Managed(HitZone),
    history: std.array_list.Managed(HistoryEntry),

    window: ?*gtk.GtkWidget = null,
    wheel_area: ?*gtk.GtkWidget = null,
    table_area: ?*gtk.GtkWidget = null,
    balance_label: ?*gtk.GtkWidget = null,
    result_label: ?*gtk.GtkWidget = null,
    selected_label: ?*gtk.GtkWidget = null,
    bet_list: ?*gtk.GtkWidget = null,
    history_list: ?*gtk.GtkWidget = null,
    status_label: ?*gtk.GtkWidget = null,
    amount_spin: ?*gtk.GtkWidget = null,
    spin_button: ?*gtk.GtkWidget = null,

    pub fn init(allocator: std.mem.Allocator) !*AppState {
        const seed: u64 = @bitCast(gtk.g_get_real_time());

        const state = try allocator.create(AppState);
        state.* = .{
            .allocator = allocator,
            .game_state = game.GameState.init(allocator),
            .rng = std.Random.DefaultPrng.init(seed),
            .hit_zones = std.array_list.Managed(HitZone).init(allocator),
            .history = std.array_list.Managed(HistoryEntry).init(allocator),
        };
        return state;
    }

    pub fn deinit(self: *AppState) void {
        self.game_state.deinit();
        self.clearHistory();
        self.history.deinit();
        self.hit_zones.deinit();
        self.allocator.destroy(self);
    }

    pub fn clearHistory(self: *AppState) void {
        for (self.history.items) |entry| {
            self.allocator.free(entry.summary);
            self.allocator.free(entry.details);
        }
        self.history.clearRetainingCapacity();
    }
};

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit();
    const allocator = debug_allocator.allocator();

    const app_state = try AppState.init(allocator);
    defer app_state.deinit();

    _ = gtk.g_log_set_handler("Gtk", gtk.G_LOG_LEVEL_WARNING, @ptrCast(&quietGtkWarning), null);
    gtk.g_log_set_writer_func(@ptrCast(&quietGtkWarningWriter), null, null);
    gtk.gtk_window_set_default_icon_name("dev.instazdll.ZigRoulette");

    const app = gtk.adw_application_new("dev.instazdll.ZigRoulette", gtk.G_APPLICATION_DEFAULT_FLAGS);
    defer gtk.g_object_unref(app);

    _ = gtk.g_signal_connect_data(app, "activate", @ptrCast(&activate), app_state, null, 0);
    const status = gtk.g_application_run(@ptrCast(app), 0, null);
    if (status != 0) return error.ApplicationFailed;
}

fn quietGtkWarning(_: [*:0]const u8, _: c_uint, _: [*:0]const u8, _: ?*anyopaque) callconv(.c) void {}

fn quietGtkWarningWriter(log_level: c_uint, _: ?*const anyopaque, _: usize, _: ?*anyopaque) callconv(.c) c_int {
    if ((log_level & gtk.G_LOG_LEVEL_MASK) == gtk.G_LOG_LEVEL_WARNING) {
        return gtk.G_LOG_WRITER_HANDLED;
    }
    return gtk.G_LOG_WRITER_UNHANDLED;
}

fn activate(app: *gtk.GtkApplication, data: ?*anyopaque) callconv(.c) void {
    const state: *AppState = @ptrCast(@alignCast(data.?));
    installCss();

    const window = gtk.adw_application_window_new(@ptrCast(app));
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

    const root = gtk.gtk_box_new(gtk.GTK_ORIENTATION_HORIZONTAL, 16);
    gtk.gtk_widget_add_css_class(root, "roulette-root");
    gtk.gtk_widget_set_margin_top(root, 16);
    gtk.gtk_widget_set_margin_bottom(root, 16);
    gtk.gtk_widget_set_margin_start(root, 16);
    gtk.gtk_widget_set_margin_end(root, 16);

    const play_box = gtk.gtk_box_new(gtk.GTK_ORIENTATION_VERTICAL, 12);
    gtk.gtk_widget_set_hexpand(play_box, 1);
    gtk.gtk_widget_set_vexpand(play_box, 1);
    gtk.gtk_box_append(@ptrCast(root), play_box);

    const wheel = gtk.gtk_drawing_area_new();
    state.wheel_area = wheel;
    gtk.gtk_widget_set_size_request(wheel, 520, 360);
    gtk.gtk_widget_set_hexpand(wheel, 1);
    gtk.gtk_drawing_area_set_draw_func(@ptrCast(wheel), @ptrCast(&drawWheel), state, null);
    gtk.gtk_box_append(@ptrCast(play_box), wheel);

    const table = gtk.gtk_drawing_area_new();
    state.table_area = table;
    gtk.gtk_widget_set_size_request(table, 720, 320);
    gtk.gtk_widget_set_hexpand(table, 1);
    gtk.gtk_widget_set_vexpand(table, 1);
    gtk.gtk_drawing_area_set_draw_func(@ptrCast(table), @ptrCast(&drawTable), state, null);

    const click = gtk.gtk_gesture_click_new();
    gtk.gtk_gesture_single_set_button(@ptrCast(click), 1);
    gtk.gtk_widget_add_controller(table, @ptrCast(click));
    _ = gtk.g_signal_connect_data(click, "pressed", @ptrCast(&tablePressed), state, null, 0);
    gtk.gtk_box_append(@ptrCast(play_box), table);

    const side = gtk.gtk_box_new(gtk.GTK_ORIENTATION_VERTICAL, 10);
    gtk.gtk_widget_add_css_class(side, "roulette-sidebar");
    gtk.gtk_widget_set_size_request(side, 300, -1);
    gtk.gtk_box_append(@ptrCast(root), side);

    state.balance_label = gtk.gtk_label_new("");
    gtk.gtk_label_set_xalign(@ptrCast(state.balance_label.?), 0);
    addTitle(side, "Solde");
    gtk.gtk_box_append(@ptrCast(side), state.balance_label.?);

    state.result_label = gtk.gtk_label_new("Aucun tirage");
    gtk.gtk_label_set_wrap(@ptrCast(state.result_label.?), 1);
    gtk.gtk_label_set_xalign(@ptrCast(state.result_label.?), 0);
    addTitle(side, "Dernier resultat");
    gtk.gtk_box_append(@ptrCast(side), state.result_label.?);

    state.selected_label = gtk.gtk_label_new("");
    gtk.gtk_label_set_wrap(@ptrCast(state.selected_label.?), 1);
    gtk.gtk_label_set_xalign(@ptrCast(state.selected_label.?), 0);
    addTitle(side, "Selection");
    gtk.gtk_box_append(@ptrCast(side), state.selected_label.?);

    const amount_row = gtk.gtk_box_new(gtk.GTK_ORIENTATION_HORIZONTAL, 8);
    const amount_label = gtk.gtk_label_new("Montant");
    state.amount_spin = gtk.gtk_spin_button_new_with_range(1, 1000, 5);
    gtk.gtk_spin_button_set_value(@ptrCast(state.amount_spin.?), 25);
    _ = gtk.g_signal_connect_data(state.amount_spin.?, "value-changed", @ptrCast(&amountChanged), state, null, 0);
    gtk.gtk_box_append(@ptrCast(amount_row), amount_label);
    gtk.gtk_box_append(@ptrCast(amount_row), state.amount_spin.?);
    const max_button = gtk.gtk_button_new_with_label("Max");
    _ = gtk.g_signal_connect_data(max_button, "clicked", @ptrCast(&maxClicked), state, null, 0);
    gtk.gtk_box_append(@ptrCast(amount_row), max_button);
    gtk.gtk_box_append(@ptrCast(side), amount_row);

    const add_button = gtk.gtk_button_new_with_label("Ajouter la mise");
    _ = gtk.g_signal_connect_data(add_button, "clicked", @ptrCast(&addBetClicked), state, null, 0);
    gtk.gtk_box_append(@ptrCast(side), add_button);

    state.spin_button = gtk.gtk_button_new_with_label("Lancer");
    gtk.gtk_widget_add_css_class(state.spin_button.?, "suggested-action");
    _ = gtk.g_signal_connect_data(state.spin_button.?, "clicked", @ptrCast(&spinClicked), state, null, 0);
    gtk.gtk_box_append(@ptrCast(side), state.spin_button.?);

    const clear_button = gtk.gtk_button_new_with_label("Effacer les mises");
    _ = gtk.g_signal_connect_data(clear_button, "clicked", @ptrCast(&clearClicked), state, null, 0);
    gtk.gtk_box_append(@ptrCast(side), clear_button);

    const undo_button = gtk.gtk_button_new_with_label("Annuler derniere mise");
    _ = gtk.g_signal_connect_data(undo_button, "clicked", @ptrCast(&undoClicked), state, null, 0);
    gtk.gtk_box_append(@ptrCast(side), undo_button);

    const new_session_button = gtk.gtk_button_new_with_label("Nouvelle session");
    _ = gtk.g_signal_connect_data(new_session_button, "clicked", @ptrCast(&newSessionClicked), state, null, 0);
    gtk.gtk_box_append(@ptrCast(side), new_session_button);

    state.status_label = gtk.gtk_label_new("Choisis un montant puis clique une zone du tapis pour ajouter la mise.");
    gtk.gtk_label_set_wrap(@ptrCast(state.status_label.?), 1);
    gtk.gtk_label_set_xalign(@ptrCast(state.status_label.?), 0);
    gtk.gtk_box_append(@ptrCast(side), state.status_label.?);

    addTitle(side, "Mises du tour");
    state.bet_list = gtk.gtk_list_box_new();
    gtk.gtk_widget_add_css_class(state.bet_list.?, "roulette-list");
    gtk.gtk_widget_set_vexpand(state.bet_list.?, 1);
    gtk.gtk_box_append(@ptrCast(side), state.bet_list.?);

    addTitle(side, "Historique");
    state.history_list = gtk.gtk_list_box_new();
    gtk.gtk_widget_add_css_class(state.history_list.?, "roulette-list");
    gtk.gtk_widget_set_vexpand(state.history_list.?, 1);
    gtk.gtk_box_append(@ptrCast(side), state.history_list.?);

    gtk.adw_toolbar_view_set_content(@ptrCast(toolbar), root);
    gtk.adw_application_window_set_content(@ptrCast(window), toolbar);

    refreshUi(state);
    gtk.gtk_window_present(@ptrCast(window));
}

fn installCss() void {
    const display = gtk.gdk_display_get_default() orelse return;
    const provider = gtk.gtk_css_provider_new();
    gtk.gtk_css_provider_load_from_string(provider, AppCss);
    gtk.gtk_style_context_add_provider_for_display(display, @ptrCast(provider), 600);
    gtk.g_object_unref(provider);
}

fn addTitle(parent: *gtk.GtkWidget, text: [*:0]const u8) void {
    const label = gtk.gtk_label_new(text);
    gtk.gtk_widget_add_css_class(label, "heading");
    gtk.gtk_label_set_xalign(@ptrCast(label), 0);
    gtk.gtk_box_append(@ptrCast(parent), label);
}

fn amountChanged(widget: *gtk.GtkSpinButton, data: ?*anyopaque) callconv(.c) void {
    const state: *AppState = @ptrCast(@alignCast(data.?));
    state.amount = @intFromFloat(gtk.gtk_spin_button_get_value(widget));
    refreshUi(state);
}

fn maxClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;

    const max_amount = @max(state.game_state.available(), 1);
    state.amount = max_amount;
    if (state.amount_spin) |spin| {
        gtk.gtk_spin_button_set_value(@ptrCast(spin), @floatFromInt(max_amount));
    }
    setStatus(state, "Montant regle sur le solde disponible.");
    refreshUi(state);
}

fn addBetClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;

    const kind = state.selected orelse {
        setStatus(state, "Selectionne d'abord une zone du tapis.");
        return;
    };

    addBetForKind(state, kind);
}

fn clearClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;
    state.game_state.clearBets();
    setStatus(state, "Mises effacees.");
    refreshUi(state);
}

fn undoClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;

    if (state.game_state.undoLastBet()) {
        setStatus(state, "Derniere mise annulee.");
    } else {
        setStatus(state, "Aucune mise a annuler.");
    }
    refreshUi(state);
}

fn newSessionClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;

    state.game_state.reset();
    state.clearHistory();
    state.amount = 25;
    state.selected = null;
    state.last_number = null;
    state.wheel_angle = 0;
    state.ball_angle = 0;
    if (state.amount_spin) |spin| {
        gtk.gtk_spin_button_set_value(@ptrCast(spin), 25);
    }
    setStatus(state, "Nouvelle session demarree.");
    refreshUi(state);
}

fn spinClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;
    if (state.game_state.bets.items.len == 0) {
        setStatus(state, "Ajoute au moins une mise avant de lancer.");
        return;
    }

    state.spin_target = state.rng.random().uintLessThan(u8, 37);
    state.spin_ticks = 0;
    state.spin_total = 120;
    state.spin_start_wheel_angle = state.wheel_angle;
    state.spin_start_ball_angle = state.ball_angle;
    state.spin_end_wheel_angle = state.spin_start_wheel_angle + std.math.tau * 4.0 + state.rng.random().float(f64) * std.math.tau;
    state.spin_end_ball_angle = state.spin_end_wheel_angle + angleForNumber(state.spin_target) + wheelSliceAngle() / 2.0;
    state.spinning = true;
    gtk.gtk_widget_set_sensitive(state.spin_button.?, 0);
    setStatus(state, "La roue tourne...");
    _ = gtk.g_timeout_add(16, @ptrCast(&spinTick), state);
}

fn spinTick(data: ?*anyopaque) callconv(.c) gtk.gboolean {
    const state: *AppState = @ptrCast(@alignCast(data.?));
    state.spin_ticks += 1;

    const raw_t = @as(f64, @floatFromInt(state.spin_ticks)) / @as(f64, @floatFromInt(state.spin_total));
    const t = @min(raw_t, 1.0);
    const eased = easeOutCubic(t);
    state.wheel_angle = lerp(state.spin_start_wheel_angle, state.spin_end_wheel_angle, eased);
    state.ball_angle = lerp(state.spin_start_ball_angle, state.spin_end_ball_angle - std.math.tau * 8.0, eased);

    if (state.wheel_area) |area| gtk.gtk_widget_queue_draw(area);

    if (state.spin_ticks < state.spin_total) return gtk.TRUE;

    state.spinning = false;
    state.last_number = state.spin_target;
    state.wheel_angle = normalizeAngle(state.spin_end_wheel_angle);
    state.ball_angle = normalizeAngle(state.spin_end_ball_angle);

    const outcome = game.outcomeForNumber(state.spin_target);
    const settled = state.game_state.settle(outcome);
    appendHistory(state, outcome, settled) catch {};
    setSpinResultStatus(state, outcome, settled);
    gtk.gtk_widget_set_sensitive(state.spin_button.?, 1);
    refreshUi(state);
    if (state.wheel_area) |area| gtk.gtk_widget_queue_draw(area);

    return gtk.FALSE;
}

fn appendHistory(state: *AppState, outcome: game.SpinOutcome, settled: game.SettleResult) !void {
    var summary_buf: [64]u8 = undefined;
    var details_buf: [128]u8 = undefined;
    const color = if (outcome.color) |col| col.label() else "Vert";
    const sign: []const u8 = if (settled.profit >= 0) "+" else "";
    const summary = try std.fmt.bufPrint(&summary_buf, "{d} {s}", .{
        outcome.number,
        color,
    });
    const details = try std.fmt.bufPrint(&details_buf, "Mise {d} · Retour {d} · {s}{d}", .{
        settled.wagered,
        settled.returned,
        sign,
        settled.profit,
    });
    const summary_owned = try state.allocator.dupeZ(u8, summary);
    errdefer state.allocator.free(summary_owned);
    const details_owned = try state.allocator.dupeZ(u8, details);
    errdefer state.allocator.free(details_owned);

    const entry: HistoryEntry = .{
        .summary = summary_owned,
        .details = details_owned,
        .profit = settled.profit,
    };

    try state.history.insert(0, entry);
    while (state.history.items.len > HistoryLimit) {
        const old = state.history.pop().?;
        state.allocator.free(old.summary);
        state.allocator.free(old.details);
    }
}

fn refreshUi(state: *AppState) void {
    if (state.balance_label) |label| {
        var buf: [128]u8 = undefined;
        const text = std.fmt.bufPrintZ(&buf, "{d} credits | disponible {d}", .{
            state.game_state.balance,
            state.game_state.available(),
        }) catch "Erreur";
        gtk.gtk_label_set_text(@ptrCast(label), text.ptr);
    }

    if (state.selected_label) |label| {
        var buf: [128]u8 = undefined;
        const text = if (state.selected) |kind| kindLabelZ(&buf, kind) else "Aucune zone selectionnee";
        gtk.gtk_label_set_text(@ptrCast(label), text.ptr);
    }

    if (state.result_label) |label| {
        var buf: [160]u8 = undefined;
        const text = resultLabelZ(&buf, state) catch "Aucun tirage";
        gtk.gtk_label_set_text(@ptrCast(label), text.ptr);
    }

    rebuildBetList(state);
    rebuildHistoryList(state);
    if (state.table_area) |area| gtk.gtk_widget_queue_draw(area);
    if (state.wheel_area) |area| gtk.gtk_widget_queue_draw(area);
}

fn rebuildBetList(state: *AppState) void {
    const list = state.bet_list orelse return;
    clearListBox(list);

    for (state.game_state.bets.items) |bet| {
        appendBetRow(list, bet);
    }
}

fn rebuildHistoryList(state: *AppState) void {
    const list = state.history_list orelse return;
    clearListBox(list);
    for (state.history.items) |entry| appendHistoryRow(list, entry);
}

fn clearListBox(list: *gtk.GtkWidget) void {
    while (true) {
        const child = gtk.gtk_widget_get_first_child(list) orelse break;
        gtk.gtk_list_box_remove(@ptrCast(list), child);
    }
}

fn appendBetRow(list: *gtk.GtkWidget, bet: game.Bet) void {
    const row = gtk.gtk_box_new(gtk.GTK_ORIENTATION_HORIZONTAL, 8);
    gtk.gtk_widget_add_css_class(row, "bet-row");
    gtk.gtk_widget_set_margin_top(row, 3);
    gtk.gtk_widget_set_margin_bottom(row, 3);
    gtk.gtk_widget_set_margin_start(row, 3);
    gtk.gtk_widget_set_margin_end(row, 3);

    var kind_buf: [96]u8 = undefined;
    const kind_text = kindLabelZ(&kind_buf, bet.kind);
    const kind_label = gtk.gtk_label_new(kind_text.ptr);
    gtk.gtk_label_set_xalign(@ptrCast(kind_label), 0);
    gtk.gtk_widget_set_hexpand(kind_label, 1);
    gtk.gtk_widget_set_halign(kind_label, gtk.GTK_ALIGN_START);
    gtk.gtk_box_append(@ptrCast(row), kind_label);

    var amount_buf: [32]u8 = undefined;
    const amount_text = std.fmt.bufPrintZ(&amount_buf, "{d}", .{bet.amount}) catch "0";
    const amount_label = gtk.gtk_label_new(amount_text.ptr);
    gtk.gtk_widget_add_css_class(amount_label, "muted-label");
    gtk.gtk_label_set_xalign(@ptrCast(amount_label), 1);
    gtk.gtk_widget_set_halign(amount_label, gtk.GTK_ALIGN_END);
    gtk.gtk_box_append(@ptrCast(row), amount_label);

    gtk.gtk_list_box_append(@ptrCast(list), row);
}

fn appendHistoryRow(list: *gtk.GtkWidget, entry: HistoryEntry) void {
    const row = gtk.gtk_box_new(gtk.GTK_ORIENTATION_VERTICAL, 3);
    gtk.gtk_widget_add_css_class(row, "history-row");
    gtk.gtk_widget_set_margin_top(row, 3);
    gtk.gtk_widget_set_margin_bottom(row, 3);
    gtk.gtk_widget_set_margin_start(row, 3);
    gtk.gtk_widget_set_margin_end(row, 3);

    const summary = gtk.gtk_label_new(entry.summary.ptr);
    gtk.gtk_label_set_xalign(@ptrCast(summary), 0);
    gtk.gtk_widget_add_css_class(summary, profitCssClass(entry.profit));
    gtk.gtk_box_append(@ptrCast(row), summary);

    const details = gtk.gtk_label_new(entry.details.ptr);
    gtk.gtk_label_set_xalign(@ptrCast(details), 0);
    gtk.gtk_label_set_wrap(@ptrCast(details), 1);
    gtk.gtk_widget_add_css_class(details, "muted-label");
    gtk.gtk_box_append(@ptrCast(row), details);

    gtk.gtk_list_box_append(@ptrCast(list), row);
}

fn profitCssClass(profit: i64) [*:0]const u8 {
    if (profit > 0) return "profit-positive";
    if (profit < 0) return "profit-negative";
    return "profit-neutral";
}

fn setStatus(state: *AppState, text: [*:0]const u8) void {
    if (state.status_label) |label| gtk.gtk_label_set_text(@ptrCast(label), text);
}

fn setSpinResultStatus(state: *AppState, outcome: game.SpinOutcome, settled: game.SettleResult) void {
    var buf: [160]u8 = undefined;
    const color = if (outcome.color) |col| col.label() else "Vert";
    const sign: []const u8 = if (settled.profit >= 0) "+" else "";
    const text = std.fmt.bufPrintZ(&buf, "Resultat {d} {s} | {s}{d}", .{ outcome.number, color, sign, settled.profit }) catch "Resultat calcule.";
    setStatus(state, text.ptr);
}

fn addBetForKind(state: *AppState, kind: game.BetKind) void {
    state.game_state.addBet(.{ .kind = kind, .amount = state.amount }) catch |err| {
        switch (err) {
            error.InsufficientBalance => setStatus(state, "Solde disponible insuffisant."),
            error.InvalidAmount => setStatus(state, "Montant invalide."),
            else => setStatus(state, "Mise invalide."),
        }
        return;
    };
    setStatus(state, "Mise ajoutee.");
    refreshUi(state);
}

fn tablePressed(_: *gtk.GtkGestureClick, _: gtk.gint, x: gtk.gdouble, y: gtk.gdouble, data: ?*anyopaque) callconv(.c) void {
    const state: *AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;

    for (state.hit_zones.items) |zone| {
        if (x >= zone.x and x <= zone.x + zone.w and y >= zone.y and y <= zone.y + zone.h) {
            state.selected = zone.kind;
            addBetForKind(state, zone.kind);
            return;
        }
    }
}

fn drawWheel(_: *gtk.GtkDrawingArea, cr: *gtk.cairo_t, width: gtk.gint, height: gtk.gint, data: ?*anyopaque) callconv(.c) void {
    const state: *AppState = @ptrCast(@alignCast(data.?));
    const w: f64 = @floatFromInt(width);
    const h: f64 = @floatFromInt(height);
    const cx = w * 0.5;
    const cy = h * 0.58;
    const radius = @min(w, h) * 0.36;

    gtk.cairo_set_source_rgb(cr, 0.06, 0.07, 0.07);
    gtk.cairo_paint(cr);

    const slice = std.math.tau / @as(f64, @floatFromInt(WheelOrder.len));
    for (WheelOrder, 0..) |number, i| {
        const start = state.wheel_angle + @as(f64, @floatFromInt(i)) * slice;
        const end = start + slice;
        setNumberColor(cr, number);
        gtk.cairo_move_to(cr, cx, cy);
        gtk.cairo_arc(cr, cx, cy, radius, start, end);
        gtk.cairo_close_path(cr);
        gtk.cairo_fill_preserve(cr);
        gtk.cairo_set_source_rgb(cr, 0.94, 0.88, 0.72);
        gtk.cairo_set_line_width(cr, 1);
        gtk.cairo_stroke(cr);
    }

    gtk.cairo_set_source_rgb(cr, 0.12, 0.08, 0.04);
    gtk.cairo_arc(cr, cx, cy, radius * 0.56, 0, std.math.tau);
    gtk.cairo_fill(cr);
    gtk.cairo_set_source_rgb(cr, 0.82, 0.62, 0.26);
    gtk.cairo_arc(cr, cx, cy, radius * 0.22, 0, std.math.tau);
    gtk.cairo_fill(cr);

    const ball_r = radius * 0.77;
    const bx = cx + @cos(state.ball_angle) * ball_r;
    const by = cy + @sin(state.ball_angle) * ball_r;
    gtk.cairo_set_source_rgb(cr, 0.97, 0.97, 0.93);
    gtk.cairo_arc(cr, bx, by, 8, 0, std.math.tau);
    gtk.cairo_fill(cr);

    if (state.last_number) |number| {
        var buf: [64]u8 = undefined;
        const text = std.fmt.bufPrintZ(&buf, "Resultat: {d}", .{number}) catch "Resultat";
        drawCenteredText(cr, text.ptr, cx, 32, 24);
    } else {
        drawCenteredText(cr, "Place tes mises", cx, 32, 22);
    }
}

fn drawTable(_: *gtk.GtkDrawingArea, cr: *gtk.cairo_t, width: gtk.gint, height: gtk.gint, data: ?*anyopaque) callconv(.c) void {
    const state: *AppState = @ptrCast(@alignCast(data.?));
    state.hit_zones.clearRetainingCapacity();

    const w: f64 = @floatFromInt(width);
    const h: f64 = @floatFromInt(height);
    gtk.cairo_set_source_rgb(cr, 0.02, 0.31, 0.16);
    gtk.cairo_paint(cr);

    const margin = 16.0;
    const grid_x = margin + 64.0;
    const grid_y = margin;
    const grid_w = w - margin * 2.0 - 64.0;
    const cell_w = grid_w / 12.0;
    const cell_h = (h - margin * 2.0 - 110.0) / 3.0;
    const zero_w = 54.0;

    drawZone(state, cr, .{ .x = margin, .y = grid_y, .w = zero_w, .h = cell_h * 3.0, .kind = .{ .straight = 0 } }, "0", .green);

    var number: u8 = 1;
    var col: usize = 0;
    while (col < 12) : (col += 1) {
        var row: usize = 0;
        while (row < 3) : (row += 1) {
            const table_number: u8 = @intCast(col * 3 + (3 - row));
            const label_buf = numberLabel(table_number);
            const zone: HitZone = .{
                .x = grid_x + @as(f64, @floatFromInt(col)) * cell_w,
                .y = grid_y + @as(f64, @floatFromInt(row)) * cell_h,
                .w = cell_w,
                .h = cell_h,
                .kind = .{ .straight = table_number },
            };
            drawZone(state, cr, zone, &label_buf, colorTagForNumber(table_number));
            number += 1;
        }
    }

    const dozen_y = grid_y + cell_h * 3.0 + 8.0;
    drawZone(state, cr, .{ .x = grid_x, .y = dozen_y, .w = cell_w * 4.0, .h = 38.0, .kind = .{ .dozen = .first } }, "1-12", .neutral);
    drawZone(state, cr, .{ .x = grid_x + cell_w * 4.0, .y = dozen_y, .w = cell_w * 4.0, .h = 38.0, .kind = .{ .dozen = .second } }, "13-24", .neutral);
    drawZone(state, cr, .{ .x = grid_x + cell_w * 8.0, .y = dozen_y, .w = cell_w * 4.0, .h = 38.0, .kind = .{ .dozen = .third } }, "25-36", .neutral);

    const outside_y = dozen_y + 46.0;
    const outside_w = grid_w / 9.0;
    drawZone(state, cr, .{ .x = grid_x + outside_w * 0.0, .y = outside_y, .w = outside_w, .h = 38.0, .kind = .{ .range = .low } }, "1-18", .neutral);
    drawZone(state, cr, .{ .x = grid_x + outside_w * 1.0, .y = outside_y, .w = outside_w, .h = 38.0, .kind = .{ .parity = .even } }, "PAIR", .neutral);
    drawZone(state, cr, .{ .x = grid_x + outside_w * 2.0, .y = outside_y, .w = outside_w, .h = 38.0, .kind = .{ .color = .red } }, "ROUGE", .red);
    drawZone(state, cr, .{ .x = grid_x + outside_w * 3.0, .y = outside_y, .w = outside_w, .h = 38.0, .kind = .{ .color = .black } }, "NOIR", .black);
    drawZone(state, cr, .{ .x = grid_x + outside_w * 4.0, .y = outside_y, .w = outside_w, .h = 38.0, .kind = .{ .parity = .odd } }, "IMPAIR", .neutral);
    drawZone(state, cr, .{ .x = grid_x + outside_w * 5.0, .y = outside_y, .w = outside_w, .h = 38.0, .kind = .{ .range = .high } }, "19-36", .neutral);
    drawZone(state, cr, .{ .x = grid_x + outside_w * 6.0, .y = outside_y, .w = outside_w, .h = 38.0, .kind = .{ .column = .first } }, "COL 1", .neutral);
    drawZone(state, cr, .{ .x = grid_x + outside_w * 7.0, .y = outside_y, .w = outside_w, .h = 38.0, .kind = .{ .column = .second } }, "COL 2", .neutral);
    drawZone(state, cr, .{ .x = grid_x + outside_w * 8.0, .y = outside_y, .w = outside_w, .h = 38.0, .kind = .{ .column = .third } }, "COL 3", .neutral);
}

const ZoneColor = enum { red, black, green, neutral };

fn drawZone(state: *AppState, cr: *gtk.cairo_t, zone: HitZone, text: [*:0]const u8, color: ZoneColor) void {
    state.hit_zones.append(zone) catch {};
    const selected = if (state.selected) |kind| std.meta.eql(kind, zone.kind) else false;

    switch (color) {
        .red => gtk.cairo_set_source_rgb(cr, 0.58, 0.04, 0.04),
        .black => gtk.cairo_set_source_rgb(cr, 0.03, 0.035, 0.04),
        .green => gtk.cairo_set_source_rgb(cr, 0.02, 0.42, 0.20),
        .neutral => gtk.cairo_set_source_rgb(cr, 0.05, 0.36, 0.18),
    }
    gtk.cairo_rectangle(cr, zone.x, zone.y, zone.w, zone.h);
    gtk.cairo_fill_preserve(cr);
    if (selected) {
        gtk.cairo_set_source_rgb(cr, 1.0, 0.84, 0.22);
        gtk.cairo_set_line_width(cr, 4);
    } else {
        gtk.cairo_set_source_rgb(cr, 0.9, 0.84, 0.68);
        gtk.cairo_set_line_width(cr, 1.5);
    }
    gtk.cairo_stroke(cr);
    drawCenteredText(cr, text, zone.x + zone.w / 2.0, zone.y + zone.h / 2.0 + 5.0, 15);
}

fn setNumberColor(cr: *gtk.cairo_t, number: u8) void {
    switch (colorTagForNumber(number)) {
        .red => gtk.cairo_set_source_rgb(cr, 0.62, 0.03, 0.03),
        .black => gtk.cairo_set_source_rgb(cr, 0.025, 0.027, 0.03),
        .green => gtk.cairo_set_source_rgb(cr, 0.0, 0.34, 0.16),
        .neutral => gtk.cairo_set_source_rgb(cr, 0.1, 0.1, 0.1),
    }
}

fn colorTagForNumber(number: u8) ZoneColor {
    if (number == 0) return .green;
    return switch (game.colorForNumber(number).?) {
        .red => .red,
        .black => .black,
    };
}

fn numberLabel(number: u8) [4:0]u8 {
    var buf: [4:0]u8 = [_:0]u8{ 0, 0, 0, 0 };
    _ = std.fmt.bufPrint(&buf, "{d}", .{number}) catch {};
    return buf;
}

fn drawCenteredText(cr: *gtk.cairo_t, text: [*:0]const u8, x: f64, y: f64, size: f64) void {
    gtk.cairo_select_font_face(cr, "Sans", gtk.CAIRO_FONT_SLANT_NORMAL, gtk.CAIRO_FONT_WEIGHT_BOLD);
    gtk.cairo_set_font_size(cr, size);
    var extents: gtk.cairo_text_extents_t = undefined;
    gtk.cairo_text_extents(cr, text, &extents);
    gtk.cairo_set_source_rgb(cr, 0.96, 0.93, 0.82);
    gtk.cairo_move_to(cr, x - extents.width / 2.0 - extents.x_bearing, y - extents.height / 2.0 - extents.y_bearing);
    gtk.cairo_show_text(cr, text);
}

fn angleForNumber(number: u8) f64 {
    const slice = wheelSliceAngle();
    for (WheelOrder, 0..) |n, i| {
        if (n == number) return @as(f64, @floatFromInt(i)) * slice;
    }
    return 0;
}

fn wheelSliceAngle() f64 {
    return std.math.tau / @as(f64, @floatFromInt(WheelOrder.len));
}

fn lerp(start: f64, end: f64, t: f64) f64 {
    return start + (end - start) * t;
}

fn easeOutCubic(t: f64) f64 {
    const inv = 1.0 - t;
    return 1.0 - inv * inv * inv;
}

fn normalizeAngle(angle: f64) f64 {
    return @mod(angle, std.math.tau);
}

fn kindLabelZ(buf: []u8, kind: game.BetKind) [:0]const u8 {
    return switch (kind) {
        .straight => |n| std.fmt.bufPrintZ(buf, "Numero plein {d}", .{n}) catch "",
        .color => |color| std.fmt.bufPrintZ(buf, "{s}", .{color.label()}) catch "",
        .parity => |parity| std.fmt.bufPrintZ(buf, "{s}", .{parity.label()}) catch "",
        .range => |range| std.fmt.bufPrintZ(buf, "{s}", .{range.label()}) catch "",
        .dozen => |dozen| std.fmt.bufPrintZ(buf, "Douzaine {s}", .{dozen.label()}) catch "",
        .column => |column| std.fmt.bufPrintZ(buf, "{s}", .{column.label()}) catch "",
    };
}

fn resultLabelZ(buf: []u8, state: *AppState) ![:0]const u8 {
    const number = state.last_number orelse return std.fmt.bufPrintZ(buf, "Aucun tirage", .{});
    const outcome = game.outcomeForNumber(number);
    const color = if (outcome.color) |col| col.label() else "Vert";
    return std.fmt.bufPrintZ(buf, "{d} {s}", .{ number, color });
}
