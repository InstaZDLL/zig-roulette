//! Tiny self-contained sound-effects engine.
//!
//! PulseAudio's `libpulse-simple` is loaded at runtime via `dlopen` (no link-time
//! dependency, no headers): if it is missing, sound silently disables and the
//! game keeps working. Effects are synthesised once into 16-bit PCM buffers and
//! played on detached threads so the GTK main loop never blocks.

const std = @import("std");

const SR: usize = 44100;
const SRF: f64 = 44100.0;

// --- libpulse-simple ABI (the few bits we need) ---------------------------

const pa_simple = opaque {};

const PaSampleSpec = extern struct {
    format: c_int,
    rate: u32,
    channels: u8,
};

const PA_SAMPLE_S16LE: c_int = 3;
const PA_STREAM_PLAYBACK: c_int = 1;

const NewFn = *const fn (?[*:0]const u8, [*:0]const u8, c_int, ?[*:0]const u8, [*:0]const u8, *const PaSampleSpec, ?*const anyopaque, ?*const anyopaque, ?*c_int) callconv(.c) ?*pa_simple;
const WriteFn = *const fn (*pa_simple, *const anyopaque, usize, ?*c_int) callconv(.c) c_int;
const DrainFn = *const fn (*pa_simple, ?*c_int) callconv(.c) c_int;
const FreeFn = *const fn (*pa_simple) callconv(.c) void;

pub const Sound = enum { chip, spin, win };

pub const Audio = struct {
    allocator: std.mem.Allocator,
    enabled: bool = true,
    available: bool = false,
    lib: ?std.DynLib = null,
    new_fn: NewFn = undefined,
    write_fn: WriteFn = undefined,
    drain_fn: DrainFn = undefined,
    free_fn: FreeFn = undefined,
    chip_pcm: []i16 = &.{},
    spin_pcm: []i16 = &.{},
    win_pcm: []i16 = &.{},
    /// Number of detached worker threads currently reading the PCM buffers.
    /// `deinit` waits for this to hit zero before freeing anything.
    in_flight: std.atomic.Value(u32) = std.atomic.Value(u32).init(0),

    /// Try to wire up PulseAudio and pre-render the effect buffers. Any failure
    /// leaves `available = false`; callers can still call `play` (it no-ops).
    pub fn init(allocator: std.mem.Allocator) Audio {
        var self = Audio{ .allocator = allocator };

        var lib = std.DynLib.open("libpulse-simple.so.0") catch return self;
        self.new_fn = lib.lookup(NewFn, "pa_simple_new") orelse {
            lib.close();
            return self;
        };
        self.write_fn = lib.lookup(WriteFn, "pa_simple_write") orelse {
            lib.close();
            return self;
        };
        self.drain_fn = lib.lookup(DrainFn, "pa_simple_drain") orelse {
            lib.close();
            return self;
        };
        self.free_fn = lib.lookup(FreeFn, "pa_simple_free") orelse {
            lib.close();
            return self;
        };

        self.chip_pcm = genChip(allocator) catch return giveUp(&lib, &self);
        self.spin_pcm = genSpin(allocator) catch return giveUp(&lib, &self);
        self.win_pcm = genWin(allocator) catch return giveUp(&lib, &self);

        self.lib = lib;
        self.available = true;
        return self;
    }

    fn giveUp(lib: *std.DynLib, self: *Audio) Audio {
        self.allocator.free(self.chip_pcm);
        self.allocator.free(self.spin_pcm);
        self.allocator.free(self.win_pcm);
        self.chip_pcm = &.{};
        self.spin_pcm = &.{};
        self.win_pcm = &.{};
        lib.close();
        return self.*;
    }

    pub fn deinit(self: *Audio) void {
        // Wait for any in-flight worker to stop touching the buffers/dynlib
        // before we free them, so a detached thread can't use freed resources.
        while (self.in_flight.load(.acquire) != 0) std.Thread.yield() catch {};
        self.allocator.free(self.chip_pcm);
        self.allocator.free(self.spin_pcm);
        self.allocator.free(self.win_pcm);
        if (self.lib) |*lib| lib.close();
    }

    /// Flip mute on/off; returns the new enabled state.
    pub fn toggle(self: *Audio) bool {
        self.enabled = !self.enabled;
        return self.enabled;
    }

    /// Fire-and-forget: play `sound` on a detached thread. No-op if unavailable
    /// or muted. The PCM buffers are read-only and outlive the thread.
    pub fn play(self: *Audio, sound: Sound) void {
        if (!self.available or !self.enabled) return;
        const pcm = switch (sound) {
            .chip => self.chip_pcm,
            .spin => self.spin_pcm,
            .win => self.win_pcm,
        };
        // Count this worker before spawning so deinit can never race ahead and
        // free the buffers between the spawn and the worker starting.
        _ = self.in_flight.fetchAdd(1, .acq_rel);
        const thread = std.Thread.spawn(.{}, worker, .{ self, pcm }) catch {
            _ = self.in_flight.fetchSub(1, .acq_rel);
            return;
        };
        thread.detach();
    }
};

fn worker(self: *Audio, pcm: []const i16) void {
    defer _ = self.in_flight.fetchSub(1, .acq_rel);
    var err: c_int = 0;
    var ss = PaSampleSpec{ .format = PA_SAMPLE_S16LE, .rate = @intCast(SR), .channels = 1 };
    const stream = self.new_fn(null, "Zig-Roulette", PA_STREAM_PLAYBACK, null, "sfx", &ss, null, null, &err) orelse return;
    defer self.free_fn(stream);
    _ = self.write_fn(stream, pcm.ptr, pcm.len * @sizeOf(i16), &err);
    _ = self.drain_fn(stream, &err);
}

// --- Synthesis ------------------------------------------------------------

fn toSample(value: f64) i16 {
    const clamped = std.math.clamp(value, -1.0, 1.0);
    return @intFromFloat(clamped * 32767.0);
}

/// Short descending blip for placing/removing a chip.
fn genChip(allocator: std.mem.Allocator) ![]i16 {
    const dur = 0.06;
    const n: usize = @intFromFloat(dur * SRF);
    const buf = try allocator.alloc(i16, n);
    var phase: f64 = 0;
    for (buf, 0..) |*s, i| {
        const t = @as(f64, @floatFromInt(i)) / SRF;
        const k = t / dur;
        const freq = 800.0 * std.math.pow(f64, 300.0 / 800.0, k);
        const env = 0.30 * std.math.pow(f64, 0.01 / 0.30, k);
        phase += std.math.tau * freq / SRF;
        s.* = toSample(env * @sin(phase));
    }
    return buf;
}

/// A train of clicks that slows down, like the ball settling on the wheel.
fn genSpin(allocator: std.mem.Allocator) ![]i16 {
    const dur = 2.0;
    const n: usize = @intFromFloat(dur * SRF);
    const buf = try allocator.alloc(i16, n);
    @memset(buf, 0);

    const click_len: usize = @intFromFloat(0.012 * SRF);
    var t: f64 = 0.0;
    var interval: f64 = 0.045;
    while (t < dur) : (t += interval) {
        const start: usize = @intFromFloat(t * SRF);
        var j: usize = 0;
        while (j < click_len and start + j < n) : (j += 1) {
            const tj = @as(f64, @floatFromInt(j)) / SRF;
            const env = 0.22 * @exp(-tj / 0.0035);
            const square: f64 = if (@sin(std.math.tau * 1500.0 * tj) >= 0) 1.0 else -1.0;
            buf[start + j] = toSample(@as(f64, @floatFromInt(buf[start + j])) / 32767.0 + env * square);
        }
        interval *= 1.06; // decelerate
    }
    return buf;
}

/// Rising four-note arpeggio for a win.
fn genWin(allocator: std.mem.Allocator) ![]i16 {
    const dur = 0.8;
    const n: usize = @intFromFloat(dur * SRF);
    const buf = try allocator.alloc(i16, n);
    const notes = [_]f64{ 440.0, 554.37, 659.25, 880.0 };
    var phase: f64 = 0;
    for (buf, 0..) |*s, i| {
        const t = @as(f64, @floatFromInt(i)) / SRF;
        const idx = @min(@as(usize, @intFromFloat(t / 0.1)), notes.len - 1);
        const freq = notes[idx];
        const env = 0.30 * (1.0 - t / dur);
        phase += std.math.tau * freq / SRF;
        // Triangle wave: warmer than a sine, softer than a square.
        const tri = std.math.asin(@sin(phase)) * (2.0 / std.math.pi);
        s.* = toSample(env * tri);
    }
    return buf;
}
