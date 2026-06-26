#!/bin/bash

# Ensure the script doesn't stop if a command returns a minor warning
set +e

# 1. Inject paths and dynamically resolve Node's path from the user's login shell environment
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

USER_NODE=$(/bin/zsh -c -l "which node" 2>/dev/null) || true
if [ ! -z "$USER_NODE" ] && [ -x "$USER_NODE" ]; then
    NODE_BIN="$USER_NODE"
else
    NODE_BIN=$(which node 2>/dev/null) || true
fi

if [ -z "$NODE_BIN" ]; then
    for path in "/Users/YashB/.local/homebrew/bin/node" "/opt/homebrew/bin/node" "/usr/local/bin/node" "/usr/bin/node"; do
        if [ -x "$path" ]; then
            NODE_BIN="$path"
            break
        fi
    done
fi

if [ -z "$NODE_BIN" ]; then
    NODE_BIN="node"
fi

# Determine the root workspace directory where server.js lives
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ -f "$SCRIPT_DIR/server.js" ]; then
    WORKSPACE_DIR="$SCRIPT_DIR"
elif [ -f "$SCRIPT_DIR/../server.js" ]; then
    WORKSPACE_DIR="$SCRIPT_DIR/.."
else
    WORKSPACE_DIR="$SCRIPT_DIR" # default fallback
fi

# Create a diagnostic log right in your project folder to catch any silent errors
# If WORKSPACE_DIR is parent, then TicTacToe folder is WORKSPACE_DIR/TicTacToe
if [ -d "$WORKSPACE_DIR/TicTacToe" ]; then
    DEBUG_LOG="$WORKSPACE_DIR/TicTacToe/server_launch_debug.log"
    OUTPUT_LOG="$WORKSPACE_DIR/TicTacToe/server_output.log"
else
    DEBUG_LOG="$WORKSPACE_DIR/server_launch_debug.log"
    OUTPUT_LOG="$WORKSPACE_DIR/server_output.log"
fi

echo "🚀 Target Initialization: $(date)" > "$DEBUG_LOG"
echo "Resolved Node binary to: $NODE_BIN" >> "$DEBUG_LOG"
echo "Resolved Workspace Directory to: $WORKSPACE_DIR" >> "$DEBUG_LOG"

# 2. Clear out old background tasks on port 8080 silently
PID=$(lsof -t -i:8080)
if [ ! -z "$PID" ]; then
    echo "Found ghost process ($PID) camping on 8080. Evicting..." >> "$DEBUG_LOG"
    kill -9 $PID 2>/dev/null
fi

# 3. Spin up Node.js silently into the deep background
echo "Spawning background engine..." >> "$DEBUG_LOG"

if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import os, sys, subprocess
try:
    os.setsid() # Breaks out of Xcode's process-reaper group completely
    os.chdir(sys.argv[1])
    with open(sys.argv[3], 'w') as log:
        subprocess.Popen([sys.argv[2], 'server.js'], stdout=log, stderr=log)
    print('Success: Node process detached and backgrounded.')
except Exception as e:
    print(f'Python execution crash: {e}')
" "$WORKSPACE_DIR" "$NODE_BIN" "$OUTPUT_LOG" >> "$DEBUG_LOG" 2>&1
else
    # Fallback to pure shell backgrounding if python3 is missing
    nohup "$NODE_BIN" "$WORKSPACE_DIR/server.js" > "$OUTPUT_LOG" 2>&1 &
    echo "Success: Backgrounded server using nohup." >> "$DEBUG_LOG"
fi

echo "🏁 Build phase script complete." >> "$DEBUG_LOG"

# 4. Tell Xcode everything exited flawlessly with a clean 0 code
exit 0
