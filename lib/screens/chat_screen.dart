import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../utils/colors.dart';
import '../services/messaging_provider.dart';
import '../models/message_model.dart';
import '../services/chat_attachment_service.dart';
import '../services/firestore_messaging_service.dart';

class ChatScreen extends StatefulWidget {
  final String contactId;
  final String contactName;
  final String contactAvatar;
  final String? contactProfilePicture;

  const ChatScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    required this.contactAvatar,
    this.contactProfilePicture,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  late ScrollController _scrollController;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPreviewPlayer = AudioPlayer();
  final AudioPlayer _audioMessagePlayer = AudioPlayer();
  final ChatAttachmentService _attachmentService = ChatAttachmentService();
  final FirestoreMessagingService _messagingService =
      FirestoreMessagingService();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Load messages for this contact
    Future.microtask(() {
      final messagingProvider = context.read<MessagingProvider>();
      messagingProvider.loadMessagesForContact(widget.contactId);
      messagingProvider.clearNewMatchFlag(widget.contactId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioPreviewPlayer.dispose();
    _audioMessagePlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      context.read<MessagingProvider>().sendMessage(
        contactId: widget.contactId,
        text: _textController.text.trim(),
      );
      _textController.clear();
      
      // Scroll to bottom after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.image, color: AppColors.black),
                title: Text('Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await _pickImage();
                  if (file != null) {
                    await _showMediaPreviewDialog(file, 'image');
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam, color: AppColors.black),
                title: Text('Video'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await _pickVideo();
                  if (file != null) {
                    await _showMediaPreviewDialog(file, 'video');
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.mic, color: AppColors.black),
                title: Text('Audio'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showAudioRecordDialog();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<File?> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    return picked != null ? File(picked.path) : null;
  }

  Future<File?> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    return picked != null ? File(picked.path) : null;
  }

  Future<void> _showMediaPreviewDialog(File file, String mediaType) async {
    VideoPlayerController? controller;

    if (mediaType == 'video') {
      controller = VideoPlayerController.file(file);
      await controller.initialize();
    }

    if (!mounted) {
      await controller?.dispose();
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Send ${mediaType == 'video' ? 'Video' : 'Photo'}?'),
          content: mediaType == 'video'
              ? AspectRatio(
                  aspectRatio: controller!.value.aspectRatio,
                  child: VideoPlayer(controller),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(file),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.black)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _sendAttachment(file, mediaType);
              },
              style: AppColors.primaryButtonStyle(),
              child: Text('Send'),
            ),
          ],
        );
      },
    );

    await controller?.dispose();
  }

  Future<void> _showAudioRecordDialog() async {
    String? recordedPath;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text('Record Audio'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    color: AppColors.black,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isRecording ? 'Recording...' : 'Tap to record',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (_isRecording) {
                      recordedPath = await _stopRecording();
                      setState(() {});
                    }
                    Navigator.pop(context);
                  },
                  child: Text('Close', style: TextStyle(color: AppColors.black)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_isRecording) {
                      recordedPath = await _stopRecording();
                      setState(() {});
                    } else {
                      await _startRecording();
                      setState(() {});
                    }
                  },
                  style: AppColors.primaryButtonStyle(),
                  child: Text(_isRecording ? 'Stop' : 'Record'),
                ),
              ],
            );
          },
        );
      },
    );

    if (recordedPath != null) {
      final file = File(recordedPath!);
      await _showAudioPreviewDialog(file);
    }
  }

  Future<void> _showAudioPreviewDialog(File file) async {
    await _audioPreviewPlayer.setFilePath(file.path);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Send Audio?'),
          content: Row(
            children: [
              IconButton(
                icon: Icon(Icons.play_arrow, color: AppColors.black),
                onPressed: () async {
                  await _audioPreviewPlayer.seek(Duration.zero);
                  await _audioPreviewPlayer.play();
                },
              ),
              Text('Preview recording'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.black)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _sendAttachment(file, 'audio');
              },
              style: AppColors.primaryButtonStyle(),
              child: Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startRecording() async {
    final canRecord = await _recorder.hasPermission();
    if (!canRecord) {
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = path.join(
      tempDir.path,
      'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    setState(() {
      _isRecording = true;
    });
  }

  Future<String?> _stopRecording() async {
    final recordedPath = await _recorder.stop();
    setState(() {
      _isRecording = false;
    });
    return recordedPath;
  }

  Future<void> _sendAttachment(File file, String mediaType) async {
    try {
      final attachmentId = await _attachmentService.uploadAttachment(
        contactId: widget.contactId,
        file: file,
        mediaType: mediaType,
      );

      await _messagingService.sendAttachmentMessage(
        contactId: widget.contactId,
        attachmentId: attachmentId,
        mediaType: mediaType,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send attachment: $e'),
            backgroundColor: AppColors.black,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ClipOval(
                child: widget.contactProfilePicture != null &&
                        widget.contactProfilePicture!.isNotEmpty
                    ? Image.network(
                        widget.contactProfilePicture!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildAvatarFallback(),
                      )
                    : _buildAvatarFallback(),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Consumer<MessagingProvider>(
                  builder: (context, messagingProvider, _) {
                    final statusText = messagingProvider.isConnected ? 'Online' : 'Offline';
                    final statusColor = messagingProvider.isConnected ? Colors.green : AppColors.textSecondary;
                    return Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Consumer<MessagingProvider>(
        builder: (context, messagingProvider, _) {
          final messages = messagingProvider.currentMessages;
          
          return Column(
            children: [
              // Messages list
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: messages.length,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
              ),
              
              // Message input
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider, width: 1),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.attach_file,
                            color: AppColors.textSecondary, size: 20),
                        onPressed: messagingProvider.isConnected
                            ? _showAttachmentSheet
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.divider, width: 1),
                        ),
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          enabled: messagingProvider.isConnected,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: messagingProvider.isConnected ? AppColors.black : AppColors.lightGray,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: AppColors.white, size: 20),
                        onPressed: messagingProvider.isConnected ? _sendMessage : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: AppColors.black,
      alignment: Alignment.center,
      child: Text(
        widget.contactAvatar,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.senderId == context.read<MessagingProvider>().currentUserId;
    final isAttachment = message.type == 'attachment';
    
    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: isMe ? 60 : 12,
        right: isMe ? 12 : 60,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  widget.contactAvatar,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? AppColors.black : AppColors.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMe ? 20 : 4),
                  topRight: Radius.circular(isMe ? 4 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isAttachment)
                    _buildAttachmentBubble(message, isMe)
                  else
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMe ? AppColors.white : AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isMe ? AppColors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.status == 'read' ? Icons.done_all : Icons.done,
                          size: 12,
                          color: isMe ? AppColors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentBubble(Message message, bool isMe) {
    final attachmentId = message.attachmentId;
    if (attachmentId == null || attachmentId.isEmpty) {
      return Text(
        'Attachment unavailable',
        style: TextStyle(
          color: isMe ? AppColors.white : AppColors.textPrimary,
          fontSize: 14,
        ),
      );
    }

    return StreamBuilder<ChatAttachment?>(
      stream: _attachmentService.watchAttachment(
        contactId: widget.contactId,
        attachmentId: attachmentId,
      ),
      builder: (context, snapshot) {
        final attachment = snapshot.data;
        if (attachment == null) {
          return Text(
            'Loading attachment...',
            style: TextStyle(
              color: isMe ? AppColors.white : AppColors.textPrimary,
              fontSize: 14,
            ),
          );
        }

        switch (attachment.mediaType) {
          case 'video':
            return _buildVideoAttachment(attachment, isMe);
          case 'audio':
            return _buildAudioAttachment(attachment, isMe);
          default:
            return _buildImageAttachment(attachment);
        }
      },
    );
  }

  Widget _buildImageAttachment(ChatAttachment attachment) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        attachment.mediaUrl,
        width: 180,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 180,
          height: 140,
          color: AppColors.divider,
          alignment: Alignment.center,
          child: Icon(Icons.broken_image, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(ChatAttachment attachment, bool isMe) {
    return GestureDetector(
      onTap: () => _playVideo(attachment.mediaUrl),
      child: Container(
        width: 180,
        height: 120,
        decoration: BoxDecoration(
          color: isMe ? AppColors.black : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_fill,
                color: isMe ? AppColors.white : AppColors.black, size: 32),
            const SizedBox(height: 6),
            Text(
              'Video',
              style: TextStyle(
                color: isMe ? AppColors.white : AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioAttachment(ChatAttachment attachment, bool isMe) {
    return GestureDetector(
      onTap: () => _playAudioMessage(attachment.mediaUrl),
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.black : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.play_arrow,
                color: isMe ? AppColors.white : AppColors.black),
            const SizedBox(width: 8),
            Text(
              'Audio',
              style: TextStyle(
                color: isMe ? AppColors.white : AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playAudioMessage(String url) async {
    try {
      await _audioMessagePlayer.setUrl(url);
      await _audioMessagePlayer.play();
    } catch (e) {
      // Ignore playback errors
    }
  }

  Future<void> _playVideo(String url) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    await controller.play();

    if (!mounted) {
      await controller.dispose();
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close', style: TextStyle(color: AppColors.black)),
            ),
          ],
        );
      },
    );

    await controller.dispose();
  }
}