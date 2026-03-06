import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/folder.dart';
import '../repositories/card_repository.dart';
import '../repositories/folder_repository.dart';
import '../widgets/card_image_widget.dart';
import '../widgets/suit_helper.dart';

class AddEditCardScreen extends StatefulWidget {
  final Folder folder;
  final PlayingCard? card; // null = Add mode, non-null = Edit mode

  const AddEditCardScreen({
    super.key,
    required this.folder,
    this.card,
  });

  @override
  State<AddEditCardScreen> createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends State<AddEditCardScreen> {
  final _cardRepo = CardRepository();
  final _folderRepo = FolderRepository();

  final _cardNameCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  List<Folder> _allFolders = [];
  String? _selectedSuit;
  int? _selectedFolderId;
  bool _saving = false;

  bool get _isEditing => widget.card != null;

  static const _suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
  static const _cardNames = [
    'Ace', '2', '3', '4', '5', '6', '7',
    '8', '9', '10', 'Jack', 'Queen', 'King',
  ];

  @override
  void initState() {
    super.initState();
    _loadFolders();

    if (_isEditing) {
      _cardNameCtrl.text = widget.card!.cardName;
      _imageUrlCtrl.text = widget.card!.imageUrl ?? '';
      _selectedSuit = widget.card!.suit;
      _selectedFolderId = widget.card!.folderId;
    } else {
      _selectedFolderId = widget.folder.id;
      _selectedSuit = widget.folder.folderName;
    }
  }

  Future<void> _loadFolders() async {
    final folders = await _folderRepo.getAllFolders();
    if (mounted) setState(() => _allFolders = folders);
  }

  @override
  void dispose() {
    _cardNameCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _cardNameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Please enter or select a card name.');
      return;
    }
    if (_selectedSuit == null) {
      _showError('Please select a suit.');
      return;
    }
    if (_selectedFolderId == null) {
      _showError('Please select a folder.');
      return;
    }

    setState(() => _saving = true);

    try {
      final imageUrl =
          _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim();

      if (_isEditing) {
        final updated = widget.card!.copyWith(
          cardName: name,
          suit: _selectedSuit,
          imageUrl: imageUrl,
          folderId: _selectedFolderId,
        );
        await _cardRepo.updateCard(updated);
      } else {
        final newCard = PlayingCard(
          cardName: name,
          suit: _selectedSuit!,
          imageUrl: imageUrl,
          folderId: _selectedFolderId!,
        );
        await _cardRepo.insertCard(newCard);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Card updated!' : 'Card added!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final suitColor = _selectedSuit != null
        ? SuitHelper.colorFor(_selectedSuit!)
        : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Card' : 'Add Card',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: suitColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            Center(
              child: CardImageWidget(
                imageUrl: _imageUrlCtrl.text.isEmpty
                    ? null
                    : _imageUrlCtrl.text,
                width: 100,
                height: 140,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),

            _sectionLabel('Card Name'),
            const SizedBox(height: 8),

            // Card name — dropdown or free text
            DropdownButtonFormField<String>(
              value: _cardNames.contains(_cardNameCtrl.text)
                  ? _cardNameCtrl.text
                  : null,
              decoration: _inputDecoration('Select card name'),
              items: _cardNames
                  .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  _cardNameCtrl.text = v;
                  // Auto-fill image URL when suit + name are both selected
                  _autoFillImageUrl();
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _cardNameCtrl,
              decoration: _inputDecoration('Or type custom name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            _sectionLabel('Suit'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSuit,
              decoration: _inputDecoration('Select suit'),
              items: _suits
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Icon(SuitHelper.iconFor(s),
                                color: SuitHelper.colorFor(s), size: 18),
                            const SizedBox(width: 8),
                            Text(s),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() => _selectedSuit = v);
                _autoFillImageUrl();
              },
            ),
            const SizedBox(height: 20),

            _sectionLabel('Folder'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedFolderId,
              decoration: _inputDecoration('Assign to folder'),
              items: _allFolders
                  .map((f) => DropdownMenuItem(
                        value: f.id,
                        child: Text(f.folderName),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFolderId = v),
            ),
            const SizedBox(height: 20),

            _sectionLabel('Image URL (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _imageUrlCtrl,
              decoration: _inputDecoration(
                  'https://deckofcardsapi.com/static/img/AS.png'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 36),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: suitColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isEditing ? 'Save Changes' : 'Add Card',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Auto-fills image URL using Deck of Cards API pattern
  void _autoFillImageUrl() {
    if (_selectedSuit == null || _cardNameCtrl.text.isEmpty) return;
    if (_imageUrlCtrl.text.isNotEmpty) return; // don't overwrite user input

    const suitCode = {
      'Hearts': 'H', 'Diamonds': 'D', 'Clubs': 'C', 'Spades': 'S'
    };
    const rankCode = {
      'Ace': 'A', '2': '2', '3': '3', '4': '4', '5': '5',
      '6': '6', '7': '7', '8': '8', '9': '9', '10': '0',
      'Jack': 'J', 'Queen': 'Q', 'King': 'K',
    };

    final s = suitCode[_selectedSuit];
    final r = rankCode[_cardNameCtrl.text];
    if (s != null && r != null) {
      setState(() {
        _imageUrlCtrl.text =
            'https://deckofcardsapi.com/static/img/$r$s.png';
      });
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
      );
}