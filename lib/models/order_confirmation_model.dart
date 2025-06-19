class OrderItem {
  final String id;
  final String name;
  final String imageUrl;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'price': price,
    };
  }

  double get totalPrice {
    final total = price * quantity;
    return total;
  }
}

class OrderSummary {
  final List<OrderItem> items;
  final double deliveryFee;
  final double taxAmount;
  final double discountAmount;

  OrderSummary({
    required this.items,
    this.deliveryFee = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
  });

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get total {
    return subtotal + deliveryFee + taxAmount - discountAmount;
  }

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      deliveryFee: (json['deliveryFee'] ?? 0.0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0.0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'deliveryFee': deliveryFee,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
    };
  }
}