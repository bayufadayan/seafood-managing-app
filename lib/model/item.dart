class Item {
  final String id;
  final String name;
  final String code;
  final int stock;
  final String expiredDate;
  final String imageUrl;

  Item({
    required this.id,
    required this.name,
    required this.code,
    required this.stock,
    required this.expiredDate,
    required this.imageUrl,
  });

  factory Item.fromMap(Map<String, dynamic> data, String documentId) {
    return Item(
      id: documentId,
      name: data['itemName'] ?? '',
      code: data['itemCode'] ?? '',
      stock: data['itemCount'] ?? 0,
      expiredDate: data['expiredDate'] ?? '',
      imageUrl: data['itemPicture'] ?? '',
    );
  }
}
