import 'dart:async';
import 'dart:io';
import 'package:centrifuge/centrifuge.dart' as cfg;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peer_net/features/auth/application/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final centrifugoServiceProvider = Provider<CentrifugoService>((ref) {
  final authState = ref.watch(authControllerProvider);
  final user = authState.user.value;
  
  // Load from dotenv or use local default
  final wsUrl = dotenv.env['CENTRIFUGO_WS_URL'] ?? 'ws://localhost:8000/connection/websocket';

  final service = CentrifugoService(
    userId: user?.firebaseUid ?? '',
    wsUrl: wsUrl,
  );

  if (user != null) {
    service.init();
  } else {
    service.disconnect();
  }

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

class CentrifugoService extends WidgetsBindingObserver {
  final String userId;
  final String wsUrl;
  
  cfg.Client? _client;
  bool _isConnected = false;
  final _subscriptions = <String, cfg.Subscription>{};
  
  // Broadcast stream controller for incoming messages
  final _messageStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;

  CentrifugoService({required this.userId, required this.wsUrl});

  void init() {
    if (userId.isEmpty) return;
    WidgetsBinding.instance.addObserver(this);
    _connect();
  }

  Future<void> _connect() async {
    if (_client != null && _isConnected) return;

    try {
      _client = cfg.createClient(
        wsUrl,
        cfg.ClientConfig(
          getToken: (event) => _fetchConnectionToken(),
        ),
      );

      _client!.connected.listen((event) {
        debugPrint('Centrifugo: Connected successfully.');
        _isConnected = true;
        _resubscribeAll();
      });

      _client!.disconnected.listen((event) {
        debugPrint('Centrifugo: Disconnected. Reason: ${event.reason}');
        _isConnected = false;
      });

      await _client!.connect();
    } catch (e) {
      debugPrint('Centrifugo connection error: $e');
    }
  }

  Future<String> _fetchConnectionToken() async {
    try {
      // Call Supabase Edge Function to get secure connection JWT
      final response = await Supabase.instance.client.functions.invoke(
        'centrifugo-token',
        body: {'user_id': userId},
      );
      if (response.status == 200) {
        return response.data['token'] as String;
      }
    } catch (e) {
      debugPrint('Centrifugo: Token fetch error (using empty/mock token): $e');
    }
    // Return empty string if not configured yet; Centrifugo in insecure mode allows empty token/anonymous users
    return '';
  }

  Future<void> subscribeToChannel(String channelName) async {
    if (_client == null) return;
    if (_subscriptions.containsKey(channelName)) return;

    try {
      final subscription = _client!.newSubscription(channelName);
      
      subscription.publication.listen((event) {
        if (event.data is Map) {
          final dataMap = Map<String, dynamic>.from(event.data as Map);
          _messageStreamController.add(dataMap);
        }
      });

      await subscription.subscribe();
      _subscriptions[channelName] = subscription;
      debugPrint('Centrifugo: Subscribed to channel $channelName');
    } catch (e) {
      debugPrint('Centrifugo subscription error for $channelName: $e');
    }
  }

  void unsubscribeFromChannel(String channelName) {
    final sub = _subscriptions.remove(channelName);
    sub?.unsubscribe();
    debugPrint('Centrifugo: Unsubscribed from channel $channelName');
  }

  void _resubscribeAll() {
    final activeChannels = List<String>.from(_subscriptions.keys);
    _subscriptions.clear();
    for (final channel in activeChannels) {
      subscribeToChannel(channel);
    }
  }

  Future<void> disconnect() async {
    for (final sub in _subscriptions.values) {
      sub.unsubscribe();
    }
    _subscriptions.clear();
    
    if (_client != null) {
      await _client!.disconnect();
      _client = null;
    }
    _isConnected = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      disconnect();
    } else if (state == AppLifecycleState.resumed) {
      _connect();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disconnect();
    _messageStreamController.close();
  }
}
