import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedMethod = 'Card';
  String? _selectedBank;
  String _statusMessage = '';

  final List<String> _methods = ['Card', 'Mobile Money', 'Bank'];
  final List<String> _banks = [
    'Bank of America',
    'Chase',
    'Wells Fargo',
    'Citi Bank',
    'Capital One',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _pay() {
    setState(() {
      _statusMessage = 'Processing payment...';
    });
    // Simulate payment processings
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _statusMessage = 'Payment successful!';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Payment Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              items: _methods
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMethod = value!;
                  _selectedBank = null;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
            ),
            if (_selectedMethod == 'Bank') ...[
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedBank,
                items: _banks
                    .map((bank) => DropdownMenuItem(
                          value: bank,
                          child: Text(bank),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBank = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Select Bank',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _pay,
                child: const Text('Pay Now'),
              ),
            ),
            const SizedBox(height: 24),
            if (_statusMessage.isNotEmpty)
              Center(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
