import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/sync/sync_engine.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) => SyncEngine.instance);

final syncStateProvider = NotifierProvider<SyncStateNotifier, SyncState>(
  SyncStateNotifier.new,
);

class SyncStateNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    final engine = ref.watch(syncEngineProvider);
    void atualizar() => state = engine.estado.value;

    engine.estado.addListener(atualizar);
    ref.onDispose(() => engine.estado.removeListener(atualizar));
    return engine.estado.value;
  }
}
