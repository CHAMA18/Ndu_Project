import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ndu_project/services/voice_input_service.dart';
import 'package:ndu_project/widgets/voice_text_field.dart';

/// A drop-in TextField that grows vertically as the user types,
/// with optional voice-to-text input via a microphone button and
/// an import button for pasting/importing content.
/// - No internal scrolling; the enclosing page scrolls instead.
/// - By default starts with [minLines] and expands with content (maxLines=null).
/// - Use for multiline content such as notes, descriptions, comments.
/// - Set [enableVoice] to false to hide the mic button (defaults to true).
/// - Set [enableImport] to false to hide the import button (defaults to true).
class ExpandingTextField extends StatefulWidget {
  const ExpandingTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.minLines = 1,
    this.readOnly = false,
    this.onChanged,
    this.keyboardType = TextInputType.multiline,
    this.textInputAction = TextInputAction.newline,
    this.decoration,
    this.style,
    this.enabled,
    this.onEditingComplete,
    this.onSubmitted,
    this.enableVoice = true,
    this.voiceIconColor,
    this.enableImport = true,
    this.importIconColor,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final int minLines;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool? enabled;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;

  /// Whether to show the voice input mic button. Defaults to true.
  final bool enableVoice;

  /// Color of the mic icon. Defaults to brand yellow.
  final Color? voiceIconColor;

  /// Whether to show the import content button. Defaults to true.
  final bool enableImport;

  /// Color of the import icon. Defaults to grey.
  final Color? importIconColor;

  @override
  State<ExpandingTextField> createState() => _ExpandingTextFieldState();
}

class _ExpandingTextFieldState extends State<ExpandingTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void didUpdateWidget(ExpandingTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller ?? TextEditingController();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final InputDecoration baseDecoration = widget.decoration ?? const InputDecoration(
      border: OutlineInputBorder(),
      isDense: true,
    );

    final effectiveDecoration = baseDecoration.copyWith(
      hintText: widget.hintText ?? baseDecoration.hintText,
      labelText: widget.labelText ?? baseDecoration.labelText,
    );

    return VoiceTextField(
      controller: _controller,
      focusNode: widget.focusNode,
      readOnly: widget.readOnly,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      minLines: widget.minLines,
      maxLines: null, // allow vertical growth with content
      decoration: effectiveDecoration,
      style: widget.style,
      enabled: widget.enabled,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      enableVoice: widget.enableVoice,
      voiceIconColor: widget.voiceIconColor,
      enableImport: widget.enableImport,
      importIconColor: widget.importIconColor,
    );
  }
}

/// A Form-compatible variant using TextFormField, with voice-to-text support
/// and import content support.
class ExpandingTextFormField extends StatefulWidget {
  const ExpandingTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.minLines = 1,
    this.readOnly = false,
    this.onChanged,
    this.keyboardType = TextInputType.multiline,
    this.textInputAction = TextInputAction.newline,
    this.decoration,
    this.style,
    this.enabled,
    this.validator,
    this.onSaved,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.autovalidateMode,
    this.enableVoice = true,
    this.voiceIconColor,
    this.enableImport = true,
    this.importIconColor,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final int minLines;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool? enabled;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final AutovalidateMode? autovalidateMode;

  /// Whether to show the voice input mic button. Defaults to true.
  final bool enableVoice;

  /// Color of the mic icon. Defaults to brand yellow.
  final Color? voiceIconColor;

  /// Whether to show the import content button. Defaults to true.
  final bool enableImport;

  /// Color of the import icon. Defaults to grey.
  final Color? importIconColor;

  @override
  State<ExpandingTextFormField> createState() => _ExpandingTextFormFieldState();
}

class _ExpandingTextFormFieldState extends State<ExpandingTextFormField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void didUpdateWidget(ExpandingTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller ?? TextEditingController();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final InputDecoration baseDecoration = widget.decoration ?? const InputDecoration(
      border: OutlineInputBorder(),
      isDense: true,
    );

    final effectiveDecoration = baseDecoration.copyWith(
      hintText: widget.hintText ?? baseDecoration.hintText,
      labelText: widget.labelText ?? baseDecoration.labelText,
    );

    return VoiceTextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      readOnly: widget.readOnly,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      minLines: widget.minLines,
      maxLines: null,
      decoration: effectiveDecoration,
      style: widget.style,
      enabled: widget.enabled,
      validator: widget.validator,
      onSaved: widget.onSaved,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted,
      autovalidateMode: widget.autovalidateMode,
      enableVoice: widget.enableVoice,
      voiceIconColor: widget.voiceIconColor,
      enableImport: widget.enableImport,
      importIconColor: widget.importIconColor,
    );
  }
}
