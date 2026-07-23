import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movieApp/providers/user_providers.dart';
import 'package:movieApp/theme/app_colors.dart';
import 'package:movieApp/theme/app_fonts.dart';
import 'package:movieApp/utils/responsive.dart';
import 'package:movieApp/widgets/shimmer_loading.dart';

class AddUserPage extends ConsumerStatefulWidget {
  const AddUserPage({super.key});

  @override
  ConsumerState<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends ConsumerState<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _movieTasteCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _movieTasteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await ref
        .read(usersProvider.notifier)
        .addUser(
          name: _nameCtrl.text.trim(),
          movieTaste: _movieTasteCtrl.text.trim(),
        );

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Profile added'),
          duration: const Duration(milliseconds: 1500),
        ),
      );
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Add Profile', style: AppFonts.title(context)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(w(context) * 0.048), // ~24px
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: h(context) * 0.02),
              Center(
                child: Container(
                  width:
                      w(context) *
                      0.28, // ~110-120px (slightly increased for better proportion)
                  height: w(context) * 0.28,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: w(context) * 0.14, // responsive icon
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: h(context) * 0.03),
              Center(
                child: Text(
                  "Create your profile",
                  style: AppFonts.display(context),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: h(context) * 0.015),
              Center(
                child: Text(
                  'Add a profile for another person\nwatching movies.',
                  style: AppFonts.caption(context),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: h(context) * 0.048),
              _buildInputField(
                controller: _nameCtrl,
                label: 'Name',
                hint: 'Enter name',
                icon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: h(context) * 0.028),
              _buildInputField(
                controller: _movieTasteCtrl,
                label: 'Movie Taste',
                hint: 'e.g. loves horror, sci-fi, no sad endings',
                icon: Icons.movie_outlined,
                textCapitalization: TextCapitalization.sentences,
              ),
              SizedBox(height: h(context) * 0.06),
              SizedBox(
                width: double.infinity,
                height: h(context) * 0.065, // slightly taller button
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w(context) * 0.008),
                    ),
                  ),
                  child: _isSaving
                      ? const PulsingDotsIndicator(color: Colors.black)
                      : Text('Save', style: AppFonts.button(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.fieldLabel(context)),
        SizedBox(height: h(context) * 0.01),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          style: AppFonts.emphasis(context),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppFonts.caption(
              context,
            ).copyWith(color: AppColors.textFaint),
            prefixIcon: Icon(
              icon,
              color: AppColors.textMuted,
              size: h(context) * 0.028,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(w(context) * 0.024),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(w(context) * 0.024),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(w(context) * 0.024),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: w(context) * 0.04,
              vertical: h(context) * 0.018,
            ),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? '$label is required'
              : null,
        ),
      ],
    );
  }
}
