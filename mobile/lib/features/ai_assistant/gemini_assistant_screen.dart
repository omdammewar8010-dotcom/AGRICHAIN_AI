import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chat_message_model.dart';
import '../../providers/providers.dart';

class GeminiAssistantScreen extends ConsumerStatefulWidget {
  const GeminiAssistantScreen({super.key});

  @override
  ConsumerState<GeminiAssistantScreen> createState() => _GeminiAssistantScreenState();
}

class _GeminiAssistantScreenState extends ConsumerState<GeminiAssistantScreen> {
  final _textController = TextEditingController();
  final List<ChatMessageModel> _messages = [
    ChatMessageModel(
      text: 'Hello! I am your AgriChain AI Agronomic Diagnostic Assistant, grounded with live telemetry for batch AGRI-2026-TOM-000124. How can I assist you with cold chain preservation or route decisions today?',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];
  bool _isLoading = false;

  void _sendMessage(String query) async {
    if (query.trim().isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.add(ChatMessageModel(text: query, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });

    final aiRepo = ref.read(aiRepoProvider);
    final response = await aiRepo.sendQuery(
      message: query,
      batchId: 'AGRI-2026-TOM-000124',
      cropName: 'Tomato',
      currentTemperature: 31.8,
      currentHumidity: 84.0,
      delayMinutes: 45.0,
      riskScore: 82.5,
      riskLevel: 'CRITICAL',
    );

    setState(() {
      _messages.add(response);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: AppTheme.accentGold, size: 22),
            SizedBox(width: 8),
            Text('Gemini Supply Chain AI'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Telemetry Context Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.darkSurface,
            child: const Row(
              children: [
                Icon(Icons.sensors, size: 14, color: AppTheme.primaryGreen),
                SizedBox(width: 6),
                Text(
                  'Grounded in Live Batch: AGRI-2026-TOM-000124 (31.8°C • +45 min delay)',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _chatBubble(msg);
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentGold)),
                  SizedBox(width: 10),
                  Text('Gemini AI analyzing telemetry...', style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),

          // Quick Question Prompts
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _promptChip('Why is this shipment risky?'),
                _promptChip('What caused the delay?'),
                _promptChip('What should the transporter do?'),
                _promptChip('Explain temperature trend'),
              ],
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppTheme.darkCard,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Ask Gemini about cargo condition or rerouting...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _promptChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: AppTheme.darkSurface,
        side: const BorderSide(color: AppTheme.darkBorder),
        label: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        onPressed: () => _sendMessage(text),
      ),
    );
  }

  Widget _chatBubble(ChatMessageModel msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isUser ? AppTheme.darkForest : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: msg.isUser ? AppTheme.primaryGreen.withOpacity(0.4) : AppTheme.darkBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
            if (msg.keyTakeaways.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(color: AppTheme.darkBorder),
              const Text(
                'Key Diagnostics:',
                style: TextStyle(color: AppTheme.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...msg.keyTakeaways.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('• $t', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  )),
            ],
            if (msg.suggestedActions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Prescribed Actions:',
                style: TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...msg.suggestedActions.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('➔ $a', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
