const http = require('http');
const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');

// Location of our persistent player database file
const USER_DATABASE_FILE = path.join(__dirname, 'users.json');

// Helper function to safely read user file
function loadUserDatabase() {
    if (!fs.existsSync(USER_DATABASE_FILE)) {
        fs.writeFileSync(USER_DATABASE_FILE, JSON.stringify({}));
    }
    try {
        const rawData = fs.readFileSync(USER_DATABASE_FILE, 'utf8');
        return JSON.parse(rawData);
    } catch (error) {
        console.error('⚠️ DB read error, resetting storage index:', error.message);
        return {};
    }
}

// Helper function to write updates to user file
function saveUserDatabase(database) {
    try {
        fs.writeFileSync(USER_DATABASE_FILE, JSON.stringify(database, null, 4));
    } catch (error) {
        console.error('❌ Failed to commit user account payload to disk:', error.message);
    }
}

// Create core HTTP health checker node
const server = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('⚡ NEO-NET Core Account Hub Online\n');
});

const wss = new WebSocket.Server({ server });
let waitingPlayer = null;

console.log('Deploying secure gaming server topology...');

wss.on('connection', (ws) => {
    // Inject internal identity tracking tracking tags directly onto the socket instance
    ws.isAuthenticated = false;
    ws.username = null;
    ws.opponent = null;

    console.log('👤 Unauthenticated connection stream established.');

    ws.on('message', (message) => {
        try {
            const packet = JSON.parse(message);

            // 1. REGISTRATION HANDLER
            if (packet.type === 'register') {
                const database = loadUserDatabase();
                const targetUser = packet.username.trim();

                if (!targetUser || !packet.password) {
                    ws.send(JSON.stringify({ type: 'auth_response', success: false, message: 'Invalid field data payloads.' }));
                    return;
                }

                if (database[targetUser.toLowerCase()]) {
                    ws.send(JSON.stringify({ type: 'auth_response', success: false, message: 'Identity signature already exists.' }));
                    console.log(`⚠️ Blocked redundant registration profile signature for: [${targetUser}]`);
                } else {
                    database[targetUser.toLowerCase()] = {
                        displayName: targetUser,
                        password: packet.password // Secure development sandbox verification string
                    };
                    saveUserDatabase(database);
                    
                    ws.isAuthenticated = true;
                    ws.username = targetUser;
                    ws.send(JSON.stringify({ type: 'auth_response', success: true, message: 'Registration secure.', username: targetUser }));
                    console.log(`📝 Created new account profile: [${targetUser}]`);
                }
                return;
            }

            // 2. LOGIN HANDLER
            if (packet.type === 'login') {
                const database = loadUserDatabase();
                const targetUser = packet.username.trim().toLowerCase();
                const profile = database[targetUser];

                if (profile && profile.password === packet.password) {
                    ws.isAuthenticated = true;
                    ws.username = profile.displayName;
                    ws.send(JSON.stringify({ type: 'auth_response', success: true, message: 'Authentication validated.', username: profile.displayName }));
                    console.log(`🔓 User authenticated successfully: [${profile.displayName}]`);
                } else {
                    ws.send(JSON.stringify({ type: 'auth_response', success: false, message: 'Access denied. Invalid credentials.' }));
                    console.log(`🔒 Failed authorization challenge for username string: [${packet.username}]`);
                }
                return;
            }

            // SECURITY SCREEN: Gate all gameplay telemetry updates behind authentication check
            if (!ws.isAuthenticated) {
                ws.send(JSON.stringify({ type: 'auth_response', success: false, message: 'Command rejected. Authenticate first.' }));
                return;
            }

            // 3. SECURE MATCHMAKING ROOM HANDLER
            if (packet.type === 'find_match') {
                if (waitingPlayer === ws) return; // Ignore duplicate queue taps

                if (!waitingPlayer) {
                    waitingPlayer = ws;
                    ws.send(JSON.stringify({ type: 'assign_piece', piece: 'X' }));
                    console.log(`⏳ [${ws.username}] queued inside matchmaking array. Waiting for partner allocation...`);
                } else {
                    const player1 = waitingPlayer;
                    const player2 = ws;
                    waitingPlayer = null; // Flush matching pointer

                    player1.opponent = player2;
                    player2.opponent = player1;

                    // Deliver custom profile labels down to client endpoints
                    player1.send(JSON.stringify({ type: 'start_game', yourTurn: true, opponent: player2.username }));
                    player2.send(JSON.stringify({ type: 'start_game', yourTurn: false, opponent: player1.username }));
                    console.log(`⚔️ Match Engaged: [${player1.username}] vs [${player2.username}]`);
                }
                return;
            }

            // 4. GAME MOVEMENT MATRIX TELEMETRY ROUTER
            if (ws.opponent && ws.opponent.readyState === WebSocket.OPEN) {
                if (packet.type === 'move') {
                    ws.opponent.send(JSON.stringify({ type: 'move', index: packet.index }));
                } else if (packet.type === 'reset') {
                    ws.opponent.send(JSON.stringify({ type: 'reset' }));
                }
            }

        } catch (err) {
            console.error('❌ Error rendering secure frame data operation:', err.message);
        }
    });

    ws.on('close', () => {
        console.log(`🔌 Connection line dropped for client: [${ws.username || 'Unauthenticated user'}]`);
        
        if (waitingPlayer === ws) {
            waitingPlayer = null;
            console.log('Flushed orphan index from lobby arrays.');
        }

        if (ws.opponent) {
            if (ws.opponent.readyState === WebSocket.OPEN) {
                ws.opponent.send(JSON.stringify({ type: 'opponent_disconnected' }));
            }
            ws.opponent.opponent = null;
            ws.opponent = null;
        }
    });
});

server.listen(8080, '0.0.0.0', () => {
    console.log('⚡ NEO-NET Core Switchboard + Account Persistence engine running on port 8080...');
});
