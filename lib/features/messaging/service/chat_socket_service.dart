import 'dart:async';
import 'dart:convert';
import 'dart:io'
    if (dart.library.html) 'package:reservation_chat_univercity_project/core/utils/io_stub.dart'
    as io;

import 'package:flutter/foundation.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_constants.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';

class RealtimeSocketPacket {
  final String event;
  final Map<String, dynamic> data;

  const RealtimeSocketPacket({required this.event, required this.data});
}

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  io.WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSub;
  final StreamController<RealtimeSocketPacket> _packetController =
      StreamController<RealtimeSocketPacket>.broadcast();

  bool _isConnected = false;
  String? _currentConversationId;
  void Function(String? conversationId, int? closeCode)? _onDisconnectCallback;

  bool get isConnected => _isConnected;
  String? get currentConversationId => _currentConversationId;
  Stream<RealtimeSocketPacket> get eventsStream => _packetController.stream;

  void _log(Object? message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[ChatWebSocket] $message');
    }
  }

  void setOnDisconnectCallback(
    void Function(String? conversationId, int? closeCode)? callback,
  ) {
    _onDisconnectCallback = callback;
  }

  /// ساخت آدرس استاندارد وب‌سوکت Django Channels:
  /// ws(s)://<host>/ws/chat/<conversation_id>/
  String _buildWebSocketUrl(String conversationId, String token) {
    final rawBase = AppConstants.appBaseUrl.trim();
    final baseUri = Uri.tryParse(rawBase);

    final scheme = (baseUri?.scheme == 'https') ? 'wss' : 'ws';
    final host = baseUri?.host ?? '192.168.1.101';
    final port = baseUri?.hasPort == true ? ':${baseUri!.port}' : '8000';

    // در وب به دلیل محدودیت ارسال هدر سفارشی در مرورگر از query param استفاده می‌شود
    if (kIsWeb) {
      return '$scheme://$host$port/ws/chat/$conversationId/?token=${Uri.encodeComponent(token)}';
    }
    return '$scheme://$host$port/ws/chat/$conversationId/';
  }

  Future<bool> connectToConversation(String conversationId) async {
    if (_socket != null &&
        _isConnected &&
        _currentConversationId == conversationId) {
      _log('Already connected to conversation $conversationId');
      return true;
    }

    await disconnect();

    final token = prefs.getString(AppConstants.userToken) ?? '';
    if (token.isEmpty) {
      _log('No JWT token found, cannot connect to WebSocket');
      return false;
    }

    _currentConversationId = conversationId;
    final wsUrl = _buildWebSocketUrl(conversationId, token);

    try {
      _log('Connecting to $wsUrl ...');
      _socket = await io.WebSocket.connect(
        wsUrl,
        headers: kIsWeb ? null : {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 8));

      _socket!.pingInterval = const Duration(seconds: 20);
      _isConnected = true;
      _log('Connected to conversation $conversationId');

      _socketSub = _socket!.listen(
        _onRawMessage,
        onError: (Object error) {
          _log('Socket error: $error');
          _handleSocketClosed();
        },
        onDone: () {
          _log('Socket closed with code: ${_socket?.closeCode}');
          _handleSocketClosed();
        },
        cancelOnError: true,
      );

      return true;
    } catch (e) {
      _log('Failed to connect WebSocket: $e');
      _isConnected = false;
      return false;
    }
  }

  void _onRawMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final eventName = decoded['event']?.toString() ?? '';
      final rawData = decoded['data'];
      final dataMap = rawData is Map<String, dynamic>
          ? rawData
          : <String, dynamic>{};

      if (eventName.isNotEmpty) {
        _packetController.add(
          RealtimeSocketPacket(event: eventName, data: dataMap),
        );
      }
    } catch (e) {
      _log('Invalid JSON payload from WebSocket: $e');
    }
  }

  void _handleSocketClosed() {
    final prevConversationId = _currentConversationId;
    final closeCode = _socket?.closeCode;
    _isConnected = false;
    _socket = null;
    _onDisconnectCallback?.call(prevConversationId, closeCode);
  }

  void _sendJson(String event, Map<String, dynamic> data) {
    if (_socket == null || !_isConnected) {
      _log('Cannot send $event: WebSocket not connected');
      return;
    }
    try {
      _socket!.add(jsonEncode({'event': event, 'data': data}));
    } catch (e) {
      _log('Error sending $event over WebSocket:$e');
    }
  }

  /// ارسال رویداد شروع تایپ: `{"event": "typing.start", "data": {}}`
  void sendTypingStart() {
    _sendJson('typing.start', const {});
  }

  /// ارسال رویداد پایان تایپ: `{"event": "typing.stop", "data": {}}`
  void sendTypingStop() {
    _sendJson('typing.stop', const {});
  }

  /// ارسال رویداد خوانده‌شدن پیام: `{"event": "message.seen", "data": {"message_id": "..."}}`
  void sendMessageSeen(String messageId) {
    if (messageId.isEmpty) return;
    _sendJson('message.seen', {'message_id': messageId});
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _currentConversationId = null;
    await _socketSub?.cancel();
    _socketSub = null;
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
  }
}

final chatSocketService = ChatSocketService();
