const std = @import("std");

fn readInput(allocator: std.mem.Allocator, comptime filename: []const u8) ![2][]u32 {
    var list1 = std.ArrayList(u32).init(allocator);
    errdefer list1.deinit();
    var list2 = std.ArrayList(u32).init(allocator);
    errdefer list2.deinit();

    const cwd = std.fs.cwd();
    const input_file = try cwd.openFile(std.fmt.comptimePrint("day01/{s}", .{filename}), .{});
    defer input_file.close();

    const file_reader = input_file.reader();

    var buffer: [64]u8 = undefined;
    while (try file_reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var it = std.mem.tokenizeAny(u8, line, " ");
        var index: u8 = 0;
        while (it.next()) |item| {
            const number = try std.fmt.parseInt(u32, item, 10);
            if (index == 0) {
                try list1.append(number);
            } else if (index == 1) {
                try list2.append(number);
            } else unreachable;
            index += 1;
        }
    }

    return .{ try list1.toOwnedSlice(), try list2.toOwnedSlice() };
}

fn calculateTotalDistance(list1: []u32, list2: []u32) u32 {
    std.mem.sort(u32, list1, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, list2, {}, comptime std.sort.asc(u32));

    var sum: u32 = 0;
    return for (list1, list2) |e1, e2| {
        sum += @abs(@as(i32, @intCast(e1)) - @as(i32, @intCast(e2)));
    } else sum;
}

fn calculateSimilarityScore(allocator: std.mem.Allocator, list1: []u32, list2: []u32) !u32 {
    var map = std.AutoHashMap(u32, u16).init(allocator);
    defer map.deinit();

    for (list2) |l2| {
        if (map.contains(l2)) {
            try map.put(l2, map.get(l2).? + 1);
        } else {
            try map.put(l2, 1);
        }
    }

    var score: u32 = 0;
    return for (list1) |l1| {
        score += l1 * (map.get(l1) orelse 0);
    } else score;
}

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    const lists = try readInput(alloc, "inputs.txt");
    defer alloc.free(lists[0]);
    defer alloc.free(lists[1]);

    const total_distance = calculateTotalDistance(lists[0], lists[1]);
    std.debug.print("Total distance: {}\n", .{total_distance});

    const similarity_score = try calculateSimilarityScore(alloc, lists[0], lists[1]);
    std.debug.print("Similarity score: {}\n", .{similarity_score});
}

test "can calculate total distance" {
    var list1 = [_]u32{ 3, 4, 2, 1, 3, 3 };
    var list2 = [_]u32{ 4, 3, 5, 3, 9, 3 };
    const expected_distance = 11;
    const calculated_distance = calculateTotalDistance(&list1, &list2);
    try std.testing.expectEqual(expected_distance, calculated_distance);
}

test "can calculate similarity score" {
    const alloc = std.testing.allocator;
    var list1 = [_]u32{ 3, 4, 2, 1, 3, 3 };
    var list2 = [_]u32{ 4, 3, 5, 3, 9, 3 };
    const expected_score = 31;
    const calculated_score = calculateSimilarityScore(alloc, &list1, &list2);
    try std.testing.expectEqual(expected_score, calculated_score);
}
