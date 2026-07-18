import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../base/res/styles/app_styles.dart';
import '../auth/application/auth_providers.dart';
import 'ai_controller.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFocusNode = FocusNode();

  String? _selectedPdfName;
  int? _selectedPdfSize;
  String? _selectedPdfBase64;

  String? _lastSessionId;
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final size = await file.length();

        if (size > 15 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File exceeds 15MB. Please choose a smaller PDF.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final bytes = await file.readAsBytes();
        setState(() {
          _selectedPdfName = result.files.single.name;
          _selectedPdfSize = size;
          _selectedPdfBase64 = base64Encode(bytes);
        });

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearSelectedPdf() {
    setState(() {
      _selectedPdfName = null;
      _selectedPdfSize = null;
      _selectedPdfBase64 = null;
    });
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedPdfBase64 == null) return;

    final controller = ref.read(peerAiControllerProvider.notifier);
    final pdfName = _selectedPdfName;
    final pdfSize = _selectedPdfSize;
    final pdfBase64 = _selectedPdfBase64;

    _textController.clear();
    _clearSelectedPdf();
    _textFocusNode.unfocus();

    await controller.sendMessage(
      text: text,
      pdfName: pdfName,
      pdfSize: pdfSize,
      base64Pdf: pdfBase64,
    );

    _scrollToBottom();
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Chat History?'),
          content: const Text('This will delete all stored conversations in this session from this device.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(peerAiControllerProvider.notifier).clearChat();
                Navigator.pop(context);
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(peerAiControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user.value;
    final nickname = user?.nickname ?? user?.name ?? 'Student';
    final controller = ref.read(peerAiControllerProvider.notifier);

    // Resolve active session messages
    final activeSessionId = aiState.activeSessionId;
    final activeSession = aiState.sessions.firstWhere(
      (s) => s.id == activeSessionId,
      orElse: () => PeerAiSession(
        id: '',
        title: 'New chat',
        messages: [],
        createdAt: DateTime.now(),
      ),
    );
    final activeMessages = activeSession.messages;

    // Listen for error messages and display a SnackBar
    ref.listen<PeerAiState>(peerAiControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppStyles.errorColor,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                controller.dismissError();
              },
            ),
          ),
        );
      }
    });

    // Smart auto-scroll only on message count change or session switch
    final currentMessageCount = activeMessages.length;
    final hasSessionChanged = activeSessionId != _lastSessionId;
    final hasNewMessages = currentMessageCount > _lastMessageCount;

    if (hasSessionChanged || hasNewMessages) {
      _lastSessionId = activeSessionId;
      _lastMessageCount = currentMessageCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppStyles.headingColor),
        titleSpacing: 0,
        title: Row(
          children: [
            const PeerAiSparkIcon(size: 22),
            const SizedBox(width: 8),
            const Text(
              'PEERai',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppStyles.headingColor,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(width: 6),
            const PulsingStatusDot(),
          ],
        ),
        actions: [
          if (activeMessages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppStyles.mutedText),
              tooltip: 'Clear Current Session',
              onPressed: _confirmClearChat,
            ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: _buildDrawer(context, aiState, controller),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: activeMessages.isEmpty
                  ? _buildWelcomeScreen(nickname)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: activeMessages.length + (aiState.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == activeMessages.length) {
                          return SlideFadeTransition(
                            key: const ValueKey('loading_bubble'),
                            child: _buildLoadingBubble(),
                          );
                        }
                        final message = activeMessages[index];
                        return SlideFadeTransition(
                          key: ValueKey('${message.timestamp.toIso8601String()}_$index'),
                          child: _buildChatBubble(message),
                        );
                      },
                    ),
            ),
            _buildInputSection(aiState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    PeerAiState aiState,
    PeerAiController controller,
  ) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  const PeerAiSparkIcon(size: 26),
                  const SizedBox(width: 10),
                  const Text(
                    'PEERai Sessions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.headingColor,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton.icon(
                onPressed: () {
                  controller.startNewSession();
                  Navigator.pop(context); // Close drawer
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: Color(0xFF4285F4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.add, color: Color(0xFF4285F4)),
                label: const Text(
                  'New Chat',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'RECENT CHATS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            Expanded(
              child: aiState.sessions.isEmpty
                  ? const Center(
                      child: Text(
                        'No recent conversations.',
                        style: TextStyle(color: AppStyles.mutedText, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: aiState.sessions.length,
                      itemBuilder: (context, index) {
                        final session = aiState.sessions[index];
                        final isActive = session.id == aiState.activeSessionId;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(left: 16, right: 8),
                            leading: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16,
                              color: isActive ? const Color(0xFF4285F4) : const Color(0xFF64748B),
                            ),
                            title: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                color: isActive ? const Color(0xFF1E3A8A) : AppStyles.headingColor,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                              onPressed: () {
                                controller.deleteSession(session.id);
                              },
                            ),
                            onTap: () {
                              controller.switchSession(session.id);
                              Navigator.pop(context); // Close drawer
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(String nickname) {
    final starterPrompts = [
      {
        'title': 'Summarize notes',
        'desc': 'Attach a PDF notes document and ask for a detailed summary.',
        'icon': Icons.summarize_outlined,
        'prompt': 'Please summarize this document.'
      },
      {
        'title': 'Explain concept',
        'desc': 'Break down any academic concept step-by-step.',
        'icon': Icons.school_outlined,
        'prompt': 'Can you explain the concept of '
      },
      {
        'title': 'Debug code',
        'desc': 'Paste code and ask for error fixes and optimization.',
        'icon': Icons.code_outlined,
        'prompt': 'Can you help me debug and optimize this code:\n```\n\n```'
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF4285F4),
                      Color(0xFF9B72CB),
                      Color(0xFFD96570),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Hello, $nickname',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'How can I help you study today?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'SUGGESTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: starterPrompts.length,
              itemBuilder: (context, index) {
                final item = starterPrompts[index];
                return GestureDetector(
                  onTap: () {
                    if (item['title'] == 'Summarize notes') {
                      _pickPdf();
                    } else {
                      _textController.text = item['prompt'] as String;
                      _textFocusNode.requestFocus();
                    }
                  },
                  child: Container(
                    width: 170,
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.015),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: const Color(0xFF4285F4),
                          size: 24,
                        ),
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(PeerAiMessage message) {
    final isUser = message.role == 'user';

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 18, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.pdfName != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          message.pdfName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppStyles.headingColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatSize(message.pdfSize),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppStyles.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SelectableText(
                message.text,
                style: const TextStyle(
                  color: AppStyles.headingColor,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Gemini response is background-less
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PeerAiSparkIcon(size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PeerAiFormattedText(text: message.text),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: message.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Response copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, size: 12, color: Color(0xFF64748B)),
                              SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const PeerAiSparkIcon(size: 20),
          const SizedBox(width: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'PEERai is thinking...',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedPdfName != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedPdfName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppStyles.headingColor,
                      ),
                    ),
                  ),
                  Text(
                    _formatSize(_selectedPdfSize),
                    style: const TextStyle(fontSize: 11, color: AppStyles.mutedText),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _clearSelectedPdf,
                    child: const Icon(Icons.close, size: 18, color: AppStyles.mutedText),
                  ),
                ],
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF64748B)),
                  tooltip: 'Attach PDF',
                  onPressed: isLoading ? null : _pickPdf,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _textFocusNode,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    decoration: const InputDecoration(
                      hintText: 'Type or share a PDF...',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: isLoading ? null : _handleSend,
                  child: Container(
                    margin: const EdgeInsets.only(right: 6, left: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isLoading ? Colors.grey.shade400 : const Color(0xFF4285F4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SparkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF4285F4),
          Color(0xFF9B72CB),
          Color(0xFFD96570),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w / 2, 0);
    path.quadraticBezierTo(w / 2, h / 2, w, h / 2);
    path.quadraticBezierTo(w / 2, h / 2, w / 2, h);
    path.quadraticBezierTo(w / 2, h / 2, 0, h / 2);
    path.quadraticBezierTo(w / 2, h / 2, w / 2, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PeerAiSparkIcon extends StatelessWidget {
  final double size;

  const PeerAiSparkIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: SparkPainter(),
    );
  }
}

class PulsingStatusDot extends StatefulWidget {
  const PulsingStatusDot({super.key});

  @override
  State<PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<PulsingStatusDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF4285F4),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class SlideFadeTransition extends StatefulWidget {
  final Widget child;
  const SlideFadeTransition({super.key, required this.child});

  @override
  State<SlideFadeTransition> createState() => _SlideFadeTransitionState();
}

class _SlideFadeTransitionState extends State<SlideFadeTransition> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class PeerAiFormattedText extends StatelessWidget {
  final String text;

  const PeerAiFormattedText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final RegExp codeBlockRegex = RegExp(r'```(?:[a-zA-Z]*)\n([\s\S]*?)\n```|```([\s\S]*?)```');
    final List<Widget> widgets = [];
    int lastIndex = 0;

    for (final Match match in codeBlockRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        final segment = text.substring(lastIndex, match.start);
        widgets.add(_buildRichText(segment));
      }

      final codeContent = match.group(1) ?? match.group(2) ?? '';
      widgets.add(_buildCodeBlock(context, codeContent.trim()));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      widgets.add(_buildRichText(text.substring(lastIndex)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichText(String segment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: MarkdownBody(
        data: segment,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: AppStyles.headingColor,
            fontFamily: 'OpenSans',
          ),
          h1: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppStyles.headingColor,
            fontFamily: 'Montserrat',
          ),
          h2: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppStyles.headingColor,
            fontFamily: 'Montserrat',
          ),
          h3: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppStyles.headingColor,
            fontFamily: 'Montserrat',
          ),
          em: const TextStyle(
            fontStyle: FontStyle.italic,
          ),
          strong: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppStyles.headingColor,
          ),
          listBullet: const TextStyle(
            color: AppStyles.headingColor,
          ),
          code: TextStyle(
            fontFamily: 'Courier',
            backgroundColor: Colors.grey.shade100,
            color: Colors.red.shade800,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCodeBlock(BuildContext context, String code) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Code Snippet',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.copy, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'Courier',
                color: Color(0xFFF8FAFC),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}