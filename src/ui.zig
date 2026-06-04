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

/// Build the game view (wheel + table + sidebar) inside the given toolbar.
fn buildGame(state: *app.AppState, toolbar: *gtk.GtkWidget) *gtk.GtkWidget {
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

    const wheel_area = gtk.gtk_drawing_area_new();
    state.wheel_area = wheel_area;
    gtk.gtk_widget_set_size_request(wheel_area, 520, 360);
    gtk.gtk_widget_set_hexpand(wheel_area, 1);
    gtk.gtk_drawing_area_set_draw_func(@ptrCast(wheel_area), @ptrCast(&render.drawWheel), state, null);
    gtk.gtk_box_append(@ptrCast(play_box), wheel_area);

    const table = gtk.gtk_drawing_area_new();
    state.table_area = table;
    gtk.gtk_widget_set_size_request(table, 720, 320);
    gtk.gtk_widget_set_hexpand(table, 1);
    gtk.gtk_widget_set_vexpand(table, 1);
    gtk.gtk_drawing_area_set_draw_func(@ptrCast(table), @ptrCast(&render.drawTable), state, null);

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

fn maxClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
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
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;

    const kind = state.selected orelse {
        setStatus(state, "Selectionne d'abord une zone du tapis.");
        return;
    };

    addBetForKind(state, kind);
}

fn clearClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;
    state.game_state.clearBets();
    setStatus(state, "Mises effacees.");
    refreshUi(state);
}

fn undoClicked(_: *gtk.GtkButton, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    if (state.spinning) return;

    if (state.game_state.undoLastBet()) {
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
    appendHistory(state, outcome, settled) catch {};
    setSpinResultStatus(state, outcome, settled);
    gtk.gtk_widget_set_sensitive(state.spin_button.?, 1);
    refreshUi(state);
    if (state.wheel_area) |area| gtk.gtk_widget_queue_draw(area);

    return gtk.FALSE;
}

fn appendHistory(state: *app.AppState, outcome: game.SpinOutcome, settled: game.SettleResult) !void {
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

    const entry: app.HistoryEntry = .{
        .summary = summary_owned,
        .details = details_owned,
        .profit = settled.profit,
    };

    try state.history.insert(0, entry);
    while (state.history.items.len > app.HistoryLimit) {
        const old = state.history.pop().?;
        state.allocator.free(old.summary);
        state.allocator.free(old.details);
    }
}

// --- UI refresh -----------------------------------------------------------

/// Recompute and repaint every dynamic widget from the current `AppState`.
pub fn refreshUi(state: *app.AppState) void {
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

fn rebuildBetList(state: *app.AppState) void {
    const list = state.bet_list orelse return;
    clearListBox(list);

    for (state.game_state.bets.items) |bet| {
        appendBetRow(list, bet);
    }
}

fn rebuildHistoryList(state: *app.AppState) void {
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

fn appendHistoryRow(list: *gtk.GtkWidget, entry: app.HistoryEntry) void {
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

fn resultLabelZ(buf: []u8, state: *app.AppState) ![:0]const u8 {
    const number = state.last_number orelse return std.fmt.bufPrintZ(buf, "Aucun tirage", .{});
    const outcome = game.outcomeForNumber(number);
    const color = if (outcome.color) |col| col.label() else "Vert";
    return std.fmt.bufPrintZ(buf, "{d} {s}", .{ number, color });
}
