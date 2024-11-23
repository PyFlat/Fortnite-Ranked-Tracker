import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../constants/endpoints.dart';
import 'rank_service.dart';

class StreamSocket {}

class SocketService {
  Socket? _socket;
  static bool _isInitialized = false;

  // Use broadcast for multiple listeners.
  final _socketResponse = StreamController<Map?>.broadcast();

  void Function(Map?) get addResponse => _socketResponse.sink.add;

  Stream<Map?> get getStream => _socketResponse.stream;

  SocketService._();

  static final SocketService _instance = SocketService._();

  factory SocketService() => _instance;

  void connectToSocket() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    final optionBuilder = OptionBuilder()
        .enableForceNew()
        .enableReconnection()
        .setExtraHeaders(
            {"authorization": await RankService().getBasicAuthHeader()});

    if (!kIsWeb) {
      optionBuilder.setTransports(['websocket']);
    } else {
      optionBuilder.setTransports(['polling']);
    }

    _socket = io(Endpoints.baseUrl, optionBuilder.build());

    _socket!.onConnect((_) {
      print("Connected to the server");
    });

    _socket!.onError((error) {
      print("Socket error: $error");
    });

    _socket!.on('rankedProgress', (data) {
      addResponse(data);
    });
  }

  void dispose() {
    _socketResponse.close();
  }
}
