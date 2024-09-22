#include "buffer.h"
#include "main.h"

// updates the rows to be consistent with the buffer data
void buffer_calculate_rows(Buffer *buffer) {
    buffer->rows.count = 0;
    size_t start = 0;
    for(size_t i = 0; i < buffer->data.count; i++) {
        if(buffer->data.data[i] == '\n') {
            DA_APPEND(&buffer->rows, ((Row){.start = start, .end = i}));
            start = i + 1;
        }
    }

    DA_APPEND(&buffer->rows, ((Row){.start = start, .end = buffer->data.count}));
}

void buffer_insert_char(State *state, Buffer *buffer, char ch) {
	ASSERT(buffer != NULL, "buffer exists");
	ASSERT(state != NULL, "state exists");		
    // constrain the cursor
    if(buffer->cursor > buffer->data.count) buffer->cursor = buffer->data.count;
    DA_APPEND(&buffer->data, ch);
    // shift the data over one
    memmove(&buffer->data.data[buffer->cursor + 1], &buffer->data.data[buffer->cursor], buffer->data.count - 1 - buffer->cursor);
    buffer->data.data[buffer->cursor++] = ch;
    // shift the end of the current undo
    state->cur_undo.end = buffer->cursor;
    buffer_calculate_rows(buffer);
}

void buffer_delete_char(Buffer *buffer, State *state) {
    (void)state;
    if(buffer->cursor < buffer->data.count) {
        // shift data left by 1
        memmove(&buffer->data.data[buffer->cursor], &buffer->data.data[buffer->cursor+1], buffer->data.count - buffer->cursor - 1);
        buffer->data.count--;
        buffer_calculate_rows(buffer);
    }
}

void buffer_delete_ch(Buffer *buffer, State *state) {
    CREATE_UNDO(INSERT_CHARS, buffer->cursor);
    reset_command(state->clipboard.str, &state->clipboard.len);
    buffer_yank_char(buffer, state);
    buffer_delete_char(buffer, state);
    state->cur_undo.end = buffer->cursor;
    undo_push(state, &state->undo_stack, state->cur_undo);
}

void buffer_delete_row(Buffer *buffer, State *state) {
    size_t repeat = state->repeating.repeating_count;
    if(repeat == 0) repeat = 1;
    if(repeat > buffer->rows.count - buffer_get_row(buffer)) repeat = buffer->rows.count - buffer_get_row(buffer);
    for(size_t i = 0; i < repeat; i++) {
        reset_command(state->clipboard.str, &state->clipboard.len);
        buffer_yank_line(buffer, state, 0);
        size_t row = buffer_get_row(buffer);
        Row cur = buffer->rows.data[row];
        size_t offset = buffer->cursor - cur.start;
        CREATE_UNDO(INSERT_CHARS, cur.start);
        if(row == 0) {
            size_t end = (buffer->rows.count > 1) ? cur.end+1 : cur.end;
            buffer_delete_selection(buffer, state, cur.start, end);
        } else {
            state->cur_undo.start -= 1;
            buffer_delete_selection(buffer, state, cur.start-1, cur.end);
        }
        undo_push(state, &state->undo_stack, state->cur_undo);
        buffer_calculate_rows(buffer);
        if(row >= buffer->rows.count) row = buffer->rows.count-1;
        cur = buffer->rows.data[row];
        size_t pos = cur.start + offset;
        if(pos > cur.end) pos = cur.end;
        buffer->cursor = pos;
    }
    state->repeating.repeating_count = 0;
}

void buffer_replace_ch(Buffer *buffer, State *state) {
    CREATE_UNDO(REPLACE_CHAR, buffer->cursor);
    DA_APPEND(&state->cur_undo.data, buffer->data.data[buffer->cursor]);
    state->ch = frontend_getch(state->main_win);
    buffer->data.data[buffer->cursor] = state->ch;
    undo_push(state, &state->undo_stack, state->cur_undo);
}

// get current row information based on cursor
size_t buffer_get_row(const Buffer *buffer) {
    ASSERT(buffer->cursor <= buffer->data.count, "cursor: %zu", buffer->cursor);
    ASSERT(buffer->rows.count >= 1, "there must be at least one line");
    for(size_t i = 0; i < buffer->rows.count; i++) {
        if(buffer->rows.data[i].start <= buffer->cursor && buffer->cursor <= buffer->rows.data[i].end) {
            return i;
        }
    }
    return 0;
}

// get current row information based on index
size_t index_get_row(Buffer *buffer, size_t index) {
    ASSERT(index <= buffer->data.count, "index: %zu", index);
    ASSERT(buffer->rows.count >= 1, "there must be at least one line");
    for(size_t i = 0; i < buffer->rows.count; i++) {
        if(buffer->rows.data[i].start <= index && index <= buffer->rows.data[i].end) {
            return i;
        }
    }
    return 0;
}

void buffer_yank_line(Buffer *buffer, State *state, size_t offset) {
    size_t row = buffer_get_row(buffer);
    // check boundaries
    if(offset > index_get_row(buffer, buffer->data.count)) return;
    Row cur = buffer->rows.data[row+offset];
    int line_offset = 0;
    size_t initial_s = state->clipboard.len;
    state->clipboard.len = cur.end - cur.start + 1; // account for new line
    // resize the clipboard as necessary
    state->clipboard.str = realloc(state->clipboard.str,
                                   initial_s+state->clipboard.len*sizeof(char));
    if(row > 0) line_offset = -1;
    else {
        state->clipboard.len--;
        initial_s++;
        state->clipboard.str[0] = '\n';
    }
    ASSERT(state->clipboard.str != NULL, "clipboard was null");
    strncpy(state->clipboard.str+initial_s, buffer->data.data+cur.start+line_offset, state->clipboard.len);
    state->clipboard.len += initial_s;
}

void buffer_yank_char(Buffer *buffer, State *state) {
    reset_command(state->clipboard.str, &state->clipboard.len);
    state->clipboard.len = 2;
    // resize the clipboard as necessary
    state->clipboard.str = realloc(state->clipboard.str,
                                   state->clipboard.len*sizeof(char));
    ASSERT(state->clipboard.str != NULL, "clipboard was null");
    strncpy(state->clipboard.str, buffer->data.data+buffer->cursor, state->clipboard.len);
}

void buffer_yank_selection(Buffer *buffer, State *state, size_t start, size_t end) {
    state->clipboard.len = end-start+1;
    state->clipboard.str = realloc(state->clipboard.str,
                                   state->clipboard.len*sizeof(char)+1);
    ASSERT(state->clipboard.str != NULL, "clipboard was null %zu", state->clipboard.len);
    strncpy(state->clipboard.str, buffer->data.data+start, state->clipboard.len);
}

void buffer_delete_selection(Buffer *buffer, State *state, size_t start, size_t end) {
    buffer_yank_selection(buffer, state, start, end);
    size_t size = end-start;
    if(size >= buffer->data.count) size = buffer->data.count;
    buffer->cursor = start;

    // constrain size to be within the buffer    
    if(buffer->cursor+size > buffer->data.count) return;
    //ASSERT(buffer->cursor+size <= buffer->data.count, "size is too great %zu", buffer->cursor+size);

    // resize undo as necessary
    if(state->cur_undo.data.capacity < size) {
        state->cur_undo.data.capacity = size;
        state->cur_undo.data.data = realloc(state->cur_undo.data.data, sizeof(char)*size);
        ASSERT(state->cur_undo.data.data != NULL, "could not alloc");
    }
    strncpy(state->cur_undo.data.data, &buffer->data.data[buffer->cursor], size);
    state->cur_undo.data.count = size;

    memmove(&buffer->data.data[buffer->cursor],
        &buffer->data.data[buffer->cursor+size],
        buffer->data.count - (end));
    buffer->data.count -= size;
    buffer_calculate_rows(buffer);
}

void buffer_insert_selection(Buffer *buffer, Data *selection, size_t start) {
    buffer->cursor = start;

    size_t size = selection->count;

    // resize buffer as necessary
    if(buffer->data.count + size >= buffer->data.capacity) {
        buffer->data.capacity += size*2;
        buffer->data.data = realloc(buffer->data.data, sizeof(char)*buffer->data.capacity+1);
        ASSERT(buffer->data.data != NULL, "could not alloc");
    }
    memmove(&buffer->data.data[buffer->cursor+size],
        &buffer->data.data[buffer->cursor],
        buffer->data.count - buffer->cursor);
    strncpy(&buffer->data.data[buffer->cursor], selection->data, size);

    buffer->data.count += size;
    buffer_calculate_rows(buffer);
}

void buffer_move_up(Buffer *buffer) {
    size_t row = buffer_get_row(buffer);
    size_t col = buffer->cursor - buffer->rows.data[row].start;
    if(row > 0) {
        // set to previous row on current column
        buffer->cursor = buffer->rows.data[row-1].start + col;
        // clamp the cursor position to the end of the row
        if(buffer->cursor > buffer->rows.data[row-1].end) {
            buffer->cursor = buffer->rows.data[row-1].end;
        }
    }
}

void buffer_move_down(Buffer *buffer) {
    size_t row = buffer_get_row(buffer);
    size_t col = buffer->cursor - buffer->rows.data[row].start;
    if(row < buffer->rows.count - 1) {
        // set to next row on current column
        buffer->cursor = buffer->rows.data[row+1].start + col;
        // clamp the cursor position to the end of the row
        if(buffer->cursor > buffer->rows.data[row+1].end) {
            buffer->cursor = buffer->rows.data[row+1].end;
        }
    }
}

void buffer_move_right(Buffer *buffer) {
    if(buffer->cursor < buffer->data.count) buffer->cursor++;
}

void buffer_move_left(Buffer *buffer) {
    if(buffer->cursor > 0) buffer->cursor--;
}

int skip_to_char(Buffer *buffer, int cur_pos, int direction, char c) {
    // check if currently on c
    if(buffer->data.data[cur_pos] == c) {
        // increment by the direciton, can be positive or negative
        cur_pos += direction;
        // search for the next instance of c
        while(cur_pos > 0 && cur_pos <= (int)buffer->data.count && buffer->data.data[cur_pos] != c) {
            if(cur_pos > 1 && cur_pos < (int)buffer->data.count && buffer->data.data[cur_pos] == '\\') {
                cur_pos += direction;
            }
            cur_pos += direction;
        }
    }
    return cur_pos;
}

void buffer_next_brace(Buffer *buffer) {
    int cur_pos = buffer->cursor;
    Brace initial_brace = find_opposite_brace(buffer->data.data[cur_pos]);
    size_t brace_stack = 0;
    // if not currently on a brace, exit
    if(initial_brace.brace == '0') return;
    // check if going forward or backward
    int direction = (initial_brace.closing) ? -1 : 1;
    while(cur_pos >= 0 && cur_pos <= (int)buffer->data.count) {
        cur_pos += direction;
        // skip over quotes if necessary to avoid strings containing braces
        cur_pos = skip_to_char(buffer, cur_pos, direction, '"');
        cur_pos = skip_to_char(buffer, cur_pos, direction, '\'');
        Brace cur_brace = find_opposite_brace(buffer->data.data[cur_pos]);
        // if not currently on a brace, continue
        if(cur_brace.brace == '0') continue;
        if((cur_brace.closing && direction == -1) || (!cur_brace.closing && direction == 1)) {
            brace_stack++;
        } else {
            if(brace_stack-- == 0 && cur_brace.brace == find_opposite_brace(initial_brace.brace).brace) {
                // set cursor to brace if found
                buffer->cursor = cur_pos;
                break;
            }
        }
    }
}

int isword(char ch) {
    if(isalnum(ch) || ch == '_') return 1;
    return 0;
}

void buffer_create_indent(Buffer *buffer, State *state) {
    // if indent is 0, then use tabs, otherwise spaces
    if(state->config.indent > 0) {
        for(size_t i = 0; i < state->config.indent*state->num_of_braces; i++) {
            buffer_insert_char(state, buffer, ' ');
        }
    } else {
        for(size_t i = 0; i < state->num_of_braces; i++) {
            buffer_insert_char(state, buffer, '\t');
        }
    }
}

// insert newline, then indent
void buffer_newline_indent(Buffer *buffer, State *state) {
    buffer_insert_char(state, buffer, '\n');
    buffer_create_indent(buffer, state);
}


State init_state(void) {
    State state = {0};
    state.config = (Config){0};
    state.config.relative_nums = 1;
    state.config.auto_indent = 1;
    state.config.syntax = 1;
    state.config.indent = 0;
    state.config.undo_size = 16;
    state.config.lang = " ";
    // Control variables
    state.config.QUIT = 0;
    state.config.mode = NORMAL;
    // Colors
    state.config.background_color = -1; // -1 for terminal background color.
    state.config.leaders[0] = ' ';
    state.config.leaders[1] = 'r';
    state.config.leaders[2] = 'd';
    state.config.leaders[3] = 'y';
    state.config.key_maps = (Maps){0};
    state.config.vars[0] = (Config_Vars){{"syntax", sizeof("syntax")-1}, &state.config.syntax};
    state.config.vars[1] = (Config_Vars){{"indent", sizeof("indent")-1}, &state.config.indent};
    state.config.vars[2] = (Config_Vars){{"auto-indent", sizeof("auto-indent")-1}, &state.config.auto_indent};
    state.config.vars[3] = (Config_Vars){{"undo-size", sizeof("undo-size")-1}, &state.config.undo_size};
    state.config.vars[4] = (Config_Vars){{"relative", sizeof("relative")-1}, &state.config.relative_nums};
    return state;
}
