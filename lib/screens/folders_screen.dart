import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../repositories/folder_repository.dart';
import '../repositories/card_repository.dart';
import '../widgets/suit_helper.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final _folderRepo = FolderRepository();
  final _cardRepo = CardRepository();

  List<Folder> _folders = [];
  Map<int, int> _cardCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _loading = true);
    try {
      final folders = await _folderRepo.getAllFolders();
      final Map<int, int> counts = {};
      for (final f in folders) {
        counts[f.id!] = await _cardRepo.getCardCountByFolder(f.id!);
      }
      if (mounted) {
        setState(() {
          _folders = folders;
          _cardCounts = counts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Failed to load folders: $e');
      }
    }
  }

  Future<void> _deleteFolder(Folder folder) async {
    final cardCount = _cardCounts[folder.id!] ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Folder?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Delete "${folder.folderName}"?\n\n'
          'This will permanently delete all $cardCount card(s) inside it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _folderRepo.deleteFolder(folder.id!);
        _loadFolders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${folder.folderName}" deleted'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } catch (e) {
        _showError('Could not delete folder: $e');
      }
    }
  }

  Future<void> _addFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Folder name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      try {
        await _folderRepo.insertFolder(Folder(
          folderName: name,
          timestamp: DateTime.now().toIso8601String(),
        ));
        _loadFolders();
      } catch (e) {
        _showError('Could not add folder: $e');
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '♠ Card Organizer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadFolders,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFolder,
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.create_new_folder),
        label: const Text('New Folder'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _folders.isEmpty
              ? _emptyState()
              : _folderGrid(),
    );
  }

  Widget _folderGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemCount: _folders.length,
      itemBuilder: (_, i) => _folderCard(_folders[i]),
    );
  }

  Widget _folderCard(Folder folder) {
    final count = _cardCounts[folder.id!] ?? 0;
    final color = SuitHelper.colorFor(folder.folderName);
    final bg = SuitHelper.backgroundFor(folder.folderName);
    final icon = SuitHelper.iconFor(folder.folderName);

    return Card(
      elevation: 3,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CardsScreen(folder: folder),
            ),
          );
          _loadFolders();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const Spacer(),
              Text(
                folder.folderName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count card${count == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              // Delete button
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.outlined(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red.shade400,
                  style: IconButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(36, 36),
                  ),
                  tooltip: 'Delete folder',
                  onPressed: () => _deleteFolder(folder),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No folders yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text('Tap + to create one',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
