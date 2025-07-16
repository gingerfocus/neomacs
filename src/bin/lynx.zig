const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const a = gpa.allocator();

    // var client = std.http.Client{ .allocator = a };
    // defer client.deinit();
    //
    // var buf = std.ArrayList(u8).init(a);
    // defer buf.deinit();
    // const res = try client.fetch(.{
    //     .response_storage = .{ .dynamic = &buf },
    //     .location = .{ .url = "https://example.com" },
    // });
    // _ = &res;
    //
    // std.debug.print("before: {s}\n", .{buf.items});

    const markdown = try http2md(a, examplecom);

    std.debug.print("before: {s}\n", .{markdown});
}

const examplecom: []const u8 =
    \\<!doctype html>
    \\<html>
    \\<head>
    \\    <title>Example Domain</title>
    \\
    \\    <meta charset="utf-8" />
    \\    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    \\    <meta name="viewport" content="width=device-width, initial-scale=1" />
    \\    <style type="text/css">
    \\    body {
    \\        background-color: #f0f0f2;
    \\        margin: 0;
    \\        padding: 0;
    \\        font-family: -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", "Open Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;
    \\
    \\    }
    \\    div {
    \\        width: 600px;
    \\        margin: 5em auto;
    \\        padding: 2em;
    \\        background-color: #fdfdff;
    \\        border-radius: 0.5em;
    \\        box-shadow: 2px 3px 7px 2px rgba(0,0,0,0.02);
    \\    }
    \\    a:link, a:visited {
    \\        color: #38488f;
    \\        text-decoration: none;
    \\    }
    \\    @media (max-width: 700px) {
    \\        div {
    \\            margin: 0 auto;
    \\            width: auto;
    \\        }
    \\    }
    \\    </style>
    \\</head>
    \\
    \\<body>
    \\<div>
    \\    <h1>Example Domain</h1>
    \\    <p>This domain is for use in illustrative examples in documents. You may use this
    \\    domain in literature without prior coordination or asking for permission.</p>
    \\    <p><a href="https://www.iana.org/domains/example">More information...</a></p>
    \\</div>
    \\</body>
    \\</html>
;
const HtmlTag = enum {
    head,
    a,
    h1,
    p,

    const maxlen = 50;
};
// const HtmlState = struct {
//     tagstack: std.ArrayList([]const u8),
// };

const Iter = struct {
    items: []const u8,
    index: usize,

    pub fn peek(self: *const Iter) ?u8 {
        if (self.index < self.items.len) return self.index[self.index];
        return null;
    }

    pub fn next(self: *Iter) ?u8 {
        const item = self.peek();
        self.index += 1;
        return item;
    }

    // pub fn get(self: *const Iter) ?u8 {}
};

pub fn http2md(
    a: std.mem.Allocator,
    input: []const u8,
) ![]const u8 {
    var buf = std.ArrayList(u8).init(a);
    defer buf.deinit();

    var iter = Iter{ .items = input, .index = 0 };

    loop: while (iter.next()) |c| {
        const i = iter.index;

        skipwhitespace(&iter);

        std.debug.assert(c == '<');

        const endindex = iter.index + HtmlTag.maxlen;
        var j = iter.index;
        while (j < endindex and j < input.len) : (j += 1) {
            if (input[j] == '>') {
                std.debug.print("tag: {s}\n", .{input[i + 1 .. j]});
                i = j;
                continue :loop;
            }
        }
        // open tag
    }

    return buf.toOwnedSlice();
}

pub fn skipwhitespace(iter: *Iter) void {
    while (iter.peek()) |c| {
        if (c != ' ') break;
        _ = iter.next();
    }
}
