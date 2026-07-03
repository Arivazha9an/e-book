import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfBookPreview extends StatelessWidget {
  const PdfBookPreview({
    super.key,
    required this.path,
  });

  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          SfPdfViewer.file(
            File(path),

            /// Only show the first page.
            initialPageNumber: 1,

            /// Disable all interaction.
            canShowPaginationDialog: false,
            canShowScrollHead: false,
            enableDoubleTapZooming: false,
            enableTextSelection: false,
            pageLayoutMode: PdfPageLayoutMode.single,

            scrollDirection: PdfScrollDirection.vertical,
          ),

          /// Dark gradient like a book cover
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(.25),
                      Colors.transparent,
                    ],
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
