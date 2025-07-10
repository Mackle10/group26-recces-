import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/recyclable_bloc.dart';
import '../../../widgets/cards/recyclable_tile.dart';
import '../../../routes/app_routes.dart';

class RecyclableListScreen extends StatelessWidget {
  const RecyclableListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Recyclables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sell),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.sellScreen,
                arguments: {
                  'items': [], // Pass selected items
                  'location': null, // Pass current location
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<RecyclableBloc, RecyclableState>(
        builder: (context, state) {
          if (state is RecyclableLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RecyclableError) {
            return Center(child: Text(state.message));
          } else if (state is RecyclableLoaded) {
            return ListView.builder(
              itemCount: state.recyclables.length,
              itemBuilder: (context, index) {
                return RecyclableTile(
                  item: state.recyclables[index],
                  onTap: () {
                    // Handle item selection
                  },
                );
              },
            );
          }
          return const Center(child: Text('No recyclables added yet'));
        },
      ),
    );
  }
}