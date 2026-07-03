import 'package:ebook_library_frontend/features/ebooks/presentation/widgets/realistic_book_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ebook_library_frontend/core/di/injection_container.dart';
import 'package:ebook_library_frontend/core/widgets/error_view.dart';
import 'package:ebook_library_frontend/features/ebooks/data/services/ebook_download_service.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/delete_ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/get_download_url.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/get_ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/detail/detail_cubit.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/pages/reader_page.dart';

class EbookDetailPage extends StatelessWidget {
  const EbookDetailPage({super.key, required this.ebookId, this.initial});

  final int ebookId;
  final Ebook? initial;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DetailCubit(
        getEbook: sl<GetEbook>(),
        deleteEbook: sl<DeleteEbook>(),
        getDownloadUrl: sl<GetDownloadUrl>(),
        ebookId: ebookId,
        initial: initial,
      )..load(),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView();

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  double? _downloadProgress;

  Future<void> _handleDownload(BuildContext context, Ebook ebook) async {
    final cubit = context.read<DetailCubit>();
    final url = await cubit.resolveDownloadUrl();
    if (url == null || !context.mounted) return;

    final filename = ebook.originalFilename ??
        '${ebook.title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}.${ebook.fileType.name}';

    setState(() => _downloadProgress = 0);
    try {
      final path = await sl<EbookDownloadService>().downloadToLocalFile(
        url: url,
        suggestedFilename: filename,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );
      if (!context.mounted) return;
      setState(() => _downloadProgress = null);
      await sl<EbookDownloadService>().openFile(path);
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _downloadProgress = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleDelete(BuildContext context, Ebook ebook) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this ebook?'),
        content: Text(
            '"${ebook.title}" will be permanently removed from your library.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<DetailCubit>().delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DetailCubit, DetailState>(
      listener: (context, state) {
        if (state.deleted) {
          Navigator.of(context).pop(true);
        }
        if (state.failure != null && state.status == DetailStatus.success) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.failure!.message)));
        }
      },
      builder: (context, state) {
        if (state.status == DetailStatus.failure) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(
              failure: state.failure!,
              onRetry: () => context.read<DetailCubit>().load(),
            ),
          );
        }

        if (state.status == DetailStatus.loading || state.ebook == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final ebook = state.ebook!;
        final isBusy = state.action != DetailAction.none;

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: state.action == DetailAction.deleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
                onPressed: isBusy ? null : () => _handleDelete(context, ebook),
                tooltip: 'Delete',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: SizedBox(
                  width: 160,
                  height: 240,
                  child: RealisticBookTile(ebook: ebook, onTap: () {}),
                ),
              ),
              const SizedBox(height: 24),
              Text(ebook.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                ebook.displayAuthor,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(ebook.fileType.name.toUpperCase())),
                  if (ebook.fileSizeLabel.isNotEmpty)
                    Chip(label: Text(ebook.fileSizeLabel)),
                  Chip(
                      label: Text(
                          'Added ${DateFormat.yMMMd().format(ebook.createdAt)}')),
                ],
              ),
              if (ebook.progress.hasStarted) ...[
                const SizedBox(height: 20),
                LinearProgressIndicator(
                    value: (ebook.progress.percent / 100).clamp(0, 1)),
                const SizedBox(height: 6),
                Text(
                  '${ebook.progress.percent.toStringAsFixed(0)}% read'
                  '${ebook.progress.totalPages != null ? ' · page ${ebook.progress.currentPage} of ${ebook.progress.totalPages}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (ebook.description?.isNotEmpty == true) ...[
                const SizedBox(height: 20),
                Text(ebook.description!,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: isBusy
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => ReaderPage(ebook: ebook)),
                        );
                        if (context.mounted) {
                          context.read<DetailCubit>().load();
                        }
                      },
                icon: Icon(ebook.progress.hasStarted
                    ? Icons.menu_book_rounded
                    : Icons.play_arrow_rounded),
                label: Text(ebook.progress.hasStarted
                    ? 'Continue reading'
                    : 'Start reading'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    isBusy ? null : () => _handleDownload(context, ebook),
                icon: _downloadProgress != null
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value:
                              _downloadProgress! > 0 ? _downloadProgress : null,
                        ),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  _downloadProgress != null
                      ? 'Downloading ${(_downloadProgress! * 100).toStringAsFixed(0)}%'
                      : 'Download',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
