const std = @import("std");

const Rule = [2]u8;
const Update = []u8;
const ConstUpdate = []const u8;

fn parseInput(allocator: std.mem.Allocator, comptime filename: []const u8) !struct { //
    std.ArrayList(Rule),
    std.ArrayList(Update),
} {
    var rules = std.ArrayList(Rule).init(allocator);
    var updates = std.ArrayList(Update).init(allocator);
    errdefer rules.deinit();
    errdefer updates.deinit();

    const cwd = std.fs.cwd();
    const input_file = try cwd.openFile(std.fmt.comptimePrint("day05/{s}", .{filename}), .{});
    defer input_file.close();

    var in_rules_section = true;

    const file_reader = input_file.reader();
    var buffer: [128]u8 = undefined;
    while (try file_reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (std.mem.eql(u8, line, "")) {
            in_rules_section = false;
            continue;
        }

        if (in_rules_section) {
            // Simple assumption which holds for our data: Rules always look like XX|YY
            try rules.append(Rule{
                try std.fmt.parseInt(u8, line[0..2], 10),
                try std.fmt.parseInt(u8, line[3..], 10),
            });
        } else {
            var pages = std.ArrayList(u8).init(allocator);
            errdefer pages.deinit();

            var it = std.mem.tokenizeScalar(u8, line, ',');
            while (it.next()) |page| {
                try pages.append(try std.fmt.parseInt(u8, page, 10));
            }

            try updates.append(try pages.toOwnedSlice());
        }
    }
    return .{ rules, updates };
}

fn isValid(update: ConstUpdate, rules: []const Rule) bool {
    for (rules) |rule| {
        var rule_check = [2]?usize{ null, null };
        for (update, 0..) |page, idx| {
            if (page == rule[0]) {
                rule_check[0] = idx;
            } else if (page == rule[1]) {
                rule_check[1] = idx;
            }
        }

        if (rule_check[0] == null or rule_check[1] == null) continue; // Rule does not apply.
        if (rule_check[0].? >= rule_check[1].?) return false;
    }
    return true;
}

fn calculateMiddlePageNumberSum(updates: []const ConstUpdate, rules: []const Rule) u32 {
    var sum: u32 = 0;
    return for (updates) |update| {
        if (isValid(update, rules)) sum += update[update.len / 2];
    } else sum;
}

fn fixInvalidUpdate(update: Update, rules: []const Rule) void {
    validity_check: while (!isValid(update, rules)) {
        for (rules) |rule| {
            var rule_check = [2]?usize{ null, null };
            for (update, 0..) |page, idx| {
                if (page == rule[0]) {
                    rule_check[0] = idx;
                } else if (page == rule[1]) {
                    rule_check[1] = idx;
                }
            }

            if (rule_check[0] == null or rule_check[1] == null) continue; // Rule does not apply.
            if (rule_check[0].? >= rule_check[1].?) {
                // Swap indices.
                const tmp = update[rule_check[0].?];
                update[rule_check[0].?] = update[rule_check[1].?];
                update[rule_check[1].?] = tmp;
                continue :validity_check;
            }
        }
    }
}

fn calculateFixedMiddlePageNumberSum(updates: []Update, rules: []const Rule) u32 {
    var sum: u32 = 0;
    return for (updates) |update| {
        if (isValid(update, rules)) continue;
        fixInvalidUpdate(update, rules);
        sum += update[update.len / 2];
    } else sum;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    defer std.debug.print("Task took {} ms to complete.", .{timer.read() / std.time.ns_per_ms});

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const rules, const updates = try parseInput(arena.allocator(), "inputs.txt");

    const middle_page_number_sum = calculateMiddlePageNumberSum(updates.items, rules.items);
    std.debug.print("Sum of middle pages: {}\n", .{middle_page_number_sum});
    const fixed_middle_page_number_sum = //
        calculateFixedMiddlePageNumberSum(updates.items, rules.items);
    std.debug.print("Sum of fixed middle pages: {}\n", .{fixed_middle_page_number_sum});
}

test "can detect if update is valid" {
    const rules = [_]Rule{
        Rule{ 47, 53 }, Rule{ 97, 13 }, Rule{ 97, 61 }, Rule{ 97, 47 }, Rule{ 75, 29 }, //
        Rule{ 61, 13 }, Rule{ 75, 53 }, Rule{ 29, 13 }, Rule{ 97, 29 }, Rule{ 53, 29 }, //
        Rule{ 61, 53 }, Rule{ 97, 53 }, Rule{ 61, 29 }, Rule{ 47, 13 }, Rule{ 75, 47 }, //
        Rule{ 97, 75 }, Rule{ 47, 61 }, Rule{ 75, 61 }, Rule{ 47, 29 }, Rule{ 75, 13 }, //
        Rule{ 53, 13 },
    };

    const valid_updates = [_][5]u8{
        [_]u8{ 75, 47, 61, 53, 29 },
        [_]u8{ 97, 61, 53, 29, 13 },
    };

    const invalid_updates = [_][5]u8{
        [_]u8{ 75, 97, 47, 61, 53 },
        [_]u8{ 97, 13, 75, 29, 47 },
    };

    for (valid_updates) |update| {
        try std.testing.expect(isValid(&update, &rules));
    }

    for (invalid_updates) |update| {
        try std.testing.expect(!isValid(&update, &rules));
    }
}

test "can calculate sum of middle page numbers" {
    const rules = [_]Rule{ Rule{ 47, 53 }, Rule{ 97, 13 }, Rule{ 97, 61 }, Rule{ 97, 75 } };
    const updates = [_][5]u8{
        [_]u8{ 75, 47, 61, 53, 29 }, // valid
        [_]u8{ 75, 97, 47, 61, 53 }, // invalid
        [_]u8{ 97, 61, 53, 29, 13 }, // valid
    };
    const updates_slice = blk: {
        const slice = [_][]const u8{ &updates[0], &updates[1], &updates[2] };
        break :blk slice;
    };

    const expected_sum = updates[0][2] + updates[2][2];
    const calculated_sum = calculateMiddlePageNumberSum(&updates_slice, &rules);
    try std.testing.expectEqual(expected_sum, calculated_sum);
}

test "can calculate sum of middle page numbers of fixed updates" {
    const rules = [_]Rule{
        Rule{ 47, 53 }, Rule{ 97, 13 }, Rule{ 97, 61 }, Rule{ 97, 47 }, Rule{ 75, 29 }, //
        Rule{ 61, 13 }, Rule{ 75, 53 }, Rule{ 29, 13 }, Rule{ 97, 29 }, Rule{ 53, 29 }, //
        Rule{ 61, 53 }, Rule{ 97, 53 }, Rule{ 61, 29 }, Rule{ 47, 13 }, Rule{ 75, 47 }, //
        Rule{ 97, 75 }, Rule{ 47, 61 }, Rule{ 75, 61 }, Rule{ 47, 29 }, Rule{ 75, 13 }, //
        Rule{ 53, 13 },
    };
    var updates = [_][5]u8{
        [_]u8{ 75, 47, 61, 53, 29 }, // valid
        [_]u8{ 97, 61, 53, 29, 13 }, // valid
        [_]u8{ 75, 97, 47, 61, 53 }, // invalid: fixed will have 47 as the middle page number
        [_]u8{ 97, 13, 75, 29, 47 }, // invalid: fixed will have 47 as the middle page number
    };
    var updates_slice = blk: {
        const slice = [_][]u8{ &updates[0], &updates[1], &updates[2], &updates[3] };
        break :blk slice;
    };

    const expected_sum = 47 + 47;
    const calculated_sum = calculateFixedMiddlePageNumberSum(&updates_slice, &rules);
    try std.testing.expectEqual(expected_sum, calculated_sum);
}
