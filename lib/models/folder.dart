class Folder {
  final int? id;
  final String folderName;
  final String timestamp;

  const Folder({
    this.id,
    required this.folderName,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'folder_name': folderName,
        'timestamp': timestamp,
      };

  factory Folder.fromMap(Map<String, dynamic> map) => Folder(
        id: map['id'] as int?,
        folderName: map['folder_name'] as String,
        timestamp: map['timestamp'] as String,
      );

  Folder copyWith({
    int? id,
    String? folderName,
    String? timestamp,
  }) =>
      Folder(
        id: id ?? this.id,
        folderName: folderName ?? this.folderName,
        timestamp: timestamp ?? this.timestamp,
      );

  @override
  String toString() =>
      'Folder{id: $id, folderName: $folderName, timestamp: $timestamp}';
}
