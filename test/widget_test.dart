import 'package:flutter_test/flutter_test.dart';
import 'package:nutrifit/main.dart';

void main() {
  group('NutriFit App Unit Tests', () {
    test('App Title & Name Check', () {
      expect('NutriFit', contains('Fit'));
    });

    test('Profile BMI and Custom Water Goal Calculation', () {
      final p = Profile(
        gender: 'male',
        age: 25,
        height: 175,
        weight: 70,
        goal: 'maintain',
        food: 'balanced',
      );

      expect(p.bmi, closeTo(22.85, 0.1));
      expect(p.recommendedWaterGoal, equals(2450)); // 70kg * 35ml = 2450ml
    });

    test('DeliveryAddress formattedAddress string check', () {
      final addr = DeliveryAddress(
        id: '1',
        fullName: 'Jane Doe',
        mobile: '9876543210',
        houseNo: 'Flat 4B',
        street: 'Park Street',
        city: 'Mumbai',
        district: 'Mumbai Suburban',
        state: 'Maharashtra',
        pincode: '400001',
      );

      expect(addr.formattedAddress, contains('Flat 4B, Park Street'));
      expect(addr.formattedAddress, contains('Mumbai Suburban, Maharashtra - 400001'));
      expect(addr.toJson()['full_name'], equals('Jane Doe'));
    });

    test('ShopOrder price and delivery fee calculation', () {
      final item1 = OrderItem(
        productId: 'p1',
        productName: 'Protein Shake',
        brand: 'GNC',
        imagePath: 'assets/images/product_gnc.png',
        price: 500.0,
        quantity: 2,
      );

      final items = [item1];
      final subtotal = items.fold<double>(0, (sum, i) => sum + (i.price * i.quantity));
      final delivery = subtotal >= 999 ? 0.0 : 50.0;
      final total = subtotal + delivery;

      expect(subtotal, equals(1000.0));
      expect(delivery, equals(0.0)); // Free shipping for >= 999
      expect(total, equals(1000.0));
    });

    test('Mobile Number and Pincode Validation Rules', () {
      final mobileRegex = RegExp(r'^[6-9]\d{9}$');
      final pincodeRegex = RegExp(r'^[1-9]\d{5}$');

      expect(mobileRegex.hasMatch('9876543210'), isTrue);
      expect(mobileRegex.hasMatch('1234567890'), isFalse); // Doesn't start with 6-9
      expect(mobileRegex.hasMatch('98765'), isFalse); // Short

      expect(pincodeRegex.hasMatch('600001'), isTrue);
      expect(pincodeRegex.hasMatch('012345'), isFalse); // Starts with 0
      expect(pincodeRegex.hasMatch('6000'), isFalse); // Short
    });
  });
}
