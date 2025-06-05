set -e

LAMBDA_FUNCTION_NAME=$1

if [ -z "$LAMBDA_FUNCTION_NAME" ]; then
    echo "ERROR: No Lambda function directory name provided."
    echo "Usage: $0 <lambda_function_directory_name>"
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT_DIR=$(dirname "$SCRIPT_DIR")
LAMBDA_BASE_DIR="terraform/modules/lambda/lambda_functions"

TARGET_LAMBDA_DIR="${PROJECT_ROOT_DIR}/${LAMBDA_BASE_DIR}/${LAMBDA_FUNCTION_NAME}"

if [ ! -d "$TARGET_LAMBDA_DIR" ]; then
    echo "ERROR: Directory not found: ${TARGET_LAMBDA_DIR}"
    echo "Please ensure the Lambda function directory '${LAMBDA_FUNCTION_NAME}' exists under '${PROJECT_ROOT_DIR}/${LAMBDA_BASE_DIR}/'"
    exit 1
fi

echo "---------------------------------------------------------------------"
echo "Building package for Lambda function: ${LAMBDA_FUNCTION_NAME}"
echo "Target Lambda source directory: ${TARGET_LAMBDA_DIR}"
echo "---------------------------------------------------------------------"

ORIGINAL_CWD=$(pwd)
cd "$TARGET_LAMBDA_DIR"

VENV_PATH=".venv/bin/activate"
VENV_ACTIVATED=false
if [ -f "$VENV_PATH" ]; then
    echo "Activating virtual environment: $VENV_PATH"
    source "$VENV_PATH"
    VENV_ACTIVATED=true
else
    echo "WARNING: Virtual environment activation script not found at ${TARGET_LAMBDA_DIR}/${VENV_PATH}."
    echo "         Dependency installation might use system Python or fail."
    echo "         Make sure you have created a .venv for this Lambda (e.g., python3 -m venv .venv)."
fi

echo "Removing old package directory (if it exists)..."
rm -rf package

echo "Creating new package directory..."
mkdir package
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create package directory in $(pwd)."
    if [ "$VENV_ACTIVATED" = true ] && type deactivate > /dev/null 2>&1; then deactivate; fi
    cd "$ORIGINAL_CWD"
    exit 1
fi

if [ -f "app.py" ]; then
  echo "Copying app.py to package directory..."
  cp app.py ./package/
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to copy app.py in $(pwd)."
    if [ "$VENV_ACTIVATED" = true ] && type deactivate > /dev/null 2>&1; then deactivate; fi
    cd "$ORIGINAL_CWD"
    exit 1
  fi
else
    echo "ERROR: app.py not found in $(pwd)."
    if [ "$VENV_ACTIVATED" = true ] && type deactivate > /dev/null 2>&1; then deactivate; fi
    cd "$ORIGINAL_CWD"
    exit 1
fi

if [ -f "requirements.txt" ]; then
    if [ -s "requirements.txt" ]; then
        echo "Installing dependencies from requirements.txt into ./package directory..."
        python -m pip install -r requirements.txt -t ./package
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to install requirements in $(pwd)."
            if [ "$VENV_ACTIVATED" = true ] && type deactivate > /dev/null 2>&1; then deactivate; fi
        cd "$ORIGINAL_CWD"
        exit 1
    fi
    echo "Dependencies installed."
  else
    echo "requirements.txt is empty, no dependencies to - install."
  fi
else
  echo "requirements.txt not found, skipping dependency installation."
fi

ZIP_FILE_NAME="${LAMBDA_FUNCTION_NAME}_lambda.zip"
echo "Creating ZIP file: ${ZIP_FILE_NAME} from contents of package/ directory..."
cd package
zip -r "../${ZIP_FILE_NAME}" .
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create ZIP file."
    cd ..
    if [ "$VENV_ACTIVATED" = true ] && type deactivate > /dev/null 2>&1; then deactivate; fi
    cd "$ORIGINAL_CWD"
    exit 1
fi
cd ..

echo "-------------------------------------------------------------"
echo "Lambda package created successfully: ${TARGET_LAMBDA_DIR}/${ZIP_FILE_NAME}"
echo "-------------------------------------------------------------"

if [ "$VENV_ACTIVATED" = true ] && type deactivate > /dev/null 2>&1; then
  echo "Deactivating virtual environment..."
  deactivate
fi

cd "$ORIGINAL_CWD"
echo "Returned to directory $(pwd)"

exit 0
