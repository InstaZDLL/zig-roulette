//! GTK glue layer: widget construction, signal callbacks, list/label refresh,
//! and the spin animation that drives `render.zig`.
//!
//! Every callback receives the shared `AppState` through `user_data` and casts
//! it back. UI strings are French, matching the rest of the app.

const std = @import("std");
const gtk = @import("gtk.zig");
const game = @import("game.zig");
const app = @import("app.zig");
const render = @import("render.zig");
const wheel = @import("wheel.zig");

const OgImageBytes = @embedFile("og-image");
const AppCss = @embedFile("style.css");

// --- Construction ---------------------------------------------------------

/// Build the main menu (the landing screen). Also pre-builds the game view and
/// stores it in `state.game_content` so "Entrer au casino" can swap to it.
pub fn buildMenu(state: *app.AppState, game_toolbar: *gtk.GtkWidget) *gtk.GtkWidget {
    const root = gtk.gtk_box_new(gtk.GTK_ORIENTATION_VERTICAL, 0);
    gtk.gtk_widget_add_css_class(root, "menu-root");
    gtk.gtk_widget_set_hexpand(root, 1);
    gtk.gtk_widget_set_vexpand(root, 1);
    gtk.gtk_widget_set_margin_top(root, 32);
    gtk.gtk_widget_set_margin_bottom(root, 32);
    gtk.gtk_widget_set_margin_start(root, 32);
    gtk.gtk_widget_set_margin_end(root, 32);

    const panel = gtk.gtk_box_new(gtk.GTK_ORIENTATION_VERTICAL, 12);
    gtk.gtk_widget_add_css_class(panel, "menu-panel");
    gtk.gtk_widget_set_hexpand(panel, 1);
    gtk.gtk_widget_set_vexpand(panel, 1);
    gtk.gtk_box_append(@ptrCast(root), panel);

    if (buildOgPicture()) |hero| {
        gtk.gtk_widget_add_css_class(hero, "menu-hero");
        gtk.gtk_widget_set_size_request(hero, 760, 376);
        gtk.gtk_widget_set_halign(hero, gtk.GTK_ALIGN_CENTER);
        gtk.gtk_widget_set_hexpand(hero, 1);
        gtk.gtk_box_append(@ptrCast(panel), hero);
    } else {
        const icon = gtk.gtk_image_new_from_icon_name("dev.instazdll.ZigRoulette");
        gtk.gtk_image_set_pixel_size(@ptrCast(icon), 128);
        gtk.gtk_widget_set_halign(icon, gtk.GTK_ALIGN_CENTER);
        gtk.gtk_box_append(@ptrCast(panel), icon);
    }

    const title = gtk.gtk_label_new("ZIG-ROULETTE");
    gtk.gtk_widget_add_css_class(title, "menu-title");
    gtk.gtk_label_set_xalign(@ptrCast(title), 0);
    gtk.gtk_box_append(@ptrCast(panel), title);

    const subtitle = gtk.gtk_label_new("The Casino of Code");
    gtk.gtk_widget_add_css_class(subtitle, "menu-subtitle");
    gtk.gtk_label_set_xalign(@ptrCast(subtitle), 0);
    gtk.gtk_box_append(@ptrCast(panel), subtitle);

    const copy = gtk.gtk_label_new("Winning is a matter of safety, not luck. Place your bets, spin the wheel, and keep the credits flowing in a native Zig GTK app.");
    gtk.gtk_widget_add_css_class(copy, "menu-copy");
    gtk.gtk_label_set_wrap(@ptrCast(copy), 1);
    gtk.gtk_label_set_xalign(@ptrCast(copy), 0);
    gtk.gtk_box_append(@ptrCast(panel), copy);

    const actions = gtk.gtk_box_new(gtk.GTK_ORIENTATION_HORIZONTAL, 10);
    gtk.gtk_widget_set_margin_top(actions, 12);
    gtk.gtk_box_append(@ptrCast(panel), actions);

    const play_button = gtk.gtk_button_new_with_label("Entrer au casino");
    gtk.gtk_widget_add_css_class(play_button, "suggested-action");
    _ = gtk.g_signal_connect_data(play_button, "clicked", @ptrCast(&playClicked), state, null, 0);
    gtk.gtk_box_append(@ptrCast(actions), play_button);

    state.game_content = buildGame(state, game_toolbar);
    return root;
}

/// Build the game view: a slim control rail on the left, then the wheel, the
/// last-results strip and the betting table filling the rest. No bulky sidebar.
fn buildGame(state: *app.AppState, toolbar: *gtk.GtkWidget) *gtk.GtkWidget {
    const root = gtk.gtk_box_new(gtk.GTK_ORIENTATION_HORIZONTAL, 0);
    gtk.gtk_widget_add_css_class(root, "roulette-root");

    // --- Left control rail ------------------------------------------------
    const rail = gtk.gtk_box_new(gtk.GTK_ORIENTATION_VERTICAL, 10);
    gtk.gtk_widget_add_css_class(rail, "control-rail");
    gtk.gtk_widget_set_size_request(rail, 190, -1);
    gtk.gtk_box_append(@ptrCast(root), rail);

    addTitle(rail, "Mise");
    state.amount_spin = gtk.gtk_spin_button_new_with_range(1, 1000, 5);
    gtk.gtk_spin_button_set_value(@ptrCast(state.amount_spin.?), 25);
    _ = gtk.g_signal_connect_data(state.amount_spin.?, "value-changed", @ptrCast(&amountChanged), state, null, 0);
    gtk.gtk_box_append(@ptrCast(rail), state.amount_spin.?);

    const scale_row = gtk.gtk_box_new(gtk.GTK_ORIENTATION_HORIZONTAL, 8);
    const half_button = gtk.gtk_button_new_with_label("½");
    gtk.gtk_widget_set_hexpand(half_button, 1);
    _ = gtk.g_signal_connect_data(half_button, "clicked", @ptrCast(&halveClicked), state, null, 0);
    gtk.gtk_box_append(@ptrCast(scale_row), half_button);
    const double_button = gtk.gtk_button_new_with_label("2×");
    gtk.gtk_widget_set_hexpand(double_button, 1);
    _ = gtk.g_signal_connect_data(double_button, "clicked", @ptrCast(&doubleClicked), state, null, 0);
    gtk.gtk_box_append(@ptrCast(scale_row), double_button);
    gtk.gtk_box_append(@ptrCast(rail), scale_row);

    state.spin_button = gtk.gtk_button_new_with_label("Lancer");
    gtk.gtk_widget_add_css_class(state.spin_button.?, "suggested-action");
    gtk.gtk_widget_add_css_class(state.spin_button.?, "spin-button");
    _ = gtk.g_signal_connect_data(state.spin_button.?, "clicked", @ptrCast(&spinClicked), state, null, 0);
    gtk.gtk_box_append(@ptrCast(rail), state.spin_button.?);

    // Spacer pushes the status text + reset to the bottom of the rail.
    const spacer = gtk.gtk_box_new(gtk.GTK_ORIENTATION_VERTICAL, 0);
    gtk.gtk_widget_set_vexpand(spacer, 1);
    gtk.gtk_box_append(@ptrCast(rail), spacer);

    state.status_label = gtk.gtk_label_new("Clique une zone du tapis pour miser.");
    gtk.gtk_label_set_wrap(@ptrCast(state.status_label.?), 1);
    gtk.gtk_label_set_xalign(@ptrCast(state.status_label.?), 0);
    gtk.gtk_widget_add_css_class(state.status_label.?, "muted-label");
    gtk.gtk_box_append(@ptrCast(rail), state.status_label.?);

    const new_session_button = gtk.gtk_button_new_with_label("Nouvelle session");
    _ = gtk.g_signal_connect_data(new_session_button, "clicked", @ptrCast(&newSessionClicked), state, null, 0);
    gtk.gtk_box_append(@ptrCast(rail), new_session_button);

    // --- Main play area ---------------------------------------------------
    const play_box = gtk.gtk_box_new(gtk.GTK_ORIENTATION_VERTICAL, 12);
    gtk.gtk_widget_add_css_class(play_box, "play-area");
    gtk.gtk_widget_set_hexpand(play_box, 1);
    gtk.gtk_widget_set_vexpand(play_box, 1);
    gtk.gtk_box_append(@ptrCast(root), play_box);

    const top_bar = gtk.gtk_box_new(gtk.GTK_ORIENTATION_HORIZONTAL, 12);

    const sound_button = gtk.gtk_button_new_with_label("🔊");
    gtk.gtk_widget_add_css_class(sound_button, "flat");
    _ = gtk.g_signal_connect_data(sound_button, "clicked", @ptrCast(&soundClicked), state, null, 0);
    gtk.gtk_box_append(@ptrCast(top_bar), sound_button);

    state.balance_label = gtk.gtk_label_new("");
    gtk.gtk_widget_add_css_class(state.balance_label.?, "balance-pill");
    gtk.gtk_label_set_xalign(@ptrCast(state.balance_label.?), 0);
    gtk.gtk_widget_set_hexpand(state.balance_label.?, 1);
    gtk.gtk_widget_set_halign(state.balance_label.?, gtk.GTK_ALIGN_START);
    gtk.gtk_box_append(@ptrCast(top_bar), state.balance_label.?);

    state.history_strip = gtk.gtk_box_new(gtk.GTK_ORIENTATION_HORIZONTAL, 5);
    gtk.gtk_widget_set_halign(state.history_strip.?, gtk.GTK_ALIGN_END);
    gtk.gtk_box_append(@ptrCast(top_bar), state.history_strip.?);
    gtk.gtk_box_append(@ptrCast(play_box), top_bar);

    const wheel_area = gtk.gtk_drawing_area_new();
    state.wheel_area = wheel_area;
    gtk.gtk_widget_set_size_request(wheel_area, 360, 320);
    gtk.gtk_widget_set_hexpand(wheel_area, 1);
    gtk.gtk_widget_set_vexpand(wheel_area, 1);
    gtk.gtk_drawing_area_set_draw_func(@ptrCast(wheel_area), @ptrCast(&render.drawWheel), state, null);
    gtk.gtk_box_append(@ptrCast(play_box), wheel_area);

    const table = gtk.gtk_drawing_area_new();
    state.table_area = table;
    gtk.gtk_widget_set_size_request(table, 720, 300);
    gtk.gtk_widget_set_hexpand(table, 1);
    gtk.gtk_drawing_area_set_draw_func(@ptrCast(table), @ptrCast(&render.drawTable), state, null);

    const click = gtk.gtk_gesture_click_new();
    gtk.gtk_gesture_single_set_button(@ptrCast(click), 1);
    gtk.gtk_widget_add_controller(table, @ptrCast(click));
    _ = gtk.g_signal_connect_data(click, "pressed", @ptrCast(&tablePressed), state, null, 0);
    gtk.gtk_box_append(@ptrCast(play_box), table);

    const bottom_bar = gtk.gtk_box_new(gtk.GTK_ORIENTATION_HORIZONTAL, 8);
    const undo_button = gtk.gtk_button_new_with_label("↩ Annuler");
    gtk.gtk_widget_add_css_class(undo_button, "flat");
    _ = gtk.g_signal_connect_data(undo_button, "clicked", @ptrCast(&undoClicked), state, null, 0);
    gtk.gtk_box_append(@ptrCast(bottom_bar), undo_button);
    const bottom_spacer = gtk.gtk_box_new(gtk.GTK_ORIENTATION_HORIZONTAL, 0);
    gtk.gtk_widget_set_hexpand(bottom_spacer, 1);
    gtk.gtk_box_append(@ptrCast(bottom_bar), bottom_spacer);
    const clear_button = gtk.gtk_button_new_with_label("Effacer ✕");
    gtk.gtk_widget_add_css_class(clear_button, "flat");
    _ = gtk.g_signal_connect_data(clear_button, "clicked", @ptrCast(&clearClicked), state, null, 0);
    gtk.gtk_box_append(@ptrCast(bottom_bar), clear_button);
    gtk.gtk_box_append(@ptrCast(play_box), bottom_bar);

    gtk.adw_toolbar_view_set_content(@ptrCast(toolbar), root);
    return toolbar;
}

fn buildOgPicture() ?*gtk.GtkWidget {
    const bytes = gtk.g_bytes_new_static(OgImageBytes.ptr, OgImageBytes.len);
    defer gtk.g_bytes_unref(bytes);

    const texture = gtk.gdk_texture_new_from_bytes(bytes, null) orelse return null;
    defer gtk.g_object_unref(@ptrCast(texture));

    const picture = gtk.gtk_picture_new_for_paintable(@ptrCast(texture));
    gtk.gtk_picture_set_keep_aspect_ratio(@ptrCast(picture), gtk.TRUE);
    gtk.gtk_picture_set_can_shrink(@ptrCast(picture), gtk.TRUE);
    return picture;
}

/// Install the app stylesheet (`style.css`) on the default display.
pub fn installCss() void {
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

// --- Signal callbacks -----------------------------------------------------

fn amountChanged(widget: *gtk.GtkSpinButton, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    state.amount = @intFromFloat(gtk.gtk_spin_button_get_value(widget));
    refreshUi(state);
}

fn playClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    const window = state.window orelse return;
    const game_content = state.game_content orelse return;
    gtk.adw_application_window_set_content(@ptrCast(window), game_content);
    refreshUi(state);
}

fn halveClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;
    state.audio.play(.chip);
    setAmount(state, @max(@divTrunc(state.amount, 2), 1));
}

fn doubleClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;
    state.audio.play(.chip);
    setAmount(state, @min(state.amount * 2, 1000));
}

fn soundClicked(button: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    const on = state.audio.toggle();
    gtk.gtk_button_set_label(button, if (on) "🔊" else "🔇");
}

/// Set the stake amount and keep the spin button's display in sync.
fn setAmount(state: *app.AppState, amount: i64) void {
    state.amount = amount;
    if (state.amount_spin) |spin| {
        gtk.gtk_spin_button_set_value(@ptrCast(spin), @floatFromInt(amount));
    }
    refreshUi(state);
}

fn clearClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;
    state.game_state.clearBets();
    state.audio.play(.chip);
    setStatus(state, "Mises effacees.");
    refreshUi(state);
}

fn undoClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;

    if (state.game_state.undoLastBet()) {
        state.audio.play(.chip);
        setStatus(state, "Derniere mise annulee.");
    } else {
        setStatus(state, "Aucune mise a annuler.");
    }
    refreshUi(state);
}

fn newSessionClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
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

fn tablePressed(_: *gtk.GtkGestureClick, _: gtk.gint, x: gtk.gdouble, y: gtk.gdouble, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;

    for (state.hit_zones.items) |zone| {
        if (x >= zone.x and x <= zone.x + zone.w and y >= zone.y and y <= zone.y + zone.h) {
            state.selected = zone.kind;
            addBetForKind(state, zone.kind);
            return;
        }
    }
}

fn addBetForKind(state: *app.AppState, kind: game.BetKind) void {
    state.game_state.addBet(.{ .kind = kind, .amount = state.amount }) catch |err| {
        switch (err) {
            error.InsufficientBalance => setStatus(state, "Solde disponible insuffisant."),
            error.InvalidAmount => setStatus(state, "Montant invalide."),
            else => setStatus(state, "Mise invalide."),
        }
        return;
    };
    state.audio.play(.chip);
    setStatus(state, "Mise ajoutee.");
    refreshUi(state);
}

// --- Spin animation -------------------------------------------------------

fn spinClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
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
    state.spin_end_ball_angle = state.spin_end_wheel_angle + wheel.angleForNumber(state.spin_target) + wheel.sliceAngle() / 2.0;
    state.spinning = true;
    state.audio.play(.spin);
    gtk.gtk_widget_set_sensitive(state.spin_button.?, 0);
    setStatus(state, "La roue tourne...");
    _ = gtk.g_timeout_add(16, @ptrCast(&spinTick), state);
}

fn spinTick(data: ?*anyopaque) callconv(.c) gtk.gboolean {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    state.spin_ticks += 1;

    const raw_t = @as(f64, @floatFromInt(state.spin_ticks)) / @as(f64, @floatFromInt(state.spin_total));
    const t = @min(raw_t, 1.0);
    const eased = wheel.easeOutCubic(t);
    state.wheel_angle = wheel.lerp(state.spin_start_wheel_angle, state.spin_end_wheel_angle, eased);
    state.ball_angle = wheel.lerp(state.spin_start_ball_angle, state.spin_end_ball_angle - std.math.tau * 8.0, eased);

    if (state.wheel_area) |area| gtk.gtk_widget_queue_draw(area);

    if (state.spin_ticks < state.spin_total) return gtk.TRUE;

    state.spinning = false;
    state.last_number = state.spin_target;
    state.wheel_angle = wheel.normalizeAngle(state.spin_end_wheel_angle);
    state.ball_angle = wheel.normalizeAngle(state.spin_end_ball_angle);

    const outcome = game.outcomeForNumber(state.spin_target);
    const settled = state.game_state.settle(outcome);
    if (settled.profit > 0) state.audio.play(.win);
    appendHistory(state, outcome, settled) catch {};
    setSpinResultStatus(state, outcome, settled);
    gtk.gtk_widget_set_sensitive(state.spin_button.?, 1);
    refreshUi(state);
    if (state.wheel_area) |area| gtk.gtk_widget_queue_draw(area);

    return gtk.FALSE;
}

fn appendHistory(state: *app.AppState, outcome: game.SpinOutcome, settled: game.SettleResult) !void {
    try state.history.insert(0, .{ .number = outcome.number, .profit = settled.profit });
    while (state.history.items.len > app.HistoryLimit) {
        _ = state.history.pop();
    }
}

// --- UI refresh -----------------------------------------------------------

/// Recompute and repaint every dynamic widget from the current `AppState`.
pub fn refreshUi(state: *app.AppState) void {
    if (state.balance_label) |label| {
        var buf: [128]u8 = undefined;
        const text = std.fmt.bufPrintZ(&buf, "Solde {d}  ·  dispo {d}", .{
            state.game_state.balance,
            state.game_state.available(),
        }) catch "Erreur";
        gtk.gtk_label_set_text(@ptrCast(label), text.ptr);
    }

    rebuildHistoryStrip(state);
    if (state.table_area) |area| gtk.gtk_widget_queue_draw(area);
    if (state.wheel_area) |area| gtk.gtk_widget_queue_draw(area);
}

/// Rebuild the row of coloured chips showing the most recent drawn numbers.
fn rebuildHistoryStrip(state: *app.AppState) void {
    const strip = state.history_strip orelse return;
    while (gtk.gtk_widget_get_first_child(strip)) |child| {
        gtk.gtk_box_remove(@ptrCast(strip), child);
    }
    for (state.history.items) |entry| appendHistoryChip(strip, entry);
}

fn appendHistoryChip(strip: *gtk.GtkWidget, entry: app.HistoryEntry) void {
    var buf: [4]u8 = undefined;
    const text = std.fmt.bufPrintZ(&buf, "{d}", .{entry.number}) catch "?";
    const chip = gtk.gtk_label_new(text.ptr);
    gtk.gtk_widget_add_css_class(chip, "result-chip");
    gtk.gtk_widget_add_css_class(chip, chipColorClass(entry.number));
    gtk.gtk_box_append(@ptrCast(strip), chip);
}

fn chipColorClass(number: u8) [*:0]const u8 {
    if (number == 0) return "chip-green";
    return switch (game.colorForNumber(number).?) {
        .red => "chip-red",
        .black => "chip-black",
    };
}

// --- Status & label formatting --------------------------------------------

fn setStatus(state: *app.AppState, text: [*:0]const u8) void {
    if (state.status_label) |label| gtk.gtk_label_set_text(@ptrCast(label), text);
}

fn setSpinResultStatus(state: *app.AppState, outcome: game.SpinOutcome, settled: game.SettleResult) void {
    var buf: [160]u8 = undefined;
    const color = if (outcome.color) |col| col.label() else "Vert";
    const sign: []const u8 = if (settled.profit >= 0) "+" else "";
    const text = std.fmt.bufPrintZ(&buf, "Resultat {d} {s} | {s}{d}", .{ outcome.number, color, sign, settled.profit }) catch "Resultat calcule.";
    setStatus(state, text.ptr);
}
