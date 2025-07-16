// O11:B
part of 'recyclable_bloc.dart';

abstract class RecyclableEvent extends Equatable {
  const RecyclableEvent();

  @override
  List<Object?> get props => [];
}

class PostRecyclableEvent extends RecyclableEvent {
  final String materialType;
  final double quantity;
  final double pricePerUnit;

  const PostRecyclableEvent({
    required this.materialType,
    required this.quantity,
    required this.pricePerUnit,
  });

  @override
  List<Object?> get props => [materialType, quantity, pricePerUnit];
}

class LoadRecyclables extends RecyclableEvent {}

class AddRecyclable extends RecyclableEvent {
  final RecyclableItem item;
  AddRecyclable(this.item);
}

class UpdateRecyclable extends RecyclableEvent {
  final RecyclableItem updatedItem;
  UpdateRecyclable(this.updatedItem);
}

class DeleteRecyclable extends RecyclableEvent {
  final String itemId;
  DeleteRecyclable(this.itemId);
}

class SearchRecyclables extends RecyclableEvent {
  final String query;
  SearchRecyclables(this.query);
}

// O11:E