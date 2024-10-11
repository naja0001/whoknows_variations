#!/bin/bashshellcheck run_forever.sh


# This script is responsible for running the Python app forever

PYTHON_SCRIPT_PATH="$1"

# TMP is currently unused. Consider removing it if it is not necessary.
TMP="This variable might become useful at some point. Otherwise delete it."

while true; do
    # Run the Python script and check if it fails
    if ! python2 "$PYTHON_SCRIPT_PATH"; then
        # Store the exit code in a variable
        exit_code=$?
        # Print the error message with the stored exit code
        echo "Script crashed with exit code $exit_code. Restarting..." >&2
    fi
    # Wait 1 second before restarting the script
    sleep 1
done
