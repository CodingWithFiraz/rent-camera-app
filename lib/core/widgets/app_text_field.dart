import 'package:flutter/material.dart';

/// Field teks standar aplikasi (Material 3, mengikuti theme).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.enabled = true,
    this.helperText,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;

  /// Mengembalikan pesan error, atau `null` bila valid.
  final FormFieldValidator<String>? validator;

  /// Bila true, teks disembunyikan dan tersedia tombol lihat/sembunyikan.
  final bool obscureText;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final String? helperText;
  final ValueChanged<String>? onFieldSubmitted;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;

  /// Jumlah baris tampilan; > 1 dipakai untuk field catatan/deskripsi.
  final int maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _isObscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      obscureText: _isObscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      textCapitalization: widget.textCapitalization,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperMaxLines: 2,
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () => setState(() => _isObscured = !_isObscured),
                tooltip: _isObscured
                    ? 'Tampilkan ${widget.label}'
                    : 'Sembunyikan ${widget.label}',
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }
}
