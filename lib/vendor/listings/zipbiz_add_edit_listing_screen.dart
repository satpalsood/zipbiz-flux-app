import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/api/zipbiz_api_service.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';
import '../../models/user_model.dart';
import '../../widgets/common/zipbiz_button.dart';
import '../../widgets/common/zipbiz_card.dart';
import '../../widgets/common/zipbiz_header.dart';

class ZipBizAddEditListingScreen extends StatefulWidget {
  final Map<String, dynamic>? initialListing;

  const ZipBizAddEditListingScreen({super.key, this.initialListing});

  @override
  State<ZipBizAddEditListingScreen> createState() =>
      _ZipBizAddEditListingScreenState();
}

class _ZipBizAddEditListingScreenState
    extends State<ZipBizAddEditListingScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Listing Type
  String _listingType = 'service'; // 'service', 'rent', 'others'

  // Step 2: Basic Info
  final _titleController = TextEditingController();
  String _selectedCategory = 'Electrician';
  final _subCategoryController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _logoUrlController = TextEditingController();

  final List<String> _categories = [
    'Electrician',
    'Plumber',
    'Cleaning',
    'Maid Service',
    'AC Repair',
    'Carpentry',
    'Painting',
    'Pest Control',
    'Appliance Repair',
    'Other Services',
  ];

  // Step 3: Location
  final _addressController = TextEditingController();
  final _friendlyAddressController = TextEditingController();
  String _selectedRegion = 'Mohali';
  final _serviceAreaController = TextEditingController();

  final List<String> _regions = [
    'Mohali',
    'Chandigarh',
    'Panchkula',
    'Zirakpur',
    'Kharar',
    'New Chandigarh',
  ];

  // Step 4: Gallery
  final List<String> _galleryImages = [];
  final _newImageUrlController = TextEditingController();

  // Step 5: Contact & Description
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  // Step 6: Opening Hours
  final Map<String, Map<String, dynamic>> _openingHours = {
    'Monday': {'open': true, 'from': '09:00 AM', 'to': '08:00 PM'},
    'Tuesday': {'open': true, 'from': '09:00 AM', 'to': '08:00 PM'},
    'Wednesday': {'open': true, 'from': '09:00 AM', 'to': '08:00 PM'},
    'Thursday': {'open': true, 'from': '09:00 AM', 'to': '08:00 PM'},
    'Friday': {'open': true, 'from': '09:00 AM', 'to': '08:00 PM'},
    'Saturday': {'open': true, 'from': '09:00 AM', 'to': '08:00 PM'},
    'Sunday': {'open': false, 'from': '09:00 AM', 'to': '08:00 PM'},
  };

  // Step 7: Pricing & Bookable Services
  bool _bookingEnabled = true;
  bool _slotsEnabled = true;
  int _slotLimit = 5;
  double _slotInterval = 1.0; // 0.5 (30 mins), 1, 2, 3, 4, 5 hours
  final _visitingFeeController = TextEditingController(text: '0');
  final _inspectionFeeController = TextEditingController(text: '0');
  final _additionalFeeLabelController = TextEditingController();
  final _additionalFeeAmountController = TextEditingController();
  final _minBookingValueController = TextEditingController();
  final List<List<String>> _daySlots = List.generate(7, (_) => []);
  int _activeSlotDayIndex = 0;

  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _formatSlotTime(int totalMinutes) {
    int hours = (totalMinutes ~/ 60) % 24;
    final mins = totalMinutes % 60;
    final ampm = hours >= 12 ? 'PM' : 'AM';
    if (hours > 12) hours -= 12;
    if (hours == 0) hours = 12;
    final hStr = hours.toString().padLeft(2, '0');
    final mStr = mins.toString().padLeft(2, '0');
    return '$hStr:$mStr $ampm';
  }

  void _generateDefaultSlotsForDay(int dayIdx) {
    final slots = <String>[];
    final step = (_slotInterval * 60).round();
    if (step <= 0) return;

    // Standard business hours: 09:00 AM (540 mins) to 08:00 PM (1200 mins)
    for (int startMin = 9 * 60; startMin + step <= 20 * 60; startMin += step) {
      final startStr = _formatSlotTime(startMin);
      final endStr = _formatSlotTime(startMin + step);
      slots.add('$startStr - $endStr|$_slotLimit');
    }
    _daySlots[dayIdx] = slots;
  }

  void _generateDefaultSlotsForAllDays() {
    for (int i = 0; i < 7; i++) {
      final dayName = _dayNames[i];
      final isOpen = _openingHours[dayName]?['open'] == true;
      if (isOpen) {
        _generateDefaultSlotsForDay(i);
      } else {
        _daySlots[i] = [];
      }
    }
    if (mounted) setState(() {});
  }
  final List<Map<String, dynamic>> _menuServices = [];

  // Media & Dynamic Config
  bool _isUploadingFeatured = false;
  bool _isUploadingGallery = false;
  int? _featuredImageId;
  final List<int> _galleryImageIds = [];
  List<Map<String, dynamic>> _backendListingTypes = [];

  // Subscription Packages & Sync
  List<Map<String, dynamic>> _packages = [];
  List<Map<String, dynamic>> _userPackages = [];
  bool _canAddListing = true;
  bool _isLoadingPackages = false;
  int? _selectedPackageProductId;
  String? _selectedPackageName;
  bool _isActivatingPackage = false;

  // Step 8: FAQ Section
  bool _faqEnabled = true;
  final List<Map<String, String>> _faqs = [];

  @override
  void initState() {
    super.initState();
    _initDefaults();
    if (widget.initialListing != null) {
      _populateInitialData(widget.initialListing!);
    } else {
      _loadPackages();
    }
    _loadVendorConfig();
    _loadDynamicFields();
  }

  Future<void> _loadPackages() async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) return;
    setState(() => _isLoadingPackages = true);
    try {
      final res = await ZipBizApiService().getVendorPackages(user);
      if (res['packages'] is List) {
        _packages = (res['packages'] as List).map((p) => Map<String, dynamic>.from(p)).toList();
      }
      if (res['user_packages'] is List) {
        _userPackages = (res['user_packages'] as List).map((p) => Map<String, dynamic>.from(p)).toList();
      }
      _canAddListing = res['can_add_listing'] == true;
      if (_userPackages.isNotEmpty) {
        final active = _userPackages.firstWhere(
          (p) => p['is_active'] == true,
          orElse: () => _userPackages.first,
        );
        _selectedPackageProductId = active['product_id'] ?? active['id'];
        _selectedPackageName = active['name'];
      } else if (_packages.isNotEmpty) {
        final freePkg = _packages.firstWhere((p) => p['is_free'] == true, orElse: () => _packages.first);
        _selectedPackageProductId = freePkg['id'];
        _selectedPackageName = freePkg['name'];
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingPackages = false);
  }

  Future<void> _loadDynamicFields() async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) return;
    try {
      final data = await ZipBizApiService().getListingFormFields(user, type: _listingType);
      if (data['categories'] is List) {
        for (var c in (data['categories'] as List)) {
          final name = c['name']?.toString();
          if (name != null && name.isNotEmpty && !_categories.contains(name)) {
            _categories.add(name);
          }
        }
      }
      if (data['regions'] is List) {
        for (var r in (data['regions'] as List)) {
          final name = r['name']?.toString();
          if (name != null && name.isNotEmpty && !_regions.contains(name)) {
            _regions.add(name);
          }
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadVendorConfig() async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) return;
    try {
      final config = await ZipBizApiService().getVendorConfig(user);
      if (config['listing_types'] is List) {
        final types = (config['listing_types'] as List).map((t) => Map<String, dynamic>.from(t)).toList();
        if (types.isNotEmpty && mounted) {
          setState(() {
            _backendListingTypes = types;
          });
        }
      }
    } catch (_) {}
  }

  void _initDefaults() {
    _generateDefaultSlotsForAllDays();
    _menuServices.add({
      'name': 'Standard Inspection & Repair',
      'price': '499',
      'description': 'Full diagnostic and up to 1 hour standard service repair.',
      'bookable': true,
    });
    _faqs.add({
      'question': 'What is included in the visiting fee?',
      'answer': 'The visiting fee covers travel and the initial diagnostic assessment at your doorstep.',
    });
  }

  void _populateInitialData(Map<String, dynamic> item) {
    _listingType = item['listing_type'] ?? 'service';
    _titleController.text = item['title'] ?? '';

    // Safe category parsing (supports String, Map, or List)
    String catName = 'Electrician';
    if (item['category'] != null && item['category'].toString().trim().isNotEmpty) {
      catName = item['category'].toString().trim();
    } else if (item['categories'] is List && (item['categories'] as List).isNotEmpty) {
      final first = (item['categories'] as List).first;
      if (first is Map) {
        catName = (first['name'] ?? first['title'] ?? 'Electrician').toString();
      } else if (first != null) {
        catName = first.toString();
      }
    }
    if (!_categories.contains(catName)) {
      _categories.insert(0, catName);
    }
    _selectedCategory = catName;

    _logoUrlController.text = item['featured_image'] ?? item['featured_image_url'] ?? item['image'] ?? '';
    _addressController.text = item['address'] ?? '';
    _friendlyAddressController.text = item['friendly_address'] ?? '';

    // Safe region parsing (supports String, Map, or List)
    String regName = 'Mohali';
    if (item['region'] != null && item['region'].toString().trim().isNotEmpty) {
      regName = item['region'].toString().trim();
    } else if (item['regions'] is List && (item['regions'] as List).isNotEmpty) {
      final first = (item['regions'] as List).first;
      if (first is Map) {
        regName = (first['name'] ?? first['title'] ?? 'Mohali').toString();
      } else if (first != null) {
        regName = first.toString();
      }
    }
    if (!_regions.contains(regName)) {
      _regions.insert(0, regName);
    }
    _selectedRegion = regName;

    _serviceAreaController.text = item['service_area'] ?? '';
    _subCategoryController.text = item['sub_category'] ?? '';
    _keywordsController.text = item['keywords'] ?? '';
    _descriptionController.text = item['description'] ?? '';
    _phoneController.text = item['phone'] ?? '';
    _emailController.text = item['email'] ?? '';
    _websiteController.text = item['website'] ?? '';
    _visitingFeeController.text = '${item['visiting_fee'] ?? '149'}';
    _inspectionFeeController.text = '${item['inspection_fee'] ?? '199'}';
    _slotInterval = double.tryParse('${item['slot_interval']}') ?? 1.0;
    _additionalFeeLabelController.text = item['additional_fee_label'] ?? '';
    _additionalFeeAmountController.text = item['additional_fee_amount'] != null ? '${item['additional_fee_amount']}' : '';
    _minBookingValueController.text = '${item['min_booking_value'] ?? item['_min_booking_value'] ?? ''}';

    final rawSlots = item['slots'] ?? item['_slots'];
    if (rawSlots != null) {
      try {
        dynamic parsed = rawSlots;
        if (rawSlots is String) {
          parsed = jsonDecode(rawSlots);
        }
        if (parsed is List) {
          for (int i = 0; i < parsed.length && i < 7; i++) {
            final dayList = parsed[i];
            if (dayList is List) {
              _daySlots[i] = dayList.map((s) => s.toString()).toList();
            }
          }
        } else if (parsed is Map) {
          for (int i = 0; i < 7; i++) {
            final dayList = parsed[i] ?? parsed['$i'] ?? parsed[_dayNames[i].toLowerCase()];
            if (dayList is List) {
              _daySlots[i] = dayList.map((s) => s.toString()).toList();
            }
          }
        }
      } catch (_) {}
    }
    if (_daySlots.every((day) => day.isEmpty)) {
      _generateDefaultSlotsForAllDays();
    }
    
    // Resilient boolean evaluation
    _bookingEnabled = item['booking_status'] == true || item['booking_status'] == 'on' || item['booking_status'] == '1';
    _slotsEnabled = item['slots_status'] == true || item['slots_status'] == 'on' || item['slots_status'] == '1';
    _slotLimit = int.tryParse('${item['slot_limit']}') ?? 5;

    if (item['gallery'] is List) {
      _galleryImages.clear();
      for (var img in (item['gallery'] as List)) {
        if (img is String && img.isNotEmpty) {
          _galleryImages.add(img);
        } else if (img is Map && img['url'] != null) {
          _galleryImages.add(img['url'].toString());
        }
      }
    }

    if (item['menu'] is List) {
      _menuServices.clear();
      for (var group in (item['menu'] as List)) {
        final elements = group['menu_elements'] ?? group['menu'];
        if (elements is List) {
          for (var elem in elements) {
            _menuServices.add({
              'name': elem['name'] ?? '',
              'price': '${elem['price'] ?? ''}',
              'description': elem['description'] ?? '',
              'bookable': elem['bookable'] == 'on' || elem['bookable'] == true || elem['bookable'] == '1',
            });
          }
        }
      }
    }

    if (item['faq'] is List) {
      _faqs.clear();
      for (var f in (item['faq'] as List)) {
        if (f is Map) {
          _faqs.add({
            'question': f['question']?.toString() ?? '',
            'answer': f['answer']?.toString() ?? '',
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subCategoryController.dispose();
    _keywordsController.dispose();
    _logoUrlController.dispose();
    _addressController.dispose();
    _friendlyAddressController.dispose();
    _serviceAreaController.dispose();
    _newImageUrlController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _visitingFeeController.dispose();
    _inspectionFeeController.dispose();
    _additionalFeeLabelController.dispose();
    _additionalFeeAmountController.dispose();
    _minBookingValueController.dispose();
    super.dispose();
  }


  Future<void> _pickAndUploadFeaturedImage() async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      setState(() => _isUploadingFeatured = true);
      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      final res = await ZipBizApiService().uploadMedia(
        user: user,
        base64Data: base64String,
        fileName: picked.name,
      );

      final url = res['url'] as String?;
      final id = res['id'] as int?;
      if (url != null && url.isNotEmpty) {
        setState(() {
          _logoUrlController.text = url;
          _featuredImageId = id;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded to media library!'), backgroundColor: ZipBizColors.statusOpen),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploadingFeatured = false);
    }
  }

  Future<void> _pickAndUploadGalleryImage() async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      setState(() => _isUploadingGallery = true);
      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      final res = await ZipBizApiService().uploadMedia(
        user: user,
        base64Data: base64String,
        fileName: picked.name,
      );

      final url = res['url'] as String?;
      final id = res['id'] as int?;
      if (url != null && url.isNotEmpty) {
        setState(() {
          _galleryImages.add(url);
          if (id != null) _galleryImageIds.add(id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo added to gallery!'), backgroundColor: ZipBizColors.statusOpen),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploadingGallery = false);
    }
  }

  Future<void> _submitListing() async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a listing title.')),
      );
      setState(() => _currentStep = 1);
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      'listing_type': _listingType,
      'title': _titleController.text.trim(),
      if (_selectedPackageProductId != null) 'package_id': _selectedPackageProductId,
      'category': _selectedCategory,
      'sub_category': _subCategoryController.text.trim(),
      'keywords': _keywordsController.text.trim(),
      'featured_image': _logoUrlController.text.trim(),
      'address': _addressController.text.trim(),
      'friendly_address': _friendlyAddressController.text.trim(),
      'region': _selectedRegion,
      'service_area': _serviceAreaController.text.trim(),
      'gallery': _galleryImages,
      'description': _descriptionController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'website': _websiteController.text.trim(),
      'opening_hours': _openingHours,
      'booking_status': _bookingEnabled ? 'on' : 'off',
      'slots_status': _slotsEnabled ? 'on' : 'off',
      'slot_limit': _slotLimit,
      'slots': _daySlots,
      '_slots': _daySlots,
      'visiting_fee': _visitingFeeController.text.trim(),
      'inspection_fee': _inspectionFeeController.text.trim(),
      'min_booking_value': _minBookingValueController.text.trim(),
      'slot_interval': _slotInterval,
      'additional_fee_label': _additionalFeeLabelController.text.trim(),
      'additional_fee_amount': _additionalFeeAmountController.text.trim(),
      if (_featuredImageId != null) 'image_id': _featuredImageId,
      if (_galleryImageIds.isNotEmpty) 'gallery_ids': _galleryImageIds,
      'menu': [
        {
          'menu_title': 'Standard Services',
          'menu_elements': _menuServices.map((s) => {
            'name': s['name'],
            'price': s['price'],
            'description': s['description'],
            'bookable': s['bookable'] == true ? 'on' : 'off',
          }).toList(),
        }
      ],
      'faq': _faqEnabled ? _faqs : [],
    };

    try {
      if (widget.initialListing != null) {
        final id = int.tryParse(widget.initialListing!['id']?.toString() ?? '0') ?? 0;
        await ZipBizApiService().updateVendorListing(user: user, id: id, data: payload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing updated successfully!'), backgroundColor: ZipBizColors.statusOpen),
        );
      } else {
        await ZipBizApiService().createVendorListing(user: user, data: payload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing submitted for review! It will be live once approved by admin.'),
            backgroundColor: ZipBizColors.statusOpen,
            duration: Duration(seconds: 4),
          ),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save listing: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _addServiceDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool bookable = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Service Package', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Service Name *', hintText: 'e.g. Fan Installation'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price (₹) *', prefixText: '₹ '),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description', hintText: 'What is included in this service'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bookable Online'),
                  subtitle: const Text('Allow customers to book this service package'),
                  value: bookable,
                  activeColor: ZipBizColors.primaryContainer,
                  onChanged: (val) => setDialogState(() => bookable = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ZipBizColors.primaryContainer, foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty && priceCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _menuServices.add({
                      'name': nameCtrl.text.trim(),
                      'price': priceCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'bookable': bookable,
                    });
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _addCustomSlotDialog(int dayIdx) {
    final startCtrl = TextEditingController(text: '09:00 AM');
    final endCtrl = TextEditingController(text: '10:00 AM');
    final capCtrl = TextEditingController(text: '$_slotLimit');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Slot to ${_dayNames[dayIdx]}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startCtrl,
              decoration: const InputDecoration(labelText: 'Start Time (e.g. 09:00 AM)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: endCtrl,
              decoration: const InputDecoration(labelText: 'End Time (e.g. 10:00 AM)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: capCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max Bookings (Capacity)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ZipBizColors.primaryContainer, foregroundColor: Colors.white),
            onPressed: () {
              final s = startCtrl.text.trim();
              final e = endCtrl.text.trim();
              final c = int.tryParse(capCtrl.text.trim()) ?? _slotLimit;
              if (s.isNotEmpty && e.isNotEmpty) {
                setState(() {
                  _daySlots[dayIdx].add('$s - $e|$c');
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Slot'),
          ),
        ],
      ),
    );
  }

  void _addFaqDialog() {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add FAQ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qCtrl,
              decoration: const InputDecoration(labelText: 'Question *', hintText: 'e.g. Do you bring tools?'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: aCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Answer *', hintText: 'Yes, all verified technicians carry standard kits.'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ZipBizColors.primaryContainer, foregroundColor: Colors.white),
            onPressed: () {
              if (qCtrl.text.trim().isNotEmpty && aCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _faqs.add({
                    'question': qCtrl.text.trim(),
                    'answer': aCtrl.text.trim(),
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add FAQ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initialListing == null;
    final steps = isNew
        ? [
            'Plan',
            'Type',
            'Basic',
            'Location',
            'Gallery',
            'Contact',
            'Hours',
            'Pricing',
            'FAQs',
            'Review',
          ]
        : [
            'Type',
            'Basic',
            'Location',
            'Gallery',
            'Contact',
            'Hours',
            'Pricing',
            'FAQs',
            'Review',
          ];

    return Scaffold(
      backgroundColor: ZipBizColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ZipBizColors.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.initialListing != null ? 'Edit Listing' : 'Add New Listing',
          style: ZipBizTypography.headlineSmall.copyWith(fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Step Progress Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Step ${_currentStep + 1} of ${steps.length}: ${steps[_currentStep]}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ZipBizColors.primaryContainer)),
                    Text('${((_currentStep + 1) / steps.length * 100).toInt()}% Complete',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / steps.length,
                  backgroundColor: ZipBizColors.surfaceContainer,
                  valueColor: const AlwaysStoppedAnimation<Color>(ZipBizColors.primaryContainer),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          // Step Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStepContent(),
            ),
          ),

          // Bottom Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF0EDED))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: ZipBizColors.outline),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => setState(() => _currentStep--),
                        child: const Text('Back', style: TextStyle(color: ZipBizColors.onSurface)),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ZipBizButton(
                      text: _currentStep == steps.length - 1
                          ? (widget.initialListing != null ? 'Update Listing' : 'Submit Listing')
                          : 'Next Step',
                      isLoading: _isSubmitting,
                      onPressed: () {
                        if (_currentStep < steps.length - 1) {
                          if (isNew && _currentStep == 0) {
                            // Check if package is active or selected
                            if (!_canAddListing && (_userPackages.isEmpty || _userPackages.every((p) => p['is_active'] != true))) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please activate the free Silver plan or choose a plan to proceed.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                          }
                          setState(() => _currentStep++);
                        } else {
                          _submitListing();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    final isNew = widget.initialListing == null;
    final effectiveStep = isNew ? _currentStep : _currentStep + 1;

    switch (effectiveStep) {
      case 0:
        return _buildStep0Plan();
      case 1:
        return _buildStep1Type();
      case 2:
        return _buildStep2Basic();
      case 3:
        return _buildStep3Location();
      case 4:
        return _buildStep4Gallery();
      case 5:
        return _buildStep5Contact();
      case 6:
        return _buildStep6Hours();
      case 7:
        return _buildStep7Pricing();
      case 8:
        return _buildStep8Faq();
      case 9:
        return _buildStep9Review();
      default:
        return const SizedBox();
    }
  }

  // Step 0: Plan Selection
  Widget _buildStep0Plan() {
    final user = Provider.of<UserModel>(context, listen: false).user;
    final defaultPackages = [
      {
        'id': 1001,
        'name': 'Silver Plan',
        'price': 0,
        'price_html': 'Free',
        'is_free': true,
        'listing_limit': 1,
        'description': 'Free starter plan. 1 active listing with basic visibility and direct bookings.',
      },
      {
        'id': 1002,
        'name': 'Gold Plan',
        'price': 499,
        'price_html': '₹499',
        'is_free': false,
        'listing_limit': 5,
        'description': 'Up to 5 listings with priority placement in search results and full analytics.',
      },
      {
        'id': 1003,
        'name': 'Diamond Plan',
        'price': 999,
        'price_html': '₹999',
        'is_free': false,
        'listing_limit': 0,
        'description': 'Unlimited listings, top banner placement, verified badge, and instant approval.',
      },
    ];

    final displayPackages = _packages.isNotEmpty ? _packages : defaultPackages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Subscription Plan', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Select the listing plan that suits your business. Silver plan is 100% free for your first listing!', style: ZipBizTypography.bodySmall),
        const SizedBox(height: 16),

        // Active Package Banner
        if (_userPackages.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Plan: ${_userPackages.first['name'] ?? 'Silver Plan'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Remaining Listings: ${_userPackages.first['remaining'] ?? '1'}',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                  child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        if (_isLoadingPackages)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else
          ...displayPackages.map((pkg) {
            final id = pkg['id'] as int;
            final isFree = pkg['is_free'] == true || (pkg['price'] is num && (pkg['price'] as num) <= 0);
            final isSelected = _selectedPackageProductId == id;
            final hasActivePackage = _userPackages.any((p) => (p['product_id'] == id || p['id'] == id) && p['is_active'] == true);

            return ZipBizCard(
              margin: const EdgeInsets.only(bottom: 12),
              color: isSelected ? ZipBizColors.primaryFixed.withOpacity(0.15) : Colors.white,
              border: Border.all(
                color: isSelected ? ZipBizColors.primaryContainer : ZipBizColors.surfaceContainer,
                width: isSelected ? 2 : 1,
              ),
              onTap: () {
                setState(() {
                  _selectedPackageProductId = id;
                  _selectedPackageName = pkg['name'];
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isFree ? Icons.eco : (id == 1002 ? Icons.military_tech : Icons.diamond),
                            color: isFree ? Colors.teal : (id == 1002 ? Colors.amber.shade700 : Colors.purple),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(pkg['name'] ?? 'Plan', style: ZipBizTypography.labelLarge.copyWith(fontSize: 16)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFree ? Colors.green.shade100 : ZipBizColors.primaryFixed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pkg['price_html'] ?? (isFree ? 'Free' : '₹${pkg['price']}'),
                          style: TextStyle(
                            color: isFree ? Colors.green.shade800 : ZipBizColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(pkg['description'] ?? '', style: ZipBizTypography.bodySmall),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pkg['listing_limit'] == 0 || pkg['listing_limit'] == null
                            ? '• Unlimited Listings'
                            : '• ${pkg['listing_limit']} Listing${pkg['listing_limit'] > 1 ? "s" : ""} Allowed',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      if (hasActivePackage)
                        const Text('Currently Subscribed', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))
                      else if (isFree)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isActivatingPackage
                              ? null
                              : () async {
                                  if (user == null) return;
                                  setState(() => _isActivatingPackage = true);
                                  try {
                                    await ZipBizApiService().selectFreeVendorPackage(user, id);
                                    await _loadPackages();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Silver Free Plan activated! You can now add your listing.'), backgroundColor: Colors.green),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Plan activation: $e'), backgroundColor: Colors.orange),
                                    );
                                  } finally {
                                    if (mounted) setState(() => _isActivatingPackage = false);
                                  }
                                },
                          child: _isActivatingPackage
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Activate Free', style: TextStyle(fontSize: 12)),
                        )
                      else
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedPackageProductId = id;
                              _selectedPackageName = pkg['name'];
                            });
                          },
                          child: Text(isSelected ? 'Selected' : 'Select', style: const TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // Step 1: Listing Type
  Widget _buildStep1Type() {
    final defaultTypes = [
      {'id': 'service', 'title': 'Service Provider', 'desc': 'Home services, repairs, cleaning, plumbing, electricians, technicians', 'icon': Icons.build_circle},
      {'id': 'rent', 'title': 'Rentals', 'desc': 'Properties, vehicles, tools, equipment, event venues', 'icon': Icons.home_work},
      {'id': 'others', 'title': 'Others', 'desc': 'General businesses, retail shops, consultation, dining & events', 'icon': Icons.storefront},
    ];

    final types = _backendListingTypes.isNotEmpty
        ? _backendListingTypes.map((b) {
            final id = b['id'] ?? b['slug'] ?? 'service';
            final name = b['name'] ?? b['title'] ?? id.toString().toUpperCase();
            final isRent = id == 'rent';
            return {
              'id': id,
              'title': name,
              'desc': isRent
                  ? 'Properties, vehicles, tools, equipment, event venues'
                  : 'Home services, repairs, cleaning, plumbing, electricians, technicians',
              'icon': isRent ? Icons.home_work : Icons.build_circle,
            };
          }).toList()
        : defaultTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Listing Type', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Select the classification that best matches your business or offering.', style: ZipBizTypography.bodySmall),
        const SizedBox(height: 16),
        ...types.map((t) {
          final isSelected = _listingType == t['id'];
          return ZipBizCard(
            margin: const EdgeInsets.only(bottom: 12),
            color: isSelected ? ZipBizColors.primaryFixed.withOpacity(0.2) : Colors.white,
            border: Border.all(
              color: isSelected ? ZipBizColors.primaryContainer : ZipBizColors.surfaceContainer,
              width: isSelected ? 2 : 1,
            ),
            onTap: () => setState(() => _listingType = t['id'] as String),
            child: Row(
              children: [
                Icon(t['icon'] as IconData, size: 40, color: isSelected ? ZipBizColors.primaryContainer : Colors.grey),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['title'] as String, style: ZipBizTypography.labelLarge.copyWith(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(t['desc'] as String, style: ZipBizTypography.bodySmall),
                    ],
                  ),
                ),
                Radio<String>(
                  value: t['id'] as String,
                  groupValue: _listingType,
                  activeColor: ZipBizColors.primaryContainer,
                  onChanged: (val) => setState(() => _listingType = val!),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Step 2: Basic Info
  Widget _buildStep2Basic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Provide essential information about your business listing.', style: ZipBizTypography.bodySmall),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Listing Title *',
            hintText: 'e.g. ZipBiz Expert Plumber Services',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category *',
            border: OutlineInputBorder(),
          ),
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val!),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _subCategoryController,
          decoration: const InputDecoration(
            labelText: 'Sub-Category',
            hintText: 'e.g. Geyser & Pipe Fitting',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _keywordsController,
          decoration: const InputDecoration(
            labelText: 'Keywords / Tags',
            hintText: 'e.g. plumber, pipe, tap repair, instant service',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _logoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Logo / Featured Image URL',
                  hintText: 'https://zipbiz.in/wp-content/uploads/...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: _isUploadingFeatured
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload_outlined, size: 16),
              label: Text(_isUploadingFeatured ? 'Uploading...' : 'Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ZipBizColors.primaryContainer,
                foregroundColor: Colors.white,
              ),
              onPressed: _isUploadingFeatured ? null : _pickAndUploadFeaturedImage,
            ),
          ],
        ),
        if (_logoUrlController.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _logoUrlController.text,
              height: 90,
              width: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        ],
      ],
    );
  }

  // Step 3: Location
  Widget _buildStep3Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location & Coverage', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Specify where your service operates or your business is physically located.', style: ZipBizTypography.bodySmall),
        const SizedBox(height: 16),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Physical Address',
            hintText: 'e.g. SCO 42, Sector 34-C',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _friendlyAddressController,
          decoration: const InputDecoration(
            labelText: 'Friendly Display Address',
            hintText: 'e.g. Sector 34, Chandigarh',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedRegion,
          decoration: const InputDecoration(
            labelText: 'Region / City *',
            border: OutlineInputBorder(),
          ),
          items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (val) => setState(() => _selectedRegion = val!),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _serviceAreaController,
          decoration: const InputDecoration(
            labelText: 'Service Area / Coverage',
            hintText: 'e.g. All Tricity within 20 km radius',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // Step 4: Gallery
  Widget _buildStep4Gallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Media Gallery', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Showcase high-resolution photos of your work, equipment, and facility.', style: ZipBizTypography.bodySmall),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              icon: _isUploadingGallery
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(_isUploadingGallery ? 'Uploading Photo...' : 'Browse & Upload Photos'),
              style: ElevatedButton.styleFrom(backgroundColor: ZipBizColors.primaryContainer, foregroundColor: Colors.white),
              onPressed: _isUploadingGallery ? null : _pickAndUploadGalleryImage,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newImageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Or enter Image URL',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ZipBizColors.surfaceContainer, foregroundColor: ZipBizColors.onSurface),
              onPressed: () {
                final url = _newImageUrlController.text.trim();
                if (url.isNotEmpty) {
                  setState(() {
                    _galleryImages.add(url);
                    _newImageUrlController.clear();
                  });
                }
              },
              child: const Text('Add URL'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_galleryImages.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ZipBizColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ZipBizColors.surfaceContainer),
            ),
            child: Column(
              children: const [
                Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('No gallery images added yet.'),
              ],
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _galleryImages.asMap().entries.map((entry) {
              final idx = entry.key;
              final url = entry.value;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _galleryImages.removeAt(idx)),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  // Step 5: Contact & Description
  Widget _buildStep5Contact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact & Description', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Tell customers about your expertise and how they can reach you directly.', style: ZipBizTypography.bodySmall),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Business Description',
            hintText: 'Describe your background, guarantees, and service specialities...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Direct Phone Number',
            hintText: '+91 98765 43210',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Official Email',
            hintText: 'contact@partner.com',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _websiteController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Website',
            hintText: 'https://zipbiz.in',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // Step 6: Opening Hours
  Widget _buildStep6Hours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Opening Hours', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Set operating timings for each day of the week.', style: ZipBizTypography.bodySmall),
        const SizedBox(height: 16),
        ..._openingHours.entries.map((entry) {
          final day = entry.key;
          final val = entry.value;
          final isOpen = val['open'] as bool;

          return ZipBizCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(day, style: ZipBizTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                ),
                Switch(
                  value: isOpen,
                  activeColor: ZipBizColors.statusOpen,
                  onChanged: (v) => setState(() => val['open'] = v),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: isOpen
                      ? Row(
                          children: [
                            Expanded(
                              child: Text('${val['from']} - ${val['to']}', style: ZipBizTypography.bodySmall),
                            ),
                          ],
                        )
                      : const Text('Closed', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Step 7: Pricing & Bookable Services
  Widget _buildStep7Pricing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pricing & Bookable Services', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Configure booking switches, slots, visit fees, and service packages.', style: ZipBizTypography.bodySmall),
        const SizedBox(height: 16),
        ZipBizCard(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Enable Online Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Allows customers to reserve appointments directly through app'),
                value: _bookingEnabled,
                activeColor: ZipBizColors.statusOpen,
                onChanged: (val) => setState(() => _bookingEnabled = val),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Time Slot Booking System', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Enables hourly customer slot selection'),
                value: _slotsEnabled,
                activeColor: ZipBizColors.primaryContainer,
                onChanged: (val) => setState(() => _slotsEnabled = val),
              ),
              if (_slotsEnabled) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Max Bookings Per Slot: '),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if (_slotLimit > 1) setState(() => _slotLimit--);
                      },
                    ),
                    Text('$_slotLimit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => _slotLimit++),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<double>(
                  value: [0.5, 1.0, 2.0, 3.0, 4.0, 5.0].contains(_slotInterval) ? _slotInterval : 1.0,
                  decoration: const InputDecoration(
                    labelText: 'Slot Duration / Interval',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0.5, child: Text('30 Minutes (0.5 hr)')),
                    DropdownMenuItem(value: 1.0, child: Text('1 Hour Interval')),
                    DropdownMenuItem(value: 2.0, child: Text('2 Hours Interval')),
                    DropdownMenuItem(value: 3.0, child: Text('3 Hours Interval')),
                    DropdownMenuItem(value: 4.0, child: Text('4 Hours Interval')),
                    DropdownMenuItem(value: 5.0, child: Text('5 Hours Interval')),
                  ],
                  onChanged: (val) => setState(() => _slotInterval = val ?? 1.0),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daily Slots Configuration:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Auto-Generate All', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        _generateDefaultSlotsForAllDays();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Generated standard slots for open days!'), duration: Duration(seconds: 2)),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (idx) {
                      final day = _dayNames[idx];
                      final isSelected = _activeSlotDayIndex == idx;
                      final count = _daySlots[idx].length;
                      final isOpen = _openingHours[day]?['open'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('${day.substring(0, 3)} ($count)'),
                          selected: isSelected,
                          selectedColor: ZipBizColors.primaryContainer,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : (isOpen ? Colors.black87 : Colors.grey),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _activeSlotDayIndex = idx),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ZipBizColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ZipBizColors.surfaceContainer),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_dayNames[_activeSlotDayIndex]} Slots (${_daySlots[_activeSlotDayIndex].length}):',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          InkWell(
                            onTap: () => _addCustomSlotDialog(_activeSlotDayIndex),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.add, size: 16, color: ZipBizColors.primaryContainer),
                                  SizedBox(width: 2),
                                  Text('Add Slot', style: TextStyle(color: ZipBizColors.primaryContainer, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_daySlots[_activeSlotDayIndex].isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No slots for this day. Tap "Add Slot" or "Auto-Generate All".', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _daySlots[_activeSlotDayIndex].map((s) {
                            final parts = s.split('|');
                            final timeText = parts[0];
                            final cap = parts.length > 1 ? parts[1] : '$_slotLimit';
                            return Chip(
                              label: Text('$timeText (max $cap)', style: const TextStyle(fontSize: 11)),
                              backgroundColor: Colors.white,
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                setState(() {
                                  _daySlots[_activeSlotDayIndex].remove(s);
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _additionalFeeLabelController,
                decoration: const InputDecoration(
                  labelText: 'Custom Additional Fee Name (Optional)',
                  hintText: 'e.g. Material / Night Charge',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _additionalFeeAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _minBookingValueController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minimum Booking Value (₹) (Optional)',
            hintText: 'e.g. 299 - minimum service order total required to book',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Service Packages (${_menuServices.length})', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 16)),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Service'),
              onPressed: _addServiceDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._menuServices.asMap().entries.map((entry) {
          final idx = entry.key;
          final s = entry.value;
          final isBookable = s['bookable'] == true;

          return ZipBizCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(s['name'] ?? '', style: ZipBizTypography.labelLarge),
                          const SizedBox(width: 8),
                          if (isBookable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: ZipBizColors.statusOpen.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                              child: const Text('Bookable', style: TextStyle(color: ZipBizColors.statusOpen, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(s['description'] ?? '', style: ZipBizTypography.bodySmall),
                      const SizedBox(height: 4),
                      Text('₹${s['price']}', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 15, color: ZipBizColors.primary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() => _menuServices.removeAt(idx)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Step 8: FAQ Section
  Widget _buildStep8Faq() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('FAQ Section (Optional)', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
            Switch(
              value: _faqEnabled,
              activeColor: ZipBizColors.primaryContainer,
              onChanged: (val) => setState(() => _faqEnabled = val),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Help customers with common questions regarding policies, materials, and warranties.', style: ZipBizTypography.bodySmall),
        const SizedBox(height: 16),
        if (_faqEnabled) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Question'),
              onPressed: _addFaqDialog,
            ),
          ),
          ..._faqs.asMap().entries.map((entry) {
            final idx = entry.key;
            final f = entry.value;

            return ZipBizCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Q: ${f['question']}', style: ZipBizTypography.labelLarge.copyWith(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('A: ${f['answer']}', style: ZipBizTypography.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => setState(() => _faqs.removeAt(idx)),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  // Step 9: Review & Submit
  Widget _buildStep9Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review Listing Details', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        Text('Please review your details before submitting to ZipBiz marketplace.', style: ZipBizTypography.bodySmall),
        const SizedBox(height: 16),
        ZipBizCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_titleController.text.isNotEmpty ? _titleController.text : 'Untitled Listing',
                  style: ZipBizTypography.headlineSmall.copyWith(fontSize: 18)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: ZipBizColors.primaryFixed, borderRadius: BorderRadius.circular(6)),
                    child: Text(_selectedCategory, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(_selectedRegion, style: ZipBizTypography.bodySmall),
                  const SizedBox(width: 8),
                  Text('• ${_listingType.toUpperCase()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const Divider(height: 24),
              if (widget.initialListing == null && _selectedPackageName != null)
                _buildReviewRow('Subscription Plan', _selectedPackageName!),
              _buildReviewRow('Address', _friendlyAddressController.text.isNotEmpty ? _friendlyAddressController.text : _addressController.text),
              if (_additionalFeeLabelController.text.isNotEmpty)
                _buildReviewRow(_additionalFeeLabelController.text, '₹${_additionalFeeAmountController.text}'),
              _buildReviewRow('Services Added', '${_menuServices.length} packages'),
              _buildReviewRow('Slot Interval', _slotInterval == 0.5 ? '30 Mins' : '${_slotInterval.toStringAsFixed(_slotInterval.truncateToDouble() == _slotInterval ? 0 : 1)} Hour${_slotInterval > 1 ? "s" : ""}'),
              _buildReviewRow('Bookings Online', _bookingEnabled ? 'Active' : 'Disabled'),
              _buildReviewRow('Slots Limit', '$_slotLimit / slot'),
              _buildReviewRow('FAQs Included', _faqEnabled ? '${_faqs.length} Q&As' : 'Disabled'),
              _buildReviewRow('Gallery Photos', '${_galleryImages.length} images'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ZipBizTypography.bodySmall),
          Text(value.isNotEmpty ? value : 'N/A', style: ZipBizTypography.labelLarge.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}
