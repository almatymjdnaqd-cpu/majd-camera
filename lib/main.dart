
import 'package:flutter/material.dart';

void main() {
  runApp(const MajdCameraApp());
}

class MajdCameraApp extends StatelessWidget {
  const MajdCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Majd Camera',
      theme: ThemeData.dark(),
      home: const CameraHome(),
    );
  }
}

class CameraHome extends StatefulWidget {
  const CameraHome({super.key});

  @override
  State<CameraHome> createState() => _CameraHomeState();
}

class _CameraHomeState extends State<CameraHome> {
  int selectedFilter = 0;

  final List<Color> filters = [
    Colors.transparent,
    Colors.orange.withOpacity(0.25),
    Colors.blue.withOpacity(0.25),
    Colors.pink.withOpacity(0.25),
    Colors.purple.withOpacity(0.25),
    Colors.green.withOpacity(0.20),
  ];

  final List<String> filterNames = [
    'Original',
    'Warm',
    'Cool',
    'Pink',
    'Dream',
    'Nature',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.flash_off, color: Colors.white, size: 28),
                  Text(
                    'MAJD CAMERA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Icon(Icons.settings, color: Colors.white, size: 28),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF191919),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 90,
                      color: Colors.white24,
                    ),
                    if (selectedFilter != 0)
                      Container(
                        decoration: BoxDecoration(
                          color: filters[selectedFilter],
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    const Positioned(
                      bottom: 22,
                      child: Text(
                        'Your camera experience starts here',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter = index;
                      });
                    },
                    child: Container(
                      width: 76,
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      child: Column(
                        children: [
                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filters[index] == Colors.transparent
                                  ? Colors.white12
                                  : filters[index],
                              border: Border.all(
                                color: selectedFilter == index
                                    ? Colors.amber
                                    : Colors.white24,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.face,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            filterNames[index],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 8, 25, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Icon(Icons.photo_library,
                      color: Colors.white, size: 30),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const Icon(Icons.flip_camera_android,
                      color: Colors.white, size: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
