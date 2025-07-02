# Literate programming for Neomacs

import sys
import io

class BasicPythonKernel:
    def __init__(self):
        self.user_ns = {}  # This will be our persistent global namespace
        self.stdout_buffer = io.StringIO()
        self.stderr_buffer = io.StringIO()

    def execute_cell(self, code):
        original_stdout = sys.stdout
        original_stderr = sys.stderr
        sys.stdout = self.stdout_buffer
        sys.stderr = self.stderr_buffer

        try:
            # Execute the code within our persistent namespace
            # 'self.user_ns' acts as both globals() and locals() for simplicity
            exec(code, self.user_ns, self.user_ns)
            output = self.stdout_buffer.getvalue()
            error = self.stderr_buffer.getvalue()
            # You might also want to capture the result of the last expression
            # but that's more complex (requires AST parsing or a more sophisticated exec)
        except Exception as e:
            error = str(e)
            output = ""
        finally:
            sys.stdout = original_stdout
            sys.stderr = original_stderr
            self.stdout_buffer.truncate(0)
            self.stdout_buffer.seek(0)
            self.stderr_buffer.truncate(0)
            self.stderr_buffer.seek(0)

        return {"stdout": output, "stderr": error}

# --- How you would use it (from a conceptual frontend) ---
if __name__ == "__main__":
    kernel = BasicPythonKernel()

    print("--- Cell 1 ---")
    result1 = kernel.execute_cell("x = 10\nprint(f'x is {x}')")
    print(f"Stdout: {result1['stdout']}")
    print(f"Stderr: {result1['stderr']}")
    # print(f"Current namespace: {kernel.user_ns}")

    print("\n--- Cell 2 ---")
    result2 = kernel.execute_cell("y = x * 2\nprint(f'y is {y}')")
    print(f"Stdout: {result2['stdout']}")
    print(f"Stderr: {result2['stderr']}")
    # print(f"Current namespace: {kernel.user_ns}")

    print("\n--- Cell 3 (Error) ---")
    result3 = kernel.execute_cell("z = undeclared_var + 1")
    print(f"Stdout: {result3['stdout']}")
    print(f"Stderr: {result3['stderr']}")
    # print(f"Current namespace: {kernel.user_ns}")
