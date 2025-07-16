import 'package:bloc/bloc.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wastemanagement/features/map/domain/repositories/map_repository.dart';
import 'package:wastemanagement/features/map/presentation/bloc/map_event.dart';
import 'package:wastemanagement/features/map/presentation/bloc/map_state.dart';

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