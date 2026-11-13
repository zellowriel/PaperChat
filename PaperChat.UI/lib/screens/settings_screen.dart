import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi PaperChat không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) await controller.logout();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final user = controller.user;
        if (user == null) return const SizedBox.shrink();
        final ratio = user.storageLimitBytes <= 0
            ? 0.0
            : (user.storageUsedBytes / user.storageLimitBytes)
                .clamp(0.0, 1.0)
                .toDouble();
        final fullName = user.fullName?.trim().isNotEmpty == true
            ? user.fullName!.trim()
            : 'PaperChat User';
        final initial = fullName.substring(0, 1).toUpperCase();

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Cài đặt'),
            actions: [
              IconButton(
                tooltip: 'Làm mới thông tin',
                onPressed: () async {
                  try {
                    await controller.refreshProfile();
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
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 29,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              _planBadge(user.planType),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 23),
              const _GroupLabel('GIAO DIỆN'),
              Card(
                child: SwitchListTile.adaptive(
                  value: controller.isDarkMode,
                  onChanged: controller.toggleDarkMode,
                  secondary: const _LeadingIcon(Icons.dark_mode_outlined),
                  title: const Text('Chế độ Sáng / Tối'),
                  subtitle: Text(
                    controller.isDarkMode ? 'Đang bật chế độ tối' : 'Đang dùng giao diện sáng',
                    style: const TextStyle(fontSize: 12),
                  ),
                  activeTrackColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 22),
              const _GroupLabel('TÀI KHOẢN & DỮ LIỆU'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _LeadingIcon(Icons.cloud_outlined),
                          const SizedBox(width: 11),
                          const Expanded(
                            child: Text(
                              'Dung lượng lưu trữ',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '${formatBytes(user.storageUsedBytes)} / ${formatBytes(user.storageLimitBytes)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceBlue,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đã sử dụng ${(ratio * 100).toStringAsFixed(1)}% dung lượng',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  leading: const _LeadingIcon(Icons.picture_as_pdf_outlined),
                  title: const Text('Tài liệu trong thư viện'),
                  subtitle: const Text('Số tài liệu đã tải lên'),
                  trailing: Text(
                    '${controller.documents.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: Color(0xFFF4B5B5)),
                  backgroundColor: const Color(0xFFFFE9E9),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Đăng xuất khỏi thiết bị'),
              ),
              const SizedBox(height: 18),
              const Text(
                'PaperChat AI • Academic Research Assistant',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _planBadge(String plan) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: plan.toUpperCase() == 'PRO'
          ? const Color(0xFFFFF2D8)
          : AppColors.surfaceBlue,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      plan.toUpperCase(),
      style: TextStyle(
        color: plan.toUpperCase() == 'PRO'
            ? const Color(0xFF9A6700)
            : AppColors.primary,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 3, bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceBlue,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: AppColors.primary, size: 21),
      );
}
