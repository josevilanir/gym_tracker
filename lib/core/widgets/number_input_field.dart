// lib/core/widgets/number_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de entrada numérica com botões de incremento/decremento
class NumberInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final double min;
  final double max;
  final double step;
  final bool isInteger;
  final String? helperText;
  final FormFieldValidator<String>? validator;
  final bool enabled;

  const NumberInputField({
    super.key,
    required this.controller,
    required this.label,
    this.min = 0,
    this.max = 999,
    this.step = 1,
    this.isInteger = true,
    this.helperText,
    this.validator,
    this.enabled = true,
  });

  @override
  State<NumberInputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<NumberInputField> {
  void _increment() {
    final current = double.tryParse(widget.controller.text) ?? widget.min;
    final newValue = (current + widget.step).clamp(widget.min, widget.max);
    widget.controller.text = widget.isInteger
        ? newValue.toInt().toString()
        : newValue.toStringAsFixed(1);
    HapticFeedback.lightImpact();
  }

  void _decrement() {
    final current = double.tryParse(widget.controller.text) ?? widget.min;
    final newValue = (current - widget.step).clamp(widget.min, widget.max);
    widget.controller.text = widget.isInteger
        ? newValue.toInt().toString()
        : newValue.toStringAsFixed(1);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Botão de decremento
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: widget.enabled ? _decrement : null,
          color: Theme.of(context).colorScheme.primary,
          tooltip: 'Diminuir',
        ),
        
        // Campo de texto
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            keyboardType: TextInputType.numberWithOptions(
              decimal: !widget.isInteger,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              helperText: widget.helperText,
              border: const OutlineInputBorder(),
            ),
            validator: widget.validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Botão de incremento
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: widget.enabled ? _increment : null,
          color: Theme.of(context).colorScheme.primary,
          tooltip: 'Aumentar',
        ),
      ],
    );
  }
}

/// Botões rápidos para valores comuns
class QuickValueButtons extends StatelessWidget {
  final List<int> values;
  final Function(int) onValueSelected;
  final String label;

  const QuickValueButtons({
    super.key,
    required this.values,
    required this.onValueSelected,
    this.label = 'Valores rápidos',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) {
            return ActionChip(
              label: Text('$value'),
              onPressed: () {
                HapticFeedback.lightImpact();
                onValueSelected(value);
              },
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Widget para copiar série anterior
class CopyPreviousSetButton extends StatelessWidget {
  final VoidCallback? onCopy;
  final String? previousSetInfo;

  const CopyPreviousSetButton({
    super.key,
    this.onCopy,
    this.previousSetInfo,
  });

  @override
  Widget build(BuildContext context) {
    if (onCopy == null || previousSetInfo == null) {
      return const SizedBox.shrink();
    }

    return OutlinedButton.icon(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onCopy?.call();
      },
      icon: const Icon(Icons.copy_all),
      label: Text('Copiar anterior ($previousSetInfo)'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

/// Campo de texto com validação visual aprimorada
class ValidatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final String? helperText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool enabled;

  const ValidatedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.helperText,
    this.keyboardType,
    this.maxLength,
    this.enabled = true,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  bool _isValid = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateInput);
    super.dispose();
  }

  void _validateInput() {
    if (widget.validator != null) {
      final error = widget.validator!(widget.controller.text);
      setState(() {
        _isValid = error == null;
        _errorText = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _isValid && widget.controller.text.isNotEmpty
        ? Colors.green
        : _errorText != null
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.outline;

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        errorText: _errorText,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: borderColor,
            width: _isValid && widget.controller.text.isNotEmpty ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: borderColor,
            width: 2,
          ),
        ),
        suffixIcon: _isValid && widget.controller.text.isNotEmpty
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}