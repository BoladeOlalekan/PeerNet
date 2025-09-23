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
        Text(
          label, 
          style: AppStyles.inputLabel
        ),

        SizedBox(height: 10),

        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            suffixIcon: suffixIcon,
            hintText: hint,
            hintStyle: AppStyles.hintStyle,
            filled: true,
            fillColor: AppStyles.backgroundColor,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator ??
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
        Text(
          label, 
          style: AppStyles.inputLabel
        ),
        
        SizedBox(height: 10),

        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppStyles.hintStyle,
            filled: true,
            fillColor: AppStyles.backgroundColor,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator ?? (value) => value == null ? 'Please select your $label' : null,
        ),
      ],
    );
  }
}
