import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:ebook_library_frontend/core/di/injection_container.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/update_progress.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/reader/reader_cubit.dart';

/// PDF reading screen. Two things make "continue where they left off" work:
///
/// 1. On open, if `ebook.progress.currentPage > 0`, we jump straight to
///    that page once the document finishes loading.
/// 2. On every page change, [ReaderCubit] debounces and persists the new
///    position to the backend — and we force one final, un-debounced save
///    when the screen is popped, so closing the book right after turning a
///    page never loses that last position.
class ReaderPage extends StatelessWidget {
  const ReaderPage({super.key, required this.ebook});

  final Ebook ebook;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReaderCubit(
        updateProgress: sl<UpdateProgress>(),
        ebookId: ebook.id,
        initialPage: ebook.progress.currentPage,
      ),
      child: _ReaderView(ebook: ebook),
    );
  }
}

class _ReaderView extends StatefulWidget {
  const _ReaderView({required this.ebook});

  final Ebook ebook;

  @override
  State<_ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<_ReaderView> {
  final PdfViewerController _controller = PdfViewerController();
  final FlutterTts _flutterTts = FlutterTts();
  
  int _currentPage = 0;
  int? _totalPages;
  bool _jumpedToInitialPage = false;
  String? _loadError;
  
  PdfDocument? _document;
  bool _isSpeaking = false;
  bool _isFullscreen = false;

  late final ReaderCubit _readerCubit;

  @override
  void initState() {
    super.initState();
    _readerCubit = context.read<ReaderCubit>();
    
    _currentPage = widget.ebook.progress.currentPage;
    if (_currentPage == 0) _currentPage = 1;
    
    _initTts();
  }
  
  Future<void> _initTts() async {
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    
    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    
    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _speakCurrentPage() async {
    if (_document == null || _totalPages == null) return;
    
    // PdfTextExtractor uses 0-based indexing for pages, but _currentPage is 1-based.
    final pageIndex = (_currentPage > 0 ? _currentPage : 1) - 1;
    
    try {
      final text = PdfTextExtractor(_document!).extractText(
        startPageIndex: pageIndex, 
        endPageIndex: pageIndex,
      );
      
      if (text.trim().isNotEmpty) {
        // Clean up excessive newlines or hyphenations if necessary, 
        // though flutter_tts usually handles raw text fine.
        await _flutterTts.speak(text);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No readable text found on this page (it might be an image).')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read text: $e')),
        );
      }
    }
  }

  Future<void> _stopTts() async {
    await _flutterTts.stop();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _stopTts();
    
    // Fire-and-forget final save — the screen is closing regardless of
    // whether this completes, but it gives the backend the best chance of
    // having the true last position.
    if (_currentPage > 0) {
      _readerCubit.saveImmediately(
            currentPage: _currentPage,
            totalPages: _totalPages,
          );
    }
    _controller.dispose();
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen ? null : AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.ebook.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Zoom Out',
            onPressed: () {
              _controller.zoomLevel = (_controller.zoomLevel - 0.5).clamp(1.0, 5.0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Zoom In',
            onPressed: () {
              _controller.zoomLevel = (_controller.zoomLevel + 0.5).clamp(1.0, 5.0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: 'Fullscreen',
            onPressed: _toggleFullscreen,
          ),
          if (_document != null)
            IconButton(
              icon: Icon(
                _isSpeaking ? Icons.stop_circle_rounded : Icons.record_voice_over_rounded,
                color: _isSpeaking ? Colors.redAccent : Colors.white,
              ),
              tooltip: _isSpeaking ? 'Stop reading' : 'Read aloud',
              onPressed: _isSpeaking ? _stopTts : _speakCurrentPage,
            ),
          BlocBuilder<ReaderCubit, ReaderState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Icon(
                    switch (state.saveStatus) {
                      ReaderSaveStatus.saving => Icons.cloud_sync_rounded,
                      ReaderSaveStatus.saved => Icons.cloud_done_rounded,
                      ReaderSaveStatus.failed => Icons.cloud_off_rounded,
                      ReaderSaveStatus.idle => Icons.cloud_outlined,
                    },
                    size: 18,
                    color: Colors.white54,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _loadError!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                // PDF viewer
                Expanded(
                  child: SfPdfViewer.network(
                    widget.ebook.downloadUrl,
                    controller: _controller,
                    scrollDirection: PdfScrollDirection.horizontal,
                    pageLayoutMode: PdfPageLayoutMode.single,
                    canShowScrollHead: false,
                    canShowPaginationDialog: true,
                    onDocumentLoadFailed: (details) {
                      setState(() => _loadError = 'Could not load this PDF: ${details.description}');
                    },
                    onDocumentLoaded: (details) {
                      _totalPages = details.document.pages.count;
                      setState(() => _document = details.document);
                      
                      final resumePage = widget.ebook.progress.currentPage;
                      if (!_jumpedToInitialPage && resumePage > 1 && resumePage <= _totalPages!) {
                        _jumpedToInitialPage = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _controller.jumpToPage(resumePage);
                        });
                      }
                    },
                    onPageChanged: (details) {
                      if (_isSpeaking) _stopTts();
                      
                      _currentPage = details.newPageNumber;
                      setState(() {}); // refresh the slider position
                      _readerCubit.onPositionChanged(
                            currentPage: details.newPageNumber,
                            totalPages: _totalPages,
                          );
                    },
                  ),
                ),
                
                // Bottom page scrubber bar
                if (_totalPages != null && _totalPages! > 0 && !_isFullscreen)
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 4),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Page number label
                          Text(
                            'Page $_currentPage of $_totalPages',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Fast scrubber slider
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Colors.white70,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              trackHeight: 3,
                              overlayColor: Colors.white.withOpacity(0.1),
                            ),
                            child: Slider(
                              value: _currentPage.toDouble().clamp(1, _totalPages!.toDouble()),
                              min: 1,
                              max: _totalPages!.toDouble(),
                              divisions: _totalPages! > 1 ? _totalPages! - 1 : 1,
                              onChanged: (value) {
                                final page = value.round();
                                setState(() => _currentPage = page);
                              },
                              onChangeEnd: (value) {
                                _controller.jumpToPage(value.round());
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _isFullscreen
          ? FloatingActionButton(
              backgroundColor: Colors.black54,
              mini: true,
              onPressed: _toggleFullscreen,
              child: const Icon(Icons.fullscreen_exit, color: Colors.white),
            )
          : null,
    );
  }
}
