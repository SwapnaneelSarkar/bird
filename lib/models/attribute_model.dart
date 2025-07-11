class AttributeGroup {
  final String attributeId;
  final String menuId;
  final String name;
  final String type;
  final bool isRequired;
  final List<AttributeValue> values;

  AttributeGroup({
    required this.attributeId,
    required this.menuId,
    required this.name,
    required this.type,
    required this.isRequired,
    required this.values,
  });

  factory AttributeGroup.fromJson(Map<String, dynamic> json) {
    return AttributeGroup(
      attributeId: json['attribute_id'] ?? '',
      menuId: json['menu_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'radio',
      isRequired: json['is_required'] == 1,
      values: (json['attribute_values'] as List<dynamic>?)
              ?.map((value) => AttributeValue.fromJson(value))
              .where((value) => value.name != null && value.valueId != null)
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attribute_id': attributeId,
      'menu_id': menuId,
      'name': name,
      'type': type,
      'is_required': isRequired ? 1 : 0,
      'attribute_values': values.map((value) => value.toJson()).toList(),
    };
  }
}

class AttributeValue {
  final String? name;
  final String? valueId;
  final bool? isDefault;
  final double? priceAdjustment;

  AttributeValue({
    this.name,
    this.valueId,
    this.isDefault,
    this.priceAdjustment,
  });

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    try {
      final raw = json['price_adjustment'];
      double? priceAdj;
      if (raw is num) {
        priceAdj = raw.toDouble();
      } else if (raw is String) {
        priceAdj = double.tryParse(raw);
      }
      // Defensive: handle is_default as int, bool, or String
      bool? isDefault;
      final rawDefault = json['is_default'];
      if (rawDefault is bool) {
        isDefault = rawDefault;
      } else if (rawDefault is int) {
        isDefault = rawDefault == 1;
      } else if (rawDefault is String) {
        isDefault = rawDefault == '1' || rawDefault.toLowerCase() == 'true';
      }
      return AttributeValue(
        name: json['name'],
        valueId: json['value_id'],
        isDefault: isDefault,
        priceAdjustment: priceAdj,
      );
    } catch (e, stack) {
      print('Error parsing AttributeValue: $e');
      print('Raw JSON: $json');
      print('Stack: $stack');
      return AttributeValue();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value_id': valueId,
      'is_default': isDefault == true ? 1 : 0,
      'price_adjustment': priceAdjustment,
    };
  }
}

class SelectedAttribute {
  final String attributeId;
  final String attributeName;
  final String valueId;
  final String valueName;
  final double priceAdjustment;

  SelectedAttribute({
    required this.attributeId,
    required this.attributeName,
    required this.valueId,
    required this.valueName,
    required this.priceAdjustment,
  });

  Map<String, dynamic> toJson() {
    return {
      'attribute_id': attributeId,
      'attribute_name': attributeName,
      'value_id': valueId,
      'value_name': valueName,
      'price_adjustment': priceAdjustment,
    };
  }

  factory SelectedAttribute.fromJson(Map<String, dynamic> json) {
    return SelectedAttribute(
      attributeId: json['attribute_id'] ?? '',
      attributeName: json['attribute_name'] ?? '',
      valueId: json['value_id'] ?? '',
      valueName: json['value_name'] ?? '',
      priceAdjustment: (json['price_adjustment'] as num?)?.toDouble() ?? 0.0,
    );
  }
} 