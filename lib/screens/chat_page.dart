import 'dart:io';
import 'dart:convert'; // Add this import for JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Keep this for MediaType
import 'package:mime_type/mime_type.dart'; // Keep this for mime() function

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  File? _selectedFile;
  bool _isLoading = false;
  String _fileName = ''; // Correctly declared as non-final
  final ImagePicker _picker = ImagePicker();
  final String _apiEndpoint = 'https://4335-102-180-159-126.ngrok-free.app/api/solve/';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _showAttachmentOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ajouter un fichier',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  context,
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  onTap: _pickFile,
                ),
                _buildAttachmentOption(
                  context,
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                _buildAttachmentOption(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Photo',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              radius: 28,
              child: Icon(
                icon,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'txt'], // Added 'txt'
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection du fichier: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          // Corrected: Use _fileName (the state variable)
          _fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: ${e.toString()}')),
      );
    }
  }

  Future<String> _sendToAPI(String text, File? file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_apiEndpoint));

      // Add the text
      if (text.isNotEmpty) {
        request.fields['text'] = text;
      }

      // Add the file if it exists
      if (file != null) {
        var mimeTypeString = mime(file.path) ?? 'application/octet-stream';
        var fileTypeParts = mimeTypeString.split('/');

        request.files.add(await http.MultipartFile.fromPath(
          'file', // This 'file' key must match request.FILES.get('file') in Django
          file.path,
          contentType: MediaType(fileTypeParts[0], fileTypeParts[1]),
        ));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        // Assuming your API returns a JSON with a 'solution' field
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> responseData = json.decode(responseBody);
        return responseData['solution'] ?? 'Pas de solution trouvée.';
      } else {
        // Handle API errors
        final errorBody = await response.stream.bytesToString();
        String errorMessage = 'Erreur inconnue de l\'API.';
        try {
          final Map<String, dynamic> errorData = json.decode(errorBody);
          errorMessage = errorData['error'] ?? errorMessage;
        } catch (_) {
          // If response body is not JSON, use the raw error message
          errorMessage = 'Erreur de l\'API: ${response.statusCode} - ${response.reasonPhrase}. Raw response: $errorBody';
        }
        return 'Erreur de l\'IA: $errorMessage';
      }
    } catch (e) {
      return 'Erreur de connexion: Impossible de joindre le serveur. (${e.toString()})';
    }
  }

  void _handleSubmitted(String text) async {
    if (text.isEmpty && _selectedFile == null) return;

    final message = text.isNotEmpty ? text : 'Fichier: $_fileName';
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        file: _selectedFile,
        fileName: _fileName,
      ));
      _isLoading = true;
    });

    // Call the API
    final responseText = await _sendToAPI(text, _selectedFile);

    setState(() {
      _messages.add(ChatMessage(
        text: responseText, // Display the API response
        isUser: false,
      ));
      _selectedFile = null;
      _fileName = '';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png', // Replace with your logo path
              height: 40,
            ),
            const SizedBox(width: 12),
            Text(
              'MathSolver AI',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                reverse: false,
                itemCount: _messages.length,
                itemBuilder: (_, index) => _messages[index],
              ),
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              color: Color(0xFFF57C00),
              minHeight: 2,
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedFile != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _fileName.toLowerCase().endsWith('.pdf')
                        ? Icons.picture_as_pdf
                        : Icons.insert_drive_file,
                    color: const Color(0xFFF57C00),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fileName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                        _fileName = '';
                      });
                    },
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                color: Theme.of(context).colorScheme.primary,
                onPressed: _showAttachmentOptions,
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Entrez un problème mathématique...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _handleSubmitted,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _isLoading ? null : () => _handleSubmitted(_textController.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final File? file;
  final String? fileName;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.file,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isUser
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
            child: Icon(
              isUser ? Icons.person : Icons.school,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? 'Vous' : 'MathSolver AI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                if (file != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (fileName!.toLowerCase().endsWith('.png') ||
                            fileName!.toLowerCase().endsWith('.jpg') ||
                            fileName!.toLowerCase().endsWith('.jpeg'))
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(8)),
                            child: Image.file(
                              file!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          )
                        else if (fileName!.toLowerCase().endsWith('.pdf'))
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Icon(Icons.insert_drive_file, size: 40, color: Colors.grey),
                          ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Colors.grey.shade100,
                          child: Row(
                            children: [
                              Icon(
                                fileName!.toLowerCase().endsWith('.pdf')
                                    ? Icons.picture_as_pdf
                                    : Icons.insert_drive_file,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  fileName!,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                        : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}