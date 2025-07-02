#include <Python.h>
#include <stdio.h>
#include <string.h>

// Forward declarations for helper functions
PyObject* get_main_module_dict();
PyObject* setup_output_capture(PyObject** original_stdout, PyObject** captured_stdout_obj);
void restore_output(PyObject* original_stdout);
char* get_captured_output(PyObject* captured_stdout_obj);


int main() {
    // 1. Initialize the Python interpreter
    Py_Initialize();
    if (!Py_IsInitialized()) {
        fprintf(stderr, "Failed to initialize Python interpreter.\n");
        return 1;
    }

    // Get the dictionary for the __main__ module. This will serve as our
    // persistent global and local namespace for all cell executions.
    PyObject* main_dict = get_main_module_dict();
    if (main_dict == NULL) {
        Py_FinalizeEx();
        return 1;
    }

    // Pointers to hold the original stdout/stderr and our captured versions
    PyObject* original_stdout = NULL;
    PyObject* captured_stdout_obj = NULL; // This will be a Python io.StringIO object

    printf("--- Running Cell 1 ---\n");
    const char* cell1_code =
        "x = 10\n"
        "y = 20\n"
        "print(f'x is {x}')\n"
        "print(f'y is {y}')\n";

    // Setup output capture
    captured_stdout_obj = setup_output_capture(&original_stdout, &captured_stdout_obj);
    if (captured_stdout_obj == NULL) {
        Py_XDECREF(main_dict);
        Py_FinalizeEx();
        return 1;
    }

    // Execute the code
    PyObject* result = PyRun_String(cell1_code, Py_file_input, main_dict, main_dict);

    // Get captured output
    char* captured_output1 = get_captured_output(captured_stdout_obj);
    if (captured_output1 != NULL) {
        printf("Captured output (Cell 1):\n%s", captured_output1);
        free(captured_output1); // Free the memory allocated by get_captured_output
    }

    // Restore original stdout
    restore_output(original_stdout);

    // Check for errors
    if (result == NULL) {
        PyErr_Print(); // Print Python traceback to stderr
        fprintf(stderr, "Error executing Cell 1.\n");
        // Clear the error indicator after printing
        PyErr_Clear();
    } else {
        Py_DECREF(result); // Decrement reference count for the result of PyRun_String
    }
    printf("--- End Cell 1 ---\n\n");

    printf("--- Running Cell 2 (uses state from Cell 1) ---\n");
    const char* cell2_code =
        "z = x + y\n" // x and y are from Cell 1's execution
        "print(f'z is {z}')\n";

    // Setup output capture again for the next cell
    captured_stdout_obj = setup_output_capture(&original_stdout, &captured_stdout_obj);
    if (captured_stdout_obj == NULL) {
        Py_XDECREF(main_dict);
        Py_FinalizeEx();
        return 1;
    }

    // Execute the code
    result = PyRun_String(cell2_code, Py_file_input, main_dict, main_dict);

    // Get captured output
    char* captured_output2 = get_captured_output(captured_stdout_obj);
    if (captured_output2 != NULL) {
        printf("Captured output (Cell 2):\n%s", captured_output2);
        free(captured_output2);
    }

    // Restore original stdout
    restore_output(original_stdout);

    // Check for errors
    if (result == NULL) {
        PyErr_Print();
        fprintf(stderr, "Error executing Cell 2.\n");
        PyErr_Clear();
    } else {
        Py_DECREF(result);
    }
    printf("--- End Cell 2 ---\n\n");


    printf("--- Running Cell 3 (Error case) ---\n");
    const char* cell3_code = "print(f'undefined_var is {undefined_var}')\n";

    captured_stdout_obj = setup_output_capture(&original_stdout, &captured_stdout_obj);
    if (captured_stdout_obj == NULL) {
        Py_XDECREF(main_dict);
        Py_FinalizeEx();
        return 1;
    }

    result = PyRun_String(cell3_code, Py_file_input, main_dict, main_dict);

    char* captured_output3 = get_captured_output(captured_stdout_obj);
    if (captured_output3 != NULL) {
        printf("Captured output (Cell 3):\n%s", captured_output3);
        free(captured_output3);
    }

    restore_output(original_stdout);

    if (result == NULL) {
        PyErr_Print(); // This will print the NameError traceback
        fprintf(stderr, "Error executing Cell 3 (expected).\n");
        PyErr_Clear();
    } else {
        Py_DECREF(result);
    }
    printf("--- End Cell 3 ---\n\n");


    // 7. Clean up
    Py_XDECREF(main_dict); // Decrement reference count for __main__ dict
    Py_XDECREF(captured_stdout_obj); // Ensure this is decremented if still held
                                      // (though it should be released after restore_output)
    Py_FinalizeEx();

    return 0;
}

// Helper function to get the __main__ module's dictionary
PyObject* get_main_module_dict() {
    PyObject* main_module = PyImport_AddModule("__main__");
    if (main_module == NULL) {
        PyErr_Print();
        fprintf(stderr, "Failed to get __main__ module.\n");
        return NULL;
    }
    PyObject* main_dict = PyModule_GetDict(main_module);
    if (main_dict == NULL) {
        PyErr_Print();
        fprintf(stderr, "Failed to get __main__ module dictionary.\n");
        Py_DECREF(main_module); // main_module is a new ref from AddModule
        return NULL;
    }
    Py_INCREF(main_dict); // Increment ref count because PyModule_GetDict returns borrowed,
                          // but we want to keep it around.
    Py_DECREF(main_module); // We only need the dict, not the module object itself long-term
    return main_dict;
}

// Helper function to set up stdout redirection to an in-memory buffer
PyObject* setup_output_capture(PyObject** original_stdout, PyObject** captured_stdout_obj) {
    PyObject* sys_module = PyImport_ImportModule("sys");
    if (sys_module == NULL) {
        PyErr_Print();
        return NULL;
    }
    PyObject* io_module = PyImport_ImportModule("io");
    if (io_module == NULL) {
        PyErr_Print();
        Py_DECREF(sys_module);
        return NULL;
    }

    *original_stdout = PyObject_GetAttrString(sys_module, "stdout");
    if (*original_stdout == NULL) {
        PyErr_Print();
        Py_DECREF(sys_module);
        Py_DECREF(io_module);
        return NULL;
    }

    PyObject* stringio_class = PyObject_GetAttrString(io_module, "StringIO");
    if (stringio_class == NULL) {
        PyErr_Print();
        Py_DECREF(sys_module);
        Py_DECREF(io_module);
        Py_DECREF(*original_stdout);
        return NULL;
    }

    // Call StringIO() constructor
    *captured_stdout_obj = PyObject_CallNoArgs(stringio_class);
    if (*captured_stdout_obj == NULL) {
        PyErr_Print();
        Py_DECREF(sys_module);
        Py_DECREF(io_module);
        Py_DECREF(*original_stdout);
        Py_DECREF(stringio_class);
        return NULL;
    }

    // Set sys.stdout to our StringIO object
    int res = PyObject_SetAttrString(sys_module, "stdout", *captured_stdout_obj);
    if (res == -1) {
        PyErr_Print();
        Py_DECREF(sys_module);
        Py_DECREF(io_module);
        Py_DECREF(*original_stdout);
        Py_DECREF(stringio_class);
        Py_DECREF(*captured_stdout_obj);
        return NULL;
    }

    Py_DECREF(sys_module);
    Py_DECREF(io_module);
    Py_DECREF(stringio_class);

    // captured_stdout_obj is a new reference, returned to caller for management
    return *captured_stdout_obj;
}

// Helper function to restore original stdout
void restore_output(PyObject* original_stdout) {
    if (original_stdout == NULL) return; // Nothing to restore

    PyObject* sys_module = PyImport_ImportModule("sys");
    if (sys_module == NULL) {
        PyErr_Print();
        return;
    }
    PyObject_SetAttrString(sys_module, "stdout", original_stdout);
    Py_DECREF(sys_module);
    Py_DECREF(original_stdout); // Decrement the reference to the original stdout
}

// Helper function to get the string value from the captured StringIO object
char* get_captured_output(PyObject* captured_stdout_obj) {
    if (captured_stdout_obj == NULL) return NULL;

    PyObject*getvalue_method = PyObject_GetAttrString(captured_stdout_obj, "getvalue");
    if (getvalue_method == NULL) {
        PyErr_Print();
        return NULL;
    }

    PyObject* output_py_str = PyObject_CallNoArgs(getvalue_method);
    Py_DECREF(getvalue_method); // Decrement reference to the method object
    if (output_py_str == NULL) {
        PyErr_Print();
        return NULL;
    }

    // Convert Python string to C string
    Py_ssize_t len;
    const char* output_c_str = PyUnicode_AsUTF8AndSize(output_py_str, &len);
    if (output_c_str == NULL) {
        PyErr_Print();
        Py_DECREF(output_py_str);
        return NULL;
    }

    // Make a copy, as output_c_str is a borrowed reference
    char* result_copy = (char*)malloc(len + 1);
    if (result_copy == NULL) {
        fprintf(stderr, "Memory allocation failed for captured output.\n");
        Py_DECREF(output_py_str);
        return NULL;
    }
    memcpy(result_copy, output_c_str, len);
    result_copy[len] = '\0';

    Py_DECREF(output_py_str); // Decrement reference to the Python string object

    return result_copy;
}
