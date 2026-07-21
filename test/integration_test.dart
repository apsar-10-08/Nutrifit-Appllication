import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrifit/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NutriFit Integration Tests', () {
    late AppController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      controller = AppController();
    });

    test('Controller initialization state', () {
      expect(controller.water, equals(0));
      expect(controller.steps, equals(0));
      expect(controller.sleep, equals(0));
      expect(controller.cart, isEmpty);
      expect(controller.orders, isEmpty);
    });

    test('Address management integration', () async {
      final addr = DeliveryAddress(
        id: 'addr-101',
        fullName: 'Test User',
        mobile: '9876543210',
        houseNo: '123',
        street: 'Test Street',
        city: 'Chennai',
        district: 'Chennai',
        state: 'Tamil Nadu',
        pincode: '600001',
        isDefault: true,
      );

      await controller.saveAddress(addr);
      expect(controller.addresses.length, equals(1));
      expect(controller.addresses.first.fullName, equals('Test User'));

      await controller.deleteAddress('addr-101');
      expect(controller.addresses, isEmpty);
    });

    test('Cart and Order placement integration flow', () async {
      final addr = DeliveryAddress(
        id: 'addr-102',
        fullName: 'Order User',
        mobile: '9876543210',
        houseNo: '456',
        street: 'Shop Road',
        city: 'Chennai',
        district: 'Chennai',
        state: 'Tamil Nadu',
        pincode: '600002',
      );

      final directItems = [
        OrderItem(
          productId: 'gnc-whey',
          productName: 'GNC Whey Protein',
          brand: 'GNC',
          imagePath: 'assets/images/shop/gnc/gnc_whey_protein.png',
          price: 1500.0,
          quantity: 2,
        ),
      ];

      final order = await controller.placeOrder(
        address: addr,
        paymentMethod: 'Cash on Delivery',
        directItems: directItems,
      );

      expect(order.id, isNotEmpty);
      expect(order.totalAmount, equals(3000.0)); // 1500 * 2 = 3000 (free shipping >= 999)
      expect(controller.orders.length, equals(1));
      expect(controller.orders.first.status, equals('Confirmed'));

      // Test order cancellation
      await controller.cancelOrder(order.id);
      expect(controller.orders.first.status, equals('Cancelled'));
    });
  });
}
