//! European roulette wheel geometry and spin-animation easing.
//!
//! Pure math, no GTK or game-state dependency, so it is trivially testable and
//! shared between the renderer (`render.zig`) and the spin logic (`ui.zig`).

const std = @import("std");

/// Pocket order of a European wheel, clockwise from the single zero.
pub const order = [_]u8{ 0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26 };

/// Angular width of a single pocket, in radians.
pub fn sliceAngle() f64 {
    return std.math.tau / @as(f64, @floatFromInt(order.len));
}

/// Angle of the pocket holding `number`, measured from the wheel's start angle.
pub fn angleForNumber(number: u8) f64 {
    const slice = sliceAngle();
    for (order, 0..) |n, i| {
        if (n == number) return @as(f64, @floatFromInt(i)) * slice;
    }
    return 0;
}

pub fn lerp(start: f64, end: f64, t: f64) f64 {
    return start + (end - start) * t;
}

pub fn easeOutCubic(t: f64) f64 {
    const inv = 1.0 - t;
    return 1.0 - inv * inv * inv;
}

pub fn normalizeAngle(angle: f64) f64 {
    return @mod(angle, std.math.tau);
}
