import 'package:flutter/material.dart';
import '../widgets/custom_card.dart';

class RecyclablesScreen extends StatefulWidget {
  const RecyclablesScreen({Key? key}) : super(key: key);

  @override
  State<RecyclablesScreen> createState() => _RecyclablesScreenState();
}

class _RecyclablesScreenState extends State<RecyclablesScreen> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> recyclables = const [
    {
      'name': 'Paper',
      'description': 'Newspapers, magazines, office paper, and cardboard can be recycled.',
      'icon': Icons.description,
      'color': Color(0xFFB3E5FC),
    },
    {
      'name': 'Plastic',
      'description': 'Bottles, containers, and packaging labeled with recycling codes 1 and 2.',
      'icon': Icons.local_drink,
      'color': Color(0xFFC8E6C9),
    },
    {
      'name': 'Glass',
      'description': 'Bottles and jars of all colors can be recycled, but not window glass or ceramics.',
      'icon': Icons.wine_bar,
      'color': Color(0xFFFFF9C4),
    },
    {
      'name': 'Metal',
      'description': 'Aluminum cans, tin cans, and foil are recyclable.',
      'icon': Icons.kitchen,
      'color': Color(0xFFFFCCBC),
    },
    {
      'name': 'Cardboard',
      'description': 'Shipping boxes and food packaging (clean and dry) can be recycled.',
      'icon': Icons.inventory,
      'color': Color(0xFFD7CCC8),
    },
    {
      'name': 'Electronics',
      'description': 'Some electronics can be recycled at special facilities.',
      'icon': Icons.devices_other,
      'color': Color(0xFFE1BEE7),
    },
  ];

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recyclables'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Column(
        children: [
          // Helpful message at the top
          Container(
            width: double.infinity,
            color: Colors.green[100],
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: const Text(
              'Learn what you can recycle! Proper recycling helps the environment and keeps your community clean.',
              style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          // Animated list of recyclables
          Expanded(
            child: ListView.builder(
              itemCount: recyclables.length,
              itemBuilder: (context, index) {
                final item = recyclables[index];
                // Fade-in animation for each card
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final animationValue = (_controller.value - (index * 0.1)).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: animationValue,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - animationValue)),
                        child: child,
                      ),
                    );
                  },
                  child: CustomCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: ListTile(
                      leading: Icon(item['icon'], color: Colors.green[700], size: 32),
                      title: Text(item['name']!),
                      subtitle: Text(item['description']!),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 