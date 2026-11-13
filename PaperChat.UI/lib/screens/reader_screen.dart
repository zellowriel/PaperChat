import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../core/api_client.dart';
import '../models/api_models.dart';
import '../widgets/chat_conversation.dart';
import '../widgets/common.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.controller,
    required this.document,
    this.initialPage,
  });

  final AppController controller;
  final PaperDocument document;
  final int? initialPage;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  PdfControllerPinch? _pdfController;
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  int _pageCount = 0;
  int _lastSavedProgress = -1;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage ??
        (widget.document.pageCount > 0
            ? ((widget.document.readingProgress / 100) *
                        widget.document.pageCount)
                    .round()
                    .clamp(1, widget.document.pageCount)
                    .toInt()
            : 1);
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final bytes = await widget.controller.api.downloadPdf(widget.document.id);
      if (!mounted) return;
      final controller = PdfControllerPinch(
        document: PdfDocument.openData(bytes),
        initialPage: _currentPage,
      );
      setState(() {
        _pdfController = controller;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (error) {
      if (mounted) setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _onDocumentLoaded(PdfDocument document) {
    if (!mounted) return;
    setState(() => _pageCount = document.pagesCount);
    _saveProgress(_currentPage, document.pagesCount);
  }

  void _onPageChanged(int page) {
    _currentPage = page;
    final total = _pageCount > 0 ? _pageCount : widget.document.pageCount;
    if (total > 0) _saveProgress(page, total);
    if (mounted) setState(() {});
  }

  Future<void> _saveProgress(int page, int total) async {
    if (total <= 0) return;
    final progress = ((page / total) * 100).round().clamp(0, 100).toInt();
    if (_lastSavedProgress == progress) return;
    _lastSavedProgress = progress;
    widget.controller.updateLocalProgress(widget.document.id, progress);
    try {
      await widget.controller.api.updateReadingProgress(
        widget.document.id,
        progress,
      );
    } catch (_) {
      // Progress remains local; the next page change retries the update.
      _lastSavedProgress = -1;
    }
  }

  void _openAiChat() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Hỏi AI về tài liệu này',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ChatConversation(
                controller: widget.controller,
                document: widget.document,
                compact: true,
                onCitationTap: (page) {
                  Navigator.of(context).pop();
                  _pdfController?.jumpToPage(page);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _pageCount > 0 ? _pageCount : widget.document.pageCount;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.document.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            Text(
              total > 0 ? 'Trang $_currentPage / $total' : 'Tài liệu PDF',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? EmptyState(
                        icon: Icons.picture_as_pdf_outlined,
                        title: 'Không mở được PDF',
                        subtitle: _error!,
                        action: OutlinedButton.icon(
                          onPressed: _loadPdf,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      )
                    : PdfViewPinch(
                        controller: _pdfController!,
                        onDocumentLoaded: _onDocumentLoaded,
                        onPageChanged: _onPageChanged,
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: const Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      total > 0
                          ? 'Đang đọc trang $_currentPage/$total'
                          : 'Đang đọc tài liệu PDF',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _loading || _error != null ? null : _openAiChat,
                    icon: const Icon(Icons.auto_awesome, size: 17),
                    label: const Text('Hỏi AI'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
