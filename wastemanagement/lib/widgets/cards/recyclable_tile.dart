import 'package:flutter/material.dart';

class RecyclableTile extends StatelessWidget {
  final dynamic item;
  final VoidCallback? onTap;

  const RecyclableTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.recycling),
      title: Text(item['name']),
      subtitle: Text('${item['weight']} kg - ${item['category']}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}