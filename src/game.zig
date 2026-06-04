const std = @import("std");

pub const STARTING_BALANCE: i64 = 1000;

pub const Color = enum {
    red,
    black,

    pub fn label(self: Color) []const u8 {
        return switch (self) {
            .red => "Rouge",
            .black => "Noir",
        };
    }
};

pub const BetKind = union(enum) {
    straight: u8,
    color: Color,
    parity: Parity,
    range: Range,
    dozen: Dozen,
    column: Column,

    pub const Parity = enum {
        even,
        odd,

        pub fn label(self: Parity) []const u8 {
            return switch (self) {
                .even => "Pair",
                .odd => "Impair",
            };
        }
    };

    pub const Dozen = enum {
        first,
        second,
        third,

        pub fn label(self: Dozen) []const u8 {
            return switch (self) {
                .first => "1-12",
                .second => "13-24",
                .third => "25-36",
            };
        }
    };

    pub const Range = enum {
        low,
        high,

        pub fn label(self: Range) []const u8 {
            return switch (self) {
                .low => "1-18",
                .high => "19-36",
            };
        }
    };

    pub const Column = enum {
        first,
        second,
        third,

        pub fn label(self: Column) []const u8 {
            return switch (self) {
                .first => "Colonne 1",
                .second => "Colonne 2",
                .third => "Colonne 3",
            };
        }
    };
};

pub const Bet = struct {
    kind: BetKind,
    amount: i64,
};

pub const SpinOutcome = struct {
    number: u8,
    color: ?Color,
};

pub const SettleResult = struct {
    wagered: i64,
    returned: i64,
    profit: i64,
};

pub const GameState = struct {
    balance: i64 = STARTING_BALANCE,
    reserved: i64 = 0,
    bets: std.array_list.Managed(Bet),

    pub fn init(allocator: std.mem.Allocator) GameState {
        return .{
            .bets = std.array_list.Managed(Bet).init(allocator),
        };
    }

    pub fn deinit(self: *GameState) void {
        self.bets.deinit();
    }

    pub fn available(self: GameState) i64 {
        return self.balance - self.reserved;
    }

    pub fn clearBets(self: *GameState) void {
        self.bets.clearRetainingCapacity();
        self.reserved = 0;
    }

    pub fn reset(self: *GameState) void {
        self.balance = STARTING_BALANCE;
        self.clearBets();
    }

    pub fn addBet(self: *GameState, bet: Bet) !void {
        try validateBet(bet);
        if (bet.amount > self.available()) return error.InsufficientBalance;
        try self.bets.append(bet);
        self.reserved += bet.amount;
    }

    pub fn undoLastBet(self: *GameState) bool {
        const bet = self.bets.pop() orelse return false;
        self.reserved -= bet.amount;
        return true;
    }

    pub fn settle(self: *GameState, outcome: SpinOutcome) SettleResult {
        var wagered: i64 = 0;
        var returned: i64 = 0;

        for (self.bets.items) |bet| {
            wagered += bet.amount;
            if (wins(bet.kind, outcome)) {
                returned += bet.amount * (payoutMultiplier(bet.kind) + 1);
            }
        }

        self.balance = self.balance - wagered + returned;
        self.clearBets();

        return .{
            .wagered = wagered,
            .returned = returned,
            .profit = returned - wagered,
        };
    }
};

pub fn validateBet(bet: Bet) !void {
    if (bet.amount <= 0) return error.InvalidAmount;
    switch (bet.kind) {
        .straight => |n| if (n > 36) return error.InvalidNumber,
        else => {},
    }
}

pub fn outcomeForNumber(number: u8) SpinOutcome {
    return .{
        .number = number,
        .color = colorForNumber(number),
    };
}

pub fn colorForNumber(number: u8) ?Color {
    if (number == 0 or number > 36) return null;
    const red_numbers = [_]u8{ 1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36 };
    for (red_numbers) |red| {
        if (red == number) return .red;
    }
    return .black;
}

pub fn payoutMultiplier(kind: BetKind) i64 {
    return switch (kind) {
        .straight => 35,
        .color, .parity, .range => 1,
        .dozen, .column => 2,
    };
}

pub fn wins(kind: BetKind, outcome: SpinOutcome) bool {
    const number = outcome.number;
    if (number > 36) return false;

    return switch (kind) {
        .straight => |wanted| wanted == number,
        .color => |wanted| if (outcome.color) |actual| actual == wanted else false,
        .parity => |wanted| number != 0 and switch (wanted) {
            .even => number % 2 == 0,
            .odd => number % 2 == 1,
        },
        .range => |wanted| switch (wanted) {
            .low => number >= 1 and number <= 18,
            .high => number >= 19 and number <= 36,
        },
        .dozen => |wanted| switch (wanted) {
            .first => number >= 1 and number <= 12,
            .second => number >= 13 and number <= 24,
            .third => number >= 25 and number <= 36,
        },
        .column => |wanted| number != 0 and switch (wanted) {
            .first => (number - 1) % 3 == 0,
            .second => (number - 2) % 3 == 0,
            .third => number % 3 == 0,
        },
    };
}

pub fn betLabel(buf: []u8, bet: Bet) []const u8 {
    return switch (bet.kind) {
        .straight => |n| std.fmt.bufPrint(buf, "Plein {d}: {d}", .{ n, bet.amount }) catch "",
        .color => |color| std.fmt.bufPrint(buf, "{s}: {d}", .{ color.label(), bet.amount }) catch "",
        .parity => |parity| std.fmt.bufPrint(buf, "{s}: {d}", .{ parity.label(), bet.amount }) catch "",
        .range => |range| std.fmt.bufPrint(buf, "{s}: {d}", .{ range.label(), bet.amount }) catch "",
        .dozen => |dozen| std.fmt.bufPrint(buf, "Douzaine {s}: {d}", .{ dozen.label(), bet.amount }) catch "",
        .column => |column| std.fmt.bufPrint(buf, "{s}: {d}", .{ column.label(), bet.amount }) catch "",
    };
}

test "straight number pays 35 to 1 plus stake" {
    var state = GameState.init(std.testing.allocator);
    defer state.deinit();

    try state.addBet(.{ .kind = .{ .straight = 17 }, .amount = 10 });
    const result = state.settle(outcomeForNumber(17));

    try std.testing.expectEqual(@as(i64, 10), result.wagered);
    try std.testing.expectEqual(@as(i64, 360), result.returned);
    try std.testing.expectEqual(@as(i64, 1350), state.balance);
}

test "zero loses color and parity bets" {
    var state = GameState.init(std.testing.allocator);
    defer state.deinit();

    try state.addBet(.{ .kind = .{ .color = .red }, .amount = 20 });
    try state.addBet(.{ .kind = .{ .parity = .even }, .amount = 20 });
    const result = state.settle(outcomeForNumber(0));

    try std.testing.expectEqual(@as(i64, 40), result.wagered);
    try std.testing.expectEqual(@as(i64, 0), result.returned);
    try std.testing.expectEqual(@as(i64, 960), state.balance);
}

test "low and high range bets pay 1 to 1 and lose on zero" {
    var state = GameState.init(std.testing.allocator);
    defer state.deinit();

    try state.addBet(.{ .kind = .{ .range = .low }, .amount = 25 });
    try state.addBet(.{ .kind = .{ .range = .high }, .amount = 25 });
    const result = state.settle(outcomeForNumber(18));

    try std.testing.expectEqual(@as(i64, 50), result.wagered);
    try std.testing.expectEqual(@as(i64, 50), result.returned);
    try std.testing.expectEqual(@as(i64, 1000), state.balance);

    try state.addBet(.{ .kind = .{ .range = .low }, .amount = 10 });
    const zero_result = state.settle(outcomeForNumber(0));
    try std.testing.expectEqual(@as(i64, 10), zero_result.wagered);
    try std.testing.expectEqual(@as(i64, 0), zero_result.returned);
    try std.testing.expectEqual(@as(i64, 990), state.balance);
}

test "dozen and column wins settle together" {
    var state = GameState.init(std.testing.allocator);
    defer state.deinit();

    try state.addBet(.{ .kind = .{ .dozen = .second }, .amount = 30 });
    try state.addBet(.{ .kind = .{ .column = .first }, .amount = 15 });
    const result = state.settle(outcomeForNumber(22));

    try std.testing.expectEqual(@as(i64, 45), result.wagered);
    try std.testing.expectEqual(@as(i64, 135), result.returned);
    try std.testing.expectEqual(@as(i64, 1090), state.balance);
}

test "invalid and over balance bets are rejected" {
    var state = GameState.init(std.testing.allocator);
    defer state.deinit();

    try std.testing.expectError(error.InvalidAmount, state.addBet(.{ .kind = .{ .straight = 1 }, .amount = 0 }));
    try std.testing.expectError(error.InvalidNumber, state.addBet(.{ .kind = .{ .straight = 37 }, .amount = 10 }));
    try std.testing.expectError(error.InsufficientBalance, state.addBet(.{ .kind = .{ .color = .black }, .amount = 2000 }));
}

test "reset restores balance and clears active bets" {
    var state = GameState.init(std.testing.allocator);
    defer state.deinit();

    try state.addBet(.{ .kind = .{ .color = .black }, .amount = 100 });
    state.reset();

    try std.testing.expectEqual(@as(i64, STARTING_BALANCE), state.balance);
    try std.testing.expectEqual(@as(i64, 0), state.reserved);
    try std.testing.expectEqual(@as(usize, 0), state.bets.items.len);
}

test "undo last bet restores available balance" {
    var state = GameState.init(std.testing.allocator);
    defer state.deinit();

    try state.addBet(.{ .kind = .{ .color = .red }, .amount = 40 });
    try state.addBet(.{ .kind = .{ .straight = 7 }, .amount = 15 });

    try std.testing.expectEqual(@as(i64, 55), state.reserved);
    try std.testing.expect(state.undoLastBet());
    try std.testing.expectEqual(@as(i64, 40), state.reserved);
    try std.testing.expectEqual(@as(usize, 1), state.bets.items.len);
    try std.testing.expect(state.undoLastBet());
    try std.testing.expectEqual(@as(i64, 0), state.reserved);
    try std.testing.expect(!state.undoLastBet());
}
