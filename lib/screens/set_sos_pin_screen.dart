import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'confirm_sos_pin_screen.dart';

class SetSOSPinScreen extends StatefulWidget {
  const SetSOSPinScreen({super.key});

  @override
  State<SetSOSPinScreen> createState() => _SetSOSPinScreenState();
}

class _SetSOSPinScreenState extends State<SetSOSPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  
  @override
  void dispose() {
    _pinController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onPinChanged() {
    if (_pinController.text.length == 4) {
      // Navigate to confirm PIN screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmSOSPinScreen(pin: _pinController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Set SOS PIN',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.divider,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.security,
                  size: 40,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 40),

              // Header
              Text(
                'Emergency SOS PIN',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Set a 4-digit PIN for emergency situations',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),

              // PIN Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return Container(
                    width: 50,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.divider,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _pinController,
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                        }
                        _onPinChanged();
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Instructions
              Text(
                'This PIN will stop the emergency buzzer',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}