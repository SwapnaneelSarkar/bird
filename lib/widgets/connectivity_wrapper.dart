import 'package:flutter/material.dart';
import '../service/connectivity_service.dart';
import '../constants/router/router.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final bool checkOnInit;

  const ConnectivityWrapper({
    Key? key,
    required this.child,
    this.checkOnInit = true,
  }) : super(key: key);

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    if (widget.checkOnInit) {
      _checkConnectivity();
    }
  }

  Future<void> _checkConnectivity() async {
    if (_isChecking) return;
    
    setState(() {
      _isChecking = true;
    });

    try {
      final hasConnection = await ConnectivityService.hasConnection();
      
      if (!hasConnection && mounted) {
        // Only show if we're not already on the no internet page
        if (ModalRoute.of(context)?.settings.name != Routes.noInternet) {
          ConnectivityService.showNoInternetPage(context);
        }
      }
    } catch (e) {
      // Handle any errors silently
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
} 