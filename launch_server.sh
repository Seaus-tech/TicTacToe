#!/bin/bash

# Ensure the script doesn't stop if a command returns a minor warning
set +e

# 1. Clear out old background tasks on port 8080 silently
PID=$(lsof -t -i:8080)
if [ ! -z "$PID" ]; then
    kill -9 $PID 2>/dev/null
fi

# 2. Grab the exact location of your project folder
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 3. Spin up Node.js silently into the deep background
# > /dev/null 2>&1 disconnects it from Xcode's console so it won't trigger warnings
node "$SCRIPT_DIR/server.js" > /dev/null 2>&1 &

# 4. Tell Xcode everything exited flawlessly with a clean 0 code
exit 0
