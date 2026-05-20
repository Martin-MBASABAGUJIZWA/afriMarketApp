enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  completed,
  cancelled,
  refunded;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  bool get isActive =>
      this == OrderStatus.pending ||
      this == OrderStatus.confirmed ||
      this == OrderStatus.processing ||
      this == OrderStatus.shipped;

  bool get isFinal =>
      this == OrderStatus.completed ||
      this == OrderStatus.cancelled ||
      this == OrderStatus.refunded;
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

enum PaymentMethod {
  mobileMoney,
  card,
  cashOnDelivery;

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'mobile_money':
        return PaymentMethod.mobileMoney;
      case 'card':
        return PaymentMethod.card;
      case 'cash_on_delivery':
        return PaymentMethod.cashOnDelivery;
      default:
        return PaymentMethod.mobileMoney;
    }
  }

  String get value {
    switch (this) {
      case PaymentMethod.mobileMoney:
        return 'mobile_money';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.cashOnDelivery:
        return 'cash_on_delivery';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
    }
  }
}
