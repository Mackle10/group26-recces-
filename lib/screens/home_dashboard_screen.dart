import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Added import
import 'recyclables_screen.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import 'request_collection_screen.dart';


class StatusCard extends StatelessWidget {
  final String lastStatus;
  final String lastDate;
  const StatusCard({required this.lastStatus, required this.lastDate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        children: [
          const Text(
            'Last Collection Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            lastStatus,
            style: TextStyle(
              fontSize: 18,
              color: lastStatus == 'Collected' ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Date: $lastDate',
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class HomeDashboardScreen extends StatefulWidget {
  final String name;
  final String lastStatus;
  final String lastDate;
  final String userType; 

  const HomeDashboardScreen({
    Key? key,
    required this.name,
    required this.lastStatus,
    required this.lastDate,
    required this.userType, // Require this in constructor
  }) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
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
        title: const Text('Home Dashboard'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/profile',
                arguments: {
                  'name': widget.name,
                  'email': FirebaseAuth.instance.currentUser?.email ?? 'unknown@example.com',
                  'userType': widget.userType, // Pass dynamic userType here
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFa8e063), Color(0xFF56ab2f)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Welcome, ${widget.name}!',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: Colors.black26,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            StatusCard(lastStatus: widget.lastStatus, lastDate: widget.lastDate),
            const SizedBox(height: 44),
            CustomButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RequestCollectionScreen()),
                );
              },
              child: const Text('Request Waste Collection', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            CustomButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecyclablesScreen()),
                );
              },
              color: Colors.blue[700],
              child: const Text('View Recyclables', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
