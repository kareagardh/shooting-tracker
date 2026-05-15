import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/shooting_result.dart';
import '../services/location_service.dart';

class AddResultScreen extends StatefulWidget {
  const AddResultScreen({super.key});

  @override
  State<AddResultScreen> createState() => _AddResultScreenState();
}

class _AddResultScreenState extends State<AddResultScreen> {
  final _formKey = GlobalKey<FormState>();
  final _venueController = TextEditingController();
  final _scoreController = TextEditingController();

  DateTime _dateTime = DateTime.now();
  double? _latitude;
  double? _longitude;
  String? _photoPath;
  bool _fetchingLocation = false;

  @override
  void dispose() {
    _venueController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => _darkPicker(ctx, child!),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
      builder: (ctx, child) => _darkPicker(ctx, child!),
    );
    if (time == null) return;
    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Widget _darkPicker(BuildContext ctx, Widget child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF58A6FF),
          surface: Color(0xFF161B22),
          onSurface: Colors.white,
        ),
        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0D1117)),
      ),
      child: child,
    );
  }

  Future<void> _fetchLocation() async {
    setState(() => _fetchingLocation = true);
    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _fetchingLocation = false;
      _latitude = pos?.latitude;
      _longitude = pos?.longitude;
    });
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get location — check GPS/permissions'),
          backgroundColor: Color(0xFF5A0000),
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/target_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(picked.path).copy(dest);
    if (mounted) setState(() => _photoPath = dest);
  }

  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF30363D),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _sheetTile(Icons.camera_alt_outlined, 'Take Photo', () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            }),
            _sheetTile(Icons.photo_library_outlined, 'Choose from Gallery', () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            }),
            if (_photoPath != null)
              _sheetTile(Icons.delete_outline, 'Remove Photo', () {
                Navigator.pop(context);
                setState(() => _photoPath = null);
              }, color: const Color(0xFFF85149)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  ListTile _sheetTile(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? const Color(0xFF58A6FF);
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: color != null ? c : Colors.white)),
      onTap: onTap,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ShootingResult(
        dateTime: _dateTime,
        score: double.parse(_scoreController.text),
        latitude: _latitude,
        longitude: _longitude,
        venueName: _venueController.text.trim(),
        photoPath: _photoPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Result'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF58A6FF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF30363D)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPhotoTile(),
            const SizedBox(height: 20),
            _section('Score', _buildScoreField()),
            const SizedBox(height: 16),
            _section('Shooting Venue', _buildVenueField()),
            const SizedBox(height: 16),
            _section('Date & Time', _buildDateTimeTile()),
            const SizedBox(height: 16),
            _section('GPS Location', _buildLocationTile()),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTile() {
    return GestureDetector(
      onTap: _showPhotoSheet,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _photoPath != null ? const Color(0xFF238636) : const Color(0xFF30363D),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _photoPath != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(_photoPath!), fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey[700]),
                  const SizedBox(height: 10),
                  Text(
                    'Tap to add target photo',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _section(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF8B949E),
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _fieldDecor({String? hint, Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF484F58)),
      prefixIcon: prefix,
      suffix: suffix,
      filled: true,
      fillColor: const Color(0xFF161B22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF58A6FF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF85149)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildScoreField() {
    return TextFormField(
      controller: _scoreController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      decoration: _fieldDecor(
        hint: '0',
        suffix: const Text('pts', style: TextStyle(color: Color(0xFF8B949E))),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter a score';
        if (double.tryParse(v) == null) return 'Invalid number';
        return null;
      },
    );
  }

  Widget _buildVenueField() {
    return TextFormField(
      controller: _venueController,
      style: const TextStyle(color: Colors.white),
      decoration: _fieldDecor(
        hint: 'e.g. City Rifle Club',
        prefix: const Icon(Icons.location_city_outlined, color: Color(0xFF8B949E), size: 20),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a venue name' : null,
    );
  }

  Widget _buildDateTimeTile() {
    return _tappableTile(
      onTap: _pickDateTime,
      leading: const Icon(Icons.calendar_today_outlined, color: Color(0xFF8B949E), size: 20),
      label: DateFormat('MMMM d, yyyy · HH:mm').format(_dateTime),
    );
  }

  Widget _buildLocationTile() {
    final hasLoc = _latitude != null;
    return _tappableTile(
      onTap: _fetchingLocation ? null : _fetchLocation,
      borderColor: hasLoc ? const Color(0xFF238636) : null,
      leading: _fetchingLocation
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF58A6FF)),
            )
          : Icon(
              hasLoc ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: hasLoc ? const Color(0xFF3FB950) : const Color(0xFF8B949E),
              size: 20,
            ),
      label: hasLoc
          ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
          : 'Tap to fetch GPS position',
      labelColor: hasLoc ? Colors.white : const Color(0xFF484F58),
    );
  }

  Widget _tappableTile({
    required VoidCallback? onTap,
    required Widget leading,
    required String label,
    Color? borderColor,
    Color? labelColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor ?? const Color(0xFF30363D)),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor ?? Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: Color(0xFF484F58), size: 18),
          ],
        ),
      ),
    );
  }
}
