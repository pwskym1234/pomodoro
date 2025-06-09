import 'package:flutter/material.dart';
import 'package:pomodoro_desktop/data/model/shop_item.dart';

class ShopModal extends StatelessWidget {
  final List<ShopItem> shopItems;
  final void Function(ShopItem) onBuy;
  final VoidCallback onClose;

  const ShopModal({
    super.key,
    required this.shopItems,
    required this.onBuy,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('🏪 상점',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
          IconButton(
            icon: const Icon(Icons.close, size: 30),
            onPressed: onClose,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: shopItems
              .map((item) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(item.name,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[700])),
                          const SizedBox(height: 8),
                          Text(item.description,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          Text('💰 ${item.cost}',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green[600])),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => onBuy(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[500],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                            ),
                            child: const Text('구매하기',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
