import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class MlTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final bool autofocus;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final int maxLines;

  const MlTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixWidget,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  State<MlTextField> createState() => _MlTextFieldState();
}

class _MlTextFieldState extends State<MlTextField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText && _isObscured,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      style: AppTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20)
            : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () => setState(() => _isObscured = !_isObscured),
                icon: Icon(
                  _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
              )
            : widget.suffixWidget,
      ),
    );
  }
}
