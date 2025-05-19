// widgets/cached_image.dart
import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../utils/image_cache_manager.dart';

class CachedImage extends StatefulWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext)? placeholder;
  final Widget Function(BuildContext, Object)? errorWidget;

  const CachedImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  Future<Uint8List?>? _imageFuture;
  
  @override
  void initState() {
    super.initState();
    _loadImage();
  }
  
  @override
  void didUpdateWidget(CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }
  
  void _loadImage() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty && widget.imageUrl!.startsWith('http')) {
      _imageFuture = ImageCacheManager.instance.getImage(widget.imageUrl!);
    } else {
      _imageFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageFuture == null) {
      return _buildErrorWidget(context, 'Invalid URL');
    }
    
    return FutureBuilder<Uint8List?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder(context);
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return _buildErrorWidget(context, snapshot.error ?? 'Failed to load image');
        } else {
          return Image.memory(
            snapshot.data!,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
          );
        }
      },
    );
  }
  
  Widget _buildPlaceholder(BuildContext context) {
    return widget.placeholder?.call(context) ?? 
      Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
            ),
          ),
        ),
      );
  }
  
  Widget _buildErrorWidget(BuildContext context, Object error) {
    return widget.errorWidget?.call(context, error) ?? 
      Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[100],
        child: Icon(
          Icons.restaurant,
          color: Colors.grey[400],
          size: 40,
        ),
      );
  }
}