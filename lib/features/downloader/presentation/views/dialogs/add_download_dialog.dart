import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:modern_downloader/core/design_system/components/app_button.dart';
import 'package:modern_downloader/core/design_system/components/app_text_field.dart';
import 'package:modern_downloader/core/design_system/components/app_toast.dart';
import 'package:modern_downloader/core/design_system/foundation/colors.dart';
import 'package:modern_downloader/core/design_system/foundation/spacing.dart';
import 'package:modern_downloader/core/design_system/foundation/typography.dart';
import 'package:modern_downloader/features/downloader/presentation/providers/downloader_provider.dart';

class AddDownloadDialog extends ConsumerStatefulWidget {
  final String? initialUrl;
  const AddDownloadDialog({super.key, this.initialUrl});

  @override
  ConsumerState<AddDownloadDialog> createState() => _AddDownloadDialogState();
}

class _AddDownloadDialogState extends ConsumerState<AddDownloadDialog> {
  late final TextEditingController _urlController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final url = _urlController.text.trim();
      ref.read(downloadListProvider.notifier).startDownload(url);
      if (context.mounted) {
        AppToast.showSuccess(context, "Download started");
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("New Download", style: AppTypography.h3),
              const Gap(AppSpacing.m),
              AppTextField(
                controller: _urlController,
                hint: "Paste link here...",
                label: "URL",
                prefixIcon: const Icon(
                  Icons.link,
                  color: AppColors.textSecondary,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a URL';
                  }
                  return null;
                },
                onSubmitted: (_) => _submit(),
                autofocus: true,
              ),
              const Gap(AppSpacing.l),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.ghost(
                    label: "Cancel",
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Gap(AppSpacing.xs),
                  AppButton.primary(
                    label: "Download",
                    icon: Icons.download,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
