import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/api_models.dart';
import '../widgets/chat_conversation.dart';
import '../widgets/common.dart';
import '../viewmodels/app_view_model.dart';
import 'upload_screen.dart';
import 'reader_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.controller});

  final AppViewModel controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final documents = controller.documents;
        final selected = controller.selectedDocument;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary),
                SizedBox(width: 9),
                Text('Trợ lý AI'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Tải lại thư viện',
                onPressed: () async {
                  try {
                    await controller.refreshDocuments();
                  } catch (error) {
                    if (context.mounted) {
                      showAppMessage(context, error.toString(), isError: true);
                    }
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: documents.isEmpty
              ? EmptyState(
                  icon: Icons.forum_outlined,
                  title: 'Bạn chưa có tài liệu để hỏi AI',
                  subtitle:
                      'PaperChat hiện hỗ trợ hỏi đáp theo một tài liệu PDF. Hãy tải PDF lên thư viện trước.',
                  action: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UploadScreen(controller: controller),
                      ),
                    ),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Tải PDF lên'),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.picture_as_pdf_outlined,
                              color: AppColors.primary,
                              size: 19,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value:
                                      documents.any((d) => d.id == selected?.id)
                                      ? selected!.id
                                      : documents.first.id,
                                  hint: const Text('Chọn tài liệu'),
                                  items: documents
                                      .map(
                                        (PaperDocument document) =>
                                            DropdownMenuItem<String>(
                                              value: document.id,
                                              child: Text(
                                                document.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: (id) {
                                    final match = documents.firstWhere(
                                      (item) => item.id == id,
                                    );
                                    controller.selectDocument(match);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: selected == null
                          ? const Center(child: CircularProgressIndicator())
                          : ChatConversation(
                              key: ValueKey(selected.id),
                              controller: controller,
                              document: selected,
                              onCitationTap: (page) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ReaderScreen(
                                      controller: controller,
                                      document: selected,
                                      initialPage: page,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
