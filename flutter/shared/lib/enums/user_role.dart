enum UserRole {
  customer,
  merchant,
  admin;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere((r) => r.name == value);
  }
}
