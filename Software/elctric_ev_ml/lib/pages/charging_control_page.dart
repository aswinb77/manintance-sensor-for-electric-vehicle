import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ChargingControlPage extends StatefulWidget {
  const ChargingControlPage({super.key});

  @override
  State<ChargingControlPage> createState() => _ChargingControlPageState();
}

class _ChargingControlPageState extends State<ChargingControlPage> {
  final TextEditingController _voltageController = TextEditingController();
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  bool _isSaving = false;
  double _voltageLimit = 250;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _voltageController.dispose();
    super.dispose();
  }

  Future<void> _saveChargingLimit() async {
    if (!_formKey.currentState!.validate()) return;
    final voltageValue = double.parse(_voltageController.text.trim());

    setState(() => _isSaving = true);

    try {
      await _databaseRef.child('charging_limits').push().set({
        'voltage_limit': voltageValue,
        'timestamp': DateTime.now().toIso8601String(),
        'user_set': true,
      });

      if (mounted) {
        _showMessage('Charging limit saved successfully!');
        _voltageController.clear();
        setState(() => _voltageLimit = 250);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to save charging limit: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Charging Control', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Set safe charging limits and keep your EV battery optimized.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bolt, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Charging limit', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Adjust power safely for longer battery life.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('${_voltageLimit.toStringAsFixed(0)} V', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                    Slider(
                      value: _voltageLimit,
                      min: 0,
                      max: 500,
                      divisions: 50,
                      label: '${_voltageLimit.toStringAsFixed(0)} V',
                      onChanged: (value) {
                        setState(() {
                          _voltageLimit = value;
                          _voltageController.text = value.toStringAsFixed(0);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _voltageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Voltage limit',
                          prefixIcon: Icon(Icons.electrical_services),
                          suffixText: 'V',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Enter a voltage value';
                          final parsed = double.tryParse(text);
                          if (parsed == null) return 'Enter a valid number';
                          if (parsed < 0 || parsed > 500) return 'Use a value between 0 and 500 V';
                          return null;
                        },
                        onChanged: (value) {
                          final parsed = double.tryParse(value);
                          if (parsed != null && parsed >= 0 && parsed <= 500) {
                            setState(() => _voltageLimit = parsed);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildRuleChip('Home 240V'),
                        _buildRuleChip('Fast 400V'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isSaving ? null : _saveChargingLimit,
                      child: _isSaving ? SizedBox(width: 18, height: 18, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save limit'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withAlpha(31),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600)),
    );
  }
}
