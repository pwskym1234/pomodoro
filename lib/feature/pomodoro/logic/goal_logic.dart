import 'package:pomodoro_desktop/data/model/shop_item.dart';

class GoalLogic {
  static int calculateXPEarned(List<ShopItem> inventory) {
    int baseXP = 10;
    if (inventory.any((item) => item.id == 3)) {
      return baseXP + 5;
    }
    return baseXP;
  }

  static void applyItemEffects({
    required ShopItem item,
    required void Function(int minutes) onFocusBoost,
    required void Function(int minutes) onBreakBoost,
  }) {
    if (item.id == 1) {
      onFocusBoost(5);
    } else if (item.id == 2) {
      onBreakBoost(2);
    }
  }

  static bool canAfford(ShopItem item, int coins) {
    return coins >= item.cost;
  }

  static int purchaseCost(ShopItem item) {
    return item.cost;
  }
}
