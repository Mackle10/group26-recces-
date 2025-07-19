
// O11:B
// import '../../models/recyclable_item.dart'; // Adjust the path as needed
part of 'recyclable_bloc.dart';

abstract class RecyclableState extends Equatable {
  const RecyclableState();

  @override
  List<Object?> get props => [];
}

class RecyclableInitial extends RecyclableState {}

class RecyclableLoading extends RecyclableState {}

class RecyclableLoaded extends RecyclableState {
  // final List<RecyclableItem> recyclables;
  final List<Object> recyclables;

  const RecyclableLoaded({required this.recyclables});

  @override
  List<Object?> get props => [recyclables];
}

class RecyclableError extends RecyclableState {
  final String message;

  const RecyclableError({required this.message});

  @override
  List<Object?> get props => [message];
}

class RecyclablePosted extends RecyclableState {}

// O11:E
