#include <stdio.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

// --- Custom Print Function to Redirect Output ---
// This function replaces the default Lua 'print'
// so we can capture its output.
static int custom_print(lua_State *L) {
    int n = lua_gettop(L); // Number of arguments
    int i;
    for (i = 1; i <= n; i++) {
        if (i > 1) printf("\t"); // Separate arguments with tabs
        if (lua_isstring(L, i)) {
            printf("%s", lua_tostring(L, i));
        } else {
            // Fallback for non-string arguments (e.g., numbers, booleans)
            // You might want to use luaL_tolstring for more robust conversion
            const char* s = lua_tolstring(L, i, NULL);
            if (s) {
                printf("%s", s);
            } else {
                printf("<unprintable value>");
            }
        }
    }
    printf("\n"); // Newline after each print call
    return 0; // Number of return values
}

// --- Main Kernel Logic ---
int main() {
    lua_State *L = luaL_newstate(); // Create a new Lua state
    if (L == NULL) {
        fprintf(stderr, "Error: Cannot create Lua state.\n");
        return 1;
    }

    luaL_openlibs(L); // Open standard Lua libraries

    // Replace the default 'print' function with our custom one
    lua_pushcfunction(L, custom_print);
    lua_setglobal(L, "print");

    char input_buffer[1024]; // Buffer to read user input
    printf("Simple Lua Kernel (type 'exit()' to quit)\n");

    while (1) {
        printf(">>> "); // Prompt
        if (fgets(input_buffer, sizeof(input_buffer), stdin) == NULL) {
            // Handle EOF or read error
            break;
        }

        // Remove trailing newline character if present
        input_buffer[strcspn(input_buffer, "\n")] = 0;

        // Check for exit command
        if (strcmp(input_buffer, "exit()") == 0) {
            break;
        }

        // Load and execute the Lua code
        // luaL_loadstring loads the string as a Lua chunk.
        // It pushes the compiled chunk onto the stack.
        int load_status = luaL_loadstring(L, input_buffer);

        if (load_status != LUA_OK) {
            // Error loading the string (e.g., syntax error)
            fprintf(stderr, "Lua Load Error: %s\n", lua_tostring(L, -1));
            lua_pop(L, 1); // Pop the error message from the stack
        } else {
            // If loaded successfully, execute the chunk.
            // lua_pcall calls the function (the compiled chunk).
            // 0 arguments, 0 return values, 0 error handler index.
            int pcall_status = lua_pcall(L, 0, 0, 0);
            if (pcall_status != LUA_OK) {
                // Error during execution
                fprintf(stderr, "Lua Runtime Error: %s\n", lua_tostring(L, -1));
                lua_pop(L, 1); // Pop the error message
            }
        }
    }

    lua_close(L); // Close the Lua state
    printf("Exiting Simple Lua Kernel.\n");
    return 0;
}

