# WebSocket Real-Time Messaging Setup Guide

## Overview
This guide explains how to set up and use the real-time WebSocket messaging system in the Smart Wristband app.

## Architecture

### Client-Side (Flutter)
- **WebSocketService**: Handles low-level WebSocket connections
- **MessagingProvider**: State management for conversations and messages
- **ChatScreen**: Real-time message display and sending
- **MessagesTab**: Conversation list with live updates

### Server-Side (Node.js)
- Express + WebSocket server
- Handles authentication, message routing, and status updates
- Can be extended with Firebase for persistent storage

## Installation

### 1. Install Server Dependencies
```bash
npm init -y
npm install ws express
```

### 2. Configure Server URL
Update the WebSocket URL in your Flutter app. In `MessagingProvider.initialize()`:

```dart
await messagingProvider.initialize(
  userId: 'user_123',
  userName: 'John Doe',
  userAvatar: 'JD',
  wsUrl: 'ws://your_server_ip:8080', // Change to your server
);
```

### 3. Run the Server
```bash
node websocket_server.js
```

Expected output:
```
🚀 WebSocket server running on ws://localhost:8080
💡 Listening for connections...
```

## Features Implemented

### ✅ Real-Time Messaging
- Messages appear instantly without page refresh
- Optimistic UI updates (message shows immediately)
- Message status tracking: pending → sent → delivered → read

### ✅ Automatic Reconnection
- Auto-reconnects on disconnection (up to 5 attempts)
- 3-second delay between reconnection attempts
- Maintains message queue during offline periods

### ✅ Connection Status
- Real-time connection indicator (green/red dot)
- Status display in chat header
- Input disabled when offline

### ✅ Message Features
- Timestamps for all messages
- Sender/recipient tracking
- Avatar display
- Unread message counts
- Message status indicators (✓ sent, ✓✓ delivered)

### ✅ Conversation Management
- Multiple conversation support
- Last message preview
- Active conversation tracking
- Conversation history

## Message Protocol

### Authentication
```json
{
  "type": "auth",
  "userId": "user_123",
  "userName": "John Doe",
  "userAvatar": "JD",
  "timestamp": "2026-02-05T10:30:00Z"
}
```

### Send Message
```json
{
  "type": "message",
  "id": "1707116400000",
  "senderId": "user_123",
  "senderName": "John Doe",
  "senderAvatar": "JD",
  "recipientId": "user_456",
  "text": "Hello there!",
  "timestamp": "2026-02-05T10:30:15Z",
  "status": "pending"
}
```

### Receive Message
```json
{
  "type": "message",
  "id": "1707116400001",
  "senderId": "user_456",
  "senderName": "Jane Smith",
  "senderAvatar": "JS",
  "recipientId": "user_123",
  "text": "Hi! How are you?",
  "timestamp": "2026-02-05T10:30:20Z",
  "status": "delivered"
}
```

### Status Update
```json
{
  "type": "status",
  "status": "online",
  "userId": "user_123",
  "timestamp": "2026-02-05T10:30:00Z"
}
```

## Usage in Your App

### Initialize Messaging (in Home Screen or Main)
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final userContext = context.read<UserContext>();
    context.read<MessagingProvider>().initialize(
      userId: userContext.user!.id,
      userName: userContext.user!.name,
      userAvatar: userContext.user!.name[0],
      wsUrl: 'ws://your_server:8080',
    );
  });
}
```

### Send a Message
```dart
context.read<MessagingProvider>().sendMessage(
  recipientId: 'user_456',
  text: 'Hello!',
);
```

### Listen to Messages
The UI automatically updates via Provider's `Consumer` widget:
```dart
Consumer<MessagingProvider>(
  builder: (context, messagingProvider, _) {
    final messages = messagingProvider.currentMessages;
    // UI updates automatically
  },
)
```

## Deployment

### Local Testing
```bash
# Terminal 1: Run WebSocket server
node websocket_server.js

# Terminal 2: Run Flutter app
flutter run
```

### Production Deployment

#### Option 1: Heroku
```bash
git init
heroku create your-app-name
git push heroku main
```

Set environment variables:
```bash
heroku config:set PORT=8080
```

#### Option 2: AWS EC2
1. Launch EC2 instance (Node.js compatible)
2. Install Node.js and dependencies
3. Run server with PM2 for persistence:
```bash
npm install -g pm2
pm2 start websocket_server.js
pm2 startup
pm2 save
```

#### Option 3: Firebase Cloud Functions
- Deploy WebSocket server as Cloud Function
- Update Firebase configuration in Flutter app

## Troubleshooting

### ❌ WebSocket connection fails
```
❌ WebSocket connection error: Connection refused
```
**Solution**: 
- Check server is running: `node websocket_server.js`
- Verify correct IP/port in Flutter app
- Check firewall rules

### ❌ Messages not appearing
**Solution**:
- Check console logs on both client and server
- Verify recipient is online
- Check message format in protocol

### ❌ Auto-reconnect not working
**Solution**:
- Check max reconnect attempts (default: 5)
- Verify network connectivity
- Check error logs in console

## Advanced Features (Future)

- [ ] Message persistence in Firebase
- [ ] Group chats
- [ ] Typing indicators
- [ ] Read receipts (fully implemented)
- [ ] Message encryption
- [ ] Voice/video calls
- [ ] File sharing
- [ ] Message search

## Performance Tips

1. **Limit message history**: Only load last 50 messages per conversation
2. **Batch updates**: Group multiple messages in single update
3. **Lazy load conversations**: Load conversation list first, details on demand
4. **Compress messages**: Use message compression for large payloads
5. **Connection pooling**: Reuse WebSocket connection for multiple conversations

## Security Considerations

1. **Authentication**: Validate user tokens on server
2. **Message validation**: Sanitize all user inputs
3. **Rate limiting**: Prevent spam messages
4. **Encryption**: Use WSS (WebSocket Secure) in production
5. **Access control**: Verify users can only access their own messages

## Support

For issues or questions:
1. Check console logs (Flutter DevTools)
2. Enable debug logging in WebSocketService
3. Verify server logs
4. Check message protocol compliance
