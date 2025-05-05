import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsField extends StatelessWidget {
  final String label;
  final String value;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData? icon;
  final bool obscureText;
  final int? maxLines;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;

  const SettingsField({
    Key? key,
    required this.label,
    required this.value,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.icon,
    this.obscureText = false,
    this.maxLines = 1,
    this.hintText,
    this.inputFormatters,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field label
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          // Text field
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            onChanged: onChanged,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hintText ?? 'Enter $label',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              contentPadding: const EdgeInsets.all(0),
              isDense: true,
              border: InputBorder.none,
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      size: 20,
                      color: Colors.black54,
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 30,
                maxHeight: 24,
              ),
            ),
          ),
          
          // Divider
          Container(
            height: 1,
            color: Colors.grey[200],
            margin: const EdgeInsets.only(top: 8),
          ),
        ],
      ),
    );
  }
}

// Alternative Settings Field with a more modern look
class ModernSettingsField extends StatelessWidget {
  final String label;
  final String value;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData? icon;
  final bool obscureText;
  final int? maxLines;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final Color? iconColor;

  const ModernSettingsField({
    Key? key,
    required this.label,
    required this.value,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.icon,
    this.obscureText = false,
    this.maxLines = 1,
    this.hintText,
    this.inputFormatters,
    this.onChanged,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color effectiveIconColor = iconColor ?? Colors.deepOrange;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field label with icon
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: effectiveIconColor,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Text field with rounded background
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              maxLines: maxLines,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              onChanged: onChanged,
              inputFormatters: inputFormatters,
              decoration: InputDecoration(
                hintText: hintText ?? 'Enter $label',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// A completely different style - Material 3 inspired settings field
class Material3SettingsField extends StatelessWidget {
  final String label;
  final String value;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData? icon;
  final bool obscureText;
  final int? maxLines;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final Color? accentColor;

  const Material3SettingsField({
    Key? key,
    required this.label,
    required this.value,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.icon,
    this.obscureText = false,
    this.maxLines = 1,
    this.hintText,
    this.inputFormatters,
    this.onChanged,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color effectiveAccentColor = accentColor ?? Colors.deepOrange;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outlined text field with floating label
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            onChanged: onChanged,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              labelText: label,
              hintText: hintText ?? 'Enter $label',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              labelStyle: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: effectiveAccentColor,
                    )
                  : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: effectiveAccentColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}