const std = @import("std");

const mvzr = @import("mvzr.zig");

fn readInput(allocator: std.mem.Allocator, comptime filename: []const u8) ![]u8 {
    const cwd = std.fs.cwd();
    const input_file = try cwd.openFile(std.fmt.comptimePrint("day03/{s}", .{filename}), .{});
    defer input_file.close();

    const file_size = (try input_file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    errdefer allocator.free(buffer);

    _ = try input_file.readAll(buffer);
    return buffer;
}

const mul_regex = mvzr.compile(
    \\mul\(\d+,\d+\)
).?;
const mul_with_controls_regex = mvzr.compile(
    \\mul\(\d+,\d+\)|do\(\)|don't\(\)
).?;
const num_regex = mvzr.compile("\\d+").?;

fn addAllMultiplications(data: []const u8) !u32 {
    var sum: u32 = 0;

    var mul_it = mul_regex.iterator(data);
    while (mul_it.next()) |mul_match| {
        var multiplication_result: u32 = 1;
        var num_it = num_regex.iterator(mul_match.slice);
        while (num_it.next()) |num_match| {
            multiplication_result *= try std.fmt.parseInt(u32, num_match.slice, 10);
        }
        sum += multiplication_result;
    }
    return sum;
}

fn addEnabledMultiplications(data: []const u8) !u32 {
    var sum: u32 = 0;
    var enable_factor: u1 = 1;

    var mul_it = mul_with_controls_regex.iterator(data);
    while (mul_it.next()) |mul_match| {
        if (std.mem.eql(u8, mul_match.slice, "do()")) {
            enable_factor = 1;
            continue;
        } else if (std.mem.eql(u8, mul_match.slice, "don't()")) {
            enable_factor = 0;
            continue;
        }

        var multiplication_result: u32 = enable_factor;
        var num_it = num_regex.iterator(mul_match.slice);
        while (num_it.next()) |num_match| {
            multiplication_result *= try std.fmt.parseInt(u32, num_match.slice, 10);
        }
        sum += multiplication_result;
    }
    return sum;
}

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const data = try readInput(alloc, "inputs.txt");
    defer alloc.free(data);

    const result = try addAllMultiplications(data);
    std.debug.print("Sum of multiplications: {}\n", .{result});

    const result_considering_controls = try addEnabledMultiplications(data);
    std.debug.print("Sum of enabled multiplications: {}\n", .{result_considering_controls});
}

test "can get result from corrupted data" {
    const input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    const expected_result = 161;
    const result = try addAllMultiplications(input);
    try std.testing.expectEqual(expected_result, result);
}

test "can get result from corrupted data with control statements" {
    const input = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
    const expected_result = 48;
    const result = try addEnabledMultiplications(input);
    try std.testing.expectEqual(expected_result, result);
}
