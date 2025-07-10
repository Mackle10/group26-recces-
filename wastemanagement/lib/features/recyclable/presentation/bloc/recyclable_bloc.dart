import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wastemanagement/features/recyclables/domain/entities/recyclable_item.dart';
import 'package:wastemanagement/features/recyclables/domain/repositories/recyclable_repository.dart';

part 'recyclable_event.dart';
part 'recyclable_state.dart';

class RecyclableBloc extends Bloc<RecyclableEvent, RecyclableState> {
  final RecyclableRepository repository;

  RecyclableBloc({required this.repository}) : super(RecyclableInitial()) {
    on<LoadRecyclables>(_onLoadRecyclables);
    on<AddRecyclable>(_onAddRecyclable);
    on<UpdateRecyclable>(_onUpdateRecyclable);
    on<DeleteRecyclable>(_onDeleteRecyclable);
    on<SearchRecyclables>(_onSearchRecyclables);
  }

  Future<void> _onLoadRecyclables(
    LoadRecyclables event,
    Emitter<RecyclableState> emit,
  ) async {
    emit(RecyclableLoading());
    try {
      final recyclables = await repository.getRecyclables();
      emit(RecyclableLoaded(recyclables: recyclables));
    } catch (e) {
      emit(RecyclableError(message: 'Failed to load recyclables: ${e.toString()}'));
    }
  }

  Future<void> _onAddRecyclable(
    AddRecyclable event,
    Emitter<RecyclableState> emit,
  ) async {
    if (state is RecyclableLoaded) {
      final currentState = state as RecyclableLoaded;
      emit(RecyclableLoading());
      try {
        await repository.addRecyclable(event.item);
        final updatedList = await repository.getRecyclables();
        emit(RecyclableLoaded(recyclables: updatedList));
      } catch (e) {
        emit(RecyclableError(message: 'Failed to add recyclable: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  Future<void> _onUpdateRecyclable(
    UpdateRecyclable event,
    Emitter<RecyclableState> emit,
  ) async {
    if (state is RecyclableLoaded) {
      final currentState = state as RecyclableLoaded;
      emit(RecyclableLoading());
      try {
        await repository.updateRecyclable(event.updatedItem);
        final updatedList = await repository.getRecyclables();
        emit(RecyclableLoaded(recyclables: updatedList));
      } catch (e) {
        emit(RecyclableError(message: 'Failed to update recyclable: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  Future<void> _onDeleteRecyclable(
    DeleteRecyclable event,
    Emitter<RecyclableState> emit,
  ) async {
    if (state is RecyclableLoaded) {
      final currentState = state as RecyclableLoaded;
      emit(RecyclableLoading());
      try {
        await repository.deleteRecyclable(event.itemId);
        final updatedList = await repository.getRecyclables();
        emit(RecyclableLoaded(recyclables: updatedList));
      } catch (e) {
        emit(RecyclableError(message: 'Failed to delete recyclable: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  Future<void> _onSearchRecyclables(
    SearchRecyclables event,
    Emitter<RecyclableState> emit,
  ) async {
    if (state is RecyclableLoaded) {
      emit(RecyclableLoading());
      try {
        final results = await repository.searchRecyclables(event.query);
        emit(RecyclableLoaded(recyclables: results));
      } catch (e) {
        emit(RecyclableError(message: 'Search failed: ${e.toString()}'));
      }
    }
  }
}