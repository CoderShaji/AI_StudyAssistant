import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.home), tooltip: 'Home', onPressed: () => Navigator.pushNamedAndRemoveUntil(context, HomeScreen.routeName, (r) => false)),
        title: const Text('Upload File'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'UploadPage placeholder\n\nSupports: PDF, DOCX, XLSX, Image',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
