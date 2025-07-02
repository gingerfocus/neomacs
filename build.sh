# Find Python include and lib paths (adjust for your system/venv)
# Example for Python 3.x
PYTHON_INCLUDE=$(python3 -c "from sysconfig import get_paths; print(get_paths()['include'])")
PYTHON_LIB_DIR=$(python3 -c "import sys; print(sys.prefix + '/lib')")
PYTHON_LIB_NAME=$(python3 -c "import sysconfig; print(sysconfig.get_config_var('LDLIBRARY').split('.so')[0].replace('lib', ''))")

# Compile command
gcc kernel.c -o kernel -I"$PYTHON_INCLUDE" -L"$PYTHON_LIB_DIR" -l"$PYTHON_LIB_NAME" -Wl,-rpath "$PYTHON_LIB_DIR"
