import 'package:flutter/material.dart';

import '../models/shooting_result.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../widgets/result_card.dart';
import 'add_result_screen.dart';

enum _MenuAction { backup, restore }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ShootingResult> _results = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final results = await DatabaseService.loadResults();
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  Future<void> _openAddResult() async {
    final result = await Navigator.push<ShootingResult>(
      context,
      MaterialPageRoute(builder: (_) => const AddResultScreen()),
    );
    if (result != null) {
      await DatabaseService.addResult(result);
      _loadResults();
    }
  }

  Future<void> _onMenuSelected(_MenuAction action) async {
    if (action == _MenuAction.backup) {
      await _createBackup();
    } else {
      await _restoreBackup();
    }
  }

  Future<void> _createBackup() async {
    setState(() => _busy = true);
    try {
      await BackupService.createBackup();
    } catch (e) {
      if (mounted) _showError('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    setState(() => _busy = true);
    try {
      final added = await BackupService.restoreBackup();
      if (!mounted) return;
      if (added == 0) {
        _showSnack('No new results found in backup.');
      } else {
        _showSnack('$added result${added == 1 ? '' : 's'} restored successfully.');
        _loadResults();
      }
    } on FormatException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF238636),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF5A0000),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text(
              'Mitti',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
            actions: [
              PopupMenuButton<_MenuAction>(
                icon: const Icon(Icons.settings_outlined),
                color: const Color(0xFF161B22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFF30363D)),
                ),
                onSelected: _busy ? null : _onMenuSelected,
                itemBuilder: (_) => [
                  _menuItem(
                    _MenuAction.backup,
                    Icons.backup_outlined,
                    'Create backup',
                    'Zip results & photos, then share',
                  ),
                  const PopupMenuDivider(height: 1),
                  _menuItem(
                    _MenuAction.restore,
                    Icons.restore_outlined,
                    'Restore backup',
                    'Pick a .zip file and merge data',
                  ),
                ],
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFF30363D)),
            ),
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF58A6FF)))
              : _results.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadResults,
                      color: const Color(0xFF58A6FF),
                      backgroundColor: const Color(0xFF161B22),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _results.length,
                        itemBuilder: (_, i) => ResultCard(
                          result: _results[i],
                          onDelete: () async {
                            await DatabaseService.deleteResult(_results[i].id);
                            _loadResults();
                          },
                        ),
                      ),
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: _busy ? null : _openAddResult,
            child: const Icon(Icons.add, size: 28),
          ),
        ),
        if (_busy)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF58A6FF)),
                  SizedBox(height: 16),
                  Text(
                    'Please wait…',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  PopupMenuItem<_MenuAction> _menuItem(
    _MenuAction value,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return PopupMenuItem<_MenuAction>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF58A6FF)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              Text(subtitle,
                  style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gps_fixed_rounded, size: 72, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text('No results yet',
              style: TextStyle(
                  color: Colors.grey[500], fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Tap + to record your first session',
              style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        ],
      ),
    );
  }
}
