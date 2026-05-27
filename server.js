const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 8080 });
let players = [];

console.log('⚡ NEO-NET Match Switchboard active on port 8080...');

wss.on('connection', (ws) => {
    // If we already have 2 players, reject any extra connections safely
    if (players.length >= 2) {
        ws.send(JSON.stringify({ type: 'lobby_full' }));
        ws.close();
        return;
    }

    players.push(ws);
    const playerID = players.length;
    console.log(`👤 Player ${playerID} synced to matrix.`);

    // Assign pieces immediately based on who joined first
    ws.send(JSON.stringify({
        type: 'assign_piece',
        piece: playerID === 1 ? 'X' : 'O'
    }));

    // If we hit exactly 2 players, kick off the match automatically!
    if (players.length === 2) {
        console.log('🎮 Match matrix initialized. Broadcasting start signals!');
        players[0].send(JSON.stringify({ type: 'start_game', yourTurn: true, opponent: 'Player 2' }));
        players[1].send(JSON.stringify({ type: 'start_game', yourTurn: false, opponent: 'Player 1' }));
    }

    // Handle incoming gameplay moves or reset requests
    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            // Find the other player in the array
            const opponent = players.find(p => p !== ws);
            
            if (opponent && opponent.readyState === WebSocket.OPEN) {
                opponent.send(JSON.stringify(data));
            }
        } catch (err) {
            console.log('⚠️ Error parsing incoming packet:', err.message);
        }
    });

    // SELF-HEALING CORES: Handle sudden drops automatically
    ws.on('close', () => {
        console.log(`❌ Player ${players.indexOf(ws) + 1} dropped from the session.`);
        
        // Remove the disconnected player from our tracking matrix
        players = players.filter(p => p !== ws);

        // Tell the remaining player (if there is one) that their opponent left
        if (players.length > 0) {
            console.log('📡 Remaining player notified. Returning lobby to matchmaking state...');
            players[0].send(JSON.stringify({ type: 'opponent_disconnected' }));
            
            // Re-assign the remaining player to be Player 1 (X) so they are ready for the next challenger
            players[0].send(JSON.stringify({ type: 'assign_piece', piece: 'X' }));
        } else {
            console.log('🧹 All sockets clear. Switchboard idling...');
        }
    });
});
