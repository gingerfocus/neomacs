#include <Python.h>
#include <stdio.h>
#include <string.h>

// Forward declarations for helper functions
PyObject* get_main_module_dict();
// Modified: now takes a pointer to PyObject** for captured_stdout_obj
// and will Py_XDECREF the old one if not NULL
PyObject* setup_output_capture(PyObject** original_stdout, PyObject** current_captured_stdout_obj_ptr);
// Modified: now also takes a pointer to the captured_stdout_obj so it can be DECREFed
void restore_output(PyObject* original_stdout, PyObject** current_captured_stdout_obj_ptr);
char* get_captured_output(PyObject* captured_stdout_obj);

int main() {
    Py_Initialize();
    if (!Py_IsInitialized()) {
        fprintf(stderr, "Failed to initialize Python interpreter.\n");
        return 1;
    }

    PyObject* main_dict = get_main_module_dict();
    if (main_dict == NULL) {
        Py_FinalizeEx();
        return 1;
    }

    PyObject* original_stdout_backup = NULL; // Stores the Python sys.stdout before redirection
    PyObject* current_captured_stdout_obj = NULL; // Stores the CURRENT StringIO object

    printf("--- Running Cell 1 ---\n");
    const char* cell1_code =
        "x = 10\n"
        "y = 20\n"
        "print(f'x is {x}')\n"
        "print(f'y is {y}')\n";

    // Pass address of current_captured_stdout_obj so setup_output_capture can modify it
    // and potentially DECREF the old one.
    current_captured_stdout_obj = setup_output_capture(&original_stdout_backup, &current_captured_stdout_obj);
    if (current_captured_stdout_obj == NULL) {
        Py_XDECREF(main_dict);
        Py_FinalizeEx();
        return 1;
    }

    PyObject* result = PyRun_String(cell1_code, Py_file_input, main_dict, main_dict);

    char* captured_output1 = get_captured_output(current_captured_stdout_obj);
    if (captured_output1 != NULL) {
        printf("Captured output (Cell 1):\n%s", captured_output1);
        free(captured_output1);
    }

    // Pass address of current_captured_stdout_obj so restore_output can DECREF it
    restore_output(original_stdout_backup, &current_captured_stdout_obj);

    if (result == NULL) {
        PyErr_Print();
        fprintf(stderr, "Error executing Cell 1 (unexpected).\n");
        PyErr_Clear();
    } else {
        Py_DECREF(result);
    }
    printf("--- End Cell 1 ---\n\n");

    printf("--- Running Cell 2 (uses state from Cell 1) ---\n");
    const char* cell2_code =
        "z = x + y\n"
        "print(f'z is {z}')\n";

    // Call again, previous current_captured_stdout_obj will be DECREFed inside
    current_captured_stdout_obj = setup_output_capture(&original_stdout_backup, &current_captured_stdout_obj);
    if (current_captured_stdout_obj == NULL) {
        Py_XDECREF(main_dict);
        Py_FinalizeEx();
        return 1;
    }

    result = PyRun_String(cell2_code, Py_file_input, main_dict, main_dict);

    char* captured_output2 = get_captured_output(current_captured_stdout_obj);
    if (captured_output2 != NULL) {
        printf("Captured output (Cell 2):\n%s", captured_output2);
        free(captured_output2);
    }

    restore_output(original_stdout_backup, &current_captured_stdout_obj);

    if (result == NULL) {
        PyErr_Print();
        fprintf(stderr, "Error executing Cell 2 (unexpected).\n");
        PyErr_Clear();
    } else {
        Py_DECREF(result);
    }
    printf("--- End Cell 2 ---\n\n");


    printf("--- Running Cell 3 (Error case) ---\n");
    const char* cell3_code = "print(f'undefined_var is {undefined_var}')\n";

    current_captured_stdout_obj = setup_output_capture(&original_stdout_backup, &current_captured_stdout_obj);
    if (current_captured_stdout_obj == NULL) {
        Py_XDECREF(main_dict);
        Py_FinalizeEx();
        return 1;
    }

    result = PyRun_String(cell3_code, Py_file_input, main_dict, main_dict);

    char* captured_output3 = get_captured_output(current_captured_stdout_obj);
    if (captured_output3 != NULL) {
        printf("Captured output (Cell 3):\n%s", captured_output3);
        free(captured_output3);
    }

    restore_output(original_stdout_backup, &current_captured_stdout_obj);

    if (result == NULL) {
        PyErr_Print();
        fprintf(stderr, "Error executing Cell 3 (expected).\n");
        PyErr_Clear();
    } else {
        Py_DECREF(result);
    }
    printf("--- End Cell 3 ---\n\n");


    // Final cleanup: main_dict is the only persistent object we held directly
    // current_captured_stdout_obj should be NULL here due to restore_output,
    // but Py_XDECREF is safe.
    Py_XDECREF(main_dict);
    Py_XDECREF(current_captured_stdout_obj); // This should ideally be NULL by now, but good practice

    Py_FinalizeEx(); // This should now run cleanly
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
        Py_DECREF(main_module);
        return NULL;
    }
    Py_INCREF(main_dict); // Now it's a "new" reference owned by the caller
    Py_DECREF(main_module);
    return main_dict;
}

// Helper function to set up stdout redirection to an in-memory buffer
// It now takes a pointer to current_captured_stdout_obj_ptr
PyObject* setup_output_capture(PyObject** original_stdout_ptr, PyObject** current_captured_stdout_obj_ptr) {
    // If there was a previous captured_stdout_obj, DECREF it first.
    // This handles the case where setup_output_capture is called multiple times.
    Py_XDECREF(*current_captured_stdout_obj_ptr);
    *current_captured_stdout_obj_ptr = NULL; // Clear pointer for safety

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

    *original_stdout_ptr = PyObject_GetAttrString(sys_module, "stdout"); // New ref
    if (*original_stdout_ptr == NULL) {
        PyErr_Print();
        Py_DECREF(sys_module);
        Py_DECREF(io_module);
        return NULL;
    }

    PyObject* stringio_class = PyObject_GetAttrString(io_module, "StringIO"); // New ref
    if (stringio_class == NULL) {
        PyErr_Print();
        Py_DECREF(sys_module);
        Py_DECREF(io_module);
        Py_DECREF(*original_stdout_ptr);
        return NULL;
    }

    *current_captured_stdout_obj_ptr = PyObject_CallNoArgs(stringio_class); // New ref
    if (*current_captured_stdout_obj_ptr == NULL) {
        PyErr_Print();
        Py_DECREF(sys_module);
        Py_DECREF(io_module);
        Py_DECREF(*original_stdout_ptr);
        Py_DECREF(stringio_class);
        return NULL;
    }

    // Set sys.stdout to our StringIO object
    int res = PyObject_SetAttrString(sys_module, "stdout", *current_captured_stdout_obj_ptr);
    if (res == -1) {
        PyErr_Print();
        Py_DECREF(sys_module);
        Py_DECREF(io_module);
        Py_DECREF(*original_stdout_ptr);
        Py_DECREF(stringio_class);
        Py_DECREF(*current_captured_stdout_obj_ptr);
        *current_captured_stdout_obj_ptr = NULL; // Clear pointer on error
        return NULL;
    }

    Py_DECREF(sys_module);
    Py_DECREF(io_module);
    Py_DECREF(stringio_class);

    // *current_captured_stdout_obj_ptr is a new reference, held by the caller
    return *current_captured_stdout_obj_ptr;
}

// Helper function to restore original stdout
// Now takes a pointer to current_captured_stdout_obj_ptr so it can be DECREFed
void restore_output(PyObject* original_stdout, PyObject** current_captured_stdout_obj_ptr) {
    if (original_stdout == NULL) return; // Nothing to restore

    PyObject* sys_module = PyImport_ImportModule("sys");
    if (sys_module == NULL) {
        PyErr_Print();
        return;
    }
    PyObject_SetAttrString(sys_module, "stdout", original_stdout);
    Py_DECREF(sys_module);
    Py_DECREF(original_stdout); // Decrement the reference to the original stdout

    // Crucially, DECREF the captured StringIO object when we're done with it
    Py_XDECREF(*current_captured_stdout_obj_ptr);
    *current_captured_stdout_obj_ptr = NULL; // Clear the pointer after DECREFing
}

// Helper function to get the string value from the captured StringIO object
char* get_captured_output(PyObject* captured_stdout_obj) {
    if (captured_stdout_obj == NULL) return NULL;

    // Check if an error is pending before making more Python API calls
    if (PyErr_Occurred()) {
        fprintf(stderr, "get_captured_output: Python exception already set, aborting capture.\n");
        // Don't clear here, let the main loop handle the primary error
        return NULL;
    }

    PyObject*getvalue_method = PyObject_GetAttrString(captured_stdout_obj, "getvalue"); // New ref
    if (getvalue_method == NULL) {
        PyErr_Print();
        return NULL;
    }

    PyObject* output_py_str = PyObject_CallNoArgs(getvalue_method); // New ref
    Py_DECREF(getvalue_method);
    if (output_py_str == NULL) {
        PyErr_Print();
        return NULL;
    }

    Py_ssize_t len;
    const char* output_c_str = PyUnicode_AsUTF8AndSize(output_py_str, &len);
    if (output_c_str == NULL) {
        PyErr_Print();
        Py_DECREF(output_py_str);
        return NULL;
    }

    char* result_copy = (char*)malloc(len + 1);
    if (result_copy == NULL) {
        fprintf(stderr, "Memory allocation failed for captured output.\n");
        Py_DECREF(output_py_str);
        return NULL;
    }
    memcpy(result_copy, output_c_str, len);
    result_copy[len] = '\0';

    Py_DECREF(output_py_str);
    return result_copy;
}
