const std = @import("std");

const LabMap = std.ArrayList(std.ArrayList(u8));
const Position = struct { x: usize, y: usize };
const GuardState = struct { position: Position, direction: u8 };
const StepResult = enum { TOOK_STEP, LEFT_MAP };

const VisitsPerPosition = std.AutoHashMap(Position, u3);

fn parseInput(allocator: std.mem.Allocator, comptime filename: []const u8) !LabMap {
    var map = LabMap.init(allocator);
    errdefer map.deinit();

    const cwd = std.fs.cwd();
    const input_file = try cwd.openFile(std.fmt.comptimePrint("day06/{s}", .{filename}), .{});
    defer input_file.close();

    const file_reader = input_file.reader();

    var buffer: [256]u8 = undefined;
    while (try file_reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var map_row = std.ArrayList(u8).init(allocator);
        try map_row.appendSlice(try allocator.dupe(u8, line));
        try map.append(map_row);
    }
    return map;
}

fn is_obstacle(map: LabMap, location: Position) bool {
    return map.items[location.x].items[location.y] == '#';
}

fn compute_new_state(map: LabMap, state: GuardState) ?GuardState {
    const rows = map.items.len;
    const cols = map.items[0].items.len;

    var new_position: Position = undefined;
    switch (state.direction) {
        '^' => {
            if (state.position.x == 0) return null;
            new_position = Position{ .x = state.position.x - 1, .y = state.position.y };
            if (is_obstacle(map, new_position)) {
                return compute_new_state(map, .{ .position = state.position, .direction = '>' });
            }
        },
        '>' => {
            if (state.position.y >= cols - 1) return null;
            new_position = Position{ .x = state.position.x, .y = state.position.y + 1 };
            if (is_obstacle(map, new_position)) {
                return compute_new_state(map, .{ .position = state.position, .direction = 'v' });
            }
        },
        'v' => {
            if (state.position.x >= rows - 1) return null;
            new_position = Position{ .x = state.position.x + 1, .y = state.position.y };
            if (is_obstacle(map, new_position)) {
                return compute_new_state(map, .{ .position = state.position, .direction = '<' });
            }
        },
        '<' => {
            if (state.position.y == 0) return null;
            new_position = Position{ .x = state.position.x, .y = state.position.y - 1 };
            if (is_obstacle(map, new_position)) {
                return compute_new_state(map, .{ .position = state.position, .direction = '^' });
            }
        },
        else => unreachable,
    }
    return .{ .position = new_position, .direction = state.direction };
}

fn take_step(map: *LabMap, state: *GuardState) StepResult {
    if (compute_new_state(map.*, state.*)) |new_state| {
        map.items[state.position.x].items[state.position.y] = 'X';
        map.items[new_state.position.x].items[new_state.position.y] = new_state.direction;
        state.* = new_state;
        return StepResult.TOOK_STEP;
    }
    return StepResult.LEFT_MAP;
}

fn get_initial_state(map: LabMap) ?GuardState {
    for (map.items, 0..) |row, x| {
        for (row.items, 0..) |element, y| {
            if (std.mem.indexOfScalar(u8, "^>v<", element) != null) {
                return .{ .position = .{ .x = x, .y = y }, .direction = element };
            }
        }
    }
    return null;
}

fn count_unique_positions(map: LabMap) u32 {
    var count: u32 = 0;
    return for (map.items) |row| {
        for (row.items) |element| {
            if (element == 'X') count += 1;
        }
    } else count;
}

fn copyMap(allocator: std.mem.Allocator, map: LabMap) !LabMap {
    var new_map = LabMap.init(allocator);
    for (map.items) |row| {
        var new_row = std.ArrayList(u8).init(allocator);
        try new_row.appendSlice(row.items);
        try new_map.append(new_row);
    }
    return new_map;
}

fn simulateMovement(map: *LabMap) u32 {
    var state = get_initial_state(map.*) orelse unreachable;
    while (take_step(map, &state) != StepResult.LEFT_MAP) {}
    map.items[state.position.x].items[state.position.y] = 'X'; // Add final state.
    return count_unique_positions(map.*);
}

fn hasLoop(allocator: std.mem.Allocator, map: *LabMap) !bool {
    var encountered_states = std.AutoHashMap(GuardState, void).init(allocator);
    defer encountered_states.deinit();

    var state = get_initial_state(map.*) orelse unreachable;
    try encountered_states.put(state, {});

    while (take_step(map, &state) != StepResult.LEFT_MAP) {
        if (encountered_states.contains(state)) return true;
        try encountered_states.put(state, {});
    }

    return false;
}

// TODO: There's probably a better way to solve this, the brute-force approach is quite inefficient.
fn createLoops(allocator: std.mem.Allocator, original_map: LabMap) !u32 {
    var count: u32 = 0;
    return for (original_map.items, 0..) |row, x| {
        for (row.items, 0..) |element, y| {
            if (element == '#') continue; // Already an obstacle.
            if (std.mem.indexOfScalar(u8, "^>v<", element) != null) continue; // Guard position.

            var new_map = try copyMap(allocator, original_map);
            defer new_map.deinit();

            new_map.items[x].items[y] = '#'; // Place obstacle.
            if (try hasLoop(allocator, &new_map)) count += 1;
        }
    } else count;
}

fn printMap(map: LabMap) void {
    for (map.items) |row| {
        for (row.items) |element| {
            std.debug.print("{c} ", .{element});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    defer std.debug.print("Task took {} ms to complete.\n", .{timer.read() / std.time.ns_per_ms});

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    const original_map = try parseInput(allocator, "inputs.txt");

    var part1_map = try copyMap(allocator, original_map);
    const unique_positions = simulateMovement(&part1_map);
    std.debug.print("Number of visited unique positions: {}\n", .{unique_positions});

    const possible_loops = try createLoops(allocator, original_map);
    std.debug.print("Number of possible loops: {}\n", .{possible_loops});
}

test "can parse input" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const expected_result = [_][]const u8{
        "....#.....",
        ".........#",
        "..........",
        "..#.......",
        ".......#..",
        "..........",
        ".#..^.....",
        "........#.",
        "#.........",
        "......#...",
    };

    const allocator = arena.allocator();
    const input = try parseInput(allocator, "inputs_test.txt");

    for (input.items, 0..) |map_row, index| {
        try std.testing.expect(std.mem.eql(u8, expected_result[index], map_row.items));
    }
}

test "can count number of visited unique positions" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var map = try parseInput(allocator, "inputs_test.txt");
    const actual_count = simulateMovement(&map);

    const expected_count = 41;
    try std.testing.expectEqual(expected_count, actual_count);
}

test "can copy map" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const map = try parseInput(allocator, "inputs_test.txt");
    const copied_map = try copyMap(allocator, map);

    for (map.items, copied_map.items) |map_row, copied_row| {
        try std.testing.expect(std.mem.eql(u8, map_row.items, copied_row.items));
    }
}

test "can create loops" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const map = try parseInput(allocator, "inputs_test.txt");

    const expected_possible_loops = 6;
    const created_loops = try createLoops(allocator, map);
    try std.testing.expectEqual(expected_possible_loops, created_loops);
}
