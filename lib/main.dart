
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  CameraController? controller;
  List<CameraDescription> cameras = [];

  bool loading = true;
  String? errorMessage;
  int cameraIndex = 0;
  int selectedFilter = 0;

  final List<String> filterNames = [
    'Original',
    'Warm',
    'Cool',
    'Pink',
    'Dream',
    'Nature',
  ];

  final List<Color> filterColors = [
    Colors.transparent,
    Colors.orange,
    Colors.blue,
    Colors.pink,
    Colors.purple,
    Colors.green,
  ];

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('لم يتم العثور على كاميرا');
      }

      await startCamera(cameras[cameraIndex]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'تعذر تشغيل الكاميرا: $e';
        loading = false;
      });
    }
  }

  Future<void> startCamera(CameraDescription camera) async {
    final oldController = controller;
    controller = null;

    if (oldController != null) {
      await oldController.dispose();
    }

    final newController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    controller = newController;

    await newController.initialize();

    if (!mounted) return;

    setState(() {
      loading = false;
      errorMessage = null;
    });
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) return;

    setState(() {
      loading = true;
    });

    cameraIndex = (cameraIndex + 1) % cameras.length;

    try {
      await startCamera(cameras[cameraIndex]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = 'تعذر تبديل الكاميرا';
      });
    }
  }

  Future<void> takePicture() async {
    final current = controller;

    if (current == null || !current.value.isInitialized) return;
    if (current.value.isTakingPicture) return;

    try {
      final XFile picture = await current.takePicture();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم التقاط الصورة: ${picture.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر التقاط الصورة')),
      );
    }
  }

  Widget buildPreview() {
    final current = controller;

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (current == null || !current.value.isInitialized) {
      return const Center(child: Text('الكاميرا غير جاهزة'));
    }

    return ClipRect(
      child: ColorFiltered(
        colorFilter: selectedFilter == 0
            ? const ColorFilter.mode(
                Colors.transparent,
                BlendMode.dst,
              )
            : ColorFilter.mode(
                filterColors[selectedFilter].withOpacity(0.25),
                BlendMode.softLight,
              ),
        child: CameraPreview(current),
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Colors.amber),
                  SizedBox(width: 10),
                  Text(
                    'MAJD CAMERA',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF191919),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white24),
                ),
                clipBehavior: Clip.antiAlias,
                child: buildPreview(),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 85,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filterNames.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter = index;
                      });
                    },
                    child: SizedBox(
                      width: 75,
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filterColors[index]
                                  .withOpacity(0.35),
                              border: Border.all(
                                color: selectedFilter == index
                                    ? Colors.amber
                                    : Colors.white38,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.face,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            filterNames[index],
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(25, 8, 25, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 30,
                  ),

                  GestureDetector(
                    onTap: takePicture,
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 5,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: switchCamera,
                    icon: const Icon(
                      Icons.flip_camera_android,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
