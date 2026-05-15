import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/shooting_result.dart';
import '../screens/photo_screen.dart';

class ResultCard extends StatelessWidget {
  final ShootingResult result;
  final VoidCallback onDelete;

  const ResultCard({super.key, required this.result, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(result.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF5A0000),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFF85149)),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF161B22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Delete result?', style: TextStyle(color: Colors.white)),
            content: Text(
              'Remove result from ${result.venueName.isEmpty ? 'Unknown Venue' : result.venueName}?',
              style: const TextStyle(color: Color(0xFF8B949E)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF8B949E))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: Color(0xFFF85149))),
              ),
            ],
          ),
        ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PhotoScreen(result: result)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Row(
            children: [
              _buildThumbnail(),
              Expanded(child: _buildInfo()),
              _buildScore(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final path = result.photoPath;
    const clip = BorderRadius.only(
      topLeft: Radius.circular(12),
      bottomLeft: Radius.circular(12),
    );
    if (path != null && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: clip,
        child: SizedBox(
          width: 80,
          height: 84,
          child: Hero(
            tag: 'photo_${result.id}',
            child: Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: clip,
      child: Container(
        width: 80,
        height: 84,
        color: const Color(0xFF21262D),
        child: const Icon(Icons.image_outlined, color: Color(0xFF484F58), size: 32),
      ),
    );
  }

  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.venueName.isEmpty ? 'Unknown Venue' : result.venueName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, yyyy · HH:mm').format(result.dateTime),
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
          ),
          if (result.latitude != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 11, color: Color(0xFF484F58)),
                const SizedBox(width: 2),
                Text(
                  '${result.latitude!.toStringAsFixed(4)}, ${result.longitude!.toStringAsFixed(4)}',
                  style: const TextStyle(color: Color(0xFF484F58), fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScore() {
    final isWhole = result.score == result.score.truncateToDouble();
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isWhole
                ? result.score.toInt().toString()
                : result.score.toStringAsFixed(1),
            style: const TextStyle(
              color: Color(0xFF58A6FF),
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const Text('pts', style: TextStyle(color: Color(0xFF484F58), fontSize: 11)),
        ],
      ),
    );
  }
}
