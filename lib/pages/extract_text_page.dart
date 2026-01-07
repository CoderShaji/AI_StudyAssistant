import 'package:flutter/material.dart';

class ExtractTextPage extends StatelessWidget {
  const ExtractTextPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.home), tooltip: 'Home', onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false)),
        title: const Text('Extract Text'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Extract text from PDF/DOCX/XLSX or images',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text('Choose a file and the app will extract the text content (placeholder)'),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File picker not implemented (placeholder)')));
                          },
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Choose file'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Extract not implemented (placeholder)')));
                          },
                          icon: const Icon(Icons.text_snippet),
                          label: const Text('Extract'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
