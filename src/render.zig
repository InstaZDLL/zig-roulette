//! Cairo draw functions for the wheel and the betting table.
//!
//! These are registered as GTK drawing-area draw funcs and receive the
//! `AppState` through `user_data`. `drawTable` additionally rebuilds
//! `state.hit_zones` so clicks can be hit-tested against the current layout.

const std = @import("std");
const gtk = @import("gtk.zig");
const game = @import("game.zig");
const app = @import("app.zig");
const wheel = @import("wheel.zig");

/// Fill colour family used for a table zone or wheel pocket.
pub const ZoneColor = enum { red, black, green, neutral };

pub fn drawWheel(_: *gtk.GtkDrawingArea, cr: *gtk.cairo_t, width: gtk.gint, height: gtk.gint, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    const w: f64 = @floatFromInt(width);
    const h: f64 = @floatFromInt(height);
    const cx = w * 0.5;
    const cy = h * 0.5;
    const radius = @min(w, h) * 0.46;

    gtk.cairo_set_source_rgb(cr, 0.07, 0.09, 0.13);
    gtk.cairo_paint(cr);

    // Dark outer rim that frames the coloured pockets.
    gtk.cairo_set_source_rgb(cr, 0.10, 0.11, 0.13);
    gtk.cairo_arc(cr, cx, cy, radius * 1.06, 0, std.math.tau);
    gtk.cairo_fill(cr);

    const slice = wheel.sliceAngle();
    for (wheel.order, 0..) |number, i| {
        const start = state.wheel_angle + @as(f64, @floatFromInt(i)) * slice;
        const end = start + slice;
        setNumberColor(cr, number);
        gtk.cairo_move_to(cr, cx, cy);
        gtk.cairo_arc(cr, cx, cy, radius, start, end);
        gtk.cairo_close_path(cr);
        gtk.cairo_fill_preserve(cr);
        gtk.cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.45);
        gtk.cairo_set_line_width(cr, 1);
        gtk.cairo_stroke(cr);

        drawPocketNumber(cr, cx, cy, radius, start + slice * 0.5, number);
    }

    // Hub: dark disc with a soft golden core, drawn over the pocket centres.
    gtk.cairo_set_source_rgb(cr, 0.13, 0.14, 0.16);
    gtk.cairo_arc(cr, cx, cy, radius * 0.52, 0, std.math.tau);
    gtk.cairo_fill(cr);
    gtk.cairo_set_source_rgb(cr, 0.82, 0.62, 0.26);
    gtk.cairo_arc(cr, cx, cy, radius * 0.16, 0, std.math.tau);
    gtk.cairo_fill(cr);

    const ball_r = radius * 0.80;
    const bx = cx + @cos(state.ball_angle) * ball_r;
    const by = cy + @sin(state.ball_angle) * ball_r;
    gtk.cairo_set_source_rgb(cr, 0.97, 0.97, 0.93);
    gtk.cairo_arc(cr, bx, by, 7, 0, std.math.tau);
    gtk.cairo_fill(cr);

    // Last result, large, in the centre of the hub (hidden while spinning).
    if (state.last_number) |number| if (!state.spinning) {
        var buf: [16]u8 = undefined;
        const text = std.fmt.bufPrintZ(&buf, "{d}", .{number}) catch "";
        drawCenteredText(cr, text.ptr, cx, cy + radius * 0.12, radius * 0.30);
    };
}

/// Draw `number` inside its pocket, rotated so it reads radially (top of the
/// glyph pointing outward), matching a real wheel.
fn drawPocketNumber(cr: *gtk.cairo_t, cx: f64, cy: f64, radius: f64, mid: f64, number: u8) void {
    const text_r = radius * 0.87;
    const tx = cx + @cos(mid) * text_r;
    const ty = cy + @sin(mid) * text_r;

    var buf: [4:0]u8 = numberLabel(number);

    gtk.cairo_save(cr);
    gtk.cairo_translate(cr, tx, ty);
    gtk.cairo_rotate(cr, mid + std.math.pi / 2.0);
    gtk.cairo_select_font_face(cr, "Sans", gtk.CAIRO_FONT_SLANT_NORMAL, gtk.CAIRO_FONT_WEIGHT_BOLD);
    gtk.cairo_set_font_size(cr, @max(radius * 0.068, 8.0));
    var extents: gtk.cairo_text_extents_t = undefined;
    gtk.cairo_text_extents(cr, &buf, &extents);
    gtk.cairo_set_source_rgb(cr, 0.98, 0.97, 0.93);
    gtk.cairo_move_to(cr, -extents.width / 2.0 - extents.x_bearing, -extents.height / 2.0 - extents.y_bearing);
    gtk.cairo_show_text(cr, &buf);
    gtk.cairo_restore(cr);
}

pub fn drawTable(_: *gtk.GtkDrawingArea, cr: *gtk.cairo_t, width: gtk.gint, height: gtk.gint, data: ?*anyopaque) callconv(.c) void {
    const state: *app.AppState = @ptrCast(@alignCast(data.?));
    state.hit_zones.clearRetainingCapacity();

    const w: f64 = @floatFromInt(width);
    const h: f64 = @floatFromInt(height);
    gtk.cairo_set_source_rgb(cr, 0.20, 0.25, 0.38);
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
            const zone: app.HitZone = .{
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

fn drawZone(state: *app.AppState, cr: *gtk.cairo_t, zone: app.HitZone, text: [*:0]const u8, color: ZoneColor) void {
    state.hit_zones.append(zone) catch {};
    const selected = if (state.selected) |kind| std.meta.eql(kind, zone.kind) else false;

    switch (color) {
        .red => gtk.cairo_set_source_rgb(cr, 0.80, 0.11, 0.18),
        .black => gtk.cairo_set_source_rgb(cr, 0.18, 0.22, 0.30),
        .green => gtk.cairo_set_source_rgb(cr, 0.10, 0.55, 0.30),
        .neutral => gtk.cairo_set_source_rgb(cr, 0.16, 0.20, 0.28),
    }
    gtk.cairo_rectangle(cr, zone.x + 2.0, zone.y + 2.0, zone.w - 4.0, zone.h - 4.0);
    gtk.cairo_fill_preserve(cr);
    if (selected) {
        gtk.cairo_set_source_rgb(cr, 1.0, 0.84, 0.22);
        gtk.cairo_set_line_width(cr, 3);
    } else {
        gtk.cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.35);
        gtk.cairo_set_line_width(cr, 1.0);
    }
    gtk.cairo_stroke(cr);
    drawCenteredText(cr, text, zone.x + zone.w / 2.0, zone.y + zone.h / 2.0 + 5.0, 15);

    const staked = stakedOn(state, zone.kind);
    if (staked > 0) drawChip(cr, zone, staked);
}

/// Sum of every bet currently staked on `kind` (a single table zone).
fn stakedOn(state: *app.AppState, kind: game.BetKind) i64 {
    var total: i64 = 0;
    for (state.game_state.bets.items) |bet| {
        if (std.meta.eql(bet.kind, kind)) total += bet.amount;
    }
    return total;
}

/// Draw a casino-style chip in the bottom-right corner of a zone, labelled with
/// the total amount staked there, so bets are visible directly on the table.
fn drawChip(cr: *gtk.cairo_t, zone: app.HitZone, amount: i64) void {
    const r = @min(@min(zone.w, zone.h) * 0.32, 18.0);
    const cx = zone.x + zone.w - r - 3.0;
    const cy = zone.y + zone.h - r - 3.0;

    gtk.cairo_set_source_rgb(cr, 0.86, 0.16, 0.16);
    gtk.cairo_arc(cr, cx, cy, r, 0, std.math.tau);
    gtk.cairo_fill(cr);
    gtk.cairo_set_source_rgb(cr, 0.97, 0.95, 0.88);
    gtk.cairo_set_line_width(cr, 2);
    gtk.cairo_arc(cr, cx, cy, r, 0, std.math.tau);
    gtk.cairo_stroke(cr);

    var buf: [16]u8 = undefined;
    const text = std.fmt.bufPrintZ(&buf, "{d}", .{amount}) catch "";
    drawCenteredText(cr, text.ptr, cx, cy + 4.0, r * 0.72);
}

fn setNumberColor(cr: *gtk.cairo_t, number: u8) void {
    switch (colorTagForNumber(number)) {
        .red => gtk.cairo_set_source_rgb(cr, 0.80, 0.11, 0.18),
        .black => gtk.cairo_set_source_rgb(cr, 0.13, 0.15, 0.18),
        .green => gtk.cairo_set_source_rgb(cr, 0.10, 0.55, 0.30),
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
