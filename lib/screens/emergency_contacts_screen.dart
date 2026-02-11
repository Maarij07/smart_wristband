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
  List<Map<String, String>> _selectedContacts = [];
  bool _isLoading = true;
  bool _isSaving = false;

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
          setState(() {
            _selectedContacts = contacts
                .map((c) => Map<String, String>.from({
                      'name': c['name']?.toString() ?? '',
                      'phone': c['phone']?.toString() ?? '',
                    }))
                .toList();
          });
        }
      }
    } catch (e) {
      // Ignore load errors
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

  void _toggleContact(Contact contact) {
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This contact has no phone number')),
      );
      return;
    }

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
        });
      }
    });
  }

  void _removeContact(int index) {
    setState(() {
      _selectedContacts.removeAt(index);
    });
  }

  Future<void> _saveContacts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'emergencyContacts': _selectedContacts,
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
                            return Chip(
                              label: Text(
                                contact['name'] ?? '',
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
