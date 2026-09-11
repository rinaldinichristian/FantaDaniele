import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/auth_provider.dart';
import '../../logic/firestore_repository.dart';
import '../../models/app_user.dart';

final chatProvider = StreamProvider<List<ChatMessage>>((ref) {
  return ref.watch(firestoreRepositoryProvider).watchChatMessages();
});

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();

  void _sendMessage(String text, AppUser? user) {
    if (text.trim().isEmpty || user == null) return;
    ref.read(firestoreRepositoryProvider).sendMessage(
      userId: user.id,
      userName: user.name,
      text: text.trim(),
    );
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider);
    final leaderboard = ref.watch(leaderboardProvider).value ?? [];
    final firebaseUser = ref.watch(authStateProvider).value;
    final appUser = leaderboard.where((u) => u.id == firebaseUser?.uid).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gruppo'),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('Nessun messaggio. Scrivi qualcosa!'));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.userId == appUser?.id;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              Text(
                                msg.userName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              msg.text,
                              style: TextStyle(
                                color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Errore: $err')),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Scrivi un messaggio...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      onSubmitted: (val) => _sendMessage(val, appUser),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary),
                      onPressed: () => _sendMessage(_textController.text, appUser),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
