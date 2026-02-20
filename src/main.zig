const std = @import("std");
const builtin = @import("builtin");

fn errprint(comptime fmt: []const u8, args: anytype) void {
    if (builtin.mode == .Debug)
        std.debug.print(fmt, args);
}

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    var prompt: std.DoublyLinkedList = .{};

    const L = struct {
        data: []const u8,
        node: std.DoublyLinkedList.Node = .{},
    };

    // cwd

    var cwd: L = .{ .data = "%F{6}%~%f" };
    prompt.append(&cwd.node);

    // work out hostname

    var hostname: []const u8 = undefined;

    var arena: std.heap.ArenaAllocator = .init(allocator);
    defer arena.deinit();

    if (env_map.get("HOST")) |result| {
        hostname = result;
    } else {
        errprint("$HOST not set, falling back to /etc/hostname\n", .{});

        const hostname_file = try std.fs.openFileAbsolute("/etc/hostname", .{ .mode = .read_only });

        const content = try hostname_file.readToEndAlloc(arena.allocator(), 1024);
        // defer allocator.free(content);

        if (content[content.len - 1] == '\n') {
            hostname = content[0 .. content.len - 1];
        }
    }

    errprint("hostname: {s}\n", .{hostname});

    if (std.mem.eql(u8, hostname, "localhost")) {
        errprint("hostname ambiguous! checking other sources\n", .{});

        // read hostname from ~/.termux/hostname if applicable
        if (env_map.get("HOME")) |home_dir| {
            const buf = try allocator.alloc(u8, home_dir.len + 32);
            allocator.free(buf);

            const termux_hostname_file = try std.fs.openFileAbsolute(try std.fmt.bufPrint(buf, "{s}/.termux/hostname", .{home_dir}), .{ .mode = .read_only });

            hostname = try termux_hostname_file.readToEndAlloc(arena.allocator(), 1024);
        }

        const buf = try allocator.alloc(u8, hostname.len + 16);
        allocator.free(buf);

        var host: L = .{ .data = try std.fmt.bufPrint(buf, "%F{{1}}{s}%f", .{hostname}) };
        prompt.prepend(&host.node);
    } else {
        const buf = try allocator.alloc(u8, hostname.len + 16);
        allocator.free(buf);

        var host: L = .{ .data = try std.fmt.bufPrint(buf, "%F{{1}}{s}%f", .{hostname}) };
        prompt.prepend(&host.node);
    }

    // username

    var name: L = .{ .data = "%F{2}%n%f" };
    prompt.prepend(&name.node);

    // shell info

    if (env_map.get("IS_NIX_SHELL")) |_| {
        errprint("is in nix shell\n", .{});
        var nix: L = .{ .data = "%F{4}nix-shell%f" };
        prompt.prepend(&nix.node);
    } else errprint("is not in nix shell\n", .{});

    if (env_map.get("IS_TOR_SHELL")) |_| {
        errprint("is in tor shell\n", .{});
        var tor: L = .{ .data = "%F{13}tor-shell%f" };
        prompt.prepend(&tor.node);
    } else errprint("is not in tor shell\n", .{});

    // if (env_map.get("HOST")) |hostname| {
    //     std.debug.print("got hostname {s}\n", .{hostname});

    //     if (std.mem.eql(u8, hostname, "localhost")) {
    //         std.debug.print("checking alternative sources for hostname\n", .{});
    //     } else {
    //         var name: L = .{ .data = "%F{13}tor-shell%f" };
    //         prompt.prepend(&name.node);
    //     }
    // }

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    var stdout = &stdout_writer.interface;

    // print prompt

    // opening character
    try stdout.print("[", .{});

    // iterate over segments with pipes in between
    var it = prompt.first;

    while (it) |node| : (it = node.next) {
        const l: *L = @fieldParentPtr("node", node);
        try stdout.print("{s}", .{l.data});
        if (node.next) |_| {
            try stdout.print("|", .{});
        }
    }

    // closing sequence

    try stdout.print("]> ", .{});

    try stdout.flush();
}
