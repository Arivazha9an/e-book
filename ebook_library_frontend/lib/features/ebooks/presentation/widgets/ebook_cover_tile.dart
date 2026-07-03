import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';

/// A single book on the shelf: cover art (or a generated placeholder),
/// title/author beneath it, and a thin progress bar if the book has been
/// started — echoing the classic iOS ebook shelf's "spine + progress" look.
class EbookCoverTile extends StatelessWidget {
  const EbookCoverTile({
    super.key,
    required this.ebook,
    required this.onTap,
    this.onLongPress,
    this.isBusy = false,
  });

  final Ebook ebook;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isBusy ? null : onTap,
      onLongPress: isBusy ? null : onLongPress,
      child: Opacity(
        opacity: isBusy ? 0.5 : 1.0,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // The book cover itself
            Positioned.fill(
              child: PhysicalModel(
                color: Colors.black,
                elevation: 12, // High elevation for a 3D pop off the shelf
                shadowColor: Colors.black,
                borderRadius: BorderRadius.circular(2),
                child: _Cover(ebook: ebook),
              ),
            ),
            
            // Loading indicator overlay
            if (isBusy)
              const Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
              
            // Progress bar at the bottom of the cover
            if (ebook.progress.hasStarted && !isBusy)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                  child: LinearProgressIndicator(
                    value: (ebook.progress.percent / 100).clamp(0, 1),
                    minHeight: 4,
                    backgroundColor: Colors.black45,
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.ebook});

  final Ebook ebook;

  @override
  Widget build(BuildContext context) {
    if (ebook.coverUrl != null) {
      return CachedNetworkImage(
        imageUrl: ebook.coverUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _PlaceholderCover(ebook: ebook),
        errorWidget: (context, url, error) => _PlaceholderCover(ebook: ebook),
      );
    }
    return _PlaceholderCover(ebook: ebook);
  }
}

/// Generated cover for books without an uploaded image — a solid color
/// derived from the title (so the same book always gets the same color)
/// plus the title text, similar to how iBooks generates placeholder spines.
class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover({required this.ebook});

  final Ebook ebook;

  Color _colorForTitle(String title) {
    const palette = [
      Color(0xFF6B4226),
      Color(0xFF2E4057),
      Color(0xFF3F6C51),
      Color(0xFF7A4069),
      Color(0xFF4C4A4A),
      Color(0xFF264653),
    ];
    final index = title.codeUnits.fold<int>(0, (sum, c) => sum + c) % palette.length;
    return palette[index];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _colorForTitle(ebook.title),
            _colorForTitle(ebook.title).withOpacity(0.75),
          ],
        ),
      ),
      padding: const EdgeInsets.all(10),
      alignment: Alignment.center,
      child: Text(
        ebook.title,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          height: 1.3,
        ),
      ),
    );
  }
}
