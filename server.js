// Run this in terminal using: node server.js
const { WebSocketServer } = require('ws');

// Spin up the network switchboard on port 8080
const wss = new WebSocketServer({ port: 8080 });
console.log("⚡ NEO-NET Match Switchboard active on port 8080...");

let players = [];

wss.on('connection', (ws) => {
    // Drop the player into our matchmaking array
    if (players.length < 2) {
        players.push(ws);
        console.log(`👤 Player ${players.length} synced to matrix.`);
        
        // Assign pieces based on who joined first
        ws.send(JSON.stringify({ type: "assign_piece", piece: players.length === 1 ? "X" : "O" }));
    } else {
        ws.send(JSON.stringify({ type: "error", message: "Server configuration full." }));
        ws.close();
        return;
    }

    // When both nodes are linked, spark the game loop start
    if (players.length === 2) {
        players[0].send(JSON.stringify({ type: "start_game", yourTurn: true, opponent: "Player_2" }));
        players[1].send(JSON.stringify({ type: "start_game", yourTurn: false, opponent: "Player_1" }));
        console.log("🎮 Match matrix initialized. Broadcasting start signals!");
    }

    // Route incoming moves to the other player instantly
    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            const target = players.find(p => p !== ws);
            if (target) {
                target.send(JSON.stringify(data));
            }
        } catch (e) {
            console.log("⚠️ Received corrupted packet payload.");
        }
    });

    // Handle abrupt disconnections cleanly
    ws.on('close', () => {
        console.log("❌ A player dropped from the session. Resetting switchboard.");
        players = players.filter(p => p !== ws);
        players.forEach(p => p.send(JSON.stringify({ type: "opponent_disconnected" })));
        players = []; // Wipe the room so players can re-join
    });
});
