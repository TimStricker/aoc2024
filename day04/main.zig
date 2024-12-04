const std = @import("std");

const StringList = std.ArrayList([]const u8);
const Direction = enum { UP, RIGHT, DOWN, LEFT, UP_RIGHT, DOWN_RIGHT, DOWN_LEFT, UP_LEFT };

fn parseInput(allocator: std.mem.Allocator, comptime filename: []const u8) !StringList {
    var data = StringList.init(allocator);
    errdefer data.deinit();

    const cwd = std.fs.cwd();
    const input_file = try cwd.openFile(std.fmt.comptimePrint("day04/{s}", .{filename}), .{});
    defer input_file.close();

    const file_reader = input_file.reader();

    var buffer: [256]u8 = undefined;
    while (try file_reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        try data.append(try allocator.dupe(u8, line));
    }
    return data;
}
fn findXmas(input: []const []const u8, i: usize, j: usize, dir: Direction) bool {
    std.debug.assert(input[i][j] == 'X');

    const minimum_padding = 3;
    const padding_is_sufficient = switch (dir) {
        .UP => i >= minimum_padding,
        .RIGHT => (input[0].len - j) > minimum_padding,
        .DOWN => (input.len - i) > minimum_padding,
        .LEFT => j >= minimum_padding,
        .UP_RIGHT => i >= minimum_padding and (input[0].len - j) > minimum_padding,
        .DOWN_RIGHT => (input.len - i) > minimum_padding and (input[0].len - j) > minimum_padding,
        .DOWN_LEFT => (input.len - i) > minimum_padding and j >= minimum_padding,
        .UP_LEFT => i >= minimum_padding and j >= minimum_padding,
    };

    if (!padding_is_sufficient) return false;

    var next_i = i;
    var next_j = j;
    for ("MAS") |character| {
        next_i = switch (dir) {
            .UP, .UP_LEFT, .UP_RIGHT => next_i - 1,
            .DOWN, .DOWN_LEFT, .DOWN_RIGHT => next_i + 1,
            else => next_i,
        };
        next_j = switch (dir) {
            .LEFT, .UP_LEFT, .DOWN_LEFT => next_j - 1,
            .RIGHT, .UP_RIGHT, .DOWN_RIGHT => next_j + 1,
            else => next_j,
        };
        if (input[next_i][next_j] != character) return false;
    }
    return true;
}

fn countXmasAround(input: []const []const u8, i: usize, j: usize) usize {
    if (input[i][j] != 'X') return 0;

    var counter: usize = 0;
    return inline for (std.meta.fields(Direction)) |direction_field| {
        const dir = @as(Direction, @enumFromInt(direction_field.value));
        counter += if (findXmas(input, i, j, dir)) 1 else 0;
    } else counter;
}

fn countXmas(input: []const []const u8) usize {
    var counter: usize = 0;
    return for (input, 0..) |line, i| {
        for (0..line.len) |j| {
            counter += countXmasAround(input, i, j);
        }
    } else counter;
}

fn countXmasPart2(input: []const []const u8) usize {
    var counter: usize = 0;
    return for (input, 0..) |line, i| {
        for (0..line.len) |j| {
            if (line[j] != 'A') continue;
            if (i <= 0 or i >= (input.len - 1) or j <= 0 or j >= (line.len - 1)) continue;

            const first_diagonal_valid = ( //
                (input[i - 1][j - 1] == 'M' and input[i + 1][j + 1] == 'S') or //
                (input[i - 1][j - 1] == 'S' and input[i + 1][j + 1] == 'M'));
            const second_diagonal_valid = ( //
                (input[i + 1][j - 1] == 'M' and input[i - 1][j + 1] == 'S') or //
                (input[i + 1][j - 1] == 'S' and input[i - 1][j + 1] == 'M'));
            if (first_diagonal_valid and second_diagonal_valid) counter += 1;
        }
    } else counter;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    defer std.debug.print("Task took {} ms to complete.", .{timer.read() / std.time.ns_per_ms});

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const alloc = arena.allocator();
    const input_data = try parseInput(alloc, "inputs.txt");

    const xmas_count = countXmas(input_data.items);
    std.debug.print(("Number of 'XMAS' occurrences: {}\n"), .{xmas_count});

    const xmas_count_p2 = countXmasPart2(input_data.items);
    std.debug.print(("Number of 'X-MAS' occurrences: {}\n"), .{xmas_count_p2});
}

test "can count xmas occurrences" {
    const input = [_][]const u8{
        "MMMSXXMASM",
        "MSAMXMSMSA",
        "AMXSXMAAMM",
        "MSAMASMSMX",
        "XMASAMXAMM",
        "XXAMMXXAMA",
        "SMSMSASXSS",
        "SAXAMASAAA",
        "MAMMMXMMMM",
        "MXMXAXMASX",
    };

    const expected_result_p1 = 18;
    const actual_result_p1 = countXmas(&input);
    try std.testing.expectEqual(expected_result_p1, actual_result_p1);

    const expected_result_p2 = 9;
    const actual_result_p2 = countXmasPart2(&input);
    try std.testing.expectEqual(expected_result_p2, actual_result_p2);
}
