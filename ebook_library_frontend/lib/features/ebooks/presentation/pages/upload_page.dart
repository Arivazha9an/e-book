import 'dart:io';

import 'package:ebook_library_frontend/features/ebooks/presentation/widgets/padf_first_Page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ebook_library_frontend/core/di/injection_container.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/upload/upload_cubit.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UploadCubit>(),
      child: const _UploadView(),
    );
  }
}

class _UploadView extends StatefulWidget {
  const _UploadView();

  @override
  State<_UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<_UploadView> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();

  PlatformFile? _selectedFile;
  PlatformFile? _selectedCover;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    setState(() {
      _selectedFile = file;
      // Pre-fill the title from the filename if the user hasn't typed one.
      if (_titleController.text.trim().isEmpty) {
        final name = file.name
            .replaceAll(RegExp(r'\.(pdf|epub)$', caseSensitive: false), '');
        _titleController.text = name.replaceAll(RegExp(r'[_-]+'), ' ');
      }
    });
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: false);
    if (result == null || result.files.isEmpty) return;
    setState(() => _selectedCover = result.files.single);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UploadCubit, UploadState>(
      listener: (context, state) {
        if (state.status == UploadStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final isUploading = state.status == UploadStatus.uploading;

        return Scaffold(
          appBar: AppBar(title: const Text('Add a book')),
          body: AbsorbPointer(
              absorbing: isUploading,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          Column(
                            children: [
                              const SizedBox(height: 20),
                              Icon(
                                Icons.menu_book_rounded,
                                size: 90,
                                color: Colors.brown.shade600,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Add a New Book",
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Import PDFs or EPUBs into your personal library",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Visibility(
                            visible: _selectedFile != null,
                            child: _BookPreview(
                              pdf: _selectedFile,
                              cover: _selectedCover,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _FilePickerTile(
                            icon: Icons.picture_as_pdf_rounded,
                            label: _selectedFile?.name ??
                                'Choose a PDF or EPUB file',
                            subtitle: _selectedFile != null
                                ? '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(1)} MB'
                                : 'Max 50MB',
                            onTap: _pickFile,
                          ),
                          const SizedBox(height: 12),
                          _FilePickerTile(
                            icon: Icons.image_outlined,
                            label: _selectedCover?.name ??
                                'Add a cover image (optional)',
                            onTap: _pickCover,
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: "Book title",
                              prefixIcon: const Icon(Icons.menu_book),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                              controller: _authorController,
                              decoration: InputDecoration(
                                hintText: "Author",
                                prefixIcon: const Icon(Icons.menu_book),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              )),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText: "Description",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 28),
                          if (state.status == UploadStatus.failure &&
                              state.failure != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                state.failure!.message,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.error),
                              ),
                            ),
                          if (isUploading) ...[
                            Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.cloud_upload,
                                      size: 44,
                                    ),
                                    const SizedBox(height: 12),
                                    LinearProgressIndicator(
                                      value: state.progress,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "${(state.progress * 100).toInt()}%",
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          FilledButton(
                            onPressed: isUploading ||
                                    _selectedFile?.path == null
                                ? null
                                : () => context.read<UploadCubit>().submit(
                                      title: _titleController.text,
                                      author: _authorController.text,
                                      description: _descriptionController.text,
                                      filePath: _selectedFile!.path!,
                                      coverImagePath: _selectedCover?.path,
                                    ),
                            child: isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Upload to library'),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              )),
        );
      },
    );
  }
}

class _FilePickerTile extends StatelessWidget {
  const _FilePickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.brown.shade200,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 54,
              color: Colors.brown,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BookPreview extends StatelessWidget {
  const _BookPreview({
    this.pdf,
    this.cover,
  });

  final PlatformFile? pdf;
  final PlatformFile? cover;

  @override
  Widget build(BuildContext context) {
    Widget preview;

    if (cover?.path != null) {
      preview = Image.file(
        File(cover!.path!),
        fit: BoxFit.cover,
      );
    } else if (pdf?.path != null) {
      preview = PdfBookPreview(
        path: pdf!.path!,
      );
    } else {
      preview = Container(
        color: Colors.brown.shade300,
        alignment: Alignment.center,
        child: const Icon(
          Icons.menu_book_rounded,
          size: 80,
          color: Colors.white,
        ),
      );
    }

    return Center(
      child: Container(
        width: 180,
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.25),
              blurRadius: 20,
              offset: const Offset(8, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: preview,
      ),
    );
  }
}
