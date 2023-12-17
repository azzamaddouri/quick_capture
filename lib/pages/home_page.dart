import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late VideoPlayerController _controller;
  late XFile _selectedVideo;
  ImagePicker picker = ImagePicker();

  Future<void> _chooseVideoFromGallery() async {
    try {
      XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedVideo = video;
          _controller = VideoPlayerController.file(File(video.path));
        });

        await _controller.initialize();
        if (_controller.value.duration.inSeconds > 90) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return ErrorAlert(
                  message:
                      'The selected video\'s duration should not be greater than 1mins30s !');
            },
          );
        } else {
          await uploadVideo(_selectedVideo);
        }
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return ErrorAlert(
              message:
                  'Please choose a video with a duration of 1min 30s or less.');
        },
      );
      print(e);
    }
  }

  void _recordVideo() {}

  Future<void> uploadVideo(XFile video) async {
    final FirebaseStorage firebaseStorage = FirebaseStorage.instance;
    Reference ref = firebaseStorage
        .ref()
        .child('videos/${_selectedVideo.name.replaceFirst(".mp4", "")}.mp4');
    try {
      SettableMetadata metadata = SettableMetadata(contentType: 'video/mp4');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return _buildUploadDialog();
        },
      );
      TaskSnapshot taskSnapshot = await ref.putFile(
        File(video.path),
        metadata,
      );
      String downloadURL = await ref.getDownloadURL();
      print('Video uploaded successfully:' + downloadURL);
      Navigator.of(context).pop();
      Fluttertoast.showToast(
        msg: 'Video uploaded successfully!',
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      Navigator.of(context).pop();
      print("Upload error: $e");
    }
  }

  Widget _buildUploadDialog() {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(width: 30.0),
            Text('Uploading...'),
            SizedBox(width: 8.0),
            StreamBuilder<TaskSnapshot>(
              stream: FirebaseStorage.instance
                  .ref()
                  .child(
                      'videos/${_selectedVideo.name.replaceFirst(".mp4", "")}.mp4')
                  .putFile(File(_selectedVideo.path))
                  .snapshotEvents,
              builder: (context, snapshot) {
                double progress = 0.0;
                if (snapshot.hasData) {
                  progress = snapshot.data!.bytesTransferred /
                      snapshot.data!.totalBytes;
                }
                return Text('${(progress * 100).toInt()}%');
              },
            ),
          ],
        ),
      ),
    );
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

class ErrorAlert extends StatelessWidget {
  final String message;

  const ErrorAlert({required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Error'),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'OK',
            style: TextStyle(color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }
}
