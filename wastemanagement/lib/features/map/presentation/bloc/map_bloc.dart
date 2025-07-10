import 'package:bloc/bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wastemanagement/features/map/domain/repositories/map_repository.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final MapRepository mapRepository;

  MapBloc(this.mapRepository) : super(MapInitial()) {
    on<LoadUserLocation>((event, emit) async {
      emit(MapLoading());
      try {
        final location = await mapRepository.getCurrentLocation();
        emit(MapLoaded(location));
      } catch (e) {
        emit(MapError(e.toString()));
      }
    });
  }
}