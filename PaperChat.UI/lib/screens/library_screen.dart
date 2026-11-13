import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/api_models.dart';
import '../widgets/common.dart';
import 'reader_screen.dart';
import 'upload_screen.dart';

void openUpload(BuildContext context, AppController controller) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => UploadScreen(controller: controller),
    ),
  );
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _search = TextEditingController();
  bool _loading = false;
  String _sort = 'newest';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      await widget.controller.refreshDocuments();
      await widget.controller.refreshProfile();
    } on Exception catch (error) {
      if (mounted) showAppMessage(context, error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PaperDocument> get _filtered {
    final query = _search.text.trim().toLowerCase();
    final items = widget.controller.documents.where((document) {
      return query.isEmpty ||
          document.title.toLowerCase().contains(query) ||
          (document.authors ?? '').toLowerCase().contains(query);
    }).toList();
    if (_sort == 'title') {
      items.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sort == 'progress') {
      items.sort((a, b) => b.readingProgress.compareTo(a.readingProgress));
    } else {
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    }
    return items;
  }

  Future<void> _openDocument(PaperDocument document) async {
    widget.controller.selectDocument(document);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          controller: widget.controller,
          document: document,
        ),
      ),
    );
  }

  Future<void> _delete(PaperDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa tài liệu?'),
        content: Text('Bạn có chắc muốn xóa "${document.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.controller.deleteDocument(document);
      if (mounted) showAppMessage(context, 'Đã xóa tài liệu.');
    } on Exception catch (error) {
      if (mounted) showAppMessage(context, error.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = _filtered;
    final user = widget.controller.user;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Text('Thư Viện'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primary,
              child: Text(
                (user?.fullName?.isNotEmpty == true
                        ? user!.fullName!.substring(0, 1)
                        : user?.email.substring(0, 1) ?? 'P')
                    .toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          children: [
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên tài liệu hoặc tác giả...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            if (user != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.controller.documents.length} tài liệu trong thư viện',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${formatBytes(user.storageUsedBytes)} / ${formatBytes(user.storageLimitBytes)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 22),
            SectionTitle(
              'Bài nghiên cứu trong thư viện',
              trailing: PopupMenuButton<String>(
                tooltip: 'Sắp xếp',
                initialValue: _sort,
                onSelected: (value) => setState(() => _sort = value),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'newest', child: Text('Mới nhất')),
                  PopupMenuItem(value: 'title', child: Text('Tên A–Z')),
                  PopupMenuItem(value: 'progress', child: Text('Tiến độ đọc')),
                ],
                child: const Row(
                  children: [
                    Text('Sắp xếp', style: TextStyle(color: AppColors.primary)),
                    SizedBox(width: 4),
                    Icon(Icons.swap_vert_rounded,
                        size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_loading && documents.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (documents.isEmpty)
              SizedBox(
                height: 360,
                child: EmptyState(
                  icon: Icons.picture_as_pdf_outlined,
                  title: _search.text.isEmpty
                      ? 'Thư viện đang trống'
                      : 'Không tìm thấy tài liệu',
                  subtitle: _search.text.isEmpty
                      ? 'Tải lên bài báo PDF đầu tiên để bắt đầu đọc và hỏi đáp với AI.'
                      : 'Thử tìm bằng một từ khóa khác.',
                  action: _search.text.isEmpty
                      ? FilledButton.icon(
                          onPressed: () => openUpload(context, widget.controller),
                          icon: const Icon(Icons.add),
                          label: const Text('Tải PDF lên'),
                        )
                      : null,
                ),
              )
            else
              ...documents.map(
                (document) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _DocumentCard(
                    document: document,
                    onTap: () => _openDocument(document),
                    onDelete: () => _delete(document),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  final PaperDocument document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = document.readingProgress.clamp(0, 100);
    final author = document.authors?.trim();
    final progressColor = progress >= 85 ? AppColors.primaryDark : AppColors.primary;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _smallTag('PDF', icon: Icons.picture_as_pdf_outlined),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${document.pageCount > 0 ? document.pageCount : '—'} trang',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 130),
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: AppColors.danger),
                            SizedBox(width: 8),
                            Text('Xóa tài liệu'),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_horiz, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                document.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              if (author != null && author.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  author,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book_outlined,
                            color: AppColors.primary, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            document.pageCount > 0
                                ? 'Tiến độ đọc: $progress%'
                                : 'Tiến độ đọc',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        Text(
                          '$progress%',
                          style: TextStyle(
                            color: progressColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFDDE2FF),
                        valueColor: AlwaysStoppedAnimation(progressColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _smallTag(formatBytes(document.sizeBytes)),
                  const SizedBox(width: 7),
                  _smallTag(document.isProcessed ? 'Đã xử lý' : 'Chưa xử lý'),
                  const Spacer(),
                  Text(
                    formatDate(document.createdAt),
                    style: const TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallTag(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceBlue,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
