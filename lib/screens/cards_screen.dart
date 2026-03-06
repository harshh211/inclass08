import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../models/card.dart';
import '../repositories/card_repository.dart';
import '../widgets/card_image_widget.dart';
import '../widgets/suit_helper.dart';
import '../screens/add_edit_card_screen.dart';

class CardsScreen extends StatefulWidget {
  final Folder folder;

  const CardsScreen({super.key, required this.folder});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final _cardRepo = CardRepository();
  List<PlayingCard> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _loading = true);
    try {
      final cards = await _cardRepo.getCardsByFolderId(widget.folder.id!);
      if (mounted) setState(() { _cards = cards; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Failed to load cards: $e');
      }
    }
  }

  Future<void> _deleteCard(PlayingCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Card?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Remove "${card.cardName} of ${card.suit}" from this folder?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _cardRepo.deleteCard(card.id!);
        _loadCards();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${card.cardName}" removed'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } catch (e) {
        _showError('Could not delete card: $e');
      }
    }
  }

  Future<void> _openAddEditScreen({PlayingCard? card}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditCardScreen(
          folder: widget.folder,
          card: card,
        ),
      ),
    );
    _loadCards();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final suitColor = SuitHelper.colorFor(widget.folder.folderName);
    final suitIcon = SuitHelper.iconFor(widget.folder.folderName);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(suitIcon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.folder.folderName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_cards.length}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: suitColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditScreen(),
        backgroundColor: suitColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _emptyState()
              : _cardsList(),
    );
  }

  Widget _cardsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _cards.length,
      itemBuilder: (_, i) => _cardTile(_cards[i]),
    );
  }

  Widget _cardTile(PlayingCard card) {
    final suitColor = SuitHelper.colorFor(card.suit);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CardImageWidget(imageUrl: card.imageUrl, width: 50, height: 70),
        ),
        title: Text(
          card.cardName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Row(
          children: [
            Icon(SuitHelper.iconFor(card.suit), color: suitColor, size: 14),
            const SizedBox(width: 4),
            Text(card.suit,
                style: TextStyle(color: suitColor, fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: Colors.blue.shade600,
              tooltip: 'Edit',
              onPressed: () => _openAddEditScreen(card: card),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red.shade400,
              tooltip: 'Delete',
              onPressed: () => _deleteCard(card),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No cards yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text('Tap + to add a card',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
