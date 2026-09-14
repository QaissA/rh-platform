import 'dart:async';
import 'dart:convert';

import 'package:alize_mobile/core/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Map<String, dynamic>? parseCableFrame(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);
    final type = map['type'];
    if (type == 'welcome' || type == 'ping' || type == 'confirm_subscription') {
      return null;
    }
    final payload = map['message'];
    if (payload is Map && payload['type'] == 'message') {
      return Map<String, dynamic>.from(payload);
    }
    return null;
  } catch (_) {
    return null;
  }
}

typedef CableSocketConnect = WebSocketChannel Function(Uri uri);

typedef CableReconnectDelay = void Function(
  Duration delay,
  void Function() callback,
);

class ActionCableClient {
  ActionCableClient({
    required AppConfig config,
    required String? Function() token,
    CableSocketConnect? connect,
    CableReconnectDelay? scheduleReconnect,
    this.maxReconnectAttempts = 5,
  })  : _config = config,
        _token = token,
        _connect = connect ?? WebSocketChannel.connect,
        _scheduleReconnect = scheduleReconnect;

  final AppConfig _config;
  final String? Function() _token;
  final CableSocketConnect _connect;
  final CableReconnectDelay? _scheduleReconnect;
  final int maxReconnectAttempts;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  void Function(Map<String, dynamic> payload)? _handler;
  Timer? _reconnectTimer;
  bool _userClosed = true;
  int _attempts = 0;

  void setHandler(void Function(Map<String, dynamic> payload)? handler) {
    _handler = handler;
  }

  void connect() {
    _userClosed = false;
    _attempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _open();
  }

  void disconnect() {
    _userClosed = true;
    _attempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _tearDownSocket();
  }

  void _open() {
    _tearDownSocket();
    if (_userClosed) return;
    final jwt = _token();
    if (jwt == null || jwt.isEmpty) return;
    try {
      final uri = Uri.parse(
        '${_config.wsBaseUrl}/cable?token=${Uri.encodeComponent(jwt)}',
      );
      final channel = _connect(uri);
      _channel = channel;
      channel.sink.add(
        jsonEncode({
          'command': 'subscribe',
          'identifier': '{"channel":"ChatChannel"}',
        }),
      );
      _subscription = channel.stream.listen(
        _onFrame,
        onError: (_) => _handleDrop(),
        onDone: _handleDrop,
        cancelOnError: false,
      );
    } catch (_) {
      _handleDrop();
    }
  }

  void _handleDrop() {
    _tearDownSocket();
    if (_userClosed) return;
    final jwt = _token();
    if (jwt == null || jwt.isEmpty) return;
    if (_attempts >= maxReconnectAttempts) return;
    final delay = Duration(seconds: (1 << _attempts).clamp(1, 16));
    _attempts++;
    _reconnectTimer?.cancel();
    void retry() {
      if (_userClosed) return;
      _open();
    }

    final schedule = _scheduleReconnect;
    if (schedule != null) {
      schedule(delay, retry);
    } else {
      _reconnectTimer = Timer(delay, retry);
    }
  }

  void _tearDownSocket() {
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _onFrame(dynamic data) {
    final raw = switch (data) {
      String s => s,
      List<int> bytes => utf8.decode(bytes),
      _ => null,
    };
    if (raw == null) return;
    final payload = parseCableFrame(raw);
    if (payload != null) _handler?.call(payload);
  }
}
