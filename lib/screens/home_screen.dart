import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    PermissionStatus status = await Permission.audio.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        status = await Permission.audio.request();
      }
    }

    setState(() {
      _permissionGranted = status.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bhai Bhai App'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: _permissionGranted
            ? const Text(
                'Music Player Ready! Scanning Songs...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              )
            : ElevatedButton(
                onPressed: _checkPermission,
                child: const Text('Grant Storage Permission'),
              ),
      ),
    );
  }
}
