import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _chooseVideoFromGallery() async {
    ImagePicker picker = ImagePicker();
    try {
      XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      VideoPlayerController controller =
          VideoPlayerController.file(File(video!.path));
      await controller.initialize();
      if (controller.value.duration.inSeconds > 90) {
        throw ('we only allow videos that are shorter than 1 minute!');
      } else {
        await uploadVideo(video);
      }
      controller.dispose();
    } catch (e) {
      print("Error Picking Video : $e");
    }
  }

  void _recordVideo() {}
  Future<void> uploadVideo(XFile video) async {
    final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

    // Generate a unique filename based on the current timestamp
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String fileName = 'video_$timestamp.mp4';

    Reference ref = firebaseStorage.ref().child('videos/$fileName');

    try {
      // Set metadata to specify the content type
      SettableMetadata metadata = SettableMetadata(contentType: 'video/mp4');

      // Upload file with metadata
      await ref.putFile(
        File(video.path),
        metadata,
      );

      String downloadURL = await ref.getDownloadURL();
      print(downloadURL);

      // Show toast message on successful upload
      Fluttertoast.showToast(
        msg: 'Video uploaded successfully!',
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

    } catch (e) {
      print("Error uploading file: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          'Video Upload',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _chooseVideoFromGallery,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'CHOOSE VIDEO FROM GALLERY',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _recordVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'RECORD VIDEO',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
