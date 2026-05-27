#!/bin/bash

# 1. Clear out any ghost processes camping on port 8080
kill -9 $(lsof -t -i:8080) 2>/dev/null

# 2. Find where this script is located so we can locate server.js
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 3. Start the Node server in the absolute background (&) so Xcode doesn't freeze up waiting for it
node "$SCRIPT_DIR/server.js" &
