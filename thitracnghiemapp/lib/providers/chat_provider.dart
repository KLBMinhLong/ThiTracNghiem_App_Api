import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service;
  ChatProvider(this._service);

  int? _ketQuaThiId;
  final List<ChatMessage> _messages = [];
  bool _sending = false;
  String? _error;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get sending => _sending;
  String? get error => _error;

  void setContext({required int ketQuaThiId}) {
    if (_ketQuaThiId != ketQuaThiId) {
      _ketQuaThiId = ketQuaThiId;
      _messages.clear();
      _error = null;
      notifyListeners();
    }
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty || _ketQuaThiId == null) return;
    _messages.add(ChatMessage(role: 'user', content: text));
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      final reply = await _service.sendMessage(
        ketQuaThiId: _ketQuaThiId!,
        message: text,
      );
      _messages.add(ChatMessage(role: 'assistant', content: reply));
    } catch (e) {
      _error = e.toString();
    } finally {
      _sending = false;
      notifyListeners();
    }
  }
}
