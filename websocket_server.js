/**
 * Sample WebSocket Server for Smart Wristband Chat
 * Run with: npm install ws && node websocket_server.js
 */

const WebSocket = require('ws');
const http = require('http');

const server = http.createServer();
const wss = new WebSocket.Server({ server });

// Store active connections
const connections = new Map(); // userId -> { ws, userInfo }

wss.on('connection', (ws) => {
  console.log('✅ Client connected. Total clients:', wss.clients.size);
  
  let userId = null;

  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data.toString());
      
      switch (message.type) {
        case 'auth':
          handleAuth(ws, message);
          userId = message.userId;
          break;
          
        case 'message':
          handleMessage(ws, message);
          break;
          
        case 'typing':
          handleTyping(ws, message);
          break;
          
        case 'status':
          handleStatusUpdate(ws, message);
          break;
          
        default:
          console.log('❓ Unknown message type:', message.type);
      }
    } catch (error) {
      console.error('❌ Error processing message:', error);
      ws.send(JSON.stringify({
        type: 'error',
        message: 'Invalid message format'
      }));
    }
  });

  ws.on('close', () => {
    if (userId && connections.has(userId)) {
      connections.delete(userId);
      console.log(`⛔ User ${userId} disconnected. Total clients:`, wss.clients.size);
      notifyOnlineStatus(userId, false);
    }
  });

  ws.on('error', (error) => {
    console.error('❌ WebSocket error:', error);
  });
});

// Handle authentication
function handleAuth(ws, data) {
  const userId = data.userId;
  const userInfo = {
    ws,
    name: data.userName,
    avatar: data.userAvatar,
    lastSeen: new Date()
  };

  connections.set(userId, userInfo);
  console.log(`✅ User authenticated: ${userId} (${data.userName})`);

  // Send confirmation
  ws.send(JSON.stringify({
    type: 'status',
    status: 'authenticated',
    userId: userId
  }));

  // Notify others that user is online
  notifyOnlineStatus(userId, true);
}

// Handle incoming messages
function handleMessage(ws, message) {
  const senderId = message.senderId;
  const recipientId = message.recipientId;
  const timestamp = new Date(message.timestamp);

  console.log(`📨 Message from ${senderId} to ${recipientId}: ${message.text}`);

  // Mark as delivered
  const deliveredMessage = {
    ...message,
    status: 'delivered',
    deliveredAt: new Date().toIso8601String()
  };

  // Send to sender's other devices (confirmation)
  const senderConnection = connections.get(senderId);
  if (senderConnection) {
    senderConnection.ws.send(JSON.stringify(deliveredMessage));
  }

  // Send to recipient if online
  const recipientConnection = connections.get(recipientId);
  if (recipientConnection && recipientConnection.ws.readyState === WebSocket.OPEN) {
    recipientConnection.ws.send(JSON.stringify({
      ...message,
      status: 'delivered'
    }));
    console.log(`✅ Message delivered to ${recipientId}`);
  } else {
    console.log(`⏳ User ${recipientId} offline. Message will be queued.`);
    // In production: save to database for offline delivery
  }
}

// Handle typing indicators
function handleTyping(ws, message) {
  const senderId = message.senderId;
  const recipientId = message.recipientId;

  const recipientConnection = connections.get(recipientId);
  if (recipientConnection && recipientConnection.ws.readyState === WebSocket.OPEN) {
    recipientConnection.ws.send(JSON.stringify({
      type: 'typing',
      userId: senderId,
      isTyping: message.isTyping
    }));
  }
}

// Handle status updates
function handleStatusUpdate(ws, message) {
  const userId = message.userId;
  const status = message.status; // 'online', 'away', 'offline', 'read'

  if (connections.has(userId)) {
    const userConnection = connections.get(userId);
    userConnection.status = status;
    userConnection.lastSeen = new Date();

    // Broadcast status to contacts
    broadcast({
      type: 'status',
      userId: userId,
      status: status,
      lastSeen: userConnection.lastSeen
    });
  }
}

// Notify others about online status
function notifyOnlineStatus(userId, isOnline) {
  broadcast({
    type: 'status',
    userId: userId,
    status: isOnline ? 'online' : 'offline',
    timestamp: new Date().toIso8601String()
  });
}

// Broadcast message to all connected clients
function broadcast(data) {
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(data));
    }
  });
}

// Start server
const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log(`🚀 WebSocket server running on ws://localhost:${PORT}`);
  console.log('💡 Listening for connections...');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('📴 Shutting down...');
  server.close(() => {
    console.log('🛑 Server closed');
    process.exit(0);
  });
});
