//! Application state: the single heap-allocated `AppState` that ties the game
//! logic, RNG, spin animation, and every GTK widget pointer together.
//!
//! `AppState` is created once in `main`, freed via `defer`, and passed as the
//! `user_data` argument through every GTK signal connection. There is no other
//! shared or global state.

const std = @import("std");
const gtk = @import("gtk.zig");
const game = @import("game.zig");
const audio = @import("audio.zig");

/// Maximum number of spins kept in the history side panel.
pub const HistoryLimit = 12;

/// A clickable region of the betting table, rebuilt every time the table is
/// drawn and hit-tested on click to place a bet.
pub const HitZone = struct {
    x: f64,
    y: f64,
    w: f64,
    h: f64,
    kind: game.BetKind,
};

/// One settled spin shown as a coloured chip in the history strip. Kept as plain
/// values (no heap allocation): the colour is derived from `number`.
pub const HistoryEntry = struct {
    number: u8,
    profit: i64,
};

pub const AppState = struct {
    allocator: std.mem.Allocator,
    game_state: game.GameState,
    rng: std.Random.DefaultPrng,
    audio: audio.Audio,
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
    menu_content: ?*gtk.GtkWidget = null,
    game_content: ?*gtk.GtkWidget = null,
    wheel_area: ?*gtk.GtkWidget = null,
    table_area: ?*gtk.GtkWidget = null,
    balance_label: ?*gtk.GtkWidget = null,
    history_strip: ?*gtk.GtkWidget = null,
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
            .audio = audio.Audio.init(allocator),
            .hit_zones = std.array_list.Managed(HitZone).init(allocator),
            .history = std.array_list.Managed(HistoryEntry).init(allocator),
        };
        return state;
    }

    pub fn deinit(self: *AppState) void {
        self.audio.deinit();
        self.game_state.deinit();
        self.clearHistory();
        self.history.deinit();
        self.hit_zones.deinit();
        self.allocator.destroy(self);
    }

    pub fn clearHistory(self: *AppState) void {
        self.history.clearRetainingCapacity();
    }
};
