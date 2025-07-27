import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'company_location_setup_screen.dart';
import 'traffic_route_planner_screen.dart';
import 'individual_route_screen.dart';
import '../services/proximity_service.dart';
import '../services/location_service.dart';
import '../services/traffic_service.dart';

class CompanyDashboardScreen extends StatefulWidget {
  final String name;
  final String lastStatus;
  final String lastDate;
  final String userType;

  const CompanyDashboardScreen({
    Key? key,
    required this.name,
    required this.lastStatus,
    required this.lastDate,
    required this.userType,
  }) : super(key: key);

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  String? currentUserId;
  final ProximityService _proximityService = ProximityService();
  final LocationService _locationService = LocationService();
  final TrafficService _trafficService = TrafficService();
  
  LatLng? _companyLocation;
  double _serviceRadius = 5000; // 5km default
  String _sortBy = 'distance'; // distance, priority, time
  
  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadCompanyLocation();
  }

  Future<void> _loadCompanyLocation() async {
    try {
      if (currentUserId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId!)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          final latitude = data['latitude'] as double?;
          final longitude = data['longitude'] as double?;
          
          if (latitude != null && longitude != null) {
            setState(() {
              _companyLocation = LatLng(latitude, longitude);
              _serviceRadius = (data['serviceRadius'] ?? 5000).toDouble();
            });
          }
        }
      }
    } catch (e) {
      print('Error loading company location: $e');
    }
  }

  Future<void> _markAsCompleted(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({'status': 'Completed'});
      // Send notification to home user
      await sendNotification(requestId, 'Your request has been completed!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request marked as completed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _markAsSeen(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({'status': 'Seen'});
      // Send notification to home user
      await sendNotification(requestId, 'Your request has been seen by the company.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request marked as seen')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: ' + e.toString())),
      );
    }
  }

  Future<void> sendNotification(String requestId, String message) async {
    // TODO: Implement real notification logic here (e.g., Firebase Cloud Messaging)
    print('Notification for request $requestId: $message');
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Dashboard'),
        actions: [
          // Sort options
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'distance',
                child: Row(
                  children: [
                    Icon(Icons.near_me, size: 16),
                    SizedBox(width: 8),
                    Text('Sort by Distance'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'priority',
                child: Row(
                  children: [
                    Icon(Icons.priority_high, size: 16),
                    SizedBox(width: 8),
                    Text('Sort by Priority'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'time',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16),
                    SizedBox(width: 8),
                    Text('Sort by Time'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort),
                  SizedBox(width: 4),
                  Text(_sortBy.toUpperCase(), style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.traffic),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrafficRoutePlannerScreen(),
                ),
              );
            },
            tooltip: 'Traffic Route Planner',
          ),
          IconButton(
            icon: Icon(Icons.location_on),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompanyLocationSetupScreen(),
                ),
              ).then((_) => _loadCompanyLocation()); // Reload location after setup
            },
            tooltip: 'Setup Company Location',
          ),
        ],
      ),
      body: _companyLocation == null
          ? _buildLocationSetupPrompt()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('assignedCompanyId', isEqualTo: currentUserId)
                  .orderBy('submittedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Something went wrong while loading requests.'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildProximityBasedRequestList(snapshot.data!.docs);
              },
            ),
    );
  }

  Widget _buildLocationSetupPrompt() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey),
            SizedBox(height: 24),
            Text(
              'Setup Company Location',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'To see nearby waste collection requests, please set up your company location and service area.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompanyLocationSetupScreen(),
                  ),
                ).then((_) => _loadCompanyLocation());
              },
              icon: Icon(Icons.location_on),
              label: Text('Setup Location'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey),
            SizedBox(height: 24),
            Text(
              'No Requests Yet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'You will see waste collection requests here once clients choose your company.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_companyLocation != null) ...[
              SizedBox(height: 16),
              Text(
                'Service Area: ${(_serviceRadius / 1000).toStringAsFixed(1)} km radius',
                style: TextStyle(fontSize: 14, color: Colors.green[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProximityBasedRequestList(List<DocumentSnapshot> requests) {
    if (_companyLocation == null) return _buildLocationSetupPrompt();

    // Apply proximity algorithms based on sort preference
    List<dynamic> sortedRequests;
    
    switch (_sortBy) {
      case 'distance':
        sortedRequests = _proximityService.sortRequestsByDistance(
          _companyLocation!,
          requests,
        );
        break;
      case 'priority':
        sortedRequests = _proximityService.sortRequestsByPriority(
          _companyLocation!,
          requests,
        );
        break;
      case 'time':
        // Sort by submission time (most recent first)
        sortedRequests = requests.toList()
          ..sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['submittedAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['submittedAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
        break;
      default:
        sortedRequests = requests;
    }

    return Column(
      children: [
        // Statistics header
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border(bottom: BorderSide(color: Colors.green[200]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', '${requests.length}', Icons.list),
              _buildStatItem('Nearby', '${_getNearbyCount(requests)}', Icons.near_me),
              _buildStatItem('Pending', '${_getPendingCount(requests)}', Icons.pending),
              _buildStatItem('Radius', '${(_serviceRadius / 1000).toStringAsFixed(1)}km', Icons.radio_button_unchecked),
            ],
          ),
        ),
        
        // Request list
        Expanded(
          child: ListView.builder(
            itemCount: sortedRequests.length,
            itemBuilder: (context, index) {
              if (_sortBy == 'distance' || _sortBy == 'priority') {
                final requestWithData = sortedRequests[index];
                return _buildProximityRequestCard(requestWithData);
              } else {
                final doc = sortedRequests[index] as DocumentSnapshot;
                return _buildTimeBasedRequestCard(doc);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[600], size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.green[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProximityRequestCard(dynamic requestWithData) {
    final request = requestWithData.request as DocumentSnapshot;
    final data = request.data() as Map<String, dynamic>;
    final distance = requestWithData.formattedDistance;
    
    String priorityInfo = '';
    Color priorityColor = Colors.grey;
    
    if (requestWithData is RequestWithPriority) {
      priorityInfo = requestWithData.priorityLevel;
      priorityColor = _getPriorityColor(priorityInfo);
    }

    // Visual indicator for 'Seen' status
    bool isSeen = (data['status']?.toLowerCase() == 'seen');
    bool isCompleted = (data['status']?.toLowerCase() == 'completed');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? Colors.green
              : isSeen
                  ? Colors.blue
                  : _getStatusColor(data['status']),
          child: Icon(
            isCompleted
                ? Icons.check_circle
                : isSeen
                    ? Icons.visibility
                    : _getStatusIcon(data['status']),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'From: ${data['clientEmail'] ?? 'Client'}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                distance,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('📅 ${data['date']} at ${data['time']}'),
            Text('📍 ${data['address']}'),
            Text('⚡ ${data['urgency']} urgency'),
            if (priorityInfo.isNotEmpty) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Priority: $priorityInfo',
                  style: TextStyle(
                    fontSize: 12,
                    color: priorityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            // Status history chips
            SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip('Pending', data['status']),
                SizedBox(width: 4),
                _buildStatusChip('Seen', data['status']),
                SizedBox(width: 4),
                _buildStatusChip('Completed', data['status']),
              ],
            ),
            if (isSeen && !isCompleted) ...[
              SizedBox(height: 4),
              Text('Status: Seen', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCompleted) ...[
              if (!isSeen) ...[
                ElevatedButton(
                  onPressed: () => _markAsSeen(request.id),
                  child: Text('Mark as Seen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(80, 32),
                  ),
                ),
                SizedBox(height: 4),
              ],
              ElevatedButton(
                onPressed: () => _markAsCompleted(request.id),
                child: Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(80, 32),
                ),
              ),
              SizedBox(height: 4),
              ElevatedButton(
                onPressed: () {
                  if (_companyLocation != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IndividualRouteScreen(
                          companyLocation: _companyLocation!,
                          requestWithDistance: requestWithData,
                        ),
                      ),
                    ).then((completed) {
                      if (completed == true) {
                        setState(() {});
                      }
                    });
                  }
                },
                child: Text('View Route'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: Size(80, 32),
                ),
              ),
            ] else
              Icon(Icons.check_circle, color: Colors.green, size: 30),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildTimeBasedRequestCard(DocumentSnapshot request) {
    final data = request.data() as Map<String, dynamic>;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(data['status']),
          child: Icon(
            _getStatusIcon(data['status']),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          'From: ${data['clientEmail'] ?? 'Client'}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('📅 ${data['date']} at ${data['time']}'),
            Text('📍 ${data['address']}'),
            Text('⚡ ${data['urgency']} urgency'),
            Text('📊 Status: ${data['status']}'),
          ],
        ),
        trailing: data['status'] != 'Completed'
            ? ElevatedButton(
                onPressed: () => _markAsCompleted(request.id),
                child: Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              )
            : Icon(Icons.check_circle, color: Colors.green, size: 30),
        isThreeLine: true,
      ),
    );
  }

  int _getNearbyCount(List<DocumentSnapshot> requests) {
    if (_companyLocation == null) return 0;
    
    final nearbyRequests = _proximityService.getRequestsWithinServiceArea(
      _companyLocation!,
      _serviceRadius,
      requests,
    );
    
    return nearbyRequests.length;
  }

  int _getPendingCount(List<DocumentSnapshot> requests) {
    return requests.where((request) {
      final data = request.data() as Map<String, dynamic>;
      return data['status'] != 'Completed';
    }).length;
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'in progress':
        return Icons.hourglass_empty;
      default:
        return Icons.help;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'very high':
        return Colors.red[700]!;
      case 'high':
        return Colors.red[500]!;
      case 'medium':
        return Colors.orange[600]!;
      case 'low':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildStatusChip(String label, String currentStatus) {
    bool isActive = currentStatus?.toLowerCase() == label.toLowerCase();
    Color color;
    switch (label.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'seen':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(label, style: TextStyle(color: Colors.white)),
      backgroundColor: isActive ? color : color.withOpacity(0.3),
    );
  }
}
