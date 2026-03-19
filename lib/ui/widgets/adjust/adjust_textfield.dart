import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdjustTextField extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey<FormFieldState>? fieldKey;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;

  static const _borderRadius = 12.0;

  const AdjustTextField({
    super.key,
    required this.controller,
    this.fieldKey,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.textInputAction = TextInputAction.done,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
  });

  OutlineInputBorder _buildBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_borderRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      style: const TextStyle(fontSize: 15),
      onChanged: onChanged,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _buildBorder(cs.primary, 1.4),
        enabledBorder: _buildBorder(cs.primary, 1.4),
        focusedBorder: _buildBorder(cs.primary, 2),
        errorBorder: _buildBorder(cs.error, 1.4),
        focusedErrorBorder: _buildBorder(cs.error, 2),
      ),
    );
  }
}
