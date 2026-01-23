import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/secure_storage_service.dart';
import 'home_screen.dart';

class ConfirmSOSPinScreen extends StatefulWidget {
  final String pin;
  const ConfirmSOSPinScreen({super.key, required this.pin});

  @override
  State<ConfirmSOSPinScreen> createState() => _ConfirmSOSPinScreenState();
}

class _ConfirmSOSPinScreenState extends State<ConfirmSOSPinScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _pinsMatch = true;
  
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onPinChanged() {
    String enteredPin = _controllers.map((c) => c.text).join();
    if (enteredPin.length == 4) {
      if (enteredPin == widget.pin) {
        // PINs match - save and go to home
        _saveSOSPin(widget.pin);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        // PINs don't match
        setState(() {
          _pinsMatch = false;
        });
        // Clear all controllers
        for (var controller in _controllers) {
          controller.clear();
        }
        for (var node in _focusNodes) {
          node.unfocus();
        }
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PINs do not match. Please try again.',
              style: TextStyle(color: AppColors.white),
            ),
            backgroundColor: AppColors.black,
          ),
        );
      }
    }
  }

  void _saveSOSPin(String pin) async {
    // Save PIN to secure storage
    await SecureStorageService().saveSosPin(pin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Confirm SOS PIN',
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
                  color: _pinsMatch ? AppColors.surfaceVariant : const Color(0xFFFFEDED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _pinsMatch ? AppColors.divider : const Color(0xFFEF4444),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _pinsMatch ? Icons.security : Icons.error,
                  size: 40,
                  color: _pinsMatch ? AppColors.black : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 40),

              // Header
              Text(
                'Confirm Your PIN',
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
                'Enter the same 4-digit PIN to confirm',
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
                        color: _pinsMatch ? AppColors.divider : const Color(0xFFEF4444),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        suffixIcon: _controllers[index].text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                                onPressed: () {
                                  _controllers[index].clear();
                                  _onPinChanged();
                                },
                              )
                            : null,
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

              // Error message
              if (!_pinsMatch)
                Text(
                  'PINs do not match',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFEF4444),
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