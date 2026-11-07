
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:gal/gal.dart';

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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraFilter {
  final String name;
  final IconData icon;
  final ColorFilter? colorFilter;

  const CameraFilter({
    required this.name,
    required this.icon,
    this.colorFilter,
  });
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  List<CameraDescription> cameras = [];

  bool loading = true;
  bool takingPicture = false;
  bool flashOn = false;

  int cameraIndex = 0;
  int selectedFilter = 0;

  final List<CameraFilter> filters = [
    const CameraFilter(
      name: 'Original',
      icon: Icons.camera_alt,
    ),
    CameraFilter(
      name: 'Warm',
      icon: Icons.wb_sunny,
      colorFilter: const ColorFilter.mode(
        Color(0x33FF9D42),
        BlendMode.softLight,
      ),
    ),
    CameraFilter(
      name: 'Pink',
      icon: Icons.favorite,
      colorFilter: const ColorFilter.mode(
        Color(0x44FF4F9A),
        BlendMode.softLight,
      ),
    ),
    CameraFilter(
      name: 'Dream',
      icon: Icons.auto_awesome,
      colorFilter: const ColorFilter.mode(
        Color(0x338C7BFF),
        BlendMode.softLight,
      ),
    ),
    CameraFilter(
      name: 'Cool',
      icon: Icons.ac_unit,
      colorFilter: const ColorFilter.mode(
        Color(0x334CAEFF),
        BlendMode.softLight,
      ),
    ),
    CameraFilter(
      name: 'Golden',
      icon: Icons.star,
      colorFilter: const ColorFilter.mode(
        Color(0x44FFD700),
        BlendMode.softLight,
      ),
    ),
    CameraFilter(
      name: 'Vintage',
      icon: Icons.photo_filter,
      colorFilter: const ColorFilter.mode(
        Color(0x447C5135),
        BlendMode.softLight,
      ),
    ),
    CameraFilter(
      name: 'Purple',
      icon: Icons.color_lens,
      colorFilter: const ColorFilter.mode(
        Color(0x445D35FF),
        BlendMode.softLight,
      ),
    ),
    CameraFilter(
      name: 'Rose',
      icon: Icons.local_florist,
      colorFilter: const ColorFilter.mode(
        Color(0x44FF7890),
        BlendMode.softLight,
      ),
    ),
    CameraFilter(
      name: 'Mono',
      icon: Icons.filter_b_and_w,
      colorFilter: const ColorFilter.matrix([
        0.33, 0.59, 0.11, 0, 0,
        0.33, 0.59, 0.11, 0, 0,
        0.33, 0.59, 0.11, 0, 0,
        0, 0, 0, 1, 0,
      ]),
    ),
    const CameraFilter(name: 'Dog', icon: Icons.pets),
    const CameraFilter(name: 'Glasses', icon: Icons.visibility),
    const CameraFilter(
      name: 'Crown',
      icon: Icons.workspace_premium,
    ),
    const CameraFilter(
      name: 'Hearts',
      icon: Icons.favorite_border,
    ),
    const CameraFilter(
      name: 'Flowers',
      icon: Icons.local_florist,
    ),
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
        if (mounted) {
          setState(() => loading = false);
          showMessage('لم يتم العثور على كاميرا');
        }
        return;
      }

      final backIndex = cameras.indexWhere(
        (camera) =>
            camera.lensDirection == CameraLensDirection.back,
      );

      cameraIndex = backIndex >= 0 ? backIndex : 0;

      await startCamera();
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        showMessage('تعذر تشغيل الكاميرا: $e');
      }
    }
  }

  Future<void> startCamera() async {
    if (cameras.isEmpty || !mounted) return;

    final oldController = controller;
    controller = null;

    if (oldController != null) {
      await oldController.dispose();
    }

    if (!mounted) return;

    final newController = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await newController.initialize();

      if (!mounted) {
        await newController.dispose();
        return;
      }

      setState(() {
        controller = newController;
        loading = false;
        flashOn = false;
      });
    } catch (e) {
      await newController.dispose();

      if (mounted) {
        setState(() => loading = false);
        showMessage('خطأ في تشغيل الكاميرا: $e');
      }
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2 || loading) return;

    setState(() => loading = true);

    cameraIndex = (cameraIndex + 1) % cameras.length;

    await startCamera();
  }

  Future<void> toggleFlash() async {
    final cam = controller;

    if (cam == null || !cam.value.isInitialized) return;

    try {
      final next = !flashOn;

      await cam.setFlashMode(
        next ? FlashMode.torch : FlashMode.off,
      );

      if (mounted) {
        setState(() => flashOn = next);
      }
    } catch (_) {
      showMessage('الفلاش غير مدعوم في هذه الكاميرا');
    }
  }

  Future<void> takePhoto() async {
    final cam = controller;

    if (cam == null ||
        !cam.value.isInitialized ||
        takingPicture) {
      return;
    }

    setState(() => takingPicture = true);

    try {
      final XFile photo = await cam.takePicture();

      final hasAccess = await Gal.requestAccess();

      if (!hasAccess) {
        showMessage('اسمح للتطبيق بالوصول إلى المعرض');
        return;
      }

      await Gal.putImage(photo.path);

      showMessage('تم حفظ الصورة في معرض الهاتف بنجاح');
    } catch (e) {
      showMessage('تعذر حفظ الصورة: $e');
    } finally {
      if (mounted) {
        setState(() => takingPicture = false);
      }
    }
  }

  Future<void> openGallery() async {
    try {
      await Gal.open();
    } catch (_) {
      showMessage('تعذر فتح المعرض');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          backgroundColor: const Color(0xFF242424),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Widget buildCameraPreview() {
    final cam = controller!;
    final filter = filters[selectedFilter];

    Widget preview = CameraPreview(cam);

    if (filter.colorFilter != null) {
      preview = ColorFiltered(
        colorFilter: filter.colorFilter!,
        child: preview,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        preview,

        if (filter.name == 'Dog')
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 170),
              child: Text(
                '🐶',
                style: TextStyle(fontSize: 95),
              ),
            ),
          ),

        if (filter.name == 'Glasses')
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 80),
              child: Text(
                '🕶️',
                style: TextStyle(fontSize: 85),
              ),
            ),
          ),

        if (filter.name == 'Crown')
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 260),
              child: Text(
                '👑',
                style: TextStyle(fontSize: 85),
              ),
            ),
          ),

        if (filter.name == 'Hearts')
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 170),
              child: Text(
                '💕',
                style: TextStyle(fontSize: 90),
              ),
            ),
          ),

        if (filter.name == 'Flowers')
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 250),
              child: Text(
                '🌸🌼🌸',
                style: TextStyle(fontSize: 55),
              ),
            ),
          ),
      ],
    );
  }

  Widget roundButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
    double size = 48,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 23,
        ),
      ),
    );
  }

  Widget filterItem(int index) {
    final filter = filters[index];
    final selected = selectedFilter == index;

    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = index);
      },
      child: SizedBox(
        width: 75,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 57 : 49,
              height: selected ? 57 : 49,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? const Color(0xFFFFD700)
                    : Colors.white.withOpacity(0.13),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFFD700)
                      : Colors.white38,
                  width: selected ? 3 : 1,
                ),
              ),
              child: Icon(
                filter.icon,
                color: selected ? Colors.black : Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filter.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? const Color(0xFFFFD700)
                    : Colors.white,
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
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
        child: Stack(
          children: [
            if (controller != null &&
                controller!.value.isInitialized &&
                !loading)
              Positioned.fill(
                child: ClipRect(
                  child: buildCameraPreview(),
                ),
              )
            else
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
              ),

            if (loading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
              ),

            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      roundButton(
                        icon: Icons.photo_library_outlined,
                        onTap: openGallery,
                      ),

                      const Column(
                        children: [
                          Text(
                            'MAJD CAMERA',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'CAPTURE YOUR MOMENTS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),

                      roundButton(
                        icon: flashOn
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: flashOn
                            ? const Color(0xFFFFD700)
                            : Colors.white,
                        onTap: toggleFlash,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 95,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: filters.length,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          itemBuilder: (context, index) {
                            return filterItem(index);
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: [
                          roundButton(
                            icon: Icons.photo_outlined,
                            onTap: openGallery,
                            size: 50,
                          ),

                          GestureDetector(
                            onTap: takePhoto,
                            child: Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 5,
                                ),
                              ),
                              padding: const EdgeInsets.all(5),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: takingPicture
                                      ? Colors.grey
                                      : const Color(0xFFFFD700),
                                  shape: BoxShape.circle,
                                ),
                                child: takingPicture
                                    ? const Padding(
                                        padding: EdgeInsets.all(17),
                                        child:
                                            CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        color: Colors.black,
                                        size: 29,
                                      ),
                              ),
                            ),
                          ),

                          roundButton(
                            icon: Icons.flip_camera_android,
                            onTap: switchCamera,
                            size: 50,
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'MAJD CAMERA • CREATE YOUR MOMENT',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
