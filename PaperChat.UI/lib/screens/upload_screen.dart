import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../core/api_client.dart';
import '../widgets/common.dart';
import 'reader_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  static const maxFileBytes = 50 * 1024 * 1024;
  final _title = TextEditingController();
  final _authors = TextEditingController();
  PlatformFile? _pickedFile;
  int? _pickedFileSize;
  bool _uploading = false;
  double _progress = 0;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _authors.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      // file_picker v13: dùng pickFile() và đọc dung lượng qua length().
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (file == null || !mounted) return;

      // lengthSync() nhanh nếu picker đã biết dung lượng; nếu chưa thì đọc async.
      final fileSize = file.lengthSync() ?? await file.length();
      if (!mounted) return;
      if (fileSize == null) {
        throw const ApiException('Không xác định được dung lượng file. Vui lòng chọn lại PDF.');
      }

      setState(() {
        _pickedFile = file;
        _pickedFileSize = fileSize;
        _error = fileSize > maxFileBytes
            ? 'File vượt quá giới hạn 50 MB (${formatBytes(fileSize)}).'
            : null;
        if (_title.text.isEmpty) {
          _title.text = file.name.replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '');
        }
      });
    } catch (error) {
      if (mounted) showAppMessage(context, error.toString(), isError: true);
    }
  }

  Future<void> _upload() async {
    final file = _pickedFile;
    if (file == null) {
      setState(() => _error = 'Vui lòng chọn một file PDF.');
      return;
    }
    // Recheck size immediately before upload (e.g. if picker metadata was unavailable).
    final fileSize = _pickedFileSize ?? file.lengthSync() ?? await file.length();
    if (fileSize == null) {
      setState(() => _error = 'Không xác định được dung lượng file. Vui lòng chọn lại PDF.');
      return;
    }
    _pickedFileSize = fileSize;

    if (fileSize > maxFileBytes) {
      setState(() => _error = 'File vượt quá giới hạn 50 MB (${formatBytes(fileSize)}).');
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0;
      _error = null;
    });

    try {
      final document = await widget.controller.api.uploadPdf(
        file,
        title: _title.text,
        authors: _authors.text,
        onProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() => _progress = sent / total);
          }
        },
      );
      await widget.controller.refreshDocuments();
      await widget.controller.refreshProfile();
      widget.controller.selectDocument(document);
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pop();
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ReaderScreen(
            controller: widget.controller,
            document: document,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _uploading ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Tải tài liệu PDF'),
      ),
      body: _error != null
          ? _buildErrorPage()
          : ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'THƯ VIỆN NGHIÊN CỨU AI',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Thêm tài liệu nghiên cứu mới',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Tải lên tệp PDF từ thiết bị để bắt đầu đọc và hỏi đáp với AI.',
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 22),
          InkWell(
            onTap: _uploading ? null : _pickFile,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: AppColors.primary,
                      size: 39,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    _pickedFile == null
                        ? 'Chạm để chọn tệp PDF từ thiết bị'
                        : _pickedFile!.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _pickedFile == null
                        ? 'Chỉ hỗ trợ PDF • Tối đa 50 MB'
                        : formatBytes(_pickedFileSize ?? 0),
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickFile,
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('Chọn file từ thiết bị'),
                  ),
                ],
              ),
            ),
          ),
          if (_pickedFile != null) ...[
            const SizedBox(height: 18),
            TextField(
              controller: _title,
              enabled: !_uploading,
              maxLength: 255,
              decoration: const InputDecoration(
                labelText: 'Tên tài liệu',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _authors,
              enabled: !_uploading,
              maxLength: 255,
              decoration: const InputDecoration(
                labelText: 'Tác giả (không bắt buộc)',
                prefixIcon: Icon(Icons.group_outlined),
              ),
            ),
          ],
          if (_uploading) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.surfaceBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Đang tải lên và xử lý tài liệu...',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 7),
                  Text('${(_progress * 100).round()}%'),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          LoadingButton(
            label: 'Bắt đầu tải lên',
            icon: Icons.bolt_rounded,
            loading: _uploading,
            onPressed: _upload,
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: AppColors.muted),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Tệp được gửi an toàn đến máy chủ PaperChat.',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPage() {
    final file = _pickedFile;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9E9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Tải tài liệu không thành công',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tệp nghiên cứu chưa thể được tải lên hoặc xử lý. Hãy kiểm tra thông tin bên dưới.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.45),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEEEE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined,
                      color: AppColors.danger),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      file?.name ?? 'Tài liệu PDF',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (file != null)
                    Text(
                      formatBytes(_pickedFileSize ?? 0),
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 13),
              const Divider(color: Color(0xFFECCACA)),
              const Text(
                'Gợi ý xử lý nhanh',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text('• Đảm bảo tệp có định dạng PDF hợp lệ.'),
              const Text('• Kích thước tệp không vượt quá 50 MB.'),
              const Text('• Kiểm tra kết nối mạng và thử tải lại.'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LoadingButton(
          label: 'Tải lại file khác',
          icon: Icons.upload_file_rounded,
          onPressed: () {
            setState(() {
              _error = null;
              _pickedFile = null;
              _pickedFileSize = null;
              _title.clear();
              _authors.clear();
            });
            _pickFile();
          },
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Về thư viện'),
        ),
      ],
    );
  }

}
