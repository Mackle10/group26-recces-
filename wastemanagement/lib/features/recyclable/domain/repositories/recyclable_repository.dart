import 'package:wastemanagement/features/recyclable/domain/entities/recyclable_item.dart';

abstract class RecyclableRepository {
  Future<List<RecyclableItem>> getRecyclables();
  Future<void> addRecyclable(RecyclableItem item);
  Future<void> updateRecyclable(RecyclableItem item);
  Future<void> deleteRecyclable(String id);
  Future<List<RecyclableItem>> searchRecyclables(String query);
}
