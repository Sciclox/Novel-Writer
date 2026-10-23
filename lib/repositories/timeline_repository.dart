import '../database/app_database.dart';
import '../models/timeline_event_model.dart';

class TimelineRepository {
  Future<List<TimelineEvent>> getByProject(int proyectoId) async {
    final rows = await AppDatabase.getEventosByProyecto(proyectoId);
    return rows.map((r) => TimelineEvent.fromMap(r)).toList();
  }

  Future<int> create(TimelineEvent event) async {
    return await AppDatabase.insertEvento(event.toMap());
  }

  Future<int> update(TimelineEvent event) async {
    if (event.id == null) return -1;
    return await AppDatabase.updateEvento(event.id!, event.toMap());
  }

  Future<void> batchUpdateOrder(List<TimelineEvent> events) async {
    await AppDatabase.batchUpdateOrden(events.map((e) => e.toMap()).toList());
  }

  Future<int> delete(int id) async {
    return await AppDatabase.deleteEvento(id);
  }
}
