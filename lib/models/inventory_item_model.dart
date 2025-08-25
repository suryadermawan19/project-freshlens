// lib/models/inventory_item_model.dart

class Batch {
  final String id;
  final DateTime entryDate;
  final int quantity;
  final int predictedShelfLife;
  final String initialCondition; // <-- TAMBAHAN BARU

  Batch({
    required this.id,
    required this.entryDate,
    required this.quantity,
    required this.predictedShelfLife,
    required this.initialCondition, // <-- TAMBAHAN BARU
  });
}

class InventoryItemGroup {
  final String itemName;
  final String imagePath;
  final List<Batch> batches;

  InventoryItemGroup({
    required this.itemName,
    required this.imagePath,
    required this.batches,
  });
  
  int get totalQuantity {
    return batches.fold(0, (sum, item) => sum + item.quantity);
  }
}