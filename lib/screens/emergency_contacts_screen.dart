import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/colors.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  List<Map<String, dynamic>> _selectedContacts = [];
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Country code selector
  String _defaultCountryCode = '+1'; // Default to US/Canada

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSavedContacts(),
      _loadPhoneContacts(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedContacts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        final contacts = data?['emergencyContacts'] as List<dynamic>?;
        if (contacts != null && mounted) {
          final convertedContacts = <Map<String, dynamic>>[];
          for (final c in contacts) {
            if (c is Map) {
              convertedContacts.add({
                'name': c['name']?.toString() ?? '',
                'phone': c['phone']?.toString() ?? '',
                'countryCode': c['countryCode']?.toString() ?? '+1',
                'country': c['country']?.toString() ?? 'US',
              });
            }
          }
          setState(() {
            _selectedContacts = convertedContacts;
          });
        }
      }
    } catch (e) {
      print('Error loading emergency contacts: $e');
      // Ignore load errors, continue with empty list
    }
  }

  Future<void> _loadPhoneContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission denied')),
        );
      }
      return;
    }
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    if (mounted) {
      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
      });
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        _filteredContacts = _allContacts.where((contact) {
          final name = contact.displayName.toLowerCase();
          final phones = contact.phones.map((p) => p.number).join(' ');
          return name.contains(query) || phones.contains(query);
        }).toList();
      }
    });
  }

  bool _isContactSelected(Contact contact) {
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
    return _selectedContacts.any((c) => c['phone'] == phone);
  }

  String _cleanPhoneNumber(String phone) {
    // Remove all formatting: spaces, dashes, parentheses, dots
    return phone.replaceAll(RegExp(r'[\s\-\(\)\.]/'), '');
  }

  void _toggleContact(Contact contact) {
    var phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This contact has no phone number')),
      );
      return;
    }

    // Clean the phone number before saving
    phone = _cleanPhoneNumber(phone);

    setState(() {
      if (_isContactSelected(contact)) {
        _selectedContacts.removeWhere((c) => c['phone'] == phone);
      } else {
        if (_selectedContacts.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 5 emergency contacts allowed')),
          );
          return;
        }
        _selectedContacts.add({
          'name': contact.displayName,
          'phone': phone,
          'countryCode': _defaultCountryCode,
          'country': _getCountryNameFromCode(_defaultCountryCode),
        });
      }
    });
    
    // Auto-save after toggling
    _autoSaveContacts();
  }

  String _getCountryNameFromCode(String code) {
    final countryMap = {
      '+1': 'US',
      '+44': 'UK',
      '+92': 'Pakistan',
      '+91': 'India',
      '+86': 'China',
      '+81': 'Japan',
      '+33': 'France',
      '+49': 'Germany',
    };
    return countryMap[code] ?? 'Unknown';
  }

  Future<void> _autoSaveContacts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Convert to list of maps safe for Firestore
      final contactsToSave = _selectedContacts.map((contact) => {
        'name': contact['name'] ?? '',
        'phone': contact['phone'] ?? '',
        'countryCode': contact['countryCode'] ?? '+1',
        'country': contact['country'] ?? 'US',
      }).toList();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'emergencyContacts': contactsToSave,
      });
      print('✅ Emergency contacts auto-saved');
    } catch (e) {
      print('⚠️ Error auto-saving contacts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving contacts: $e')),
        );
      }
    }
  }

  void _removeContact(int index) {
    setState(() {
      _selectedContacts.removeAt(index);
    });
    
    // Auto-save after removing
    _autoSaveContacts();
  }

  Future<void> _saveContacts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      // Convert to list of maps safe for Firestore
      final contactsToSave = _selectedContacts.map((contact) => {
        'name': contact['name'] ?? '',
        'phone': contact['phone'] ?? '',
        'countryCode': contact['countryCode'] ?? '+1',
        'country': contact['country'] ?? 'US',
      }).toList();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'emergencyContacts': contactsToSave,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency contacts saved'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving contacts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Emergency Contacts',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Country Code Selector
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default Country Code',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _defaultCountryCode,
                        underline: Container(
                          height: 1,
                          color: AppColors.divider,
                        ),
                        items: [
                          DropdownMenuItem(value: '+1', child: Text('🇺🇸 US/Canada (+1)')),
                          DropdownMenuItem(value: '+44', child: Text('🇬🇧 United Kingdom (+44)')),
                          DropdownMenuItem(value: '+92', child: Text('🇵🇰 Pakistan (+92)')),
                          DropdownMenuItem(value: '+91', child: Text('🇮🇳 India (+91)')),
                          DropdownMenuItem(value: '+86', child: Text('🇨🇳 China (+86)')),
                          DropdownMenuItem(value: '+81', child: Text('🇯🇵 Japan (+81)')),
                          DropdownMenuItem(value: '+33', child: Text('🇫🇷 France (+33)')),
                          DropdownMenuItem(value: '+49', child: Text('🇩🇪 Germany (+49)')),
                          DropdownMenuItem(value: '+61', child: Text('🇦🇺 Australia (+61)')),
                          DropdownMenuItem(value: '+64', child: Text('🇳🇿 New Zealand (+64)')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _defaultCountryCode = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Selected contacts chips
                if (_selectedContacts.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected (${_selectedContacts.length}/5)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_selectedContacts.length, (index) {
                            final contact = _selectedContacts[index];
                            final countryCode = contact['countryCode'] ?? '+1';
                            return Chip(
                              label: Text(
                                '${contact['name']} ($countryCode)',
                                style: const TextStyle(fontSize: 13),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _removeContact(index),
                              backgroundColor: AppColors.surfaceVariant,
                              side: BorderSide(color: AppColors.divider),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                // Search field
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.black, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                // Contacts list
                Expanded(
                  child: _filteredContacts.isEmpty
                      ? Center(
                          child: Text(
                            'No contacts found',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _filteredContacts[index];
                            final phone = contact.phones.isNotEmpty
                                ? contact.phones.first.number
                                : 'No phone';
                            final isSelected = _isContactSelected(contact);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? AppColors.black
                                    : AppColors.surfaceVariant,
                                child: Text(
                                  contact.displayName.isNotEmpty
                                      ? contact.displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              title: Text(
                                contact.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                phone,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: AppColors.black)
                                  : Icon(Icons.circle_outlined, color: AppColors.divider),
                              onTap: () => _toggleContact(contact),
                            );
                          },
                        ),
                ),

                // Save button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveContacts,
                      style: AppColors.primaryButtonStyle(),
                      child: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : Text(
                              'Save (${_selectedContacts.length}/5)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
