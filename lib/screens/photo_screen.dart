import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/shooting_result.dart';

class PhotoScreen extends StatefulWidget {
  final ShootingResult result;

  const PhotoScreen({super.key, required this.result});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  bool _showInfo = true;
  final TransformationController _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transform.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final rawPath = widget.result.photoPath;
    final path = (rawPath != null && File(rawPath).existsSync()) ? rawPath : null;
    final hasPhoto = path != null;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (hasPhoto)
            IconButton(
              icon: Icon(
                _showInfo ? Icons.info_outline : Icons.info,
                color: Colors.white,
              ),
              onPressed: () => setState(() => _showInfo = !_showInfo),
            ),
          if (hasPhoto)
            IconButton(
              icon: const Icon(Icons.zoom_out_map, color: Colors.white),
              tooltip: 'Reset zoom',
              onPressed: _resetZoom,
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => setState(() => _showInfo = !_showInfo),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (path != null)
              InteractiveViewer(
                transformationController: _transform,
                minScale: 0.5,
                maxScale: 8.0,
                child: Hero(
                  tag: 'photo_${widget.result.id}',
                  child: Image.file(File(path), fit: BoxFit.contain),
                ),
              )
            else
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        size: 64, color: Color(0xFF484F58)),
                    SizedBox(height: 12),
                    Text('No photo attached',
                        style: TextStyle(color: Color(0xFF8B949E))),
                  ],
                ),
              ),
            if (_showInfo && hasPhoto) _buildInfoOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoOverlay() {
    final r = widget.result;
    final isWhole = r.score == r.score.truncateToDouble();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    r.venueName.isEmpty ? 'Unknown Venue' : r.venueName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMMM d, yyyy · HH:mm').format(r.dateTime),
                    style: const TextStyle(color: Color(0xFFCDD9E5), fontSize: 13),
                  ),
                  if (r.latitude != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Color(0xFF8B949E)),
                        const SizedBox(width: 3),
                        Text(
                          '${r.latitude!.toStringAsFixed(5)}, ${r.longitude!.toStringAsFixed(5)}',
                          style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isWhole ? r.score.toInt().toString() : r.score.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Color(0xFF58A6FF),
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const Text('pts',
                    style: TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
