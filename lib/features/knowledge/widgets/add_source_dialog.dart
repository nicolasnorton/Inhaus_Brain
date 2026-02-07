import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/knowledge_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/google_drive_service.dart';
import '../providers/knowledge_service_providers.dart';
import '../../../../core/services/integration_service.dart';
import '../../connectors/models/connected_account_model.dart';
import '../../../../core/services/sources_service.dart';
import '../../services/services/services_repository.dart' as services_repo;
import '../../services/models/service_model.dart' as service_model;

class AddSourceDialog extends ConsumerStatefulWidget {
  final Function(KnowledgeSource) onSourceAdded;

  const AddSourceDialog({super.key, required this.onSourceAdded});

  @override
  ConsumerState<AddSourceDialog> createState() => _AddSourceDialogState();
}

class _AddSourceDialogState extends ConsumerState<AddSourceDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  
  String? _activeInputMode; // 'url', 'text', 'drive', 'services', null (default)
  List<GoogleDriveFile>? _driveFiles;
  bool _isLoadingDrive = false;
  List<service_model.Service>? _availableServices;
  Set<String> _selectedServiceIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _fetchDriveFiles() async {
    setState(() {
      _isLoadingDrive = true;
      _activeInputMode = 'drive';
    });
    try {
      final drive = ref.read(googleDriveServiceProvider);
      final files = await drive.listRecentFiles();
      setState(() => _driveFiles = files);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _activeInputMode = null);
      }
    } finally {
      if (mounted) setState(() => _isLoadingDrive = false);
    }
  }

  Future<void> _handleDriveSelect(GoogleDriveFile file) async {
    setState(() => _isLoadingDrive = true);
    try {
      final drive = ref.read(googleDriveServiceProvider);
      final bytes = await drive.downloadFile(file.id);
      
      KnowledgeSourceType type = KnowledgeSourceType.file;
      final m = file.mimeType.toLowerCase();
      if (m.contains('image')) type = KnowledgeSourceType.image;
      if (m.contains('audio')) type = KnowledgeSourceType.audio;
      if (m.contains('pdf') || m.contains('google-apps.document')) type = KnowledgeSourceType.pdf;

      String content = 'Google Drive: ${file.name}';
      if (bytes != null && (type == KnowledgeSourceType.file || type == KnowledgeSourceType.pdf)) {
           content = await SourcesService.extractTextFromFile(bytes, file.name);
      }

      final newSource = KnowledgeSource(
        id: const Uuid().v4(),
        title: file.name,
        content: content,
        bytes: bytes,
        type: type,
        createdAt: DateTime.now(),
        metadata: {
          'source': 'google_drive',
          'driveId': file.id,
          'mimeType': file.mimeType,
        },
      );
      
      widget.onSourceAdded(newSource);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingDrive = false);
    }
  }

  Future<void> _handleFileUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'json', 'csv', 'mp3', 'wav', 'm4a', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.single;
        // Determine type
        KnowledgeSourceType type = KnowledgeSourceType.file;
        final ext = file.extension?.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) type = KnowledgeSourceType.image;
        if (['mp3', 'wav', 'm4a', 'ogg'].contains(ext)) type = KnowledgeSourceType.audio;
        if (ext == 'pdf') type = KnowledgeSourceType.pdf;

        // Extract text content if possible
        String content = 'File: ${file.name}';
        if (file.bytes != null && (type == KnowledgeSourceType.file || type == KnowledgeSourceType.pdf)) {
           content = await SourcesService.extractTextFromFile(file.bytes!, file.name);
        }

        final newSource = KnowledgeSource(
          id: const Uuid().v4(),
          title: file.name,
          content: content,
          bytes: file.bytes,
          type: type,
          createdAt: DateTime.now(),
          metadata: {
            'fileSize': '${(file.size / 1024).toStringAsFixed(2)} KB',
            'extension': file.extension ?? 'unknown',
          },
        );
        
        widget.onSourceAdded(newSource);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _handleAddUrl() {
    if (_urlController.text.isEmpty) return;
    final url = _urlController.text;
    KnowledgeSourceType type = KnowledgeSourceType.url;
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      type = KnowledgeSourceType.youtube;
    }

    final newSource = KnowledgeSource(
      id: const Uuid().v4(),
      title: url, // Could notify to fetch metadata
      content: url,
      type: type,
      createdAt: DateTime.now(),
    );
    widget.onSourceAdded(newSource);
    Navigator.pop(context);
  }

  void _handleAddText() {
    if (_textController.text.isEmpty) return;
    
    // Extract title from first line or default
    final lines = _textController.text.split('\n');
    String title = lines.isNotEmpty ? lines.first : 'Copied Text';
    if (title.length > 50) title = '${title.substring(0, 47)}...';

    final newSource = KnowledgeSource(
      id: const Uuid().v4(),
      title: title,
      content: _textController.text,
      type: KnowledgeSourceType.text,
      createdAt: DateTime.now(),
    );
    widget.onSourceAdded(newSource);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Text("Add new source", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_activeInputMode == null) ...[
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Search the web for new sources',
                          hintStyle: TextStyle(color: Colors.white30),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onSubmitted: (val) {
                          final newSource = KnowledgeSource(
                            id: const Uuid().v4(), 
                            title: 'Search: $val',
                            content: 'Web search results for $val',
                            type: KnowledgeSourceType.url,
                            createdAt: DateTime.now(),
                          );
                          widget.onSourceAdded(newSource);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                      child: const Row(children: [Icon(Icons.public, size: 14, color: Colors.white70), SizedBox(width: 4), Text("Web", style: TextStyle(color: Colors.white70, fontSize: 12))])
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // "Or drop your files here" area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white10, style: BorderStyle.solid), 
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.02),
                ),
                child: Column(
                  children: [
                    const Text("or drop your files here", style: TextStyle(color: Colors.white54, fontSize: 16)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildOptionButton(Icons.upload_file, "Upload", () => _handleFileUpload()),
                        const SizedBox(width: 8),
                        _buildOptionButton(FontAwesomeIcons.globe, "Web", () => setState(() => _activeInputMode = 'url')),
                        const SizedBox(width: 8),
                        _buildOptionButton(FontAwesomeIcons.googleDrive, "Drive", () => _fetchDriveFiles()),
                        const SizedBox(width: 8),
                        _buildOptionButton(Icons.hub, "Platforms", () => setState(() => _activeInputMode = 'platforms')),
                        const SizedBox(width: 8),
                        _buildOptionButton(Icons.assignment, "Text", () => setState(() => _activeInputMode = 'text')),
                        const SizedBox(width: 8),
                        _buildOptionButton(Icons.business_center, "Services", () => _fetchServices()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Limit: 50 sources, 500k words each. Audio/Video supported.",
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ] else ...[
              _buildInputModeUI(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInputModeUI() {
    String title = '';
    Widget content = const SizedBox();
    VoidCallback? onConfirm;

    if (_isLoadingDrive) {
       return const Center(child: Padding(
         padding: EdgeInsets.all(48.0),
         child: CircularProgressIndicator(),
       ));
    }

    if (_activeInputMode == 'url') {
      title = 'Add Website / YouTube';
      content = TextField(
        controller: _urlController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'https://example.com or YouTube URL',
          hintStyle: const TextStyle(color: Colors.white30),
          filled: true,
          fillColor: AppTheme.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      onConfirm = _handleAddUrl;
    } else if (_activeInputMode == 'text') {
      title = 'Paste Text';
      content = TextField(
        controller: _textController,
        style: const TextStyle(color: Colors.white),
        maxLines: 8,
        decoration: InputDecoration(
          hintText: 'Paste your text here...',
          hintStyle: const TextStyle(color: Colors.white30),
          filled: true,
          fillColor: AppTheme.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      onConfirm = _handleAddText;
    } else if (_activeInputMode == 'services') {
      title = 'Select Services';
      content = _buildServicesSelector();
      onConfirm = _handleAddServices;
    } else if (_activeInputMode == 'platforms') {
      title = 'Connect Platform';
      content = Column(
        children: [
          _buildPlatformItem("Google Ads", FontAwesomeIcons.google, AdPlatform.googleAds),
          _buildPlatformItem("Meta Ads", FontAwesomeIcons.meta, AdPlatform.metaAds),
          _buildPlatformItem("TikTok Ads", FontAwesomeIcons.tiktok, AdPlatform.tiktokAds),
          _buildPlatformItem("Google Analytics 4", Icons.analytics, AdPlatform.googleAnalytics),
        ],
      );
    } else if (_activeInputMode == 'drive') {
      title = 'Select from Google Drive';
      content = SizedBox(
        height: 300,
        child: _driveFiles == null || _driveFiles!.isEmpty 
          ? const Center(child: Text("No files found in Drive", style: TextStyle(color: Colors.white38)))
          : ListView.builder(
              itemCount: _driveFiles!.length,
              itemBuilder: (context, index) {
                final file = _driveFiles![index];
                IconData icon = Icons.insert_drive_file;
                if (file.mimeType.contains('document')) icon = FontAwesomeIcons.fileLines;
                if (file.mimeType.contains('pdf')) icon = FontAwesomeIcons.filePdf;
                if (file.mimeType.contains('image')) icon = FontAwesomeIcons.fileImage;
                
                return ListTile(
                  leading: Icon(icon, color: Colors.blueAccent, size: 20),
                  title: Text(file.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  onTap: () => _handleDriveSelect(file),
                );
              },
            ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => setState(() => _activeInputMode = null),
          ),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        content,
        const SizedBox(height: 24),
        if (onConfirm != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
               TextButton(
                onPressed: () => setState(() => _activeInputMode = null),
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text("Add Source", style: TextStyle(color: Colors.white)),
              ),
            ],
          )
      ],
    );
  }

  Widget _buildPlatformItem(String name, IconData icon, AdPlatform platform) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 20),
      title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
      onTap: () => _handlePlatformConnect(name, platform),
    );
  }

  Future<void> _handlePlatformConnect(String name, AdPlatform platform) async {
     setState(() => _isLoadingDrive = true); // Reuse loading state
     try {
        final integrationService = ref.read(integrationServiceProvider);
        final account = await integrationService.initiateConnection(platform, 'client_1'); // TODO: Pass clientID
        
        if (account != null) {
           final source = await SourcesService.fetchAndAddConnectedSource('dynamic', account, integrationService);
           
           final newSource = KnowledgeSource(
              id: const Uuid().v4(),
              title: source.name,
              content: source.content ?? 'Empty data',
              type: platform == AdPlatform.googleAnalytics ? KnowledgeSourceType.ga4 : KnowledgeSourceType.googleAds,
              createdAt: DateTime.now(),
              metadata: {'platform': platform.toString().split('.').last, 'accountId': account.externalAccountId},
           );
           
           widget.onSourceAdded(newSource);
           if (mounted) Navigator.pop(context);
        }
     } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
     } finally {
        if (mounted) setState(() => _isLoadingDrive = false);
     }
  }

  Widget _buildOptionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchServices() async {
    setState(() {
      _isLoadingDrive = true; // Reuse loading state
      _activeInputMode = 'services';
    });
    try {
      final repo = services_repo.ServicesRepository();
      final services = await repo.streamServices().first;
      setState(() => _availableServices = services);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading services: $e')));
        setState(() => _activeInputMode = null);
      }
    } finally {
      if (mounted) setState(() => _isLoadingDrive = false);
    }
  }

  Widget _buildServicesSelector() {
    if (_availableServices == null || _availableServices!.isEmpty) {
      return const Center(child: Text("No services available", style: TextStyle(color: Colors.white38)));
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        itemCount: _availableServices!.length,
        itemBuilder: (context, index) {
          final service = _availableServices![index];
          final isSelected = _selectedServiceIds.contains(service.id);
          
          return CheckboxListTile(
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedServiceIds.add(service.id);
                } else {
                  _selectedServiceIds.remove(service.id);
                }
              });
            },
            title: Text(service.nameEs, style: const TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text('\$${service.basePrice}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            activeColor: AppTheme.primary,
            checkColor: Colors.white,
          );
        },
      ),
    );
  }

  void _handleAddServices() {
    if (_selectedServiceIds.isEmpty) return;
    
    final selectedServices = _availableServices!.where((s) => _selectedServiceIds.contains(s.id)).toList();
    
    // Create a single knowledge source with all selected services
    final serviceNames = selectedServices.map((s) => s.nameEs).join(', ');
    final serviceDetails = selectedServices.map((s) {
      return '''
${s.nameEs} (${s.name})
- Ejecución: ${s.execution}
- Equipo: ${s.team.join(', ')}
- Entregables: ${s.deliverables.join(', ')}
- Incluye: ${s.includes.join(', ')}
- No incluye: ${s.excludes.join(', ')}
- Precio: \$${s.basePrice}
''';
    }).join('\n---\n');

    final newSource = KnowledgeSource(
      id: const Uuid().v4(),
      title: 'Services: $serviceNames',
      content: serviceDetails,
      type: KnowledgeSourceType.text,
      createdAt: DateTime.now(),
      metadata: {
        'source': 'services',
        'serviceIds': _selectedServiceIds.toList(),
        'serviceCount': _selectedServiceIds.length.toString(),
      },
    );
    
    widget.onSourceAdded(newSource);
    Navigator.pop(context);
  }
}
