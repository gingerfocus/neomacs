const std = @import("std");
const root = @import("../root.zig");
const km = root.km;
const trm = root.trm;
const lib = root.lib;

const Buffer = root.Buffer;

const State = root.State;

const norm = trm.keys.norm;
const ctrl = trm.keys.ctrl;

const keys = @import("root.zig");

const Ks = trm.KeySymbol;

const ModeId = km.ModeId;

pub fn init(a: std.mem.Allocator, modes: *km.Keymap) !void {
    var normal = modes.appender(km.ModeId.Normal);
    normal.targeter(km.KeyFunction.initstate(keys.actions.move));

    try initToInsertKeys(a, &normal);
    try initToVisualKeys(a, &normal);
    try initMotionKeys(a, &normal);
    try initModifyingKeys(a, &normal);
    // try initNormalKeys(a, &normal);
}

fn initToInsertKeys(a: std.mem.Allocator, normal: *km.Keymap.Appender) !void {
    try normal.put(a, norm('i'), km.KeyFunction.initstate(inserts.before));
    try normal.put(a, norm('I'), km.KeyFunction.initstate(inserts.start));
    try normal.put(a, norm('a'), km.KeyFunction.initstate(inserts.after));
    try normal.put(a, norm('A'), km.KeyFunction.initstate(inserts.end));
    try normal.put(a, norm('o'), km.KeyFunction.initstate(inserts.below));
    try normal.put(a, norm('O'), km.KeyFunction.initstate(inserts.above));
}

fn initToVisualKeys(a: std.mem.Allocator, normal: *km.Keymap.Appender) !void {
    try normal.put(a, norm('v'), km.KeyFunction.initstate(visuals.set(.Range)));
    try normal.put(a, norm('V'), km.KeyFunction.initstate(visuals.set(.Line)));
    try normal.put(a, ctrl('v'), km.KeyFunction.initstate(visuals.set(.Block)));
}

pub fn initMotionKeys(a: std.mem.Allocator, maps: *km.Keymap.Appender) !void {
    std.log.info("prefix: {any}", .{maps.curprefix});

    // arrow keys?
    try maps.put(a, norm('j'), km.KeyFunction.initstate(targeters.target_down_linewise));
    try maps.put(a, norm('k'), km.KeyFunction.initstate(targeters.target_up_linewise));
    try maps.put(a, norm('l'), km.KeyFunction.initstate(targeters.target_right));
    try maps.put(a, norm('h'), km.KeyFunction.initstate(targeters.target_left));

    try maps.put(a, norm('G'), km.KeyFunction.initstate(targeters.target_bottom));
    try maps.put(a, '$', km.KeyFunction.initstate(motions.end_of_line));
    try maps.put(a, '0', km.KeyFunction.initstate(targeters.motion_start));

    try maps.put(a, norm('w'), km.KeyFunction.initstate(targeters.motion_word_start));
    // try maps.put(a, norm('W'), km.KeyFunction.initstate(targeters.motion_WORD_start));
    try maps.put(a, norm('e'), km.KeyFunction.initstate(targeters.motion_word_end));
    // try maps.put(a, norm('E'), km.KeyFunction.initstate(targeters.motion_WORD_end));
    try maps.put(a, norm('b'), km.KeyFunction.initstate(targeters.motion_word_back));
    // try maps.put(a, norm('B'), km.KeyFunction.initstate(targeters.motion_WORD_back));

    var f = try maps.then(norm('f'));
    try f.put(a, Ks.Esc.toBits(), km.KeyFunction.initsetmod(ModeId.Normal));
    f.fallback(km.KeyFunction.initbuffer(targeters.jump_letter));
    f.targeter(km.KeyFunction.initstate(keys.actions.move));

    var t = try maps.then(norm('t'));
    try t.put(a, Ks.Esc.toBits(), km.KeyFunction.initsetmod(ModeId.Normal));
    t.fallback(km.KeyFunction.initbuffer(targeters.jump_letter_before));
    t.targeter(km.KeyFunction.initstate(keys.actions.move));

    var g = try maps.then(norm('g'));
    g.targeter(km.KeyFunction.initstate(keys.actions.move));
    try g.put(a, norm('g'), km.KeyFunction.initstate(targeters.target_top));

    //  @as(c_int, 37) buffer_next_brace(buffer);

}

fn initNormalKeys(a: std.mem.Allocator, normal: *km.Keymap.Appender) !void {
    _ = a;
    _ = normal;

    // if (tools.check_keymaps(buffer, state)) return;

    // if (isdigit(state.ch) and
    //     !(state.ch.character.b() == '0' and state.num.items.len == 0))
    // {
    //     // std.log.info("adding number!\n", .{});
    //     try state.num.append(state.a, state.ch.character.b());
    //     return;
    // }

    // if (!isdigit(state.ch) and state.num.items.len > 0) {
    //     state.repeating.repeating_count = std.fmt.parseInt(u32, state.num.items, 10) catch {
    //         // TODO: error handleing
    //         return;
    //     };
    //     state.num.clearRetainingCapacity();
    //
    //     // Some functions are smart and will look at repeating_count when the
    //     // run and then set it to 0 when finished. Some are not and so this
    //     // allows the dumb ones (and user defined ones) to still be repeated.
    //     // An optimization might be to make this return a dynamic dispatch
    //     // object so we can just call it many times and not worry about finding
    //     // it many times.
    //     errdefer state.repeating.repeating_count = 0;
    //     var i: usize = 0;
    //     while (i < state.repeating.repeating_count) : (i += 1) {
    //         try state.key_func[@intFromEnum(state.config.mode)](buffer, state);
    //     }
    //     state.repeating.repeating_count = 0;
    //     return;
    // }

    // '-' => {
    //     if (state.*.is_exploring) break;
    //     reset_command(state.*.command, &state.*.command_s);
    //     state.*.x = state.*.command_s +% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))));
    //     frontend_move_cursor(state.*.status_bar, state.*.x, @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))));
    //     state.*.config.mode = @as(c_uint, @bitCast(SEARCH));
    //     break;
    // },

    // 15 => {
    //         var row: usize = buffer_get_row(buffer);
    //         var end: usize = buffer.*.rows.data[row].end;
    //         buffer.*.cursor = end;
    //         buffer_newline_indent(buffer, state);
    // },

    // @as(c_int, 110) => {
    //         var index_1: usize = search(buffer, state.*.command, state.*.command_s);
    //         _ = &index_1;
    //         buffer.*.cursor = index_1;
    // },

    // ctrl('s') => save

    // @as(c_int, 3), @as(c_int, 27) => {
    //     state.*.repeating.repeating_count = 0;
    //     reset_command(state.*.command, &state.*.command_s);
    //     state.*.config.mode = @as(c_uint, @bitCast(NORMAL));
    //     break;
    // },

    // @as(c_int, 121) => {
    //     switch (state.*.leader) {
    //         @as(c_uint, @bitCast(@as(c_int, 3))) => {
    //             {
    //                 if (state.*.repeating.repeating_count == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) {
    //                     state.*.repeating.repeating_count = 1;
    //                 }
    //                 reset_command(state.*.clipboard.str, &state.*.clipboard.len);
    //                 {
    //                     var i: usize = 0;
    //                     _ = &i;
    //                     while (i < state.*.repeating.repeating_count) : (i +%= 1) {
    //                         buffer_yank_line(buffer, state, i);
    //                     }
    //                 }
    //                 state.*.repeating.repeating_count = 0;
    //             }
    //             break;
    //         },
    //         else => break,
    //     }
    // },

    // 'p', 'P' => {
    //         if (state.*.clipboard.len == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) break;
    //         var data: Data = dynstr_to_data(state.*.clipboard);
    //
    //         if ((state.*.clipboard.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, state.*.clipboard.str[@as(c_uint, @intCast(@as(c_int, 0)))]))) == @as(c_int, '\n'))) {
    //             var row: usize = buffer_get_row(buffer);
    //             var end: usize = buffer.*.rows.data[row].end;
    //             buffer.*.cursor = end;
    //         }
    //         buffer_insert_selection(buffer, &data, buffer.*.cursor);
    //         state.*.cur_undo.end = buffer.*.cursor;
    //         undo_push(state, &state.*.undo_stack, state.*.cur_undo);
    //         if (((state.*.clipboard.len > @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, state.*.clipboard.str[@as(c_uint, @intCast(@as(c_int, 0)))]))) == @as(c_int, '\n'))) and (buffer.*.cursor < buffer.*.data.count)) {
    //             buffer.*.cursor +%= 1;
    //         }
    // },

    // term.ctrl('n') => {
    //     state.*.is_exploring = !state.*.is_exploring;
    // },
}

pub fn initModifyingKeys(a: std.mem.Allocator, maps: *km.Keymap.Appender) !void {
    // x - buffer_delete_ch(buffer, state);

    // c - buffer_replace_ch(buffer, state);

    var d = try maps.then(norm('d'));
    d.targeter(km.KeyFunction.initbuffer(keys.actions.delete));
    try d.put(a, norm('d'), km.KeyFunction.initstate(targeters.full_linewise));
    try initMotionKeys(a, &d);

    var c = try maps.then(norm('c'));
    c.targeter(km.KeyFunction.initbuffer(keys.actions.change));
    try initMotionKeys(a, &c);

    // const gq = try g.then(a, 'q');
    // _ = gq; // autofix

    try maps.put(a, norm('D'), km.KeyFunction.initstate(functions.delete_end_of_line));
    try maps.put(a, norm('C'), km.KeyFunction.initstate(functions.change_end_of_line));

    var r = try maps.then(norm('r'));
    r.fallback(km.KeyFunction.initstate(functions.replace_letter));

    var y = try maps.then(norm('y'));
    y.targeter(km.KeyFunction.initstate(functions.yank));
    try initMotionKeys(a, &y);
    try y.put(a, norm('y'), km.KeyFunction.initstate(targeters.full_linewise));
}

pub const motions = struct {
    pub fn end_of_line(state: *State, _: km.KeyFunctionDataValue) !void {
        const count = state.repeating.take();
        const buffer = state.getCurrentBuffer();

        const begin = buffer.position();
        const end = targeters.end_of_line(buffer, count);

        buffer.updateTarget(Buffer.VisualMode.Range, begin, end);
    }
};

/// A collection of key targeters that can be applied in different contexts.
const targeters = struct {
    fn jump_letter_before(buffer: *Buffer, ctx: km.KeyFunctionDataValue) !void {
        // TODO: count
        try jump_letter(buffer, ctx);
        if (buffer.target) |*target| {
            target.end = buffer.moveLeft(target.end, 1);
        }
    }

    fn jump_letter(buffer: *Buffer, ctx: km.KeyFunctionDataValue) !void {
        const ch = ctx.character.character;

        const start = buffer.position();
        var end = start;

        while (buffer.lines.items[end.row].items[end.col] != ch) {
            end = buffer.moveRight(end, 1);
            // no match found
            if (end.row >= buffer.lines.items.len) return;
        }

        buffer.updateTarget(Buffer.VisualMode.Range, start, end);
    }

    /// Selects `count` full lines starting from the current cursor position.
    fn full_linewise(state: *State, _: km.KeyFunctionDataValue) !void {
        const count = state.takeRepeating();
        const buffer = state.getCurrentBuffer();

        const start = lib.Vec2{ .row = buffer.row, .col = 0 };

        const row = @min(buffer.row + count, buffer.lines.items.len - 1);

        buffer.target = .{
            .mode = .Line,
            .start = start,
            .end = .{
                .row = row,
                .col = buffer.lines.items[row].items.len,
            },
        };
    }

    fn target_down_linewise(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();
        const count = state.takeRepeating();

        const start = buffer.position();
        var end = start;
        end.row = @min(start.row + count, buffer.lines.items.len - 1);
        end.col = @min(end.col, buffer.lines.items[end.row].items.len);

        buffer.updateTarget(Buffer.VisualMode.Line, start, end);
    }

    fn target_up_linewise(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();

        const count = state.takeRepeating();

        buffer.row = if (buffer.row < count) 0 else buffer.row - count;

        buffer.col = @min(buffer.col, buffer.lines.items[buffer.row].items.len);
        // buffer.updatePostionKeepRow();
    }

    fn target_right(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();

        const count = state.takeRepeating();

        if (buffer.target) |*t| {
            t.end = buffer.moveRight(t.end, count);
        } else {
            const start = buffer.position();
            buffer.target = .{ .start = start, .end = buffer.moveRight(start, count) };
        }
    }

    fn target_left(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();
        const count = state.repeating.take();

        const start = buffer.position();
        buffer.target = .{ .start = start, .end = buffer.moveLeft(start, count) };
    }

    fn target_top(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();
        const count = state.repeating.take();

        buffer.target = .{
            .mode = .Line,
            .start = buffer.position(),
            .end = .{ .row = count - 1, .col = 0 },
        };
        // buffer.updatePostionKeepRow();

    }

    fn target_bottom(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();
        const start = buffer.position();
        var end = start;

        // yeah the G motion is weird
        end.row =
            if (state.repeating.some()) |count| count - 1 // eh
            else buffer.lines.items.len - 1;

        buffer.updateTarget(Buffer.VisualMode.Range, start, end);
    }

    /// TODO: make a word selector and then just get the end. also can be used
    /// for the word start
    fn motion_word_end(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();
        const count = state.repeating.take();

        const start = buffer.position();
        var end = start;

        var i: u32 = 0;
        while (i < count) : (i += 1) {
            end = buffer.moveRight(end, 1);
            while (end.row < buffer.lines.items.len and std.ascii.isWhitespace(buffer.lines.items[end.row].items[end.col])) {
                end = buffer.moveRight(end, 1);
            }
            if (end.row >= buffer.lines.items.len) {
                end = buffer.moveLeft(end, 1);
                break;
            }

            const is_word = isWordChar(buffer.lines.items[end.row].items[end.col]);
            while (end.row < buffer.lines.items.len and !std.ascii.isWhitespace(buffer.lines.items[end.row].items[end.col])) {
                const next_pos = buffer.moveRight(end, 1);
                if (next_pos.row >= buffer.lines.items.len or
                    std.ascii.isWhitespace(buffer.lines.items[next_pos.row].items[next_pos.col]) or
                    is_word != isWordChar(buffer.lines.items[next_pos.row].items[next_pos.col]))
                {
                    break;
                }
                end = next_pos;
            }
        }

        buffer.updateTarget(Buffer.VisualMode.Range, start, end);
    }

    /// TODO: this is not correct, it should loop on more than just
    /// alphanumeric but also some symbols
    fn motion_word_start(state: *State, _: km.KeyFunctionDataValue) !void {
        // TODO: count
        const buffer = state.getCurrentBuffer();

        const start = buffer.position();
        var end = start;

        var inword = std.ascii.isAlphanumeric(buffer.lines.items[start.row].items[start.col]);
        var loop = true;
        while (loop) {
            end = buffer.moveRight(end, 1);

            if (inword) {
                inword = !std.ascii.isWhitespace(buffer.lines.items[end.row].items[end.col]);
            }

            if (inword) {
                loop = std.ascii.isAlphanumeric(buffer.lines.items[end.row].items[end.col]);
            } else {
                loop = std.ascii.isWhitespace(buffer.lines.items[end.row].items[end.col]);
            }

            // TODO: this can infinitly loop
        }

        buffer.updateTarget(Buffer.VisualMode.Range, start, end);
    }

    fn motion_word_back(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();
        const count = state.repeating.take();

        const start = buffer.position();
        var end = start;

        var i: u32 = 0;
        while (i < count) : (i += 1) {
            end = buffer.moveLeft(end, 1);
            while ((end.row > 0 or end.col > 0) and std.ascii.isWhitespace(buffer.lines.items[end.row].items[end.col])) {
                end = buffer.moveLeft(end, 1);
            }

            const is_word = isWordChar(buffer.lines.items[end.row].items[end.col]);
            while ((end.row > 0 or end.col > 0) and !std.ascii.isWhitespace(buffer.lines.items[end.row].items[end.col])) {
                const prev_pos = buffer.moveLeft(end, 1);
                if (std.ascii.isWhitespace(buffer.lines.items[prev_pos.row].items[prev_pos.col]) or
                    is_word != isWordChar(buffer.lines.items[prev_pos.row].items[prev_pos.col]))
                {
                    break;
                }
                end = prev_pos;
            }
        }

        buffer.updateTarget(Buffer.VisualMode.Range, start, end);
    }

    // fn motion_WORD_back(state: *State, _: km.KeyFunctionDataValue) !void {
    //     const buffer = state.getCurrentBuffer();
    //     const count = state.repeating.take();
    //
    //     const start = buffer.position();
    //     var end = start;
    //
    //     var i: u32 = 0;
    //     while (i < count) : (i += 1) {
    //         end = buffer.moveLeft(end, 1);
    //         while ((end.row > 0 or end.col > 0) and std.ascii.isWhitespace(buffer.lines.items[end.row].items[end.col])) {
    //             end = buffer.moveLeft(end, 1);
    //         }
    //
    //         while ((end.row > 0 or end.col > 0) and !std.ascii.isWhitespace(buffer.lines.items[end.row].items[end.col])) {
    //             const prev_pos = buffer.moveLeft(end, 1);
    //             if (std.ascii.isWhitespace(buffer.lines.items[prev_pos.row].items[prev_pos.col])) {
    //                 break;
    //             }
    //             end = prev_pos;
    //         }
    //     }
    //
    //     buffer.updateTarget(Buffer.VisualMode.Range, start, end);
    // }

    fn isWordChar(c: u8) bool {
        return std.ascii.isAlphanumeric(c) or c == '_';
    }

    pub fn end_of_line(buffer: *Buffer, count: usize) lib.Vec2 {
        var end = buffer.position();

        // move count-1, rows down
        end.row = @min(end.row - (count - 1), buffer.lines.items.len - 1);
        // move to end of line
        end.col = buffer.lines.items[buffer.row].items.len;

        return end;
    }

    fn motion_start(state: *State, _: km.KeyFunctionDataValue) !void {
        const count = state.repeating.take();
        const buffer = state.getCurrentBuffer();

        const begin = buffer.position();
        var end = begin;

        end.row = std.math.sub(usize, begin.row, count - 1) catch 0;
        end.col = 0;

        buffer.updateTarget(Buffer.VisualMode.Range, begin, end);
    }

    // pub fn buffer_next_brace(arg_buffer: *Buffer) void {
    //     var buffer = arg_buffer;
    //     _ = &buffer;
    //     var cur_pos: c_int = @as(c_int, @bitCast(@as(c_uint, @truncate(buffer.*.cursor))));
    //     _ = &cur_pos;
    //     var initial_brace: Brace = find_opposite_brace((blk: {
    //         const tmp = cur_pos;
    //         if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    //     }).*);
    //     _ = &initial_brace;
    //     var brace_stack: usize = 0;
    //     _ = &brace_stack;
    //     if (@as(c_int, @bitCast(@as(c_uint, initial_brace.brace))) == @as(c_int, '0')) return;
    //     var direction: c_int = if (initial_brace.closing != 0) -@as(c_int, 1) else @as(c_int, 1);
    //     _ = &direction;
    //     while ((cur_pos >= @as(c_int, 0)) and (cur_pos <= @as(c_int, @bitCast(@as(c_uint, @truncate(buffer.*.data.count)))))) {
    //         cur_pos += direction;
    //         cur_pos = skip_to_char(buffer, cur_pos, direction, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '"'))))));
    //         cur_pos = skip_to_char(buffer, cur_pos, direction, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, '\''))))));
    //         var cur_brace: Brace = find_opposite_brace((blk: {
    //             const tmp = cur_pos;
    //             if (tmp >= 0) break :blk buffer.*.data.data + @as(usize, @intCast(tmp)) else break :blk buffer.*.data.data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    //         }).*);
    //         _ = &cur_brace;
    //         if (@as(c_int, @bitCast(@as(c_uint, cur_brace.brace))) == @as(c_int, '0')) continue;
    //         if (((cur_brace.closing != 0) and (direction == -@as(c_int, 1))) or (!(cur_brace.closing != 0) and (direction == @as(c_int, 1)))) {
    //             brace_stack +%= 1;
    //         } else {
    //             if (((blk: {
    //                 const ref = &brace_stack;
    //                 const tmp = ref.*;
    //                 ref.* -%= 1;
    //                 break :blk tmp;
    //             }) == @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))) and (@as(c_int, @bitCast(@as(c_uint, cur_brace.brace))) == @as(c_int, @bitCast(@as(c_uint, find_opposite_brace(initial_brace.brace).brace))))) {
    //                 buffer.*.cursor = @as(usize, @bitCast(@as(c_long, cur_pos)));
    //                 break;
    //             }
    //         }
    //     }
    // }
};

// TODO: remake this functions by just saying, move to target, then go insert
// using the appropriate abstractions
const inserts = struct {
    fn before(state: *State, _: km.KeyFunctionDataValue) !void {
        root.log(@src(), .debug, "inserts before", .{});
        const buffer = state.getCurrentBuffer();

        // TODO: repeating this repeart the text you insert, i dont want to
        // make that
        state.repeating.reset();
        buffer.setMode(ModeId.Insert);
    }

    fn after(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();

        // targeter.right()
        // buffer.moveRight(buffer.position(), 1);

        // if (buffer.cursor < buffer.data.items.len) {
        //     buffer.cursor += 1;
        // }
        //state.repeating.reset();
        buffer.setMode(ModeId.Insert);
    }

    fn start(state: *State, ctx: km.KeyFunctionDataValue) !void {
        // TODO: move this to an external function that both call, for exmaple
        //
        // const target = motions.movestart(buffer, count);
        // buffer.moveto(target.end);
        // buffer.setMode(ModeId.Insert);

        try targeters.motion_start(state, ctx);
        const buffer = state.getCurrentBuffer();
        buffer.setMode(ModeId.Insert);
    }

    fn end(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();
        // const row = buffer.rows.items[buffer.row];
        //
        // buffer.cursor = row.end;
        // buffer.col = row.end - row.start;
        //
        // state.repeating.reset();
        buffer.setMode(ModeId.Insert);
    }

    fn above(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();

        buffer.col = 0;
        try buffer.newlineInsert(state.a);

        root.log(@src(), .debug, "number of lines: {d}", .{buffer.lines.items.len});

        buffer.row = @max(0, buffer.row - 1);

        state.repeating.reset();
        buffer.setMode(ModeId.Insert);
    }

    fn below(state: *State, _: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();
        const line = &buffer.lines.items[buffer.row];

        buffer.col = line.items.len;
        try buffer.newlineInsert(state.a);

        state.repeating.reset();
        buffer.setMode(ModeId.Insert);
    }
};

/// These are the visual mode shims that set a trivial target then move to visual mode
const visuals = struct {
    fn set(comptime mode: Buffer.VisualMode) (*const fn (*State, km.KeyFunctionDataValue) anyerror!void) {
        return struct {
            fn set(state: *State, _: km.KeyFunctionDataValue) !void {
                const buffer = state.getCurrentBuffer();
                const cur = buffer.position();

                buffer.setMode(ModeId.Visual);
                buffer.target = .{ .mode = mode, .start = cur, .end = cur };
            }
        }.set;
    }
};

const functions = struct {
    fn yank(state: *State, _: km.KeyFunctionDataValue) !void {
        _ = state.repeating.take();
        const buffer = state.getCurrentBuffer();
        if (buffer.target) |target| {
            const selection = try buffer.gettarget(target);
            defer selection.deinit();

            root.log(@src(), .debug, "yank: {s}", .{selection.items});

            var child = std.process.Child.init(&.{"wl-copy", selection.items}, state.a);
            try child.spawn();
            _ = try child.wait();

            // TODO: this should reset by something else
            buffer.target = null;
        }
    }

    fn delete_end_of_line(state: *State, _: km.KeyFunctionDataValue) !void {
        const count = state.repeating.take();
        const buffer = state.getCurrentBuffer();

        if (buffer.target) |target| {
            try buffer.delete(target);
            buffer.target = null;
        } else {
            const start = buffer.position();
            const end = targeters.end_of_line(buffer, count);
            try buffer.delete(.{ .start = start, .end = end });
        }
    }

    fn change_end_of_line(state: *State, _: km.KeyFunctionDataValue) !void {
        const count = state.takeRepeating();
        const buffer = state.getCurrentBuffer();

        if (buffer.target) |target| {
            try buffer.delete(target);
        } else {
            const start = buffer.position();
            const end = targeters.end_of_line(buffer, count);
            try buffer.delete(.{ .start = start, .end = end });
        }
        buffer.setMode(ModeId.Insert);
    }

    fn replace_letter(state: *State, ctx: km.KeyFunctionDataValue) !void {
        const buffer = state.getCurrentBuffer();
        const count = state.repeating.take();

        const ch = ctx.character;

        const target = buffer.target orelse blk: {
            const start = buffer.position();
            var end = start;
            for (0..count) |_| {
                end = buffer.moveRight(end, 1);
            }
            break :blk Buffer.Visual{ .start = start, .end = end };
        };
        try buffer.replace(target, ch.character);
    }
};
