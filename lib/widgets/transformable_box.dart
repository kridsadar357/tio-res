import 'dart:math';
import 'package:flutter/material.dart';

class TransformableBox extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final double width;
  final double height;
  final double rotation;
  final VoidCallback? onTap;
  final void Function(Offset delta) onDrag;
  final void Function(double width, double height) onResize;
  final void Function(double angle) onRotate;
  final double currentScale; // From InteractiveViewer

  const TransformableBox({
    super.key,
    required this.child,
    required this.isSelected,
    required this.width,
    required this.height,
    required this.rotation,
    this.onTap,
    required this.onDrag,
    required this.onResize,
    required this.onRotate,
    this.currentScale = 1.0,
  });

  @override
  State<TransformableBox> createState() => _TransformableBoxState();
}

class _TransformableBoxState extends State<TransformableBox> {
  // Handle size
  static const double handleSize = 12.0;

  @override
  Widget build(BuildContext context) {
    // If not selected, just show the child content with rotation
    // We wrap in GestureDetector to allow selection
    if (!widget.isSelected) {
      return Transform.rotate(
        angle: widget.rotation,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.translucent,
          child: Container(
            width: widget.width,
            height: widget.height,
            child: widget.child,
          ),
        ),
      );
    }

    // If selected, show handles
    // We need a coordinate space that rotates WITH the object for the handles to align naturally
    // OR we draw handles outside.
    // Standard approach: The "box" rotates, handles are attached to the box corners.

    // Calculate effective handle size counter-scaled so they stay constant visual size
    final effectiveHandleSize = handleSize / widget.currentScale;
    
    return Transform.rotate(
      angle: widget.rotation,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
        children: [
          // 1. The Content & Drag Area
          Positioned(
            left: 0,
            top: 0,
            width: widget.width,
            height: widget.height,
            child: GestureDetector(
              onTap: widget.onTap,
              onPanUpdate: (details) {
                // We need to rotate the delta back to world space if the parent is rotated?
                // Actually, the parent stack is rotated. So the drag delta is in the local rotated coordinate system.
                // We need to convert local delta to global delta for the parent's x/y.
                
                final dx = details.delta.dx;
                final dy = details.delta.dy;
                
                // Rotate vector (dx, dy) by rotation angle to get world space delta
                final cosA = cos(widget.rotation);
                final sinA = sin(widget.rotation);
                
                final globalDx = dx * cosA - dy * sinA;
                final globalDy = dx * sinA + dy * cosA;
                
                widget.onDrag(Offset(globalDx, globalDy));
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2 / widget.currentScale),
                ),
                child: widget.child,
              ),
            ),
          ),

          // 2. Resize Handles (Corners)
           // Top Left
          _buildHandle(
            alignment: Alignment.topLeft,
            onDrag: (dx, dy) => _handleResize(dx, dy, -1, -1),
            size: effectiveHandleSize,
            left: -effectiveHandleSize/2,
            top: -effectiveHandleSize/2,
          ),
          // Top Right
          _buildHandle(
            alignment: Alignment.topRight,
            onDrag: (dx, dy) => _handleResize(dx, dy, 1, -1),
            size: effectiveHandleSize,
            right: -effectiveHandleSize/2,
            top: -effectiveHandleSize/2,
          ),
          // Bottom Left
          _buildHandle(
            alignment: Alignment.bottomLeft,
            onDrag: (dx, dy) => _handleResize(dx, dy, -1, 1),
            size: effectiveHandleSize,
            left: -effectiveHandleSize/2,
            bottom: -effectiveHandleSize/2,
          ),
          // Bottom Right
          _buildHandle(
            alignment: Alignment.bottomRight,
            onDrag: (dx, dy) => _handleResize(dx, dy, 1, 1),
            size: effectiveHandleSize,
            right: -effectiveHandleSize/2,
            bottom: -effectiveHandleSize/2,
          ),

          // 3. Rotation Handle (Top Center extend)
          Positioned(
            top: -30 / widget.currentScale,
            left: widget.width / 2 - (effectiveHandleSize / 2),
            child: GestureDetector(
              onPanUpdate: (details) {
                 // Calculate angle change based on horizontal drag for simplicity
                 widget.onRotate(details.delta.dx * 0.02);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: effectiveHandleSize,
                    height: effectiveHandleSize,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black26)],
                    ),
                    child: Icon(Icons.rotate_right, size: effectiveHandleSize * 0.8, color: Colors.black),
                  ),
                  Container(
                    width: 1,
                    height: 30 / widget.currentScale - (effectiveHandleSize / 2),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildHandle({
    required Alignment alignment,
    required Function(double dx, double dy) onDrag,
    required double size,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 1),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  void _handleResize(double dx, double dy, int xDir, int yDir) {
    // Simple resizing logic
    double newW = widget.width + (dx * xDir);
    double newH = widget.height + (dy * yDir);
    
    if (newW < 20) newW = 20;
    if (newH < 20) newH = 20;

    widget.onResize(newW, newH);
  }
}
