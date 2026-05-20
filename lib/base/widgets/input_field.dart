import 'package:flutter/material.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String errMsg;
  final String? Function(String?)? validator;
  final int? minLength;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const InputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.errMsg,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.minLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.formLabelStyle),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          autofillHints: null,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppStyles.inputTextStyle,
          decoration: AppStyles.inputDecoration(
            hint: hint,
            suffixIcon: suffixIcon,
          ),
          validator:
              validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return errMsg;
                }
                if (minLength != null && value.length < minLength!) {
                  return 'Must be at least $minLength characters';
                }
                return null;
              },
        ),
      ],
    );
  }
}

class DropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> items;
  final String? value;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;

  const DropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.formLabelStyle),

        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          value: value,
          style: AppStyles.inputTextStyle,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppStyles.iconMuted,
          ),
          decoration: AppStyles.inputDecoration(hint: hint),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          validator:
              validator ??
              (value) => value == null ? 'Please select your $label' : null,
        ),
      ],
    );
  }
}
