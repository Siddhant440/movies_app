import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>();
  final connectivity = Connectivity();

  connectivity.checkConnectivity().then((result) {
    controller.add(!result.contains(ConnectivityResult.none));
  });

  final sub = connectivity.onConnectivityChanged.listen((result) {
    controller.add(!result.contains(ConnectivityResult.none));
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});
