import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../constants/endpoints.dart';
import 'rank_service.dart';
import 'talker_service.dart';

class StreamSocket {}

class SocketService {
  Socket? _socket;
  List? data;
  static bool _isInitialized = false;

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
      talker.verbose("Connected to socket.io server");
    });

    _socket!.onDisconnect((_) {
      talker.warning("Disconnected from socket.io server");
    });

    _socket!.onError((error) {
      talker.error("Socket error: $error");
    });

    _socket!.on('rankedProgress', (data) {
      addResponse(data);
    });

    _socket!.on('dataChanged', (_) {
      RankService().emitDataRefresh(data: data);
      data = null;
    });

    _socket!.on('cardIndexUpdated', (_) {
      RankService().cardIndexUpdated(_);
    });
  }

  bool get isConnected => _socket?.connected ?? false;

  void reconnect() async {
    _socket?.disconnect();
    _socket?.io.options?["extraHeaders"] = {
      "authorization": await RankService().getBasicAuthHeader()
    };
    _socket?.connect();
  }

  Stream<bool> get connectedStatus async* {
    while (true) {
      await Future.delayed(Duration(seconds: 1));
      yield _socket?.connected ?? false;
    }
  }

  void sendDataChanged({List? data}) {
    if (data != null) {
      this.data = data;
    }
    _socket!.emit('refreshPage', "");
  }

  void updateCardIndex(int index, String accountId, int time) {
    _socket!.emit('updateCardIndex',
        {"index": index, "accountId": accountId, "time": time});
  }

  void dispose() {
    _socketResponse.close();
  }
}
