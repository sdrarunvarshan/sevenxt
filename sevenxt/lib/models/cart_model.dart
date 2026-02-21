import 'package:sevenxt/models/product_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
class CartItem {
  final ProductModel product;
  int quantity;
  final String colorHex;
  final double weight;
  final double length;
  final String hsnCode;
  final double breadth;
  final double height;

  CartItem({required this.product, required this.hsnCode,required this.colorHex, this.quantity = 1,required this.weight,

required this.length,
required this.breadth,
required this.height,});
  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
    'colorHex': colorHex,
    'hsnCode': hsnCode,
    'weight': weight,
    'length': length,
    'breadth': breadth,
    'height': height,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: ProductModel.fromJson(json['product']),
      quantity: json['quantity'],
      colorHex: json['colorHex'],
      hsnCode: json['hsnCode'],
      weight: json['weight'],
      length: json['length'],
      breadth: json['breadth'],
      height: json['height'],
    );
  }
}


class Cart {
  static final Cart _instance = Cart._internal();
  factory Cart() => _instance;
  Cart._internal();

  final List<CartItem> _items = [];
  late Box _cartBox;
  String? _currentUserKey;

  List<CartItem> get items => _items;


  void addItem(ProductModel product, String colorHex,
      {int quantity = 1, String? hsnCode,
        double? weightKg, double? lengthCm, double?breadthCm, double? heightCm,}) {
    // Check if item with same product ID AND same colorHex already exists
    for (var item in _items) {
      if (item.product.id == product.id && item.colorHex == colorHex) {
        item.quantity += quantity;
        _saveCart();
        return;
      }
    }
    // If not found, add new item with the colorHex
    _items.add(
      CartItem(
        product: product,
        colorHex: colorHex,
        quantity: quantity,
        hsnCode: hsnCode ?? '',
        weight: product.weightKg,
        length: product.lengthCm,
        breadth: product.breadthCm,
        height: product.heightCm,
      ),
    );
    _saveCart();

  }

  void removeItem(CartItem item) {
    _items.remove(item);
    _saveCart();

  }

  void clearCart() {
    _items.clear();
    _saveCart();
  }

  void incrementQuantity(CartItem item) {
    item.quantity++;
    _saveCart();
  }

  void decrementQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
      _saveCart();
    }
  }

  double get subtotal {
    return _items.fold(
        0, (total, item) => total + (item.product.price * item.quantity));
  }
  Future<void> loadUserCart(String userIdentifier) async {
    _cartBox = Hive.box('user_settings');

    _currentUserKey = 'cart_$userIdentifier';
    _items.clear();

    final List<dynamic>? storedItems = _cartBox.get(_currentUserKey);

    if (storedItems != null) {
      _items.addAll(
        storedItems.map(
              (e) => CartItem.fromJson(Map<String, dynamic>.from(e)),
        ),
      );
    }
  }
  Future<void> _saveCart() async {
    if (_currentUserKey == null) return;

    await _cartBox.put(
      _currentUserKey,
      _items.map((e) => e.toJson()).toList(),
    );
  }


}