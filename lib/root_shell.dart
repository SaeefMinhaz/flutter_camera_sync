import 'package:flutter/material.dart';
import 'package:flutter_camera_sync/features/camera/presentation/presentation.dart';
import 'package:flutter_camera_sync/features/sync/presentation/presentation.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const CameraPreviewScreen(),
      const PendingUploadsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload_outlined),
            label: 'Pending',
          ),
        ],
      ),
    );
  }
}

