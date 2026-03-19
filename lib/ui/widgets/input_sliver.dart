import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputSliver extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const InputSliver({
    super.key,
    required this.formKey,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 400;

            return Form(
              key: formKey,
              child: isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(context),
                        const SizedBox(height: 10),
                        _buildButton(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildTextField(context)),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: _buildButton()),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  static const double _borderRadius = 14;

  Widget _buildTextField(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final primary = theme.primary;
    final errorColor = theme.error;

    OutlineInputBorder buildBorder(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextFormField(
      controller: controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [_NumericInputFormatter()],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => onSubmit(),
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Valor de X',
        hintText: 'Ej. 0.47',
        prefixIcon: const Icon(Icons.functions_rounded),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: buildBorder(primary, 1.4),
        enabledBorder: buildBorder(primary, 1.4),
        focusedBorder: buildBorder(primary, 2),
        errorBorder: buildBorder(errorColor, 1.4),
        focusedErrorBorder: buildBorder(errorColor, 2),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Ingresa un valor';

        final v = double.tryParse(value.trim());
        if (v == null || !v.isFinite) return 'Número inválido';

        if (!exp(v).isFinite) return 'Valor demasiado grande';

        return null;
      },
    );
  }

  Widget _buildButton() {
    return SizedBox(
      height: 50,
      child: FilledButton.icon(
        onPressed: onSubmit,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text(
          'Calcular',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
        ),
      ),
    );
  }
}

class _NumericInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty || text == '-') return newValue;

    final valid = RegExp(r'^-?\d*\.?\d*$').hasMatch(text);
    return valid ? newValue : oldValue;
  }
}
