enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  pickedUp,
  cancelled,
  refunded;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere((s) => s.name == value);
  }

  bool get isActive => this != cancelled && this != refunded;
  bool get isTerminal => this == pickedUp || this == cancelled || this == refunded;
}
