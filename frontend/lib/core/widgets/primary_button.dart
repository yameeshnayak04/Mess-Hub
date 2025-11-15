import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isDestructive;
  final bool isSecondary;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.isDestructive = false,
    this.isSecondary = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  Color _getBackgroundColor() {
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    if (widget.isDestructive) return AppTheme.errorRed;
    if (widget.isSecondary) return AppTheme.secondaryOrange;
    return AppTheme.primaryOrange;
  }

  Color _getForegroundColor() {
    if (widget.foregroundColor != null) return widget.foregroundColor!;
    if (widget.isOutlined) {
      if (widget.isDestructive) return AppTheme.errorRed;
      return AppTheme.primaryOrange;
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor();
    final fgColor = _getForegroundColor();

    if (widget.isOutlined) {
      return _buildOutlinedButton(bgColor, fgColor);
    }

    return _buildFilledButton(bgColor, fgColor);
  }

  Widget _buildFilledButton(Color bgColor, Color fgColor) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 56,
          decoration: BoxDecoration(
            gradient: widget.onPressed != null && !widget.isLoading
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      bgColor,
                      bgColor.withOpacity(0.8),
                    ],
                  )
                : null,
            color: widget.onPressed == null || widget.isLoading
                ? AppTheme.borderColor.withOpacity(0.3)
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow:
                widget.onPressed != null && !widget.isLoading && !_isPressed
                    ? [
                        BoxShadow(
                          color: bgColor.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _buildButtonContent(fgColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(Color bgColor, Color fgColor) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 56,
          decoration: BoxDecoration(
            color: widget.onPressed != null && !widget.isLoading
                ? bgColor.withOpacity(0.05)
                : AppTheme.borderColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.onPressed != null && !widget.isLoading
                  ? bgColor.withOpacity(0.5)
                  : AppTheme.borderColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(14),
              splashColor: bgColor.withOpacity(0.1),
              highlightColor: bgColor.withOpacity(0.05),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _buildButtonContent(fgColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(Color fgColor) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.isOutlined ? fgColor : Colors.white,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 22,
            color: widget.onPressed == null
                ? AppTheme.textSecondary.withOpacity(0.5)
                : fgColor,
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.onPressed == null
                  ? AppTheme.textSecondary.withOpacity(0.5)
                  : fgColor,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Secondary Button Variant
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      height: height,
      isSecondary: true,
    );
  }
}

// Destructive Button Variant
class DestructiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;
  final bool isOutlined;

  const DestructiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      height: height,
      isOutlined: isOutlined,
      isDestructive: true,
    );
  }
}

// Text Button Variant
class TextButtonCustom extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;

  const TextButtonCustom({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
  });

  @override
  State<TextButtonCustom> createState() => _TextButtonCustomState();
}

class _TextButtonCustomState extends State<TextButtonCustom> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primaryOrange;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(8),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: widget.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 18,
                          color: widget.onPressed == null
                              ? AppTheme.textSecondary.withOpacity(0.5)
                              : _isPressed
                                  ? color.withOpacity(0.7)
                                  : color,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: widget.onPressed == null
                              ? AppTheme.textSecondary.withOpacity(0.5)
                              : _isPressed
                                  ? color.withOpacity(0.7)
                                  : color,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Icon Button Variant
class IconButtonCustom extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;

  const IconButtonCustom({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 48,
    this.tooltip,
  });

  @override
  State<IconButtonCustom> createState() => _IconButtonCustomState();
}

class _IconButtonCustomState extends State<IconButtonCustom>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primaryOrange;
    final bgColor = widget.backgroundColor ?? color.withOpacity(0.1);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: Tooltip(
          message: widget.tooltip ?? '',
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.onPressed == null
                  ? AppTheme.borderColor.withOpacity(0.2)
                  : bgColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(14),
                splashColor: color.withOpacity(0.2),
                child: Center(
                  child: Icon(
                    widget.icon,
                    color: widget.onPressed == null
                        ? AppTheme.textSecondary.withOpacity(0.5)
                        : color,
                    size: widget.size * 0.45,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
