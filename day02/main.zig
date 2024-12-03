const std = @import("std");

const Report = std.ArrayList(u8);
const Reports = std.ArrayList(Report);

fn parseInput(allocator: std.mem.Allocator, comptime filename: []const u8) !Reports {
    var reports = Reports.init(allocator);

    const cwd = std.fs.cwd();
    const input_file = try cwd.openFile(std.fmt.comptimePrint("day02/{s}", .{filename}), .{});
    defer input_file.close();

    const file_reader = input_file.reader();

    var buffer: [64]u8 = undefined;
    while (try file_reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var report = Report.init(allocator);
        var it = std.mem.tokenizeAny(u8, line, " ");
        while (it.next()) |item| {
            const number = try std.fmt.parseInt(u8, item, 10);
            try report.append(number);
        }
        try reports.append(report);
    }

    return reports;
}

fn isSafeSequence(first: u8, second: u8, previously_increasing: ?bool) bool {
    const diff = if (first >= second) first - second else second - first;
    if (diff < 1 or diff > 3) {
        return false;
    }

    const is_increasing = first < second;
    if (previously_increasing != null and previously_increasing.? != is_increasing) {
        return false;
    }

    return true;
}

fn isSafeReport(report: []u8) bool {
    if (report.len <= 1) return true;

    var previously_increasing: ?bool = null;

    var i: usize = 0;
    while (i < report.len - 1) : (i += 1) {
        const current = report[i];
        const next = report[i + 1];

        if (!isSafeSequence(current, next, previously_increasing)) return false;
        previously_increasing = current < next;
    }

    return true;
}

fn isSafeReportSplit(report_p1: []u8, report_p2: []u8) bool {
    var previously_increasing: ?bool = null;

    var combined_index: usize = 0;
    while (combined_index < (report_p1.len + report_p2.len - 1)) : (combined_index += 1) {
        const i = combined_index;
        const j = combined_index + 1;

        const current = if (i < report_p1.len) report_p1[i] else report_p2[i - report_p1.len];
        const next = if (j < report_p1.len) report_p1[j] else report_p2[j - report_p1.len];

        if (!isSafeSequence(current, next, previously_increasing)) return false;
        previously_increasing = current < next;
    }

    return true;
}

fn isSafeReportDampened(report: []u8) bool {
    if (isSafeReport(report)) {
        return true;
    }

    // Dampening: Remove any single level and check if it makes the report safe.
    // TODO: This can probably be improved by only checking potentially erroneous levels.
    var k: usize = 0;
    while (k < report.len) : (k += 1) {
        if (isSafeReportSplit(report[0..k], report[k + 1 ..])) {
            return true;
        }
    }

    return false;
}

fn countSafeReports(reports: *const Reports, comptime with_dampening: bool) usize {
    var safe_reports: usize = 0;
    return for (reports.items) |report| {
        const safety_check = comptime if (with_dampening) isSafeReportDampened else isSafeReport;
        if (safety_check(report.items)) {
            safe_reports += 1;
        }
    } else safe_reports;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const reports = try parseInput(arena.allocator(), "inputs.txt");

    const number_of_safe_reports = countSafeReports(&reports, false);
    std.debug.print("Number of safe reports: {}\n", .{number_of_safe_reports});

    const number_of_dampened_safe_reports = countSafeReports(&reports, true);
    std.debug.print(
        "Number of safe reports (with dampening): {}\n",
        .{number_of_dampened_safe_reports},
    );
}

test "check if reports are safe" {
    const input = [_][5]u8{
        [_]u8{ 7, 6, 4, 2, 1 },
        [_]u8{ 1, 2, 7, 8, 9 },
        [_]u8{ 9, 7, 6, 2, 1 },
        [_]u8{ 1, 3, 2, 4, 5 },
        [_]u8{ 8, 6, 4, 4, 1 },
        [_]u8{ 1, 3, 6, 7, 9 },
    };

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    var reports = std.ArrayList(std.ArrayList(u8)).init(alloc);
    for (input) |line| {
        const report = std.ArrayList(u8).fromOwnedSlice(alloc, try alloc.dupe(u8, &line));
        try reports.append(report);
    }

    try std.testing.expectEqual(2, countSafeReports(&reports, false));
    try std.testing.expectEqual(4, countSafeReports(&reports, true));
}
