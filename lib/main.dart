import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

const green = Color(0xFF10A866);
const darkGreen = Color(0xFF087A4A);
const lightGreen = Color(0xFFE8F8F0);
const textDark = Color(0xFF172B21);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
  await dotenv.load(fileName: '.env');
  // Debug: print loaded Supabase env values (obfuscate key for security)
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    print('⚠️ Supabase URL not set in .env');
  } else {
    print('✅ Supabase URL loaded');
  }
  if (anonKey == null || anonKey.isEmpty) {
    print('⚠️ Supabase anon key not set in .env');
  } else {
    print('✅ Supabase anon key loaded');
  } } catch (_) {}
  await Supa.init();
  final controller = AppController();
  await controller.init();
  runApp(Scope(controller: controller, child: NutriFitApp(controller: controller)));
}

class Supa {
  static bool ready = false;
  static SupabaseClient get client => Supabase.instance.client;
  static Future<void> init() async {
    final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    final key = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
    if (!url.startsWith('https://') || key.isEmpty || key.contains('your-supabase')) return;
    await Supabase.initialize(
      url: url,
      anonKey: key,
      authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
    ready = true;
  }
}

class Scope extends InheritedNotifier<AppController> {
  const Scope({super.key, required AppController controller, required super.child}) : super(notifier: controller);
  static AppController of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<Scope>()!.notifier!;
}

class NutriFitApp extends StatelessWidget {
  const NutriFitApp({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NutriFit',
        locale: Locale(controller.lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: green).copyWith(primary: green, secondary: darkGreen),
          scaffoldBackgroundColor: const Color(0xFFFAFCFB),
          appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: textDark),
          cardTheme: CardThemeData(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
          inputDecorationTheme: InputDecorationTheme(
            filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: green, width: 1.5)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(54), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
          textTheme: const TextTheme(headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: textDark), headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textDark), titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textDark), titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textDark)),
        ),
        onGenerateRoute: (settings) {
          final isAuthRoute = ['/', '/login', '/signup', '/forgot'].contains(settings.name);
          String targetRoute = settings.name ?? '/';

          if (!isAuthRoute && !controller.signedIn) {
            targetRoute = '/login';
          } else if (controller.signedIn && controller.profile?.complete != true && targetRoute == '/dashboard') {
            targetRoute = '/goal';
          } else if (controller.signedIn && controller.profile?.complete == true && (targetRoute == '/login' || targetRoute == '/signup')) {
            targetRoute = '/dashboard';
          }

          Widget page;
          switch (targetRoute) {
            case '/': page = const SplashScreen(); break;
            case '/login': page = const LoginScreen(); break;
            case '/signup': page = const SignUpScreen(); break;
            case '/forgot': page = const ForgotScreen(); break;
            case '/goal': page = const GoalScreen(); break;
            case '/gender': page = const GenderScreen(); break;
            case '/age': page = const NumberScreen(kind: 'age'); break;
            case '/height': page = const NumberScreen(kind: 'height'); break;
            case '/weight': page = const NumberScreen(kind: 'weight'); break;
            case '/food': page = const FoodScreen(); break;
            case '/location': page = const LocationScreen(); break;
            case '/dashboard': page = const DashboardScreen(); break;
            case '/cart': page = const CartScreen(); break;
            case '/checkout':
              final directProduct = settings.arguments as Product?;
              page = CheckoutScreen(directProduct: directProduct);
              break;
            case '/order_confirmation':
              final order = settings.arguments as ShopOrder;
              page = OrderConfirmationScreen(order: order);
              break;
            case '/orders': page = const MyOrdersScreen(); break;
            default: page = const SplashScreen(); break;
          }

          return MaterialPageRoute(builder: (_) => page, settings: RouteSettings(name: targetRoute));
        },
      ),
    );
  }
}

class Profile {
  Profile({this.id='demo-user', this.name='', this.email='', this.goal='', this.gender='', this.age, this.height, this.weight, this.food='', this.location='', this.lang='en', this.onboardingCompleted=false});
  String id, name, email, goal, gender, food, location, lang;
  int? age; double? height, weight;
  bool onboardingCompleted;
  bool get complete => onboardingCompleted;
  Profile copy({String? id, name, email, goal, gender, food, location, lang, int? age, double? height, weight, bool? onboardingCompleted}) => Profile(
    id: id ?? this.id, name: name ?? this.name, email: email ?? this.email, goal: goal ?? this.goal, gender: gender ?? this.gender,
    age: age ?? this.age, height: height ?? this.height, weight: weight ?? this.weight, food: food ?? this.food, location: location ?? this.location, lang: lang ?? this.lang, onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted);
  Map<String,dynamic> toJson() => {'id': id, 'full_name': name, 'email': email, 'goal': goal, 'gender': gender, 'age': age, 'height_cm': height, 'weight_kg': weight, 'food_preference': food, 'workout_location': location, 'preferred_language': lang, 'onboarding_completed': onboardingCompleted};
  Map<String,dynamic> profileJson(String uid) => {'id': uid, 'full_name': name, 'email': email, 'gender': gender, 'age': age, 'height_cm': height, 'weight_kg': weight, 'food_preference': food, 'workout_location': location, 'preferred_language': lang, 'onboarding_completed': onboardingCompleted};
  double get bmi {
    if (height == null || weight == null || height! <= 0 || weight! <= 0) return 0.0;
    final hM = height! / 100.0;
    return weight! / (hM * hM);
  }

  int get recommendedWaterGoal {
    if (weight == null || weight! <= 0) return 2000;
    return (weight! * 35).round();
  }

  factory Profile.from(Map<String,dynamic> j) => Profile(id:(j['id']??'demo-user').toString(), name:(j['full_name']??'').toString(), email:(j['email']??'').toString(), goal:(j['goal']??'').toString(), gender:(j['gender']??'').toString(), age:int.tryParse('${j['age']??''}'), height:double.tryParse('${j['height_cm']??''}'), weight:double.tryParse('${j['weight_kg']??''}'), food:(j['food_preference']??'').toString(), location:(j['workout_location']??'').toString(), lang:(j['preferred_language']??'en').toString(), onboardingCompleted: j['onboarding_completed'] == true);
}

class Product {
  const Product(this.id, this.brand, this.name, this.category, this.description, this.price, this.imagePath, this.rating);
  final String id, brand, name, category, description, imagePath;
  final double price, rating;
}

class BudgetProduct {
  BudgetProduct({
    required this.id,
    required this.productName,
    required this.imagePath,
    required this.category,
    required this.price,
    this.originalPrice,
    this.protein = 0,
    this.calories = 0,
    required this.storeName,
    required this.updatedAt,
    this.quantity = '1 kg / unit',
  });

  final String id, productName, imagePath, category, storeName, quantity;
  final double price, protein, calories;
  final double? originalPrice;
  final DateTime updatedAt;

  double get discountPercentage {
    if (originalPrice == null || originalPrice! <= price || originalPrice! == 0) return 0;
    return ((originalPrice! - price) / originalPrice! * 100);
  }

  double get budgetScore {
    if (price == 0) return 0;
    return (protein / price) * 100;
  }

  bool get isBestValue => discountPercentage > 20 || (budgetScore > 5 && price < 150);

  factory BudgetProduct.from(Map<String, dynamic> j) {
    return BudgetProduct(
      id: j['id']?.toString() ?? '',
      productName: j['product_name']?.toString() ?? 'Unknown',
      imagePath: j['image_url']?.toString() ?? 'assets/images/budget_products/eggs.png',
      category: j['category']?.toString() ?? '',
      price: double.tryParse(j['price']?.toString() ?? '0') ?? 0,
      originalPrice: j['original_price'] != null ? double.tryParse(j['original_price'].toString()) : null,
      protein: double.tryParse(j['protein']?.toString() ?? '0') ?? 0,
      calories: double.tryParse(j['calories']?.toString() ?? '0') ?? 0,
      storeName: j['store_name']?.toString() ?? '',
      updatedAt: j['updated_at'] != null ? DateTime.tryParse(j['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
      quantity: j['quantity']?.toString() ?? '1 kg / unit',
    );
  }
}

class DeliveryAddress {
  final String id;
  final String fullName;
  final String mobile;
  final String houseNo;
  final String street;
  final String landmark;
  final String city;
  final String district;
  final String state;
  final String pincode;
  final String instructions;
  final bool isDefault;

  DeliveryAddress({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.houseNo,
    required this.street,
    this.landmark = '',
    required this.city,
    required this.district,
    required this.state,
    required this.pincode,
    this.instructions = '',
    this.isDefault = false,
  });

  String get formattedAddress => '$houseNo, $street${landmark.isNotEmpty ? ', Near $landmark' : ''}, $city, $district, $state - $pincode';

  static bool isValidMobile(String m) => RegExp(r'^[6-9]\d{9}$').hasMatch(m.trim());
  static bool isValidPincode(String p) => RegExp(r'^[1-9]\d{5}$').hasMatch(p.trim());

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'mobile': mobile,
    'house_no': houseNo,
    'street': street,
    'landmark': landmark,
    'city': city,
    'district': district,
    'state': state,
    'pincode': pincode,
    'instructions': instructions,
    'is_default': isDefault,
  };

  factory DeliveryAddress.fromJson(Map<String, dynamic> j) => DeliveryAddress(
    id: (j['id'] ?? '').toString(),
    fullName: (j['full_name'] ?? j['fullName'] ?? '').toString(),
    mobile: (j['mobile'] ?? '').toString(),
    houseNo: (j['house_no'] ?? j['houseNo'] ?? '').toString(),
    street: (j['street'] ?? '').toString(),
    landmark: (j['landmark'] ?? '').toString(),
    city: (j['city'] ?? '').toString(),
    district: (j['district'] ?? '').toString(),
    state: (j['state'] ?? '').toString(),
    pincode: (j['pincode'] ?? '').toString(),
    instructions: (j['instructions'] ?? '').toString(),
    isDefault: j['is_default'] == true || j['isDefault'] == true,
  );
}

class OrderItem {
  final String productId;
  final String productName;
  final String brand;
  final String imagePath;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.brand,
    required this.imagePath,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,
    'brand': brand,
    'image_path': imagePath,
    'price': price,
    'quantity': quantity,
  };

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    productId: (j['product_id'] ?? j['productId'] ?? '').toString(),
    productName: (j['product_name'] ?? j['productName'] ?? '').toString(),
    brand: (j['brand'] ?? '').toString(),
    imagePath: (j['image_path'] ?? j['imagePath'] ?? '').toString(),
    price: double.tryParse('${j['price'] ?? 0}') ?? 0.0,
    quantity: int.tryParse('${j['quantity'] ?? 1}') ?? 1,
  );
}

class ShopOrder {
  final String id;
  final DateTime date;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryCharge;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final DeliveryAddress address;
  final String status; // 'Confirmed', 'Packed', 'Shipped', 'Delivered'

  ShopOrder({
    required this.id,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.deliveryCharge,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.address,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'delivery_charge': deliveryCharge,
    'total_amount': totalAmount,
    'payment_method': paymentMethod,
    'payment_status': paymentStatus,
    'address': address.toJson(),
    'status': status,
  };

  factory ShopOrder.fromJson(Map<String, dynamic> j) => ShopOrder(
    id: (j['id'] ?? '').toString(),
    date: j['date'] != null ? DateTime.tryParse(j['date'].toString()) ?? DateTime.now() : DateTime.now(),
    items: (j['items'] as List? ?? []).map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e))).toList(),
    subtotal: double.tryParse('${j['subtotal'] ?? 0}') ?? 0.0,
    deliveryCharge: double.tryParse('${j['delivery_charge'] ?? j['deliveryCharge'] ?? 0}') ?? 0.0,
    totalAmount: double.tryParse('${j['total_amount'] ?? j['totalAmount'] ?? 0}') ?? 0.0,
    paymentMethod: (j['payment_method'] ?? j['paymentMethod'] ?? 'Cash on Delivery').toString(),
    paymentStatus: (j['payment_status'] ?? j['paymentStatus'] ?? 'Pending').toString(),
    address: DeliveryAddress.fromJson(Map<String, dynamic>.from(j['address'] ?? {})),
    status: (j['status'] ?? 'Confirmed').toString(),
  );
}

class AppController extends ChangeNotifier {
  Profile? profile; bool busy=false; bool demo=false; String lang='en';
  List<BudgetProduct> allProducts = [];
  List<BudgetProduct> visibleProducts = [];
  String budgetSort = 'Best Value';
  String budgetFilter = 'All';
  bool isLoadingBudget = false;

  final List<BudgetProduct> fallbackProducts = [
    BudgetProduct(id: 'fb1', productName: 'Eggs', imagePath: 'assets/images/budget_products/eggs.png', category: 'Non-Vegetarian', price: 75, protein: 12, calories: 143, storeName: 'Local Market', updatedAt: DateTime.now(), quantity: '1 Tray (30)'),
    BudgetProduct(id: 'fb2', productName: 'Milk', imagePath: 'assets/images/budget_products/milk.png', category: 'Vegetarian', price: 32, protein: 3.4, calories: 42, storeName: 'Local Market', updatedAt: DateTime.now(), quantity: '1 Litre'),
    BudgetProduct(id: 'fb3', productName: 'Oats', imagePath: 'assets/images/budget_products/oats.png', category: 'Vegetarian', price: 95, protein: 13, calories: 389, storeName: 'Local Market', updatedAt: DateTime.now(), quantity: '1 kg'),
    BudgetProduct(id: 'fb4', productName: 'Peanuts', imagePath: 'assets/images/budget_products/peanuts.png', category: 'Vegetarian', price: 40, protein: 25.8, calories: 567, storeName: 'Local Market', updatedAt: DateTime.now(), quantity: '500g'),
    BudgetProduct(id: 'fb5', productName: 'Green Gram', imagePath: 'assets/images/budget_products/green_gram.png', category: 'Vegetarian', price: 65, protein: 24, calories: 347, storeName: 'Local Market', updatedAt: DateTime.now(), quantity: '1 kg'),
    BudgetProduct(id: 'fb6', productName: 'Black Chana', imagePath: 'assets/images/budget_products/black_chana.png', category: 'Vegetarian', price: 60, protein: 20, calories: 378, storeName: 'Local Market', updatedAt: DateTime.now(), quantity: '1 kg'),
    BudgetProduct(id: 'fb7', productName: 'Curd', imagePath: 'assets/images/budget_products/curd.png', category: 'Vegetarian', price: 35, protein: 11, calories: 98, storeName: 'Local Market', updatedAt: DateTime.now(), quantity: '500g'),
    BudgetProduct(id: 'fb8', productName: 'Banana', imagePath: 'assets/images/budget_products/banana.png', category: 'Vegetarian', price: 50, protein: 1.1, calories: 89, storeName: 'Local Market', updatedAt: DateTime.now(), quantity: '1 Dozen'),
    BudgetProduct(id: 'fb9', productName: 'Chicken Liver', imagePath: 'assets/images/budget_products/chicken_liver.png', category: 'Non-Vegetarian', price: 90, protein: 17, calories: 119, storeName: 'Local Market', updatedAt: DateTime.now(), quantity: '500g'),
    BudgetProduct(id: 'fb10', productName: 'Soya Chunks', imagePath: 'assets/images/budget_products/soya_chunks.png', category: 'Vegetarian', price: 55, protein: 52, calories: 345, storeName: 'Local Market', updatedAt: DateTime.now(), quantity: '500g'),
  ];

  void setBudgetSort(String sort) {
    budgetSort = sort;
    _applyFiltersAndSort();
  }

  void setBudgetFilter(String filter) {
    budgetFilter = filter;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    visibleProducts = List.from(allProducts);
    
    // Filtering
    if (budgetFilter != 'All') {
      if (budgetFilter == 'Cheapest') {
        visibleProducts.sort((a, b) => a.price.compareTo(b.price));
        if (visibleProducts.length > 5) visibleProducts = visibleProducts.sublist(0, 5);
      } else if (budgetFilter == 'Highest Protein') {
        visibleProducts.sort((a, b) => b.protein.compareTo(a.protein));
        if (visibleProducts.length > 5) visibleProducts = visibleProducts.sublist(0, 5);
      } else if (budgetFilter == 'Vegetarian' || budgetFilter == 'Non-Vegetarian') {
        visibleProducts = visibleProducts.where((e) => e.category == budgetFilter).toList();
      } else if (budgetFilter == 'Under ₹100') {
        visibleProducts = visibleProducts.where((e) => e.price < 100).toList();
      } else if (budgetFilter == 'Under ₹200') {
        visibleProducts = visibleProducts.where((e) => e.price < 200).toList();
      }
    }
    
    // Sorting
    if (budgetSort == 'Lowest Price') {
      visibleProducts.sort((a, b) => a.price.compareTo(b.price));
    } else if (budgetSort == 'Highest Protein') {
      visibleProducts.sort((a, b) => b.protein.compareTo(a.protein));
    } else if (budgetSort == 'Best Value') {
      visibleProducts.sort((a, b) => b.budgetScore.compareTo(a.budgetScore));
    } else if (budgetSort == 'Biggest Discount') {
      visibleProducts.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
    }

    debugPrint('Visible products: ${visibleProducts.length}');
    notifyListeners();
  }

  Future<void> fetchBudgetProducts() async {
    isLoadingBudget = true;
    notifyListeners();
    
    List<BudgetProduct> loadedProducts = [];
    if (Supa.ready) {
      try {
        final res = await Supa.client.from('budget_products').select();
        loadedProducts = List<Map<String, dynamic>>.from(res).map((e) => BudgetProduct.from(e)).toList();
      } catch (e) {
        print('⚠️ Error fetching budget products: $e');
      }
    }
    
    if (loadedProducts.isEmpty) {
      allProducts = List.from(fallbackProducts);
    } else {
      allProducts = loadedProducts;
    }

    debugPrint('Supabase products: ${loadedProducts.length}');
    debugPrint('All products: ${allProducts.length}');
    
    _applyFiltersAndSort();
    
    isLoadingBudget = false;
    notifyListeners();
  }

  int water=0, steps=0, tab=0, timerSeconds=0; double sleep=0;
  final wishlist=<String>{}; final cart=<String,int>{}; final habits=<String,bool>{};
  final completedWorkouts=<String>{};

  // Addresses & Orders management
  List<DeliveryAddress> addresses = [];
  List<ShopOrder> orders = [];

  // Weekly history for 7-day charts (list of {date, value} maps)
  List<Map<String,dynamic>> weeklyHydration = [];
  List<Map<String,dynamic>> weeklySteps = [];
  List<Map<String,dynamic>> weeklySleep = [];

  /// Dynamic water goal: weight_kg × 35 ml, clamped 2000–5000. Defaults to 3000.
  int get waterGoal => profile?.weight != null
      ? (profile!.weight! * 35).round().clamp(2000, 5000)
      : 3000;

  List<String> aiHistory = [];
  String get latestAIAdvice => aiHistory.isNotEmpty ? aiHistory.last : 'Tap refresh to get your first personalized advice!';
  final Map<String, bool> reminders = {'Breakfast': false, 'Lunch': false, 'Dinner': false, 'Workout': false};

  final localToDbProductId = <String, String>{};
  final dbToLocalProductId = <String, String>{};

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  bool get signedIn => Supa.ready ? Supa.client.auth.currentSession != null : (demo || profile != null);
  String t(String key) => strings[lang]?[key] ?? strings['en']?[key] ?? key;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    lang = p.getString('lang') ?? 'en';
    final raw = p.getString('profile'); if (raw != null) profile = Profile.from(jsonDecode(raw));
    water = p.getInt('water') ?? 0; steps = p.getInt('steps') ?? 0; sleep = p.getDouble('sleep') ?? 0;
    wishlist.addAll(p.getStringList('wishlist') ?? []);
    aiHistory.addAll(p.getStringList('aiHistory') ?? []);
    final rawRem = p.getString('reminders'); if (rawRem != null) reminders.addAll((jsonDecode(rawRem) as Map<String,dynamic>).map((k,v)=>MapEntry(k, v as bool)));
    completedWorkouts.addAll(p.getStringList('completedWorkouts') ?? []);
    final rawCart = p.getString('cart'); if (rawCart != null) cart.addAll((jsonDecode(rawCart) as Map<String,dynamic>).map((k,v)=>MapEntry(k, v as int)));
    // Load cached weekly history
    final rawHyd = p.getString('weekly_hydration'); if (rawHyd != null) weeklyHydration = List<Map<String,dynamic>>.from((jsonDecode(rawHyd) as List).map((e) => Map<String,dynamic>.from(e as Map)));
    final rawSlp = p.getString('weekly_sleep'); if (rawSlp != null) weeklySleep = List<Map<String,dynamic>>.from((jsonDecode(rawSlp) as List).map((e) => Map<String,dynamic>.from(e as Map)));
    await loadAddresses();
    await loadOrders();
    if (Supa.ready) {
      Supa.client.auth.onAuthStateChange.listen((event) async {
        if (event.session != null) {
          await loadRemoteProfile();
          await loadRemoteActivity();
          await syncProductsAndCart();
          await loadAddresses();
          await loadOrders();
        }
        notifyListeners();
      });
      await loadRemoteProfile();
      await loadRemoteActivity();
      await syncProductsAndCart();
      await loadAddresses();
      await loadOrders();
    }
  }

  
  void addAIAdvice(String advice) {
    aiHistory.add(advice);
    persist();
    notifyListeners();
  }

  void toggleReminder(String key, String timeStr, bool value) {
    reminders[key] = value;
    persist();
    notifyListeners();
    if (value) {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int h = int.parse(timeParts[0]);
      int m = int.parse(timeParts[1]);
      if (parts[1] == 'PM' && h != 12) h += 12;
      if (parts[1] == 'AM' && h == 12) h = 0;
      NotificationService().scheduleDailyNotification(id: reminders.keys.toList().indexOf(key), title: 'NutriFit Reminder', body: 'Time for your $key!', hour: h, minute: m);
    } else {
      NotificationService().cancelNotification(reminders.keys.toList().indexOf(key));
    }
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    if (profile != null) await p.setString('profile', jsonEncode(profile!.toJson()));
    await p.setString('lang', lang); await p.setInt('water', water); await p.setInt('steps', steps); await p.setDouble('sleep', sleep);
    await p.setStringList('wishlist', wishlist.toList());
    await p.setStringList('aiHistory', aiHistory);
    await p.setString('reminders', jsonEncode(reminders));
    await p.setStringList('completedWorkouts', completedWorkouts.toList());
    await p.setString('cart', jsonEncode(cart));
    // Cache weekly history locally
    if (weeklyHydration.isNotEmpty) await p.setString('weekly_hydration', jsonEncode(weeklyHydration));
    if (weeklySleep.isNotEmpty) await p.setString('weekly_sleep', jsonEncode(weeklySleep));
    if (weeklySteps.isNotEmpty) await p.setString('weekly_steps', jsonEncode(weeklySteps));
  }

  // ── Address Management ──────────────────────────────────────────────────
  Future<void> saveAddress(DeliveryAddress addr) async {
    final idx = addresses.indexWhere((a) => a.id == addr.id);
    if (idx >= 0) {
      addresses[idx] = addr;
    } else {
      addresses.add(addr);
    }
    await persistAddresses();
    notifyListeners();
  }

  Future<void> deleteAddress(String id) async {
    addresses.removeWhere((a) => a.id == id);
    await persistAddresses();
    notifyListeners();
  }

  Future<void> persistAddresses() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('saved_addresses', jsonEncode(addresses.map((a) => a.toJson()).toList()));
    if (Supa.ready) {
      final u = Supa.client.auth.currentUser;
      if (u != null) {
        try {
          for (final a in addresses) {
            await Supa.client.from('addresses').upsert({
              'id': a.id,
              'user_id': u.id,
              'full_name': a.fullName,
              'mobile': a.mobile,
              'house_no': a.houseNo,
              'street': a.street,
              'landmark': a.landmark,
              'city': a.city,
              'district': a.district,
              'state': a.state,
              'pincode': a.pincode,
              'instructions': a.instructions,
              'is_default': a.isDefault,
            }, onConflict: 'id');
          }
        } catch (e) {
          print('⚠️ Supabase address sync error: $e');
        }
      }
    }
  }

  Future<void> loadAddresses() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('saved_addresses');
    if (raw != null) {
      try {
        final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
        addresses = list.map((e) => DeliveryAddress.fromJson(e)).toList();
      } catch (e) {
        print('Error parsing local addresses: $e');
      }
    }
    if (Supa.ready) {
      final u = Supa.client.auth.currentUser;
      if (u != null) {
        try {
          final res = await Supa.client.from('addresses').select().eq('user_id', u.id);
          final list = List<Map<String, dynamic>>.from(res);
          if (list.isNotEmpty) {
            addresses = list.map((e) => DeliveryAddress.fromJson(e)).toList();
            await p.setString('saved_addresses', jsonEncode(addresses.map((a) => a.toJson()).toList()));
          }
        } catch (e) {
          print('⚠️ Error loading remote addresses: $e');
        }
      }
    }
    notifyListeners();
  }

  // ── Order Management ─────────────────────────────────────────────────────
  String _generateUUID() {
    final random = Random();
    String hexDigit(int min, int max) => (min + random.nextInt(max - min)).toRadixString(16);
    return '${List.generate(8, (_) => hexDigit(0, 16)).join()}-'
           '${List.generate(4, (_) => hexDigit(0, 16)).join()}-'
           '4${List.generate(3, (_) => hexDigit(0, 16)).join()}-'
           '${hexDigit(8, 12)}${List.generate(3, (_) => hexDigit(0, 16)).join()}-'
           '${List.generate(12, (_) => hexDigit(0, 16)).join()}';
  }

  Future<ShopOrder> placeOrder({
    required DeliveryAddress address,
    required String paymentMethod,
    List<OrderItem>? directItems,
  }) async {
    final orderItems = directItems ?? cart.entries.map((e) {
      final prod = products.firstWhere((p) => p.id == e.key, orElse: () => const Product('', '', '', '', '', 0, '', 0));
      return OrderItem(
        productId: prod.id,
        productName: prod.name,
        brand: prod.brand,
        imagePath: prod.imagePath,
        price: prod.price,
        quantity: e.value,
      );
    }).where((item) => item.productId.isNotEmpty).toList();

    final subtotal = orderItems.fold<double>(0, (sum, i) => sum + (i.price * i.quantity));
    final deliveryCharge = subtotal >= 999 || subtotal == 0 ? 0.0 : 50.0;
    final total = subtotal + deliveryCharge;

    final orderId = _generateUUID();

    final order = ShopOrder(
      id: orderId,
      date: DateTime.now(),
      items: orderItems,
      subtotal: subtotal,
      deliveryCharge: deliveryCharge,
      totalAmount: total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == 'Cash on Delivery' ? 'Pending' : 'Paid',
      address: address,
      status: 'Confirmed',
    );

    orders.insert(0, order);
    
    if (directItems == null) {
      cart.clear();
    }
    
    await persistOrders();
    await persist();
    
    if (Supa.ready) {
      final u = Supa.client.auth.currentUser;
      if (u != null) {
        try {
          await Supa.client.from('orders').insert({
            'id': orderId,
            'user_id': u.id,
            'total_amount': total,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          });
          
          for (final item in orderItems) {
            final dbProdId = localToDbProductId[item.productId];
            if (dbProdId != null) {
              await Supa.client.from('order_items').insert({
                'order_id': orderId,
                'product_id': dbProdId,
                'quantity': item.quantity,
                'price': item.price,
              });
            }
          }
        } catch (e) {
          print('⚠️ Supabase place order error: $e');
        }
      }
    }
    
    notifyListeners();
    return order;
  }

  Future<void> cancelOrder(String orderId) async {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      final o = orders[idx];
      orders[idx] = ShopOrder(
        id: o.id,
        date: o.date,
        items: o.items,
        subtotal: o.subtotal,
        deliveryCharge: o.deliveryCharge,
        totalAmount: o.totalAmount,
        paymentMethod: o.paymentMethod,
        paymentStatus: 'Cancelled',
        address: o.address,
        status: 'Cancelled',
      );
      
      await persistOrders();
      
      if (Supa.ready) {
        try {
          await Supa.client.from('orders').update({'status': 'cancelled'}).eq('id', orderId);
        } catch (e) {
          print('⚠️ Supabase order cancellation error: $e');
        }
      }
      notifyListeners();
    }
  }

  Future<void> buyAgain(ShopOrder order) async {
    for (final item in order.items) {
      final prod = products.firstWhere((p) => p.id == item.productId, orElse: () => const Product('', '', '', '', '', 0, '', 0));
      if (prod.id.isNotEmpty) {
        cart[prod.id] = (cart[prod.id] ?? 0) + item.quantity;
        if (Supa.ready) {
          final user = Supa.client.auth.currentUser;
          if (user != null) {
            final dbId = localToDbProductId[prod.id];
            if (dbId != null) {
              try {
                await Supa.client.from('cart_items').upsert({
                  'user_id': user.id,
                  'product_id': dbId,
                  'quantity': cart[prod.id],
                  'updated_at': DateTime.now().toIso8601String(),
                }, onConflict: 'user_id,product_id');
              } catch (_) {}
            }
          }
        }
      }
    }
    await persist();
    notifyListeners();
  }

  Future<void> persistOrders() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('user_orders', jsonEncode(orders.map((o) => o.toJson()).toList()));
  }

  Future<void> loadOrders() async {
    final p = await SharedPreferences.getInstance();
    
    final raw = p.getString('user_orders');
    if (raw != null) {
      try {
        final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
        orders = list.map((e) => ShopOrder.fromJson(e)).toList();
      } catch (e) {
        print('Error parsing local orders: $e');
      }
    }

    if (Supa.ready) {
      final u = Supa.client.auth.currentUser;
      if (u != null) {
        try {
          final addrRes = await Supa.client.from('addresses').select().eq('user_id', u.id);
          final addrList = List<Map<String, dynamic>>.from(addrRes).map((e) => DeliveryAddress.fromJson(e)).toList();
          final defaultAddr = addrList.firstWhere((a) => a.isDefault, orElse: () => addrList.isNotEmpty ? addrList.first : DeliveryAddress(
            id: 'default',
            fullName: profile?.name.isNotEmpty == true ? profile!.name : 'NutriFit User',
            mobile: '9876543210',
            houseNo: 'Flat 101',
            street: 'Main Road',
            city: 'Chennai',
            district: 'Chennai',
            state: 'Tamil Nadu',
            pincode: '600001',
          ));

          final res = await Supa.client.from('orders')
              .select('*, order_items(*)')
              .eq('user_id', u.id)
              .order('created_at', ascending: false);
              
          final orderRows = List<Map<String, dynamic>>.from(res);
          
          List<ShopOrder> remoteOrders = [];
          for (final row in orderRows) {
            final orderId = row['id']?.toString() ?? '';
            final totalAmount = double.tryParse('${row['total_amount'] ?? 0}') ?? 0.0;
            final dbStatus = (row['status'] ?? 'pending').toString().toLowerCase();
            final createdAtStr = row['created_at']?.toString();
            final date = createdAtStr != null ? DateTime.tryParse(createdAtStr) ?? DateTime.now() : DateTime.now();

            String preciseStatus = 'Confirmed';
            if (dbStatus == 'cancelled') {
              preciseStatus = 'Cancelled';
            } else if (dbStatus == 'delivered') {
              preciseStatus = 'Delivered';
            } else {
              final diff = DateTime.now().difference(date);
              if (diff.inHours < 2) {
                preciseStatus = 'Confirmed';
              } else if (diff.inHours < 6) {
                preciseStatus = 'Packed';
              } else if (diff.inHours < 24) {
                preciseStatus = 'Shipped';
              } else if (diff.inHours < 48) {
                preciseStatus = 'Out for Delivery';
              } else {
                preciseStatus = 'Delivered';
              }
            }

            final itemsRaw = List<Map<String, dynamic>>.from(row['order_items'] ?? []);
            List<OrderItem> orderItems = [];
            for (final itemRow in itemsRaw) {
              final dbProdId = itemRow['product_id']?.toString() ?? '';
              final qty = itemRow['quantity'] as int? ?? 1;
              final price = double.tryParse('${itemRow['price'] ?? 0}') ?? 0.0;

              final localId = dbToLocalProductId[dbProdId];
              final prod = products.firstWhere((p) => p.id == localId, orElse: () => const Product('', '', '', '', '', 0, '', 0));

              orderItems.add(OrderItem(
                productId: localId ?? '',
                productName: prod.name.isNotEmpty ? prod.name : 'Unknown Product',
                brand: prod.brand.isNotEmpty ? prod.brand : 'NutriFit',
                imagePath: prod.imagePath.isNotEmpty ? prod.imagePath : 'assets/images/product_gnc.png',
                price: price,
                quantity: qty,
              ));
            }

            final subtotal = orderItems.fold<double>(0, (sum, i) => sum + (i.price * i.quantity));
            final deliveryCharge = totalAmount - subtotal;

            remoteOrders.add(ShopOrder(
              id: orderId,
              date: date,
              items: orderItems,
              subtotal: subtotal,
              deliveryCharge: deliveryCharge,
              totalAmount: totalAmount,
              paymentMethod: 'Cash on Delivery',
              paymentStatus: preciseStatus == 'Delivered' ? 'Paid' : (preciseStatus == 'Cancelled' ? 'Cancelled' : 'Pending'),
              address: defaultAddr,
              status: preciseStatus,
            ));
          }

          final mergedOrders = <String, ShopOrder>{};
          for (final o in remoteOrders) {
            mergedOrders[o.id] = o;
          }
          for (final o in orders) {
            if (mergedOrders.containsKey(o.id)) {
              final remote = mergedOrders[o.id]!;
              mergedOrders[o.id] = ShopOrder(
                id: o.id,
                date: remote.date,
                items: o.items,
                subtotal: o.subtotal,
                deliveryCharge: o.deliveryCharge,
                totalAmount: remote.totalAmount,
                paymentMethod: o.paymentMethod,
                paymentStatus: remote.paymentStatus,
                address: o.address,
                status: remote.status,
              );
            } else {
              mergedOrders[o.id] = o;
            }
          }

          orders = mergedOrders.values.toList();
          orders.sort((a, b) => b.date.compareTo(a.date));
          await p.setString('user_orders', jsonEncode(orders.map((o) => o.toJson()).toList()));
        } catch (e) {
          print('⚠️ Supabase order load error: $e');
        }
      }
    }
    notifyListeners();
  }

  // ── Load today's activity from Supabase ──
  Future<void> loadRemoteActivity() async {
    if (!Supa.ready) return;
    final u = Supa.client.auth.currentUser;
    if (u == null) return;
    try {
      // Hydration
      final hydRow = await Supa.client.from('hydration_logs').select()
          .eq('user_id', u.id).eq('log_date', _today).maybeSingle();
      water = (hydRow != null) ? (hydRow['water_ml'] as int? ?? 0) : 0;

      // Sleep
      final sleepRow = await Supa.client.from('sleep_logs').select()
          .eq('user_id', u.id).eq('log_date', _today).maybeSingle();
      sleep = (sleepRow != null) ? (double.tryParse('${sleepRow['sleep_hours']}') ?? 0) : 0;

      // Steps
      final stepsRow = await Supa.client.from('progress_logs').select()
          .eq('user_id', u.id).eq('log_date', _today).maybeSingle();
      steps = (stepsRow != null) ? (stepsRow['steps'] as int? ?? 0) : 0;

      // Habits
      final habitRows = await Supa.client.from('habit_logs').select()
          .eq('user_id', u.id).eq('log_date', _today);
      habits.clear();
      for (final row in List<Map<String, dynamic>>.from(habitRows)) {
        final name = row['habit_name']?.toString() ?? '';
        final done = row['is_done'] as bool? ?? false;
        if (name.isNotEmpty) habits[name] = done;
      }

      // Wishlist
      final wishRows = await Supa.client.from('wishlist_items').select()
          .eq('user_id', u.id);
      wishlist.clear();
      for (final row in List<Map<String, dynamic>>.from(wishRows)) {
        final dbProdId = row['product_id']?.toString() ?? '';
        final localId = dbToLocalProductId[dbProdId];
        if (localId != null) wishlist.add(localId);
      }

      await loadWeeklyHistory();
      await persist();
      notifyListeners();
    } catch (e) {
      print('⚠️ Error loading remote activity: $e');
    }
  }

  /// Fetches the last 7 days of hydration, sleep and steps from Supabase.
  /// Falls back to SharedPreferences cache, then seeds with today's data.
  Future<void> loadWeeklyHistory() async {
    final now = DateTime.now();
    final last7 = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    });

    if (Supa.ready) {
      final u = Supa.client.auth.currentUser;
      if (u != null) {
        try {
          final hydRows = await Supa.client.from('hydration_logs')
              .select('log_date, water_ml, target_ml')
              .eq('user_id', u.id)
              .gte('log_date', last7.first)
              .order('log_date');
          final sleepRows = await Supa.client.from('sleep_logs')
              .select('log_date, sleep_hours')
              .eq('user_id', u.id)
              .gte('log_date', last7.first)
              .order('log_date');
          final stepsRows = await Supa.client.from('progress_logs')
              .select('log_date, steps, calories_burned')
              .eq('user_id', u.id)
              .gte('log_date', last7.first)
              .order('log_date');

          final hydMap = {for (final r in List<Map<String,dynamic>>.from(hydRows)) r['log_date'].toString(): r};
          final sleepMap = {for (final r in List<Map<String,dynamic>>.from(sleepRows)) r['log_date'].toString(): r};
          final stepsMap = {for (final r in List<Map<String,dynamic>>.from(stepsRows)) r['log_date'].toString(): r};

          weeklyHydration = last7.map((d) => {
            'date': d,
            'water_ml': (hydMap[d]?['water_ml'] as int?) ?? (d == _today ? water : 0),
            'target_ml': (hydMap[d]?['target_ml'] as int?) ?? waterGoal,
          }).toList();
          weeklySleep = last7.map((d) => {
            'date': d,
            'sleep_hours': double.tryParse('${sleepMap[d]?['sleep_hours'] ?? 0}') ?? (d == _today ? sleep : 0.0),
          }).toList();
          weeklySteps = last7.map((d) => {
            'date': d,
            'steps': (stepsMap[d]?['steps'] as int?) ?? (d == _today ? steps : 0),
            'calories_burned': (stepsMap[d]?['calories_burned'] as int?) ?? (d == _today ? (steps * 0.04).round() : 0),
          }).toList();

          notifyListeners();
          return;
        } catch (e) {
          print('⚠️ Weekly history fetch error: $e');
        }
      }
    }

    // Offline fallback: seed with today's values if empty
    if (weeklyHydration.isEmpty) {
      weeklyHydration = last7.map((d) => {'date': d, 'water_ml': d == _today ? water : 0, 'target_ml': waterGoal}).toList();
      weeklySleep = last7.map((d) => {'date': d, 'sleep_hours': d == _today ? sleep : 0.0}).toList();
      weeklySteps = last7.map((d) => {'date': d, 'steps': d == _today ? steps : 0, 'calories_burned': d == _today ? (steps * 0.04).round() : 0}).toList();
      notifyListeners();
    }
  }

  // ── Sync individual trackers to Supabase ──
  Future<void> _syncHydration() async {
    if (!Supa.ready) return;
    final u = Supa.client.auth.currentUser; if (u == null) return;
    try {
      await Supa.client.from('hydration_logs').upsert({
        'user_id': u.id, 'log_date': _today, 'water_ml': water, 'target_ml': waterGoal,
      }, onConflict: 'user_id,log_date');
    } catch (e) { print('⚠️ Hydration sync error: $e'); }
  }

  Future<void> _syncSleep() async {
    if (!Supa.ready) return;
    final u = Supa.client.auth.currentUser; if (u == null) return;
    try {
      await Supa.client.from('sleep_logs').upsert({
        'user_id': u.id, 'log_date': _today, 'sleep_hours': sleep,
      }, onConflict: 'user_id,log_date');
    } catch (e) { print('⚠️ Sleep sync error: $e'); }
  }

  Future<void> _syncSteps() async {
    if (!Supa.ready) return;
    final u = Supa.client.auth.currentUser; if (u == null) return;
    try {
      await Supa.client.from('progress_logs').upsert({
        'user_id': u.id, 'log_date': _today, 'steps': steps,
        'calories_burned': (steps * 0.04).round(),
      }, onConflict: 'user_id,log_date');
    } catch (e) { print('⚠️ Steps sync error: $e'); }
  }

  Future<void> _syncHabit(String habit, bool done) async {
    if (!Supa.ready) return;
    final u = Supa.client.auth.currentUser; if (u == null) return;
    try {
      await Supa.client.from('habit_logs').upsert({
        'user_id': u.id, 'habit_name': habit, 'log_date': _today, 'is_done': done,
      }, onConflict: 'user_id,habit_name,log_date');
    } catch (e) { print('⚠️ Habit sync error: $e'); }
  }

  Future<void> _syncWishlistItem(Product p, bool add) async {
    if (!Supa.ready) return;
    final u = Supa.client.auth.currentUser; if (u == null) return;
    final dbId = localToDbProductId[p.id]; if (dbId == null) return;
    try {
      if (add) {
        await Supa.client.from('wishlist_items').upsert({
          'user_id': u.id, 'product_id': dbId,
        }, onConflict: 'user_id,product_id');
      } else {
        await Supa.client.from('wishlist_items').delete()
            .eq('user_id', u.id).eq('product_id', dbId);
      }
    } catch (e) { print('⚠️ Wishlist sync error: $e'); }
  }

  Future<void> syncProductsAndCart() async {
    if (!Supa.ready) return;
    final user = Supa.client.auth.currentUser;
    try {
      final res = await Supa.client.from('products').select();
      final list = List<Map<String, dynamic>>.from(res);
      localToDbProductId.clear();
      dbToLocalProductId.clear();
      for (final row in list) {
        final dbId = row['id']?.toString() ?? '';
        final name = row['name']?.toString() ?? '';
        final matching = products.firstWhere((p) => p.name == name, orElse: () => const Product('', '', '', '', '', 0, '', 0));
        if (matching.id.isNotEmpty) {
          localToDbProductId[matching.id] = dbId;
          dbToLocalProductId[dbId] = matching.id;
        }
      }
      
      if (user != null) {
        final cartRes = await Supa.client.from('cart_items').select().eq('user_id', user.id);
        final cartList = List<Map<String, dynamic>>.from(cartRes);
        cart.clear();
        for (final item in cartList) {
          final dbProdId = item['product_id']?.toString() ?? '';
          final qty = item['quantity'] as int? ?? 1;
          final localId = dbToLocalProductId[dbProdId];
          if (localId != null) {
            cart[localId] = qty;
          }
        }
        await persist();
        notifyListeners();
      }
    } catch (e) {
      print('⚠️ Error syncing products/cart: $e');
    }
  }

  Future<String?> login(String email, String pass) async => run(() async {
    if (email.trim().isEmpty || pass.trim().isEmpty) throw 'Enter email and password';
    if (!Supa.ready) {
      demo = true;
      profile = (profile ?? Profile()).copy(
        email: email.trim(),
        name: profile?.name.isNotEmpty == true ? profile!.name : 'NutriFit User',
      );
      water = 0; steps = 0; sleep = 0; habits.clear(); completedWorkouts.clear();
      await persist();
      return;
    }
    try {
      final res = await Supa.client.auth.signInWithPassword(
        email: email.trim(),
        password: pass.trim(),
      );
      print('✅ Login successful, user id: ${res.user?.id}');
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
    await loadRemoteProfile();
    await loadRemoteActivity();
    await syncProductsAndCart();
  });

  Future<String?> signUp(String name, String email, String pass) async => run(() async {
    if (name.trim().isEmpty || email.trim().isEmpty || pass.length<6) throw 'Enter name, email, and 6 character password';
    if (!Supa.ready) { demo=true; profile=Profile(name:name.trim(), email:email.trim(), lang:lang); water=0; steps=0; sleep=0; habits.clear(); await persist(); return; }
    final r = await Supa.client.auth.signUp(email: email.trim(), password: pass.trim(), data: {'full_name': name.trim()});
    profile=Profile(id:r.user?.id ?? 'demo-user', name:name.trim(), email:email.trim(), lang:lang); await saveProfile();
    water=0; steps=0; sleep=0; habits.clear(); completedWorkouts.clear();
    await syncProductsAndCart();
  });

  Future<String?> googleLogin() async => run(() async {
    if (!Supa.ready) { demo=true; profile=(profile??Profile()).copy(name:'Google User', email:'google.user@nutrifit.local'); await persist(); return; }
    await Supa.client.auth.signInWithOAuth(OAuthProvider.google, redirectTo: dotenv.env['SUPABASE_REDIRECT_URL'] ?? 'io.supabase.nutrifit://login-callback/');
  });

  Future<String?> reset(String email) async => run(() async {
    if (email.trim().isEmpty) throw 'Enter email';
    if (Supa.ready) await Supa.client.auth.resetPasswordForEmail(email.trim(), redirectTo: 'io.supabase.nutrifit://reset-callback/');
  });

  Future<String?> run(Future<void> Function() f) async { try { busy=true; notifyListeners(); await f(); return null; } on AuthException catch(e){ return e.message; } catch(e){ return e.toString(); } finally { busy=false; notifyListeners(); } }
  void draft({String? goal, String? gender, String? food, String? location, int? age, double? height, double? weight, bool? onboardingCompleted}) { profile = (profile ?? Profile()).copy(goal: goal, gender: gender, food: food, location: location, age: age, height: height, weight: weight, lang: lang, onboardingCompleted: onboardingCompleted); notifyListeners(); }
  
  Future<void> saveProfile() async {
    if (profile==null) return; await persist();
    if (!Supa.ready) return; final u=Supa.client.auth.currentUser; if (u==null) return;
    profile=profile!.copy(id:u.id, email:u.email ?? profile!.email);
    await Supa.client.from('profiles').upsert(profile!.profileJson(u.id));
    if (profile!.goal.isNotEmpty) await Supa.client.from('goals').insert({'user_id':u.id,'goal':profile!.goal,'target_weight_kg':profile!.weight,'target_height_cm':profile!.height,'status':'active'});
  }

  Future<void> loadRemoteProfile() async {
    final u=Supa.client.auth.currentUser; if (u==null) return;
    final data=await Supa.client.from('profiles').select().eq('id', u.id).maybeSingle();
    if (data != null) { profile=Profile.from(Map<String,dynamic>.from(data)).copy(email:u.email??''); lang=profile!.lang; await persist(); }
  }

  Future<void> logout() async {
    if (Supa.ready) await Supa.client.auth.signOut();
    profile=null; demo=false; cart.clear(); wishlist.clear(); completedWorkouts.clear();
    water=0; steps=0; sleep=0; habits.clear();
    final p=await SharedPreferences.getInstance();
    await p.remove('profile');
    await p.remove('cart');
    await p.remove('wishlist');
    await p.remove('completedWorkouts');
    await p.setInt('water', 0);
    await p.setInt('steps', 0);
    await p.setDouble('sleep', 0);
    notifyListeners();
  }

  void setLang(String v){ lang=v; if(profile!=null){profile!.lang=v; if(Supa.ready) Supa.client.from('profiles').update({'preferred_language':v}).eq('id',profile!.id);} persist(); notifyListeners(); }
  void waterAdd(int v){ water=(water+v).clamp(0,6000); _updateTodayInWeeklyHydration(); persist(); _syncHydration(); notifyListeners(); }
  void waterSet(int ml){ water=ml.clamp(0,6000); _updateTodayInWeeklyHydration(); persist(); _syncHydration(); notifyListeners(); }
  void stepsAdd(int v){ steps=(steps+v).clamp(0,50000); _updateTodayInWeeklySteps(); persist(); _syncSteps(); notifyListeners(); }
  void sleepSet(double v){ sleep=v.clamp(0,14); _updateTodayInWeeklySleep(); persist(); _syncSleep(); notifyListeners(); }

  /// Updates the today entry in weeklyHydration without a full Supabase round-trip.
  void _updateTodayInWeeklyHydration() {
    if (weeklyHydration.isEmpty) { loadWeeklyHistory(); return; }
    final idx = weeklyHydration.indexWhere((d) => d['date'] == _today);
    if (idx >= 0) weeklyHydration[idx] = {'date': _today, 'water_ml': water, 'target_ml': waterGoal};
  }

  void _updateTodayInWeeklySteps() {
    if (weeklySteps.isEmpty) { loadWeeklyHistory(); return; }
    final idx = weeklySteps.indexWhere((d) => d['date'] == _today);
    if (idx >= 0) weeklySteps[idx] = {'date': _today, 'steps': steps, 'calories_burned': (steps * 0.04).round()};
  }

  void _updateTodayInWeeklySleep() {
    if (weeklySleep.isEmpty) { loadWeeklyHistory(); return; }
    final idx = weeklySleep.indexWhere((d) => d['date'] == _today);
    if (idx >= 0) weeklySleep[idx] = {'date': _today, 'sleep_hours': sleep};
  }
  void toggleHabit(String h){ habits[h]=!(habits[h]??false); _syncHabit(h, habits[h]!); notifyListeners(); }
  void toggleWish(Product p){ final adding = !wishlist.contains(p.id); wishlist.contains(p.id) ? wishlist.remove(p.id) : wishlist.add(p.id); persist(); _syncWishlistItem(p, adding); notifyListeners(); }
  void toggleWorkoutCompleted(String day){ if(completedWorkouts.contains(day)) completedWorkouts.remove(day); else completedWorkouts.add(day); persist(); notifyListeners(); }

  Future<void> addCart(Product p) async {
    cart[p.id] = (cart[p.id] ?? 0) + 1;
    await persist();
    notifyListeners();

    if (Supa.ready) {
      final user = Supa.client.auth.currentUser;
      if (user != null) {
        final dbId = localToDbProductId[p.id];
        if (dbId != null) {
          try {
            await Supa.client.from('cart_items').upsert({
              'user_id': user.id,
              'product_id': dbId,
              'quantity': cart[p.id],
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'user_id,product_id');
          } catch (e) {
            print('⚠️ Error adding to Supabase cart: $e');
          }
        }
      }
    }
  }

  Future<void> removeCart(Product p) async {
    final n = (cart[p.id] ?? 0) - 1;
    if (n <= 0) {
      cart.remove(p.id);
    } else {
      cart[p.id] = n;
    }
    await persist();
    notifyListeners();

    if (Supa.ready) {
      final user = Supa.client.auth.currentUser;
      if (user != null) {
        final dbId = localToDbProductId[p.id];
        if (dbId != null) {
          try {
            if (n <= 0) {
              await Supa.client.from('cart_items').delete().eq('user_id', user.id).eq('product_id', dbId);
            } else {
              await Supa.client.from('cart_items').upsert({
                'user_id': user.id,
                'product_id': dbId,
                'quantity': n,
                'updated_at': DateTime.now().toIso8601String(),
              }, onConflict: 'user_id,product_id');
            }
          } catch (e) {
            print('⚠️ Error removing from Supabase cart: $e');
          }
        }
      }
    }
  }

  Future<void> deleteCart(Product p) async {
    cart.remove(p.id);
    await persist();
    notifyListeners();

    if (Supa.ready) {
      final user = Supa.client.auth.currentUser;
      if (user != null) {
        final dbId = localToDbProductId[p.id];
        if (dbId != null) {
          try {
            await Supa.client.from('cart_items').delete().eq('user_id', user.id).eq('product_id', dbId);
          } catch (e) {
            print('⚠️ Error deleting from Supabase cart: $e');
          }
        }
      }
    }
  }

  void setTab(int i){ tab=i; notifyListeners(); }
}

const strings = {
'en': {'app':'NutriFit','tag':'Your Health, Your Care','login':'Login','signup':'Sign Up','email':'Email','password':'Password','name':'Full Name','forgot':'Forgot Password','google':'Continue with Google','continue':'Continue','dashboard':'Dashboard','plans':'Plans','trackers':'Trackers','shop':'Shop','profile':'Profile','goal':'Choose your fitness goal','gender':'Select your gender','age':'Enter your age','height':'Enter your height','weight':'Enter your weight','food':'Choose food preference','location':'Where will you workout?','ai':'AI Trainer','water':'Hydration','sleep':'Sleep','steps':'Steps','habits':'Daily Habits','calorie':'Calorie Calculator','weeklyWorkout':'Weekly Workout Split','weeklyDiet':'Weekly Diet Plan','budget':'Budget Diet Plan','warmup':'Stretching & Warm-up','settings':'Settings','logout':'Logout','language':'Language'},
'ta': {'app':'NutriFit','tag':'உங்கள் ஆரோக்கியம், உங்கள் கவனம்','login':'உள்நுழை','signup':'பதிவு செய்','email':'மின்னஞ்சல்','password':'கடவுச்சொல்','name':'முழு பெயர்','forgot':'கடவுச்சொல் மறந்துவிட்டதா','google':'Google மூலம் தொடரவும்','continue':'தொடரவும்','dashboard':'Dashboard','plans':'Plan','trackers':'Tracker','shop':'Shop','profile':'Profile','goal':'உங்கள் fitness goal தேர்வு செய்யவும்','gender':'பாலினத்தை தேர்வு செய்யவும்','age':'வயதை உள்ளிடவும்','height':'உயரத்தை உள்ளிடவும்','weight':'எடையை உள்ளிடவும்','food':'உணவு விருப்பம் தேர்வு செய்யவும்','location':'எங்கு workout செய்வீர்கள்?','ai':'AI Trainer','water':'தண்ணீர்','sleep':'தூக்கம்','steps':'நடைகள்','habits':'தினசரி பழக்கம்','calorie':'கலோரி கணக்கீடு','weeklyWorkout':'வார workout split','weeklyDiet':'வார diet plan','budget':'Budget diet plan','warmup':'Stretching & Warm-up','settings':'Settings','logout':'வெளியேறு','language':'மொழி'}
};
const goals=['Weight Loss','Weight Gain','Increase Height','Calisthenics','Maintain Weight','Improve Stamina','General Fitness'];
const genders=['Male','Female','Other']; const foods=['Vegetarian','Non-Vegetarian','Eggetarian']; const locations=['Gym Workout','Home Workout'];
const habits=['Drink 3L water','Complete workout','Eat protein with every meal','Sleep before 11 PM','10 minutes stretching','No junk food today'];
const products=[
Product('gnc-weight-gainer','GNC','GNC Pro Performance Weight Gainer (Chocolate)','Protein','Weight gainer for muscle building.',2999,'assets/images/shop/gnc/gnc_weight_gainer.png',4.5),
Product('gnc-whey','GNC','GNC Whey Protein','Protein','Protein support for muscle recovery.',2499,'assets/images/shop/gnc/gnc_whey_protein.png',4.6),
Product('gnc-amp-gold','GNC','GNC AMP Gold Whey','Protein','Advanced whey isolate.',3299,'assets/images/shop/gnc/gnc_amp_gold_whey.png',4.8),
Product('gnc-creatine','GNC','GNC Creatine Monohydrate','Performance','Performance and strength.',899,'assets/images/shop/gnc/gnc_creatine.png',4.7),
Product('gnc-multi','GNC','GNC Multivitamin','Wellness','Daily wellness support.',1299,'assets/images/shop/gnc/gnc_multivitamin.png',4.5),
Product('gnc-fish-oil','GNC','GNC Fish Oil','Wellness','Omega 3 support.',999,'assets/images/shop/gnc/gnc_fish_oil.png',4.6),
Product('gnc-bcaa','GNC','GNC BCAA','Performance','Intra-workout recovery.',1499,'assets/images/shop/gnc/gnc_bcaa.png',4.4),
Product('gnc-l-carnitine','GNC','GNC L-Carnitine','Performance','Fat metabolism support.',1199,'assets/images/shop/gnc/gnc_l_carnitine.png',4.3),
Product('mb-whey','MuscleBlaze','MuscleBlaze Biozyme Whey','Protein','Recovery protein for workouts.',2199,'assets/images/shop/muscleblaze/mb_whey.png',4.7),
Product('mb-creatine','MuscleBlaze','MuscleBlaze Creatine','Performance','Performance support.',899,'assets/images/shop/muscleblaze/mb_creatine.png',4.4),
Product('ywf-band','YouWeFit','YouWeFit Resistance Band','Equipment','Home workout equipment.',499,'assets/images/shop/youwefit/ywf_band.png',4.3),
Product('ywf-shaker','YouWeFit','YouWeFit Shaker Bottle','Accessories','Protein and water shaker.',299,'assets/images/shop/youwefit/ywf_shaker.png',4.2),
];

class WorkoutDayDetails {
  final String dayName;
  final String workoutTitle;
  final List<String> warmup;
  final List<String> exercises;
  final String restTime;
  final String duration;
  final List<String> cooldown;
  final String beginnerInstructions;
  final String safetyTips;

  WorkoutDayDetails({
    required this.dayName,
    required this.workoutTitle,
    required this.warmup,
    required this.exercises,
    required this.restTime,
    required this.duration,
    required this.cooldown,
    required this.beginnerInstructions,
    required this.safetyTips,
  });
}

class DietDayDetails {
  final String dayName;
  final String breakfast;
  final String midMorningSnack;
  final String lunch;
  final String eveningSnack;
  final String dinner;
  final int calories;
  final int protein;
  final String budgetTips;
  final String foodsToAvoid;

  DietDayDetails({
    required this.dayName,
    required this.breakfast,
    required this.midMorningSnack,
    required this.lunch,
    required this.eveningSnack,
    required this.dinner,
    required this.calories,
    required this.protein,
    required this.budgetTips,
    required this.foodsToAvoid,
  });
}

List<WorkoutDayDetails> getWeeklyWorkoutDetails(String goal, String location) {
  final isHome = location == 'Home Workout';
  final List<WorkoutDayDetails> list = [];
  final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  for (int i = 0; i < 7; i++) {
    final day = days[i];
    String title = '';
    List<String> warmup = [];
    List<String> exercises = [];
    String rest = '45 to 60 seconds between sets';
    String duration = '45 minutes';
    List<String> cooldown = [];
    String instructions = '';
    String safety = '';
    
    warmup = [
      'Jumping jacks - 2 minutes',
      'Arm circles - 1 minute',
      'Hip rotations - 1 minute'
    ];
    
    cooldown = [
      'Hamstring stretch - 1 minute',
      'Shoulder stretch - 1 minute',
      'Deep breathing - 2 minutes'
    ];

    if (goal == 'Weight Gain') {
      if (day == 'Monday') {
        title = 'Chest & Triceps';
        exercises = isHome 
          ? ['Push-ups - 3 sets x 12 reps', 'Decline Push-ups - 3 sets x 10 reps', 'Dips on chair - 3 sets x 12 reps', 'Diamond Push-ups - 3 sets x 8 reps']
          : ['Barbell Bench Press - 4 sets x 10 reps', 'Incline Dumbbell Press - 3 sets x 12 reps', 'Cable Chest Flyes - 3 sets x 15 reps', 'Tricep Rope Pushdowns - 3 sets x 12 reps'];
        instructions = 'Focus on progressive overload. Rest 90s between main compound lifts.';
        safety = 'Keep your back slightly arched on bench press, feet flat on the floor.';
      } else if (day == 'Tuesday') {
        title = 'Back & Biceps';
        exercises = isHome
          ? ['Pull-ups (or Doorway Rows) - 4 sets x 8 reps', 'Resistance Band Rows - 3 sets x 15 reps', 'Bicep curls with resistance band - 3 sets x 12 reps', 'Plank - 3 sets x 45 seconds']
          : ['Lat Pulldown - 4 sets x 12 reps', 'Bent Over Barbell Rows - 3 sets x 10 reps', 'Dumbbell Bicep Curls - 3 sets x 12 reps', 'Hammer Curls - 3 sets x 12 reps'];
        instructions = 'Squeeze your shoulder blades together at the top of each row.';
        safety = 'Keep spine neutral; do not round your lower back during rows.';
      } else if (day == 'Wednesday') {
        title = 'Legs & Core';
        exercises = isHome
          ? ['Bodyweight Squats - 4 sets x 20 reps', 'Walking Lunges - 3 sets x 15 reps per leg', 'Glute Bridges - 3 sets x 20 reps', 'Calf Raises - 3 sets x 25 reps']
          : ['Barbell Squats - 4 sets x 10 reps', 'Leg Press - 3 sets x 12 reps', 'Leg Curls - 3 sets x 12 reps', 'Standing Calf Raises - 4 sets x 15 reps'];
        instructions = 'Go deep on squats to activate the glutes and hamstrings fully.';
        safety = 'Ensure knees track in line with toes; do not let knees cave inward.';
      } else if (day == 'Thursday') {
        title = 'Rest & Recovery';
        exercises = ['Active mobility work - 15 minutes', 'Light walking - 20 minutes'];
        warmup = ['Neck rolls - 1 minute', 'Shoulder shrugs - 1 minute'];
        cooldown = ['Child pose - 2 minutes', 'Cobra stretch - 2 minutes'];
        duration = '20 minutes';
        instructions = 'Allow your muscles to recover and synthesize protein.';
        safety = 'Focus on hydration and good nutrition today.';
      } else if (day == 'Friday') {
        title = 'Shoulders & Arms';
        exercises = isHome
          ? ['Pike Push-ups - 3 sets x 10 reps', 'Resistance Band Shoulder Press - 3 sets x 15 reps', 'Band Lateral Raises - 3 sets x 15 reps', 'Chair Dips - 3 sets x 12 reps']
          : ['Overhead Barbell Press - 4 sets x 10 reps', 'Dumbbell Lateral Raises - 3 sets x 12 reps', 'Rear Delt Flyes - 3 sets x 15 reps', 'Barbell Bicep Curls - 3 sets x 10 reps'];
        instructions = 'Keep core engaged during overhead press to protect lower back.';
        safety = 'Avoid flaring elbows out excessively during shoulder pressing.';
      } else if (day == 'Saturday') {
        title = 'Full Body Strength';
        exercises = isHome
          ? ['Burpees - 3 sets x 10 reps', 'Bulgarian Split Squats - 3 sets x 12 reps per leg', 'Push-ups - 3 sets x 15 reps', 'Plank to Push-up - 3 sets x 10 reps']
          : ['Deadlifts - 3 sets x 8 reps', 'Dumbbell Lunges - 3 sets x 12 reps per leg', 'Pull-ups - 3 sets x max reps', 'Dips - 3 sets x 10 reps'];
        instructions = 'A heavy full body day. Warm up thoroughly.';
        safety = 'Maintain a solid core brace during deadlifts.';
      } else {
        title = 'Active Rest & Stretching';
        exercises = ['Full body static stretching - 20 minutes', 'Deep breathing exercises - 5 minutes'];
        duration = '25 minutes';
        instructions = 'Gentle stretching to enhance muscle repair.';
        safety = 'Never stretch to the point of pain; keep it comfortable.';
      }
    } else if (goal == 'Weight Loss') {
      if (day == 'Monday') {
        title = 'Full Body Strength + Cardio';
        exercises = isHome
          ? ['Jumping Squats - 3 sets x 15 reps', 'Mountain Climbers - 3 sets x 30 seconds', 'Push-ups - 3 sets x 12 reps', 'Bicycle Crunches - 3 sets x 20 reps']
          : ['Thrusters - 3 sets x 12 reps', 'Kettlebell Swings - 3 sets x 20 reps', 'Lat Pulldowns - 3 sets x 12 reps', 'Treadmill Incline Walk - 15 minutes'];
        instructions = 'Keep intensity high and rest short (30-45s) between sets.';
        safety = 'Focus on landing softly on your feet during jumping exercises.';
      } else if (day == 'Tuesday') {
        title = 'HIIT + Core';
        exercises = isHome
          ? ['Burpees - 4 sets x 10 reps', 'High Knees - 4 sets x 40 seconds', 'Plank - 3 sets x 60 seconds', 'Russian Twists - 3 sets x 20 reps']
          : ['Rowing Machine - 4 sets x 500m sprint', 'Medicine Ball Slams - 3 sets x 15 reps', 'Hanging Leg Raises - 3 sets x 12 reps', 'Woodchoppers - 3 sets x 15 reps per side'];
        instructions = 'Perform at maximum effort during the intervals.';
        safety = 'Ensure your back does not round during woodchoppers or swings.';
      } else if (day == 'Wednesday') {
        title = 'Lower Body Cardio';
        exercises = isHome
          ? ['Sumo Squats - 4 sets x 20 reps', 'Reverse Lunges - 3 sets x 15 reps per leg', 'Donkey Kicks - 3 sets x 20 reps', 'Calf Raises - 3 sets x 25 reps']
          : ['Goblet Squats - 4 sets x 12 reps', 'Lying Leg Curls - 3 sets x 15 reps', 'Leg Extensions - 3 sets x 15 reps', 'Stairmaster - 15 minutes'];
        instructions = 'Keep moving with minimal rest to burn maximum calories.';
        safety = 'Push through your heels during squats and lunges.';
      } else if (day == 'Thursday') {
        title = 'Mobility & Light Cardio';
        exercises = ['Yin Yoga or stretching - 20 minutes', 'Brisk walking - 30 minutes'];
        duration = '50 minutes';
        instructions = 'Promotes recovery and fat oxidation without heavy stress.';
        safety = 'Listen to your body. Keep cardio at a conversational pace.';
      } else if (day == 'Friday') {
        title = 'Upper Body + Cycling';
        exercises = isHome
          ? ['Dolphin Push-ups - 3 sets x 10 reps', 'Doorway Rows - 3 sets x 12 reps', 'Band Tricep Press - 3 sets x 15 reps', 'Shadow Boxing - 5 minutes']
          : ['Dumbbell Shoulder Press - 3 sets x 12 reps', 'Seated Cable Row - 3 sets x 15 reps', 'Push-ups - 3 sets x max reps', 'Stationary Bike - 15 minutes'];
        instructions = 'Keep upper body muscles active while adding cardio.';
        safety = 'Adjust bike seat height so your knees are slightly bent at the bottom.';
      } else if (day == 'Saturday') {
        title = 'Fat-Loss Circuit';
        exercises = isHome
          ? ['Burpees - 3 circuits x 10 reps', 'Squats - 3 circuits x 15 reps', 'Jumping Jacks - 3 circuits x 30 reps', 'Plank - 3 circuits x 45 seconds']
          : ['Deadlifts - 3 sets x 10 reps', 'Dumbbell Clean and Press - 3 sets x 10 reps', 'Box Jumps - 3 sets x 12 reps', 'Elliptical Trainer - 15 minutes'];
        instructions = 'Move from one exercise to the next with minimal rest.';
        safety = 'Keep your back flat when picking up weights from the floor.';
      } else {
        title = 'Rest & Long Walk';
        exercises = ['Outdoor walking - 45 minutes', 'Full body stretching - 15 minutes'];
        duration = '60 minutes';
        instructions = 'Low intensity active recovery to flush out lactic acid.';
        safety = 'Stay hydrated and dress comfortably.';
      }
    } else if (goal == 'Increase Height') {
      if (day == 'Monday') {
        title = 'Cobra Stretch, Hanging, Pelvic Tilt';
        exercises = ['Bar Hanging - 3 sets x 45 seconds', 'Cobra Stretch - 3 sets x 30 seconds', 'Pelvic Tilt - 3 sets x 15 reps', 'Dry Land Swim - 3 sets x 30 seconds'];
        instructions = 'Focus on spinal decompression. Stretch as far as comfortable.';
        safety = 'Ensure your grip is secure when hanging. Do not drop suddenly.';
      } else if (day == 'Tuesday') {
        title = 'Skipping & Posture Drills';
        exercises = ['Rope Skipping - 5 sets x 1 minute', 'Wall Posture Alignment - 3 sets x 2 minutes', 'Forward Spine Stretch - 3 sets x 30 seconds', 'Plank - 3 sets x 45 seconds'];
        instructions = 'Jump on the balls of your feet. Keep head up and spine aligned.';
        safety = 'Ensure you have supportive footwear to absorb the jump impacts.';
      } else if (day == 'Wednesday') {
        title = 'Cat-Cow, Bridge & Mobility';
        exercises = ['Cat-Cow Stretch - 4 sets x 10 reps', 'Glute Bridge - 3 sets x 15 reps', 'Supermans - 3 sets x 12 reps', 'Toe Touch Stretch - 3 sets x 30 seconds'];
        instructions = 'Move fluidly between cat and cow positions, breathing deep.';
        safety = 'Do not overextend your neck during cobra or cat-cow.';
      } else if (day == 'Thursday') {
        title = 'Core Stability & Spine Stretch';
        exercises = ['Bird-Dog - 3 sets x 12 reps per side', 'Side Plank - 3 sets x 30 seconds per side', 'Seated Forward Fold - 3 sets x 45 seconds', 'Lying Quad Stretch - 3 sets x 30 seconds'];
        instructions = 'Strong core helps maintain excellent tall posture.';
        safety = 'Keep your neck in line with your spine during bird-dogs.';
      } else if (day == 'Friday') {
        title = 'Hanging & Yoga Flow';
        exercises = ['Bar Hanging (Active grip) - 3 sets x 60 seconds', 'Down Dog to Up Dog Flow - 3 sets x 8 reps', 'Triangle Pose - 3 sets x 30 seconds per side', 'Tree Pose - 3 sets x 30 seconds per side'];
        instructions = 'Yoga poses help extend and align the skeletal structure.';
        safety = 'Engage your shoulders while hanging; do not hang passively if painful.';
      } else if (day == 'Saturday') {
        title = 'Light Sports & Stretch';
        exercises = ['Basketball drills / Swimming - 30 minutes', 'Full body dynamic stretch - 15 minutes'];
        duration = '45 minutes';
        instructions = 'High-impact movements like basketball stimulate growth plates.';
        safety = 'Land with bent knees to absorb impact during jumps.';
      } else {
        title = 'Sleep Focus & Rest';
        exercises = ['Meditation & Deep Breathing - 10 minutes', 'Progressive Muscle Relaxation - 15 minutes'];
        duration = '25 minutes';
        instructions = 'Growth hormone is released during deep sleep. Focus on resting.';
        safety = 'Create a completely dark and quiet sleeping environment.';
      }
    } else if (goal == 'Calisthenics') {
      if (day == 'Monday') {
        title = 'Push Skill / Strength';
        exercises = isHome
          ? ['Regular Push-ups - 4 sets x 15 reps', 'Pike Push-ups - 3 sets x 10 reps', 'Decline Push-ups - 3 sets x 12 reps', 'Bench Dips - 3 sets x 15 reps']
          : ['Dips - 4 sets x 10 reps', 'Pike Push-ups - 3 sets x 10 reps', 'Incline Push-ups - 3 sets x 15 reps', 'Dumbbell Press (for shoulder balance) - 3 sets x 12 reps'];
        instructions = 'Maintain a solid hollow-body position throughout.';
        safety = 'Keep your elbows tucked at a 45-degree angle. Do not flare.';
      } else if (day == 'Tuesday') {
        title = 'Pull Skill / Strength';
        exercises = isHome
          ? ['Pull-ups - 4 sets x 8 reps', 'Chin-ups - 3 sets x 8 reps', 'Inverted Rows (under table/bar) - 3 sets x 12 reps', 'Doorway pull curls - 3 sets x 15 reps']
          : ['Wide Grip Pull-ups - 4 sets x 8 reps', 'Neutral Grip Chin-ups - 3 sets x 8 reps', 'Inverted Rows on rings/bar - 3 sets x 12 reps', 'Band Face Pulls - 3 sets x 15 reps'];
        instructions = 'Pull with your elbows, engaging your lats rather than just biceps.';
        safety = 'Ensure your pull-up bar is securely mounted before testing.';
      } else if (day == 'Wednesday') {
        title = 'Legs & Calisthenics Conditioning';
        exercises = ['Pistol Squat Progression - 3 sets x 8 reps per leg', 'Air Squats - 4 sets x 25 reps', 'Jumping Lunges - 3 sets x 12 reps per leg', 'Calf Raises - 3 sets x 20 reps'];
        instructions = 'Use support for pistol squats if you cannot perform them free.';
        safety = 'Maintain upright posture; do not let your lower back round.';
      } else if (day == 'Thursday') {
        title = 'Mobility & Handstand Practice';
        exercises = ['Wrist Mobility Drills - 5 minutes', 'Wall Handstand Hold - 4 sets x 30 seconds', 'Crow Pose Practice - 3 sets x 20 seconds', 'Shoulder opener stretches - 10 minutes'];
        duration = '40 minutes';
        instructions = 'Focus on alignment: stack shoulders over wrists, push active floor.';
        safety = 'Have a clear space to bail safely if you fall out of handstand.';
      } else if (day == 'Friday') {
        title = 'Core & L-Sit Progression';
        exercises = ['Hanging Knee/Leg Raises - 4 sets x 10 reps', 'L-Sit hold on floor/parallettes - 4 sets x 15 seconds', 'Hollow Body Hold - 3 sets x 45 seconds', 'Plank - 3 sets x 60 seconds'];
        instructions = 'Keep legs perfectly straight in L-sit if possible; else tuck knees.';
        safety = 'Do not swing your body during hanging raises; keep it controlled.';
      } else if (day == 'Saturday') {
        title = 'Full Body Flow';
        exercises = ['Burpee Pull-ups - 3 sets x 8 reps', 'Push-up to Side Plank - 3 sets x 12 reps', 'Squat Jumps - 3 sets x 15 reps', 'Bear Crawls - 3 sets x 30 seconds'];
        instructions = 'Focus on cardiovascular endurance and muscle coordination.';
        safety = 'Keep core tight to prevent hips from sagging in planks and push-ups.';
      } else {
        title = 'Active Recovery & Stretching';
        exercises = ['Foam Rolling - 15 minutes', 'Full Body Stretch - 15 minutes'];
        duration = '30 minutes';
        instructions = 'Gently massage tight muscles to improve mobility.';
        safety = 'Avoid rolling directly over joints or lower back bones.';
      }
    } else {
      if (day == 'Monday') {
        title = 'Full Body Strength';
        exercises = isHome
          ? ['Bodyweight Squats - 3 sets x 15 reps', 'Push-ups - 3 sets x 12 reps', 'Band Rows - 3 sets x 15 reps', 'Plank - 3 sets x 45 seconds']
          : ['Barbell Squats - 3 sets x 10 reps', 'Dumbbell Bench Press - 3 sets x 10 reps', 'Seated Rows - 3 sets x 12 reps', 'Plank - 3 sets x 60 seconds'];
        instructions = 'Maintain a moderate, controlled tempo on all exercises.';
        safety = 'Always prioritize proper form over adding more weight.';
      } else if (day == 'Tuesday') {
        title = 'Cardio & Mobility';
        exercises = isHome
          ? ['Jumping Jacks - 3 sets x 45 seconds', 'High Knees - 3 sets x 30 seconds', 'Dynamic stretches - 10 minutes', 'Fast walking - 20 minutes']
          : ['Treadmill Run/Jog - 20 minutes', 'Rowing Machine - 10 minutes', 'Stretching - 10 minutes'];
        instructions = 'Maintain a steady heart rate. Focus on breathing rhythm.';
        safety = 'Wear proper athletic shoes. Keep your posture upright.';
      } else if (day == 'Wednesday') {
        title = 'Upper Body Balance';
        exercises = isHome
          ? ['Doorway Rows - 3 sets x 12 reps', 'Incline Push-ups - 3 sets x 15 reps', 'Band Shoulder Press - 3 sets x 12 reps', 'Diamond Push-ups - 3 sets x 8 reps']
          : ['Incline Dumbbell Press - 3 sets x 10 reps', 'Lat Pulldowns - 3 sets x 12 reps', 'Overhead Dumbbell Press - 3 sets x 12 reps', 'Bicep Curl to Tricep Extension - 3 sets x 12 reps'];
        instructions = 'Work muscles on both sides of the joints to ensure balance.';
        safety = 'Avoid using momentum; control both concentric and eccentric phases.';
      } else if (day == 'Thursday') {
        title = 'Lower Body Strength';
        exercises = isHome
          ? ['Lunges - 3 sets x 12 reps per leg', 'Glute Bridges - 3 sets x 20 reps', 'Side Lunges - 3 sets x 10 reps per leg', 'Calf Raises - 3 sets x 20 reps']
          : ['Leg Press - 3 sets x 12 reps', 'Romanian Deadlifts - 3 sets x 10 reps', 'Lying Leg Curls - 3 sets x 12 reps', 'Calf Raises - 3 sets x 15 reps'];
        instructions = 'Ensure full range of motion. Rest 60s between sets.';
        safety = 'Keep your knees tracking over your feet. Keep core braced.';
      } else if (day == 'Friday') {
        title = 'Core, Balance & Posture';
        exercises = ['Bird-Dogs - 3 sets x 12 reps', 'Deadbugs - 3 sets x 12 reps', 'Supermans - 3 sets x 12 reps', 'Cobra Stretch - 3 sets x 30 seconds'];
        instructions = 'Slow, controlled movements to activate deep spinal stabilizers.';
        safety = 'Keep your lower back flat on the ground during deadbugs.';
      } else if (day == 'Saturday') {
        title = 'Active Sports or Recovery Flow';
        exercises = ['Brisk walk or cycling - 30 minutes', 'Dynamic joint rotation - 15 minutes'];
        duration = '45 minutes';
        instructions = 'Choose an activity you enjoy to promote overall fitness.';
        safety = 'Stay hydrated throughout your active session.';
      } else {
        title = 'Rest & Reflection';
        exercises = ['Relaxed breathing - 10 minutes', 'Gentle neck & shoulder stretch - 10 minutes'];
        duration = '20 minutes';
        instructions = 'Give your body complete rest today to prevent burnout.';
        safety = 'Get 8 hours of sleep tonight.';
      }
    }

    list.add(WorkoutDayDetails(
      dayName: day,
      workoutTitle: title,
      warmup: warmup,
      exercises: exercises,
      restTime: rest,
      duration: duration,
      cooldown: cooldown,
      beginnerInstructions: instructions,
      safetyTips: safety,
    ));
  }
  return list;
}

List<DietDayDetails> getWeeklyDietPlan(String goal, String foodPref) {
  final List<DietDayDetails> list = [];
  final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  for (int i = 0; i < 7; i++) {
    final day = days[i];
    String breakfast = '';
    String midMorning = '';
    String lunch = '';
    String evening = '';
    String dinner = '';
    int calories = 2000;
    int protein = 80;
    String budgetTips = '';
    String foodsToAvoid = 'Sugary drinks, processed snacks, deep-fried food, refined flour (Maida).';

    if (goal == 'Weight Gain') {
      calories = 2700 + (i % 3) * 100;
      protein = 110 + (i % 2) * 10;
      
      if (foodPref == 'Vegetarian') {
        breakfast = 'Oats porridge with milk (300ml), 1 banana, 15g almonds, and 10g chia seeds.';
        midMorning = 'Peanut butter sandwich (2 slices of whole wheat bread with 2 tbsp peanut butter) + 1 apple.';
        lunch = '2 cups brown rice, 1 cup mixed vegetable curry, 150g grilled paneer tikka, and 1 cup thick dal.';
        evening = '1 cup boiled chickpeas (chana chat) with chopped onions and tomatoes, plus 1 glass sweet lassi.';
        dinner = '3 whole wheat chapatis, 1 cup paneer bhurji, 1 cup cooked green vegetables, and a side salad.';
      } else if (foodPref == 'Eggetarian') {
        breakfast = '3 whole boiled eggs, 2 slices of toasted whole wheat bread, and 1 banana with a glass of milk.';
        midMorning = 'Fruit salad (apple, papaya) with 1 cup greek yogurt/curd and 30g roasted peanuts.';
        lunch = '2 cups rice, 3-egg omelet with chopped spinach and tomatoes, 1 cup paneer sabji, and 1 cup dal.';
        evening = 'Peanut butter sandwich (2 slices) + 1 glass milk or whey shake.';
        dinner = '3 chapatis, 1 cup egg bhurji (3 eggs), 1 cup steamed broccoli/beans, and a side salad.';
      } else {
        breakfast = '3 scrambled eggs, 2 slices of toasted bread, and 1 banana with a glass of whole milk.';
        midMorning = 'Handful of mixed nuts (almonds, walnuts) and 1 cup boiled chana.';
        lunch = '2 cups rice, 200g chicken breast curry/grilled chicken, 1 cup cooked dal, and a side salad.';
        evening = 'Boiled egg chat (2 eggs) or chicken sandwich, plus a glass of fresh fruit juice.';
        dinner = '3 chapatis, 150g grilled fish or chicken, 1 cup mixed vegetable sabji, and 1 cup curd.';
      }

      budgetTips = 'Buy raw peanuts, bananas, and local seasonal fruits in bulk. Prepare curd (yogurt) at home. Purchase eggs in trays of 30. Use soya chunks as a highly affordable protein source.';
      foodsToAvoid = 'Avoid low-calorie fillers, carbonated soda, excess coffee/caffeine that suppresses appetite, and trans fats.';
    } else if (goal == 'Weight Loss') {
      calories = 1450 + (i % 3) * 50;
      protein = 85 + (i % 2) * 5;

      if (foodPref == 'Vegetarian') {
        breakfast = 'Oats cooked in water/diluted milk (150ml), topped with 1/2 apple and 5-6 almonds.';
        midMorning = '1 cucumber, sliced, with a pinch of black pepper, and 1 cup green tea.';
        lunch = '1 chapati, 1 cup boiled chana/sprouts salad, 100g low-fat paneer, and 1 large bowl of cucumber-tomato salad.';
        evening = '1 cup roasted makhana (foxnuts) or roasted chana, plus 1 cup unsweetened black coffee/tea.';
        dinner = '1 bowl of vegetable oats khichdi or 100g tofu stir-fry with broccoli, capsicum, and mushrooms.';
      } else if (foodPref == 'Eggetarian') {
        breakfast = '2 egg white omelet with spinach, mushrooms, and tomatoes, plus 1 cup green tea.';
        midMorning = '1 apple or orange, plus 5-6 almonds.';
        lunch = '1 chapati, 1 cup boiled dal, salad bowl, and 2 boiled egg whites.';
        evening = '1 cup curd with a dash of flax seeds, or boiled egg white chat (2 egg whites).';
        dinner = 'Grilled paneer (100g) or tofu with stir-fried vegetables, and a hot cup of vegetable soup.';
      } else {
        breakfast = '2 egg white omelet with spinach, plus 1 slice of whole wheat toast and green tea.';
        midMorning = '1 cup papaya or apple, plus 5 almonds.';
        lunch = '1 chapati, 150g boiled/grilled chicken breast, 1 cup salad, and 1 cup buttermilk.';
        evening = 'Sprouted green gram (moong) salad (1 cup) or chicken soup.';
        dinner = '150g grilled fish or chicken with steamed zucchini, carrots, and beans.';
      }

      budgetTips = 'Load up on local green vegetables. Buy whole grains like oats and brown rice which are cheap and filling. Eggs are the most economical source of premium protein.';
      foodsToAvoid = 'Sugar, deep-fried snacks, processed meats, bakery items, salad dressings with high oil content, and sweetened juices.';
    } else {
      calories = 1800 + (i % 3) * 100;
      protein = 90 + (i % 2) * 10;

      if (foodPref == 'Vegetarian') {
        breakfast = '2 vegetable idlis or 1 moong dal chilla with mint chutney, and 1 glass buttermilk.';
        midMorning = '1 orange or apple, plus 10 almonds.';
        lunch = '1.5 cups rice, 1 cup dal, 100g paneer curry, and 1 cup mixed vegetable salad.';
        evening = '1 cup boiled sprouts with lemon juice, plus 1 cup green tea.';
        dinner = '2 chapatis, 1 cup soya chunks curry, 1 cup green vegetables, and 1 cup curd.';
      } else if (foodPref == 'Eggetarian') {
        breakfast = '2 whole eggs boiled or scrambled, 1 slice whole wheat toast, and 1 cup green tea.';
        midMorning = '1 cup curd with 1 tsp honey and some berries/apple.';
        lunch = '1.5 cups rice, 3-egg white omelet, 1 cup dal, and 1 bowl of mixed salad.';
        evening = 'Peanut butter on 1 slice of toast + 1 glass of coconut water.';
        dinner = '2 chapatis, 100g paneer bhurji, 1 cup steamed green vegetables, and 1 boiled egg white.';
      } else {
        breakfast = '2 boiled eggs, 1 slice whole wheat toast, and 1 cup green tea/coffee.';
        midMorning = '1 apple, plus a handful of roasted peanuts.';
        lunch = '1.5 cups rice, 150g grilled chicken, 1 cup dal, and 1 bowl of mixed salad.';
        evening = 'Boiled egg chat (2 eggs) or 1 cup roasted makhana.';
        dinner = '2 chapatis, 150g grilled fish or chicken, 1 cup mixed vegetables, and 1 cup curd.';
      }

      budgetTips = 'Buy legumes and lentils in bulk. Use eggs and paneer regularly. Buy seasonal vegetables directly from local farmer markets.';
      foodsToAvoid = 'Junk foods, refined sugars, hydrogenated vegetable oil, and high-sodium packed foods.';
    }

    list.add(DietDayDetails(
      dayName: day,
      breakfast: breakfast,
      midMorningSnack: midMorning,
      lunch: lunch,
      eveningSnack: evening,
      dinner: dinner,
      calories: calories,
      protein: protein,
      budgetTips: budgetTips,
      foodsToAvoid: foodsToAvoid,
    ));
  }
  return list;
}

List<String> workout(String goal, String loc) {
  final home=loc=='Home Workout';
  if(goal=='Weight Gain') return ['Monday: Chest + Triceps - ${home?'Push-ups, dips':'Bench press, incline press'}','Tuesday: Back + Biceps - ${home?'Pull-ups, towel rows':'Lat pulldown, rows'}','Wednesday: Legs - ${home?'Squats, lunges':'Squats, leg press'}','Thursday: Active rest + stretching','Friday: Shoulders + Core','Saturday: Full body strength circuit','Sunday: Rest and meal prep'];
  if(goal=='Weight Loss') return ['Monday: Full body strength + cardio','Tuesday: HIIT + core','Wednesday: Lower body + 6000 steps','Thursday: Mobility + light cardio','Friday: Upper body + cycling','Saturday: Fat-loss circuit','Sunday: Rest + long walk'];
  if(goal=='Increase Height') return ['Monday: Cobra stretch, hanging, pelvic tilt','Tuesday: Skipping + posture drills','Wednesday: Cat-cow, bridge, mobility','Thursday: Core stability','Friday: Hanging + yoga flow','Saturday: Light sports + stretch','Sunday: Sleep focus'];
  if(goal=='Calisthenics') return ['Monday: Push skill','Tuesday: Pull skill','Wednesday: Legs','Thursday: Mobility + handstand wall practice','Friday: Core L-sit progression','Saturday: Full body flow','Sunday: Recovery'];
  return ['Monday: Full body strength','Tuesday: Cardio + mobility','Wednesday: Upper body','Thursday: Lower body','Friday: Core + posture','Saturday: Sports or active recovery','Sunday: Rest'];
}
List<String> diet(String goal,String food){
  final p=food=='Vegetarian'?'paneer, dal, chana, sprouts, curd':food=='Eggetarian'?'eggs, dal, paneer, sprouts, curd':'eggs, chicken, fish, dal, curd';
  if(goal=='Weight Gain') return ['Breakfast: oats + milk + banana + nuts','Snack: fruit + curd','Lunch: rice/chapati + $p + vegetables','Pre workout: banana or dates','Post workout: milk + protein','Dinner: chapati/rice + protein + vegetables','Before sleep: milk or curd'];
  if(goal=='Weight Loss') return ['Breakfast: oats/eggs/sprouts','Snack: cucumber/carrot','Lunch: controlled rice + $p + salad','Evening: tea + nuts','Dinner: light protein bowl','Avoid sugary drinks and fried snacks','Target high protein calorie deficit'];
  return ['Breakfast: carbs + protein','Snack: fruit or nuts','Lunch: rice/chapati + $p + vegetables','Evening: light snack + water','Dinner: protein + vegetables','Hydration: 8-10 glasses','Weekly prep affordable protein'];
}
// budget static function removed
String aiAdvice(String goal,String food,String loc)=>'Today focus on $goal with $loc. Keep protein steady using $food choices, drink water before meals, warm up properly, and sleep 7-8 hours.';

void go(BuildContext c,String r)=>Navigator.pushNamed(c,r);
void replace(BuildContext c,String r)=>Navigator.pushReplacementNamed(c,r);
void msg(BuildContext c,String t)=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(t)));

class SplashScreen extends StatefulWidget { const SplashScreen({super.key}); @override State<SplashScreen> createState()=>_SplashScreenState(); }
class _SplashScreenState extends State<SplashScreen>{
  @override void initState(){ super.initState(); Timer(const Duration(milliseconds:1500),(){ if(!mounted)return; final c=Scope.of(context); replace(context,c.signedIn?(c.profile?.complete==true?'/dashboard':'/goal'):'/login'); }); }
  @override Widget build(BuildContext context)=>Scaffold(body:Container(decoration:const BoxDecoration(gradient:LinearGradient(colors:[Colors.white,lightGreen])),child:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Image.asset('assets/images/logo.png',width:132),SizedBox(height:22),Text('NutriFit',style:Theme.of(context).textTheme.headlineLarge?.copyWith(color:green)),SizedBox(height:8),Text('Your Health, Your Care',style:Theme.of(context).textTheme.titleMedium)]))));
}

class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState()=>_LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen>{ final email=TextEditingController(); final pass=TextEditingController();
  @override void dispose(){email.dispose();pass.dispose();super.dispose();}
  Future<void> submit() async { final c=Scope.of(context); final e=await c.login(email.text,pass.text); if(!mounted)return; e==null?replace(context,c.profile?.complete==true?'/dashboard':'/goal'):msg(context,e); }
  Future<void> google() async { final c=Scope.of(context); final e=await c.googleLogin(); if(!mounted)return; e==null?replace(context,c.profile?.complete==true?'/dashboard':'/goal'):msg(context,e); }
  @override Widget build(BuildContext context){ final c=Scope.of(context); return AuthScaffold(title:c.t('app'),subtitle:c.t('tag'),children:[Image.asset('assets/images/logo.png',width:92),field(email,c.t('email'),Icons.mail,false,TextInputType.emailAddress),field(pass,c.t('password'),Icons.lock,true,null),Align(alignment:Alignment.centerRight,child:TextButton(onPressed:()=>go(context,'/forgot'),child:Text(c.t('forgot')))),button(c.t('login'),submit,c.busy),OutlinedButton.icon(onPressed:c.busy?null:google,icon:Icon(Icons.g_mobiledata_rounded,size:32),label:Text(c.t('google')),style:OutlinedButton.styleFrom(minimumSize:const Size.fromHeight(54),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)))),Row(mainAxisAlignment:MainAxisAlignment.center,children:[Text("Don't have an account?"),TextButton(onPressed:()=>go(context,'/signup'),child:Text(c.t('signup')))]),Card(child:Padding(padding:EdgeInsets.all(14),child:Text(AppLocalizations.of(context)!.demoModeWorksWhenSupabaseKeysAreEmptyAddSupabaseUrlAndAnonKeyInEnvForRealAuthentication)))]); }
}
class SignUpScreen extends StatefulWidget { const SignUpScreen({super.key}); @override State<SignUpScreen> createState()=>_SignUpScreenState(); }
class _SignUpScreenState extends State<SignUpScreen>{ final name=TextEditingController(); final email=TextEditingController(); final pass=TextEditingController(); @override void dispose(){name.dispose();email.dispose();pass.dispose();super.dispose();}
  Future<void> submit() async{final c=Scope.of(context);final e=await c.signUp(name.text,email.text,pass.text);if(!mounted)return;e==null?replace(context,'/goal'):msg(context,e);}
  @override Widget build(BuildContext context){final c=Scope.of(context);return AuthScaffold(title:c.t('signup'),subtitle: AppLocalizations.of(context)!.createYourNutrifitAccount,children:[Image.asset('assets/images/fitness_hero.png',height:150),field(name,c.t('name'),Icons.person,false,null),field(email,c.t('email'),Icons.mail,false,TextInputType.emailAddress),field(pass,c.t('password'),Icons.lock,true,null),button(c.t('signup'),submit,c.busy)]);}
}
class ForgotScreen extends StatefulWidget { const ForgotScreen({super.key}); @override State<ForgotScreen> createState()=>_ForgotScreenState(); }
class _ForgotScreenState extends State<ForgotScreen>{ final email=TextEditingController(); @override void dispose(){email.dispose();super.dispose();}
  @override Widget build(BuildContext context){final c=Scope.of(context);return AuthScaffold(title:c.t('forgot'),subtitle: AppLocalizations.of(context)!.sendResetLinkUsingSupabaseAuth,children:[field(email,c.t('email'),Icons.mail,false,TextInputType.emailAddress),button('Send Reset Link',()async{final e=await c.reset(email.text);if(context.mounted)msg(context,e??'Password reset email sent if account exists.');},c.busy)]);}
}

class AuthScaffold extends StatelessWidget{ const AuthScaffold({super.key,required this.title,required this.subtitle,required this.children}); final String title,subtitle; final List<Widget> children;
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(),body:SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.headlineLarge?.copyWith(color:green)),SizedBox(height:8),Text(subtitle,style:Theme.of(context).textTheme.titleMedium),SizedBox(height:26),...children.map((w)=>Padding(padding:const EdgeInsets.only(bottom:14),child:w))]))));
}
Widget field(TextEditingController c,String label,IconData icon,bool obscure,TextInputType? type)=>TextField(controller:c,obscureText:obscure,keyboardType:type,decoration:InputDecoration(labelText:label,prefixIcon:Icon(icon)));
Widget button(String label,VoidCallback? on,bool busy)=>ElevatedButton.icon(onPressed:busy?null:on,icon:busy?SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Icon(Icons.arrow_forward),label:Text(label));

class SelectScreen extends StatelessWidget{ const SelectScreen({super.key,required this.title,required this.subtitle,required this.items,required this.next,required this.onSelect,required this.icon}); final String title,subtitle,next; final List<String> items; final void Function(AppController,String) onSelect; final IconData icon;
  @override Widget build(BuildContext context){final c=Scope.of(context);return Scaffold(appBar:AppBar(),body:SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.favorite,color:green,size:42),SizedBox(height:20),Text(title,style:Theme.of(context).textTheme.headlineMedium),SizedBox(height:8),Text(subtitle),SizedBox(height:20),for(final it in items) SelectCard(title:it,icon:icon,onTap:(){onSelect(c,it);go(context,next);})]))));}
}
class SelectCard extends StatelessWidget{ const SelectCard({super.key,required this.title,required this.icon,required this.onTap}); final String title; final IconData icon; final VoidCallback onTap;
 @override Widget build(BuildContext context)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(22),child:Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFE7EEE9))),child:Row(children:[Icon(icon,color:green),SizedBox(width:14),Expanded(child:Text(title,style:Theme.of(context).textTheme.titleMedium)),Icon(Icons.chevron_right)])));
}
class GoalScreen extends StatelessWidget{ const GoalScreen({super.key}); @override Widget build(BuildContext context){final c=Scope.of(context);return SelectScreen(title:c.t('goal'),subtitle: AppLocalizations.of(context)!.nutrifitWillPersonalizeYourWorkoutAndDiet,items:goals,next:'/gender',icon:Icons.fitness_center,onSelect:(c,v)=>c.draft(goal:v));}}
class GenderScreen extends StatelessWidget{ const GenderScreen({super.key}); @override Widget build(BuildContext context){final c=Scope.of(context);return SelectScreen(title:c.t('gender'),subtitle: AppLocalizations.of(context)!.thisHelpsCalculateBetterRecommendations,items:genders,next:'/age',icon:Icons.person,onSelect:(c,v)=>c.draft(gender:v));}}
class FoodScreen extends StatelessWidget{ const FoodScreen({super.key}); @override Widget build(BuildContext context){final c=Scope.of(context);return SelectScreen(title:c.t('food'),subtitle: AppLocalizations.of(context)!.yourDietPlanWillMatchYourPreference,items:foods,next:'/location',icon:Icons.restaurant,onSelect:(c,v)=>c.draft(food:v));}}
class LocationScreen extends StatelessWidget{ const LocationScreen({super.key}); @override Widget build(BuildContext context){final c=Scope.of(context);return SelectScreen(title:c.t('location'),subtitle: AppLocalizations.of(context)!.chooseGymOrHomeWorkout,items:locations,next:'/dashboard',icon:Icons.home,onSelect:(c,v){c.draft(location:v, onboardingCompleted:true);c.saveProfile();});}}

class NumberScreen extends StatefulWidget{ const NumberScreen({super.key,required this.kind}); final String kind; @override State<NumberScreen> createState()=>_NumberScreenState();}
class _NumberScreenState extends State<NumberScreen>{
  TextEditingController? _ctrl;
  TextEditingController get ctrl => _ctrl!;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final p = Scope.of(context).profile;
      _ctrl = TextEditingController(
        text: widget.kind == 'age'
            ? p?.age?.toString() ?? ''
            : widget.kind == 'height'
                ? p?.height?.toStringAsFixed(0) ?? ''
                : p?.weight?.toStringAsFixed(0) ?? '',
      );
      _initialized = true;
    }
  }

  @override void dispose() { _ctrl?.dispose(); super.dispose(); }
@override Widget build(BuildContext context){final c=Scope.of(context);final title=widget.kind=='age'?c.t('age'):widget.kind=='height'?c.t('height'):c.t('weight'); final unit=widget.kind=='age'?'years':widget.kind=='height'?'cm':'kg'; final next=widget.kind=='age'?'/height':widget.kind=='height'?'/weight':'/food'; return Scaffold(appBar:AppBar(),body:Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.headlineMedium),SizedBox(height:8),Text('Enter value in $unit'),SizedBox(height:24),field(ctrl,title,widget.kind=='age'?Icons.cake:widget.kind=='height'?Icons.height:Icons.monitor_weight,false,TextInputType.number),SizedBox(height:20),button(c.t('continue'),(){final v=double.tryParse(ctrl.text.trim()); if(v==null){msg(context,'Enter valid value');return;} if(widget.kind=='age') c.draft(age:v.round()); if(widget.kind=='height') c.draft(height:v); if(widget.kind=='weight') c.draft(weight:v); go(context,next);},false)])));}}

class DashboardScreen extends StatefulWidget{ const DashboardScreen({super.key}); @override State<DashboardScreen> createState()=>_DashboardScreenState(); }
class _DashboardScreenState extends State<DashboardScreen>{
  @override Widget build(BuildContext context){
    final c=Scope.of(context);
    final pages=[const HomeTab(),const PlansTab(),const TrackersTab(),const ShopTab(),const ProfileTab()];
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;
      final body = AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(key: ValueKey(c.tab), child: pages[c.tab]),
      );
      final nav = NavigationBar(
        selectedIndex:c.tab,
        indicatorColor:lightGreen,
        onDestinationSelected:(i){c.setTab(i);},
        destinations:[
          NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:c.t('dashboard')),
          NavigationDestination(icon:Icon(Icons.calendar_month_outlined),selectedIcon:Icon(Icons.calendar_month),label:c.t('plans')),
          NavigationDestination(icon:Icon(Icons.track_changes_outlined),selectedIcon:Icon(Icons.track_changes),label:c.t('trackers')),
          NavigationDestination(icon:Icon(Icons.shopping_bag_outlined),selectedIcon:Icon(Icons.shopping_bag),label:c.t('shop')),
          NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:c.t('profile')),
        ],
      );

      if (isWide) {
        // ── Web / Desktop layout: proper responsive layout ──
        return Scaffold(
          backgroundColor: const Color(0xFFFAFCFB),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: green,
            title: Row(
              children: [
                Icon(Icons.eco, color: Colors.white, size: 26),
                SizedBox(width: 8),
                Text('NutriFit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                SizedBox(width: 40),
                // Navigation items
                ...List.generate(nav.destinations.length, (i) {
                  final dest = nav.destinations[i] as NavigationDestination;
                  final isSelected = c.tab == i;
                  return InkWell(
                    onTap: () => c.setTab(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: isSelected ? const Border(bottom: BorderSide(color: Colors.white, width: 3)) : null,
                      ),
                      child: Text(dest.label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                }),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      c.profile?.name.isNotEmpty == true ? c.profile!.name : 'User',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(width: 12),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      child: Text(
                        (c.profile?.name.isNotEmpty == true ? c.profile!.name[0] : 'U').toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: body,
            ),
          ),
        );
      }

      // ── Mobile layout: unchanged ──
      return Scaffold(
        body: SafeArea(child: body),
        bottomNavigationBar: nav,
      );
    });
  }
}

class HomeTab extends StatelessWidget{ const HomeTab({super.key}); @override Widget build(BuildContext context){final c=Scope.of(context);final p=c.profile;final g=p?.goal.isNotEmpty==true?p!.goal:'General Fitness';final f=p?.food.isNotEmpty==true?p!.food:'Eggetarian';final l=p?.location.isNotEmpty==true?p!.location:'Home Workout';final w=workout(g,l);final d=diet(g,f);return ListView(padding:const EdgeInsets.all(20),children:[Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Hi, ${p?.name.isNotEmpty==true?p!.name:'User'}',style:Theme.of(context).textTheme.headlineMedium),Text('Ready for ${g.toLowerCase()}?')])),CircleAvatar(radius:28,backgroundColor:lightGreen,child:Text((p?.name.isNotEmpty==true?p!.name[0]:'N').toUpperCase(),style:const TextStyle(color:green,fontWeight:FontWeight.w900,fontSize:22)))]),SizedBox(height:20),HeroCard(title:w.first,subtitle:d.first),SizedBox(height:16),grid(context,[Info('Hydration','${c.water} ml','Target 3000 ml',Icons.water_drop, c.water/3000),Info('Sleep','${c.sleep.toStringAsFixed(1)} h','Target 8 h',Icons.bedtime, c.sleep/8),Info('Steps','${c.steps}','Target 8000',Icons.directions_walk, c.steps/8000),Info('Goal',g,l,Icons.flag, 1.0)]),section(c.t('ai')),InkWell(onTap: () => Navigator.pushNamed(context, '/ai_trainer'), child: infoBox(Icons.smart_toy, c.latestAIAdvice)),section('Meal Reminder'),reminder(context, 'Breakfast','7:30 AM',Icons.breakfast_dining),reminder(context, 'Lunch','1:00 PM',Icons.lunch_dining),reminder(context, 'Dinner','8:00 PM',Icons.dinner_dining),reminder(context, 'Workout','6:00 PM',Icons.fitness_center)]);}}
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.title, required this.subtitle});
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final imgSize = isWide ? 130.0 : 100.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 18, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [green, darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: text content ──────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.calendar_today_rounded, color: Colors.white, size: 11),
                      SizedBox(width: 5),
                      Text(
                        'Today Plan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Workout title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.fitness_center_rounded, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Meal recommendation
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.restaurant_rounded, color: Colors.white60, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Right: fitness illustration ─────────────────────────────────
          Image.asset(
            'assets/images/dashboard/today_plan_fitness.png',
            width: imgSize,
            height: imgSize,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.fitness_center,
              color: Colors.white38,
              size: imgSize * 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
class Info{Info(this.title,this.value,this.sub,this.icon,this.progress);String title,value,sub;IconData icon;double progress;}
Widget grid(BuildContext context, List<Info> items) {
  final isWide = MediaQuery.of(context).size.width > 700;
  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: isWide ? 4 : 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: isWide ? 1.2 : 0.95,
    children: [for(final i in items) _MetricCard(info: i)],
  );
}

class _MetricCard extends StatefulWidget {
  final Info info;
  const _MetricCard({required this.info});
  @override State<_MetricCard> createState() => _MetricCardState();
}
class _MetricCardState extends State<_MetricCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _hovered ? green : const Color(0xFFE7EEE9), width: _hovered ? 1.5 : 1),
          boxShadow: _hovered
              ? [BoxShadow(color: green.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40, height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 36, height: 36,
                    child: CircularProgressIndicator(
                      value: widget.info.progress.clamp(0, 1).toDouble(),
                      strokeWidth: 3,
                      backgroundColor: lightGreen,
                      color: green,
                    ),
                  ),
                  Icon(widget.info.icon, color: green, size: 18),
                ],
              ),
            ),
            SizedBox(height: 8),
            Text(widget.info.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(widget.info.title, style: const TextStyle(fontSize: 13)),
            Text(widget.info.sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

Widget card(Widget child)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:const Color(0xFFE7EEE9))),child:child);
Widget section(String title)=>Padding(padding:const EdgeInsets.only(top:20,bottom:10),child:Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:textDark)));
Widget infoBox(IconData icon,String text)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:lightGreen,borderRadius:BorderRadius.circular(24)),child:Row(children:[CircleAvatar(backgroundColor:Colors.white,child:Icon(icon,color:green)),SizedBox(width:12),Expanded(child:Text(text))]));
Widget reminder(BuildContext context, String t,String time,IconData icon){ final c = Scope.of(context); return Card(child:ListTile(leading:CircleAvatar(backgroundColor:lightGreen,child:Icon(icon,color:green)),title:Text(t),subtitle:Text(time),trailing:Switch(value:c.reminders[t] ?? false,onChanged:(v)=>c.toggleReminder(t, time, v))));}

class WorkoutDayCard extends StatefulWidget {
  final WorkoutDayDetails details;
  final AppController controller;
  const WorkoutDayCard({super.key, required this.details, required this.controller});

  @override
  State<WorkoutDayCard> createState() => _WorkoutDayCardState();
}

class _WorkoutDayCardState extends State<WorkoutDayCard> {
  bool _expanded = false;
  Timer? _timer;
  int _timeLeft = 0;
  bool _resting = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRestTimer() {
    if (_resting) {
      _timer?.cancel();
      setState(() {
        _resting = false;
        _timeLeft = 0;
      });
      return;
    }
    int duration = 60;
    final rStr = widget.details.restTime.toLowerCase();
    if (rStr.contains('45')) duration = 45;
    else if (rStr.contains('90')) duration = 90;
    else if (rStr.contains('120')) duration = 120;

    setState(() {
      _resting = true;
      _timeLeft = duration;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        setState(() {
          _resting = false;
          _timeLeft = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 Rest time over for ${widget.details.dayName}! Ready for the next set?'),
            backgroundColor: green,
            behavior: SnackBarBehavior.floating,
          )
        );
      } else {
        setState(() {
          _timeLeft--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayKey = '${widget.details.dayName}_${widget.controller.profile?.goal ?? 'General Fitness'}_${widget.controller.profile?.location ?? 'Home Workout'}';
    final completed = widget.controller.completedWorkouts.contains(dayKey);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: completed ? green : const Color(0xFFE7EEE9),
          width: completed ? 2 : 1,
        ),
      ),
      color: completed ? const Color(0xFFF0FAF5) : Colors.white,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.details.dayName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                if (completed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: const BoxDecoration(
                      color: green,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'COMPLETED',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.details.workoutTitle,
                style: TextStyle(
                  color: completed ? darkGreen : textDark.withOpacity(0.7),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            trailing: Icon(
              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: green,
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: Color(0xFFE7EEE9)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubSectionHeader('Warm-up:', Icons.directions_run),
                  SizedBox(height: 8),
                  for (final item in widget.details.warmup) _buildBulletPoint(item),
                  SizedBox(height: 16),

                  _buildSubSectionHeader('Exercises:', Icons.fitness_center),
                  SizedBox(height: 8),
                  for (final item in widget.details.exercises) _buildBulletPoint(item),
                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetaBox(
                          Icons.timer_outlined,
                          'Duration',
                          widget.details.duration,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildMetaBox(
                          Icons.snooze,
                          'Rest Time',
                          widget.details.restTime,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  _buildSubSectionHeader('Cool-down stretching:', Icons.accessibility_new),
                  SizedBox(height: 8),
                  for (final item in widget.details.cooldown) _buildBulletPoint(item),
                  SizedBox(height: 16),

                  if (widget.details.beginnerInstructions.isNotEmpty) ...[
                    _buildSubSectionHeader('Beginner Instructions:', Icons.info_outline),
                    SizedBox(height: 6),
                    Text(
                      widget.details.beginnerInstructions,
                      style: const TextStyle(fontSize: 14, color: textDark),
                    ),
                    SizedBox(height: 16),
                  ],

                  if (widget.details.safetyTips.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFE6D5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Safety Tips',
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            widget.details.safetyTips,
                            style: const TextStyle(color: Color(0xFF9E5C2C), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18),
                  ],

                  if (_resting) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: green),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Rest Timer Running: $_timeLeft seconds left',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🚀 Workout started for ${widget.details.dayName}! Go to Trackers to track time.'),
                                backgroundColor: green,
                                behavior: SnackBarBehavior.floating,
                                action: SnackBarAction(
                                  label: AppLocalizations.of(context)!.view,
                                  textColor: Colors.white,
                                  onPressed: () {
                                    widget.controller.setTab(2);
                                  },
                                ),
                              )
                            );
                          },
                          icon: Icon(Icons.play_arrow, size: 18),
                          label: Text('Start', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _startRestTimer,
                          icon: Icon(_resting ? Icons.stop : Icons.timer, size: 18, color: green),
                          label: Text(
                            _resting ? 'Stop (${_timeLeft}s)' : 'Rest Timer',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: green),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: Size.zero,
                            side: const BorderSide(color: green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => widget.controller.toggleWorkoutCompleted(dayKey),
                      icon: Icon(
                        completed ? Icons.check_circle : Icons.check_circle_outline,
                        color: completed ? green : Colors.grey,
                        size: 20,
                      ),
                      label: Text(
                        completed ? 'Completed (Tap to undo)' : 'Mark as Completed',
                        style: TextStyle(
                          color: completed ? green : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: completed ? green : Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubSectionHeader(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: green, size: 16),
        SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: green),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaBox(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F3ED)),
      ),
      child: Row(
        children: [
          Icon(icon, color: green, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  value,
                  style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DietDayCard extends StatefulWidget {
  final DietDayDetails details;
  const DietDayCard({super.key, required this.details});

  @override
  State<DietDayCard> createState() => _DietDayCardState();
}

class _DietDayCardState extends State<DietDayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE7EEE9), width: 1),
      ),
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Text(
              widget.details.dayName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, size: 16, color: Colors.orange.shade700),
                  SizedBox(width: 4),
                  Text(
                    '${widget.details.calories} kcal',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(width: 14),
                  Icon(Icons.fitness_center, size: 16, color: green),
                  SizedBox(width: 4),
                  Text(
                    '${widget.details.protein}g protein',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            trailing: Icon(
              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: green,
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: Color(0xFFE7EEE9)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMealSection('Breakfast', widget.details.breakfast, Icons.breakfast_dining),
                  SizedBox(height: 12),
                  _buildMealSection('Mid-morning Snack', widget.details.midMorningSnack, Icons.apple),
                  SizedBox(height: 12),
                  _buildMealSection('Lunch', widget.details.lunch, Icons.lunch_dining),
                  SizedBox(height: 12),
                  _buildMealSection('Evening Snack', widget.details.eveningSnack, Icons.local_cafe),
                  SizedBox(height: 12),
                  _buildMealSection('Dinner', widget.details.dinner, Icons.dinner_dining),
                  SizedBox(height: 16),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4EFE0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.currency_rupee, color: darkGreen, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Budget Food Tips',
                              style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          widget.details.budgetTips,
                          style: const TextStyle(color: darkGreen, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD1D1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.block, color: Colors.redAccent, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Foods to Avoid',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          widget.details.foodsToAvoid,
                          style: const TextStyle(color: Color(0xFFB13D3D), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealSection(String title, String content, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: lightGreen,
          child: Icon(icon, color: green, size: 16),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark),
              ),
              SizedBox(height: 2),
              Text(
                content,
                style: TextStyle(fontSize: 13, color: textDark.withOpacity(0.85)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WarmupExercise {
  final String title;
  final String durationReps;
  final String calories;
  final String shortDesc;
  final String details;
  /// Filename used to build gender-specific paths, e.g. 'brisk_walk.png'.
  final String fileName;

  WarmupExercise({
    required this.title,
    required this.durationReps,
    required this.calories,
    required this.shortDesc,
    required this.details,
    required this.fileName,
  });

  /// Returns the asset path for the given gender.
  /// Falls back to 'male' when [gender] is empty or unrecognised.
  String imagePath(String gender) {
    final folder = gender.toLowerCase() == 'female' ? 'female' : 'male';
    return 'assets/images/stretching/$folder/$fileName';
  }
}

List<WarmupExercise> _warmupExercises(BuildContext context) => [
  WarmupExercise(
    title: AppLocalizations.of(context)!.num5MinBriskWalk,
    durationReps: 'Duration: 5 Minutes',
    calories: 'Calories Burn: ~25-35 kcal',
    shortDesc: 'Walk at a steady pace. Keep your posture upright, swing your arms naturally and breathe evenly.',
    details: 'A brisk walk is a great way to elevate your heart rate gradually. Maintain a pace where you can still hold a conversation but feel your breathing quicken.',
    fileName: 'brisk_walk.png',
  ),
  WarmupExercise(
    title: AppLocalizations.of(context)!.armCircles,
    durationReps: 'Duration: 30 Seconds (Each Direction)',
    calories: '',
    shortDesc: 'Extend your arms and make small circles forward, then backward. Keep shoulders relaxed.',
    details: 'Start with small circles and gradually increase the size. This warms up the shoulder joint and increases blood flow to your arms.',
    fileName: 'arm_circles.png',
  ),
  WarmupExercise(
    title: AppLocalizations.of(context)!.hipRotation,
    durationReps: 'Reps: 10 Each Side',
    calories: '',
    shortDesc: 'Place hands on hips and rotate your hips in a circular motion. Keep your core engaged.',
    details: 'Make wide circles with your hips, ensuring you feel the stretch in your lower back and hip flexors. Avoid moving your shoulders too much.',
    fileName: 'hip_rotation.png',
  ),
  WarmupExercise(
    title: AppLocalizations.of(context)!.catCowStretch,
    durationReps: 'Reps: 10-12',
    calories: '',
    shortDesc: 'Inhale, arch your back and lift your head (Cow). Exhale, round your back and tuck your chin (Cat).',
    details: 'Start on all fours with hands under shoulders and knees under hips. Move slowly with your breath to improve spinal flexibility and core control.',
    fileName: 'cat_cow_stretch.png',
  ),
  WarmupExercise(
    title: AppLocalizations.of(context)!.dynamicHamstringStretch,
    durationReps: 'Reps: 10 Each Leg',
    calories: '',
    shortDesc: 'Swing one leg forward while keeping it straight, then back. Repeat with the other leg.',
    details: 'Hold onto a wall for balance if needed. Keep your torso upright and avoid leaning forward too much as you swing your leg.',
    fileName: 'hamstring_stretch.png',
  ),
  WarmupExercise(
    title: AppLocalizations.of(context)!.lightPushUp,
    durationReps: 'Reps: 10-15',
    calories: '',
    shortDesc: 'Place hands under shoulders and lower your body. Push back up. Keep your core tight.',
    details: 'If standard push-ups are too difficult, perform them on your knees. Focus on a full range of motion and keeping your elbows slightly tucked.',
    fileName: 'light_pushup.png',
  ),
];

class WarmupCard extends StatefulWidget {
  final WarmupExercise workout;
  final int index;
  /// The user's gender string (e.g. 'Male', 'Female', or '').
  final String gender;
  const WarmupCard({super.key, required this.workout, required this.index, this.gender = ''});

  @override
  State<WarmupCard> createState() => _WarmupCardState();
}

class _WarmupCardState extends State<WarmupCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7EEE9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  widget.workout.imagePath(widget.gender),
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center, size: 60),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: lightGreen,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${widget.index + 1}',
                                style: const TextStyle(
                                  color: darkGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.workout.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined, size: 14, color: green),
                                SizedBox(width: 4),
                                Text(
                                  widget.workout.durationReps,
                                  style: const TextStyle(fontSize: 12, color: textDark),
                                ),
                              ],
                            ),
                            if (widget.workout.calories.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_fire_department_outlined, size: 14, color: green),
                                  SizedBox(width: 4),
                                  Text(
                                    widget.workout.calories,
                                    style: const TextStyle(fontSize: 12, color: textDark),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.workout.shortDesc,
                          style: TextStyle(fontSize: 12, color: textDark.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: green,
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const Divider(height: 1, color: Color(0xFFE7EEE9)),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFFAFCFB),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: darkGreen),
                        SizedBox(width: 6),
                        Text(
                          'How to do:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkGreen),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      widget.workout.details,
                      style: const TextStyle(fontSize: 13, color: textDark),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PlansTab extends StatelessWidget {
  const PlansTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Scope.of(context);
    final p = c.profile;
    final g = p?.goal.isNotEmpty == true ? p!.goal : 'General Fitness';
    final f = p?.food.isNotEmpty == true ? p!.food : 'Eggetarian';
    final l = p?.location.isNotEmpty == true ? p!.location : 'Home Workout';
    final workoutList = getWeeklyWorkoutDetails(g, l);
    final dietList = getWeeklyDietPlan(g, f);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(c.t('plans'), style: Theme.of(context).textTheme.headlineMedium),
        SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Goal: $g  •  Food: $f  •  Location: $l',
            style: const TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        SizedBox(height: 18),
        
        section(c.t('weeklyWorkout')),
        for (final w in workoutList) WorkoutDayCard(details: w, controller: c),
        
        section(c.t('weeklyDiet')),
        for (final d in dietList) DietDayCard(details: d),
        
        section(c.t('warmup')),
        ..._warmupExercises(context).asMap().entries.map(
          (e) => WarmupCard(
            workout: e.value,
            index: e.key,
            // Read gender from profile every build; Scope is an InheritedNotifier
            // so this widget rebuilds automatically when the profile changes.
            gender: p?.gender ?? '',
          ),
        ),
        
        section(c.t('budget')),
        BudgetFoodSection(controller: c),
      ],
    );
  }
}

Widget planList(List<String> items, IconData icon) => Column(
      children: [
        for (final x in items)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7EEE9)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: lightGreen,
                  child: Icon(icon, color: green),
                ),
                SizedBox(width: 12),
                Expanded(child: Text(x)),
              ],
            ),
          )
      ],
    );

class TrackersTab extends StatefulWidget {
  const TrackersTab({super.key});
  @override
  State<TrackersTab> createState() => _TrackersTabState();
}

class _TrackersTabState extends State<TrackersTab> {
  Timer? _workoutTimer;
  int _workoutSec = 0;
  TimeOfDay? _sleepTime;
  TimeOfDay? _wakeTime;
  double? _customMet;

  // Reminder state
  TimeOfDay? _waterReminderTime;
  bool _waterReminderEnabled = false;
  TimeOfDay? _bedtimeReminderTime;
  bool _bedtimeReminderEnabled = false;

  @override
  void dispose() {
    _workoutTimer?.cancel();
    super.dispose();
  }

  // ── Sleep quality helpers ──────────────────────────────────────────────────
  String _sleepQualityLabel(double h) {
    if (h <= 0) return '–';
    if (h < 5) return 'Poor';
    if (h < 7) return 'Average';
    if (h <= 9) return 'Excellent';
    return 'Over-slept';
  }

  Color _sleepQualityColor(double h) {
    if (h <= 0) return Colors.grey;
    if (h < 5) return Colors.red;
    if (h < 7) return Colors.orange;
    if (h <= 9) return green;
    return Colors.amber;
  }

  int _sleepQualityScore(double h) {
    if (h <= 0) return 0;
    if (h < 5) return ((h / 5) * 40).round();
    if (h < 7) return (40 + ((h - 5) / 2) * 30).round();
    if (h <= 9) return (70 + ((h - 7) / 2) * 30).round();
    return ((100 - (h - 9) * 15).clamp(0, 100)).round();
  }

  String _getSleepAdvice(double hours) {
    if (hours >= 7 && hours <= 9) return 'Excellent! You are getting well-rested sleep. Keep it up.';
    if (hours >= 5 && hours < 7) return 'Warning: Try to get a bit more sleep. Aim for 7–9 hours for better recovery.';
    return 'Poor sleep! You need more rest. Tips: Sleep by 10–11 PM, avoid screens 1 hour before bed, keep room cool, avoid caffeine after 2 PM, meditate before sleeping.';
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  String _dayLabel(String dateStr) {
    if (dateStr.length < 10) return '';
    try {
      final d = DateTime.parse(dateStr);
      return ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday - 1];
    } catch (_) { return ''; }
  }

  // ── Root build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = Scope.of(context);
    final p = c.profile;
    final isWide = MediaQuery.of(context).size.width > 700;

    final bool complete = p != null && p.age != null && p.height != null &&
        p.weight != null && p.gender.isNotEmpty && p.goal.isNotEmpty;

    double bmi = 0, bmr = 0, tdee = 0, tdeeAdj = 0;
    int protein = 0, carbs = 0, fats = 0;
    if (complete) {
      double w = p.weight!, h = p.height!; int a = p.age!;
      bmi = w / ((h / 100) * (h / 100));
      bmr = p.gender == 'Male' ? (10 * w + 6.25 * h - 5 * a + 5) : (10 * w + 6.25 * h - 5 * a - 161);
      double met = _customMet ?? 1.55;
      if (_customMet == null) {
        if (p.location == 'Home Workout') met = 1.375;
        if (p.goal == 'Improve Stamina' || p.goal == 'Weight Loss') met = 1.55;
      }
      tdee = bmr * met;
      tdeeAdj = tdee;
      if (p.goal == 'Weight Loss') tdeeAdj -= 500;
      if (p.goal == 'Weight Gain') tdeeAdj += 500;
      protein = (w * 2.0).round();
      fats = ((tdeeAdj * 0.25) / 9).round();
      carbs = ((tdeeAdj - (protein * 4) - (fats * 9)) / 4).round();
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(c.t('trackers'), style: Theme.of(context).textTheme.headlineMedium),

        // ── 💧 Hydration ───────────────────────────────────────────────────
        section(c.t('water')),
        _buildWaterSection(context, c, isWide),

        // ── 😴 Sleep ────────────────────────────────────────────────────────
        section(c.t('sleep')),
        _buildSleepSection(context, c),

        // ── 👟 Steps ────────────────────────────────────────────────────────
        section(c.t('steps')),
        _buildStepsSection(context, c, isWide),

        // ── 🔥 Calories ─────────────────────────────────────────────────────
        section(c.t('calorie')),
        if (!complete) ...[
          track(Icons.local_fire_department, 'Complete Profile', Column(children: [
            Text(AppLocalizations.of(context)!.pleaseCompleteYourProfileFirstToCalculateYourPreciseCalories),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/goal'), child: Text(AppLocalizations.of(context)!.editProfileMetrics)),
          ]))
        ] else ...[
          track(Icons.local_fire_department, '${tdeeAdj.round()} kcal / day', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('BMI: ${bmi.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('BMR: ${bmr.round()} kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Container(padding: const EdgeInsets.all(10), color: Colors.blue.shade50, child: Column(children: [Text(AppLocalizations.of(context)!.protein), Text('${protein}g', style: const TextStyle(fontWeight: FontWeight.bold))]))),
              Expanded(child: Container(padding: const EdgeInsets.all(10), color: Colors.green.shade50, child: Column(children: [Text(AppLocalizations.of(context)!.carbs), Text('${carbs}g', style: const TextStyle(fontWeight: FontWeight.bold))]))),
              Expanded(child: Container(padding: const EdgeInsets.all(10), color: Colors.orange.shade50, child: Column(children: [Text(AppLocalizations.of(context)!.fats), Text('${fats}g', style: const TextStyle(fontWeight: FontWeight.bold))]))),
            ]),
            const SizedBox(height: 14),
            DropdownButtonFormField<double>(
              value: _customMet ?? (p.location == 'Home Workout' ? 1.375 : 1.55),
              decoration: const InputDecoration(labelText: 'Activity Level (Optional)'),
              items: [
                DropdownMenuItem(value: 1.2, child: Text(AppLocalizations.of(context)!.sedentary)),
                DropdownMenuItem(value: 1.375, child: Text(AppLocalizations.of(context)!.lightlyActive)),
                DropdownMenuItem(value: 1.55, child: Text(AppLocalizations.of(context)!.moderatelyActive)),
                DropdownMenuItem(value: 1.725, child: Text(AppLocalizations.of(context)!.veryActive)),
              ],
              onChanged: (v) => setState(() => _customMet = v),
            ),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerRight, child: TextButton.icon(icon: const Icon(Icons.edit), label: Text(AppLocalizations.of(context)!.editProfileMetrics), onPressed: () => Navigator.pushNamed(context, '/goal'))),
          ])),
        ],

        // ── ⏱ Workout Timer ─────────────────────────────────────────────────
        section('Workout Timer & Rest Timer'),
        track(Icons.timer, _fmt(_workoutSec), Row(children: [
          Expanded(child: ElevatedButton(
            onPressed: () {
              if (_workoutTimer == null) {
                _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _workoutSec++));
              } else {
                _workoutTimer?.cancel();
                _workoutTimer = null;
              }
              setState(() {});
            },
            child: Text(_workoutTimer == null ? 'Start' : 'Pause'),
          )),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton(onPressed: () => setState(() => _workoutSec = 0), child: Text(AppLocalizations.of(context)!.reset))),
        ])),

        // ── ✅ Habits ────────────────────────────────────────────────────────
        section(c.t('habits')),
        for (final h in habits)
          CheckboxListTile(
            value: c.habits[h] ?? false,
            onChanged: (_) => c.toggleHabit(h),
            title: Text(h),
            activeColor: green,
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
      ],
    );
  }

  // ── 💧 Water Section ───────────────────────────────────────────────────────
  Widget _buildWaterSection(BuildContext context, AppController c, bool isWide) {
    final goal = c.waterGoal;
    final pct = (c.water / goal).clamp(0.0, 1.0);
    final remaining = (goal - c.water).clamp(0, goal);

    // Streak: consecutive days from today backwards where water_ml >= target_ml
    int streak = 0;
    for (int i = c.weeklyHydration.length - 1; i >= 0; i--) {
      final d = c.weeklyHydration[i];
      final ml = (d['water_ml'] as int?) ?? 0;
      final tgt = (d['target_ml'] as int?) ?? goal;
      if (ml >= tgt) streak++;
      else break;
    }

    return track(
      Icons.water_drop,
      '${c.water} ml / $goal ml',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Progress ring + stats
        Row(children: [
          SizedBox(
            width: 84, height: 84,
            child: CustomPaint(
              painter: _RingPainter(progress: pct, color: Colors.blue),
              child: Center(child: Text('${(pct * 100).round()}%',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textDark))),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _statRow(Icons.flag_outlined,   'Goal',      '$goal ml',    Colors.blue),
            const SizedBox(height: 6),
            _statRow(Icons.emoji_events_outlined, 'Streak', '$streak day${streak == 1 ? '' : 's'}', Colors.amber),
            const SizedBox(height: 6),
            _statRow(Icons.water_outlined, 'Remaining', '$remaining ml', Colors.teal),
          ])),
        ]),
        const SizedBox(height: 12),
        // Linear progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct, minHeight: 10,
            backgroundColor: Colors.blue.shade50,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        const SizedBox(height: 14),
        // Quick-add buttons
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final ml in [250, 500, 750, 1000])
            _addButton('+${ml}ml', Colors.blue, () => c.waterAdd(ml)),
          _outlineButton('Custom', Colors.blue, () => _showCustomWaterDialog(context, c)),
          _outlineButton(AppLocalizations.of(context)!.reset, Colors.grey, () => c.waterAdd(-c.water)),
        ]),
        const SizedBox(height: 16),
        // 7-day chart
        if (c.weeklyHydration.isNotEmpty) ...[
          const Text('7-Day History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
          const SizedBox(height: 8),
          _BarChart(
            data: c.weeklyHydration.map((d) {
              final ml = (d['water_ml'] as int?) ?? 0;
              final tgt = (d['target_ml'] as int?) ?? goal;
              return _BarData(
                label: _dayLabel(d['date']?.toString() ?? ''),
                value: ml.toDouble(),
                maxValue: (goal * 1.2),
                color: ml >= tgt ? Colors.blue : Colors.blue.shade200,
                tooltip: '${ml}ml',
                isToday: d['date'] == DateTime.now().toIso8601String().substring(0, 10),
              );
            }).toList(),
            goalLine: goal.toDouble(),
            goalMax: (goal * 1.2),
          ),
        ],
        const SizedBox(height: 14),
        // Water reminder
        _reminderTile(
          context: context,
          icon: Icons.water_drop_outlined,
          label: 'Water Reminder',
          time: _waterReminderTime,
          enabled: _waterReminderEnabled,
          color: Colors.blue,
          onToggle: (v) async {
            setState(() => _waterReminderEnabled = v);
            if (v && _waterReminderTime != null) {
              await NotificationService().scheduleDailyNotification(
                id: 10, title: 'NutriFit 💧 Hydration',
                body: 'Time to drink water! Stay hydrated.',
                hour: _waterReminderTime!.hour, minute: _waterReminderTime!.minute,
              );
            } else {
              await NotificationService().cancelNotification(10);
            }
          },
          onTimeTap: () async {
            final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
            if (t != null) setState(() => _waterReminderTime = t);
          },
        ),
      ]),
    );
  }

  // ── 😴 Sleep Section ───────────────────────────────────────────────────────
  Widget _buildSleepSection(BuildContext context, AppController c) {
    final qScore = _sleepQualityScore(c.sleep);
    final qLabel = _sleepQualityLabel(c.sleep);
    final qColor = _sleepQualityColor(c.sleep);

    return track(
      Icons.bedtime,
      '${c.sleep.toStringAsFixed(1)} hours',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Quality ring + stats
        Row(children: [
          SizedBox(
            width: 84, height: 84,
            child: CustomPaint(
              painter: _RingPainter(progress: qScore / 100.0, color: qColor),
              child: Center(child: Text('$qScore',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: qColor))),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: qColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(qLabel, style: TextStyle(color: qColor, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(height: 8),
            _statRow(Icons.nightlight_round,   'Target', '7–9 hours', Colors.indigo),
            const SizedBox(height: 6),
            _statRow(Icons.score_outlined, 'Quality', '$qScore / 100', qColor),
          ])),
        ]),
        const SizedBox(height: 14),
        // Time pickers
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.nights_stay),
            label: Text(_sleepTime?.format(context) ?? 'Sleep Time'),
            onPressed: () async {
              final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 22, minute: 0));
              if (t != null) setState(() => _sleepTime = t);
            },
          )),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.wb_sunny),
            label: Text(_wakeTime?.format(context) ?? 'Wake Time'),
            onPressed: () async {
              final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 6, minute: 0));
              if (t != null) setState(() => _wakeTime = t);
            },
          )),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_sleepTime != null && _wakeTime != null) {
                double sH = _sleepTime!.hour + _sleepTime!.minute / 60.0;
                double wH = _wakeTime!.hour + _wakeTime!.minute / 60.0;
                double diff = wH - sH;
                if (diff < 0) diff += 24;
                c.sleepSet(diff);
              }
            },
            child: Text(AppLocalizations.of(context)!.calculateSleep),
          ),
        ),
        if (c.sleep > 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(12)),
            child: Text(_getSleepAdvice(c.sleep), style: const TextStyle(color: textDark)),
          ),
        ],
        const SizedBox(height: 16),
        // 7-day chart
        if (c.weeklySleep.isNotEmpty) ...[
          const Text('7-Day History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
          const SizedBox(height: 8),
          _BarChart(
            data: c.weeklySleep.map((d) {
              final h = (double.tryParse('${d['sleep_hours'] ?? 0}') ?? 0.0);
              return _BarData(
                label: _dayLabel(d['date']?.toString() ?? ''),
                value: h,
                maxValue: 12,
                color: (h >= 7 && h <= 9)
                    ? Colors.indigo
                    : h > 0 ? Colors.indigo.shade200 : Colors.grey.shade200,
                tooltip: '${h.toStringAsFixed(1)}h',
                isToday: d['date'] == DateTime.now().toIso8601String().substring(0, 10),
              );
            }).toList(),
            goalLine: 7,
            goalMax: 12,
          ),
        ],
        const SizedBox(height: 14),
        // Bedtime reminder
        _reminderTile(
          context: context,
          icon: Icons.bedtime_outlined,
          label: 'Bedtime Reminder',
          time: _bedtimeReminderTime,
          enabled: _bedtimeReminderEnabled,
          color: Colors.indigo,
          onToggle: (v) async {
            setState(() => _bedtimeReminderEnabled = v);
            if (v && _bedtimeReminderTime != null) {
              await NotificationService().scheduleDailyNotification(
                id: 11, title: 'NutriFit 😴 Bedtime',
                body: 'Time to wind down and get some rest!',
                hour: _bedtimeReminderTime!.hour, minute: _bedtimeReminderTime!.minute,
              );
            } else {
              await NotificationService().cancelNotification(11);
            }
          },
          onTimeTap: () async {
            final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 22, minute: 0));
            if (t != null) setState(() => _bedtimeReminderTime = t);
          },
        ),
      ]),
    );
  }

  // ── 👟 Steps Section ───────────────────────────────────────────────────────
  Widget _buildStepsSection(BuildContext context, AppController c, bool isWide) {
    const stepGoal = 8000;
    final pct = (c.steps / stepGoal).clamp(0.0, 1.0);
    final calsBurned = (c.steps * 0.04).toStringAsFixed(0);
    final distanceKm = (c.steps * 0.000762).toStringAsFixed(2);
    final weeklyTotal = c.weeklySteps.fold<int>(0, (s, d) => s + ((d['steps'] as int?) ?? 0));
    final weeklyAvg = c.weeklySteps.isNotEmpty ? (weeklyTotal / c.weeklySteps.length).round() : 0;

    return track(
      Icons.directions_walk,
      '${c.steps} / $stepGoal steps',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct, minHeight: 12,
            backgroundColor: lightGreen,
            valueColor: const AlwaysStoppedAnimation<Color>(green),
          ),
        ),
        const SizedBox(height: 4),
        Text('${(pct * 100).round()}% of daily goal',
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 14),
        // Stats chips
        Wrap(spacing: 10, runSpacing: 10, children: [
          _metricChip(Icons.local_fire_department_outlined, '$calsBurned kcal', 'Calories', Colors.orange),
          _metricChip(Icons.straighten, '$distanceKm km', 'Distance', Colors.teal),
          _metricChip(Icons.bar_chart, '$weeklyTotal', 'Weekly Total', green),
          _metricChip(Icons.trending_up, '$weeklyAvg', 'Daily Avg', Colors.purple),
        ]),
        const SizedBox(height: 14),
        // Quick-add buttons row
        Row(children: [
          for (int i = 0; i < [500, 1000, 2000, 5000].length; i++) ...[
            Expanded(child: ElevatedButton(
              onPressed: () => c.stepsAdd([500, 1000, 2000, 5000][i]),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('+${[500, 1000, 2000, 5000][i]}', style: const TextStyle(fontSize: 12)),
            )),
            if (i < 3) const SizedBox(width: 6),
          ],
        ]),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: () => c.stepsAdd(-c.steps),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(AppLocalizations.of(context)!.reset, style: const TextStyle(fontSize: 12)),
        )),
        const SizedBox(height: 16),
        // 7-day chart
        if (c.weeklySteps.isNotEmpty) ...[
          const Text('7-Day History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
          const SizedBox(height: 8),
          _BarChart(
            data: c.weeklySteps.map((d) {
              final s = (d['steps'] as int?) ?? 0;
              return _BarData(
                label: _dayLabel(d['date']?.toString() ?? ''),
                value: s.toDouble(),
                maxValue: stepGoal * 1.3,
                color: s >= stepGoal ? green : s > 0 ? const Color(0xFF80CCA8) : Colors.grey.shade200,
                tooltip: '$s steps',
                isToday: d['date'] == DateTime.now().toIso8601String().substring(0, 10),
              );
            }).toList(),
            goalLine: stepGoal.toDouble(),
            goalMax: stepGoal * 1.3,
          ),
        ],
      ]),
    );
  }

  // ── Reusable tiny helpers ───────────────────────────────────────────────────
  Widget _statRow(IconData icon, String label, String value, Color color) => Row(children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 6),
    Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
    Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color), overflow: TextOverflow.ellipsis)),
  ]);

  Widget _metricChip(IconData icon, String value, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
      ]),
    ]),
  );

  Widget _addButton(String label, Color color, VoidCallback onTap) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );

  Widget _outlineButton(String label, Color color, VoidCallback onTap) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      side: BorderSide(color: color),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(label, style: TextStyle(fontSize: 12, color: color)),
  );

  Widget _reminderTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required TimeOfDay? time,
    required bool enabled,
    required Color color,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTimeTap,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
        GestureDetector(
          onTap: onTimeTap,
          child: Text(
            time != null ? time.format(context) : 'Tap to set time',
            style: TextStyle(fontSize: 12, color: time != null ? color : Colors.grey),
          ),
        ),
      ])),
      Switch(value: enabled, onChanged: onToggle, activeColor: color),
    ]),
  );

  void _showCustomWaterDialog(BuildContext context, AppController c) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Custom Amount'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (ml)', hintText: 'e.g. 350'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final ml = int.tryParse(ctrl.text.trim());
              if (ml != null && ml > 0) c.waterAdd(ml);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ── track() helper ────────────────────────────────────────────────────────────
Widget track(IconData icon, String title, Widget child) => Container(
  margin: const EdgeInsets.only(bottom: 14),
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: const Color(0xFFE7EEE9)),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
  ),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      CircleAvatar(backgroundColor: lightGreen, child: Icon(icon, color: green)),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
    ]),
    const SizedBox(height: 14),
    child,
  ]),
);

// ── 7-Day Bar Chart widget ────────────────────────────────────────────────────
class _BarData {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final String tooltip;
  final bool isToday;
  const _BarData({
    required this.label, required this.value, required this.maxValue,
    required this.color, required this.tooltip, this.isToday = false,
  });
}

class _BarChart extends StatelessWidget {
  final List<_BarData> data;
  final double goalLine;
  final double goalMax;
  const _BarChart({required this.data, required this.goalLine, required this.goalMax});

  @override
  Widget build(BuildContext context) {
    const maxH = 72.0;
    final goalBarH = goalMax > 0 ? ((goalLine / goalMax) * maxH).clamp(0.0, maxH) : 0.0;
    return SizedBox(
      height: maxH + 22,
      child: Stack(children: [
        // Dashed goal line
        Positioned(
          bottom: 22 + goalBarH - 1,
          left: 0, right: 0,
          child: Row(children: List.generate(20, (i) => Expanded(
            child: Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 2),
                color: i.isEven ? Colors.grey.shade300 : Colors.transparent),
          ))),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((d) {
            final barH = goalMax > 0 ? ((d.value / goalMax) * maxH).clamp(d.value > 0 ? 4.0 : 0.0, maxH) : 0.0;
            return Expanded(
              child: Tooltip(
                message: '${d.label}: ${d.tooltip}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: barH,
                      decoration: BoxDecoration(
                        color: d.color,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        border: d.isToday ? Border.all(color: green, width: 1.5) : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(d.label,
                      style: TextStyle(
                        fontSize: 9,
                        color: d.isToday ? green : Colors.grey,
                        fontWeight: d.isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

// ── Circular Ring Painter ─────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 7;
    final bg = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      progress.clamp(0.0, 1.0) * 6.2832,
      false, fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}



class ShopTab extends StatefulWidget{ const ShopTab({super.key}); @override State<ShopTab> createState()=>_ShopTabState();}
class _ShopTabState extends State<ShopTab>{
  String brand='All';
  @override Widget build(BuildContext context){
    final c=Scope.of(context);
    final list=products.where((p)=>brand=='All'||p.brand==brand).toList();
    final total=c.cart.entries.fold<double>(0,(s,e)=>s+products.firstWhere((p)=>p.id==e.key).price*e.value);
    final cartCount = c.cart.values.fold<int>(0, (sum, qty) => sum + qty);

    return ListView(
      padding:const EdgeInsets.all(20),
      children:[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(c.t('shop'),style:Theme.of(context).textTheme.headlineMedium),
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart, color: green, size: 28),
                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: Colors.redAccent,
                      child: Text(
                        cartCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Text(AppLocalizations.of(context)!.fitnessShoppingModuleWithWishlistAndCart),
        SizedBox(height:14),
        Wrap(spacing:8,children:[for(final b in ['All','GNC','MuscleBlaze','YouWeFit']) ChoiceChip(label:Text(b),selected:brand==b,onSelected:(_)=>setState(()=>brand=b))]),
        SizedBox(height:14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
          childAspectRatio: MediaQuery.of(context).size.width > 700 ? 0.8 : 0.52,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: list.map((p) => productCard(context, p)).toList(),
        ),
        section('Cart'),
        InkWell(
          onTap: () => Navigator.pushNamed(context, '/cart'),
          borderRadius: BorderRadius.circular(24),
          child: infoBox(Icons.shopping_cart,'$cartCount items • ₹${total.toStringAsFixed(0)} (Tap to view Cart)'),
        )
      ]
    );
  }
}
Widget productCard(BuildContext context,Product p){
  final c=Scope.of(context);
  final liked=c.wishlist.contains(p.id);
  final isWeb = MediaQuery.of(context).size.width > 700;
  
  Widget imageStack = Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          p.imagePath,
          width: double.infinity,
          height: 220,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.shopping_bag, size: 70),
        ),
      ),
      Align(
        alignment: Alignment.topRight,
        child: IconButton(
          onPressed: () => c.toggleWish(p),
          icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? Colors.redAccent : green),
        ),
      ),
    ],
  );

  return card(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (isWeb) SizedBox(height: 160, child: imageStack) else Expanded(child: imageStack),
      Text(p.brand, style: const TextStyle(color: green, fontWeight: FontWeight.w700)),
      Text(p.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800)),
      Text('₹${p.price.toStringAsFixed(0)} • ⭐ ${p.rating}'),
      SizedBox(height: 8),
      if (isWeb) const Spacer(),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: const BorderSide(color: green),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await c.addCart(p);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.addedToCart),
                      backgroundColor: green,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Add', style: TextStyle(color: green, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                backgroundColor: green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/checkout', arguments: p);
              },
              child: const Text('Order Now', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ],
  ));
}

class ProfileTab extends StatelessWidget{ const ProfileTab({super.key}); @override Widget build(BuildContext context){final c=Scope.of(context);final p=c.profile;return ListView(padding:const EdgeInsets.all(20),children:[Text(c.t('profile'),style:Theme.of(context).textTheme.headlineMedium),SizedBox(height:16),card(Row(children:[CircleAvatar(radius:34,backgroundColor:lightGreen,child:Text((p?.name.isNotEmpty==true?p!.name[0]:'N').toUpperCase(),style:const TextStyle(fontSize:28,color:green,fontWeight:FontWeight.w900))),SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p?.name.isNotEmpty==true?p!.name:'NutriFit User',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),Text(p?.email.isNotEmpty==true?p!.email:'demo@nutrifit.local'),Text(p?.goal.isNotEmpty==true?p!.goal:'General Fitness',style:const TextStyle(color:green,fontWeight:FontWeight.w700))]))])),section('Progress Tracking'),detail('Age','${p?.age??'-'}'),detail('Height','${p?.height?.toStringAsFixed(0)??'-'} cm'),detail('Weight','${p?.weight?.toStringAsFixed(0)??'-'} kg'),detail('Food',p?.food??'-'),detail('Workout',p?.location??'-'),section(c.t('settings')),card(Column(children:[Row(children:[Expanded(child:Text(c.t('language'),style:const TextStyle(fontWeight:FontWeight.w800))),DropdownButton<String>(value:c.lang,items: [DropdownMenuItem(value:'en',child:Text('English')),DropdownMenuItem(value:'ta',child:Text('தமிழ்')),DropdownMenuItem(value:'hi',child:Text('हिन्दी')),DropdownMenuItem(value:'te',child:Text('తెలుగు')),DropdownMenuItem(value:'ml',child:Text('മലയാളം')),DropdownMenuItem(value:'kn',child:Text('ಕನ್ನಡ')),DropdownMenuItem(value:'ar',child:Text('العربية'))],onChanged:(s)=>c.setLang(s??'en'))]),const Divider(),ListTile(leading:Icon(Icons.local_shipping_outlined,color:green),title:const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w700)),trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),onTap:()=>Navigator.pushNamed(context,'/orders')),const Divider(),ListTile(leading:Icon(Icons.edit,color:green),title:Text(AppLocalizations.of(context)!.editOnboardingDetails),onTap:()=>go(context,'/goal')),ListTile(leading:Icon(Icons.logout,color:Colors.redAccent),title:Text(c.t('logout')),onTap:()async{await c.logout();if(context.mounted)Navigator.pushNamedAndRemoveUntil(context,'/login',(_)=>false);})]))]);}}
Widget detail(String l,String v)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFE7EEE9))),child:Row(children:[Expanded(child:Text(l,style:const TextStyle(fontWeight:FontWeight.w800))),Text(v)]));

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Scope.of(context);
    final cartItems = c.cart.entries.toList();
    final total = cartItems.fold<double>(0, (s, e) {
      final p = products.firstWhere((prod) => prod.id == e.key, orElse: () => const Product('', '', '', '', '', 0, '', 0));
      return s + p.price * e.value;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('My Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: lightGreen,
                      child: Icon(Icons.shopping_bag_outlined, color: green, size: 48),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Explore our shop tab to add nutritional supplements and fitness gear to your cart.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: textDark.withOpacity(0.6)),
                    ),
                    SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        minimumSize: const Size(0, 50),
                      ),
                      child: Text('Go Shopping', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: cartItems.length,
                    itemBuilder: (ctx, i) {
                      final item = cartItems[i];
                      final p = products.firstWhere((prod) => prod.id == item.key, orElse: () => const Product('', '', '', '', '', 0, '', 0));
                      if (p.id.isEmpty) return const SizedBox.shrink();
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFCFB),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Image.asset(
                                  p.imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          p.brand,
                                          style: const TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                          onPressed: () => c.deleteCart(p),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark),
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '₹${p.price.toStringAsFixed(0)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => c.removeCart(p),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.grey.shade300),
                                                ),
                                                child: Icon(Icons.remove, size: 14, color: textDark),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              child: Text(
                                                item.value.toString(),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => c.addCart(p),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.grey.shade300),
                                                ),
                                                child: Icon(Icons.add, size: 14, color: textDark),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal',
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(color: textDark, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivery',
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'FREE',
                            style: TextStyle(color: green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Color(0xFFF1F5F2)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Price',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: green),
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/checkout');
                        },
                        child: const Text('Proceed to Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final Product? directProduct;
  const CheckoutScreen({super.key, this.directProduct});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isAddNew = false;
  DeliveryAddress? _selectedAddress;
  String? _editingAddressId;

  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _houseCtrl;
  late TextEditingController _streetCtrl;
  late TextEditingController _landmarkCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _districtCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _pincodeCtrl;
  late TextEditingController _instructionsCtrl;

  String _paymentMethod = 'Cash on Delivery'; // 'Cash on Delivery', 'UPI', 'Card'
  final TextEditingController _upiCtrl = TextEditingController();
  final TextEditingController _cardNumberCtrl = TextEditingController();
  final TextEditingController _cardExpiryCtrl = TextEditingController();
  final TextEditingController _cardCvvCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _mobileCtrl = TextEditingController();
    _houseCtrl = TextEditingController();
    _streetCtrl = TextEditingController();
    _landmarkCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _districtCtrl = TextEditingController();
    _stateCtrl = TextEditingController(text: 'Tamil Nadu');
    _pincodeCtrl = TextEditingController();
    _instructionsCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _houseCtrl.dispose();
    _streetCtrl.dispose();
    _landmarkCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _instructionsCtrl.dispose();
    _upiCtrl.dispose();
    _cardNumberCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    super.dispose();
  }

  void _fillFormForEdit(DeliveryAddress addr) {
    setState(() {
      _isAddNew = true;
      _editingAddressId = addr.id;
      _nameCtrl.text = addr.fullName;
      _mobileCtrl.text = addr.mobile;
      _houseCtrl.text = addr.houseNo;
      _streetCtrl.text = addr.street;
      _landmarkCtrl.text = addr.landmark;
      _cityCtrl.text = addr.city;
      _districtCtrl.text = addr.district;
      _stateCtrl.text = addr.state;
      _pincodeCtrl.text = addr.pincode;
      _instructionsCtrl.text = addr.instructions;
    });
  }

  void _clearForm() {
    setState(() {
      _isAddNew = false;
      _editingAddressId = null;
      _nameCtrl.clear();
      _mobileCtrl.clear();
      _houseCtrl.clear();
      _streetCtrl.clear();
      _landmarkCtrl.clear();
      _cityCtrl.clear();
      _districtCtrl.clear();
      _stateCtrl.text = 'Tamil Nadu';
      _pincodeCtrl.clear();
      _instructionsCtrl.clear();
    });
  }

  void _prefillProfile(AppController c) {
    if (_nameCtrl.text.isEmpty && c.profile?.name.isNotEmpty == true) {
      _nameCtrl.text = c.profile!.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Scope.of(context);
    _prefillProfile(c);

    final List<OrderItem> checkoutItems;
    if (widget.directProduct != null) {
      checkoutItems = [
        OrderItem(
          productId: widget.directProduct!.id,
          productName: widget.directProduct!.name,
          brand: widget.directProduct!.brand,
          imagePath: widget.directProduct!.imagePath,
          price: widget.directProduct!.price,
          quantity: 1,
        )
      ];
    } else {
      checkoutItems = c.cart.entries.map((e) {
        final p = products.firstWhere((prod) => prod.id == e.key, orElse: () => const Product('', '', '', '', '', 0, '', 0));
        return OrderItem(
          productId: p.id,
          productName: p.name,
          brand: p.brand,
          imagePath: p.imagePath,
          price: p.price,
          quantity: e.value,
        );
      }).where((i) => i.productId.isNotEmpty).toList();
    }

    final subtotal = checkoutItems.fold<double>(0, (sum, item) => sum + item.price * item.quantity);
    final deliveryCharge = subtotal >= 999 || subtotal == 0 ? 0.0 : 50.0;
    final grandTotal = subtotal + deliveryCharge;

    if (_selectedAddress == null && c.addresses.isNotEmpty && !_isAddNew) {
      _selectedAddress = c.addresses.firstWhere((a) => a.isDefault, orElse: () => c.addresses.first);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: checkoutItems.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: lightGreen,
                      child: Icon(Icons.shopping_cart_outlined, color: green, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text('No items to checkout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to Shop'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Delivery Address
                  _buildSectionHeader(Icons.location_on_outlined, 'Delivery Address'),
                  const SizedBox(height: 12),
                  
                  if (c.addresses.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Use Saved Address'),
                            selected: !_isAddNew,
                            selectedColor: lightGreen,
                            onSelected: (val) {
                              if (val) setState(() => _isAddNew = false);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('+ Add New Address'),
                            selected: _isAddNew,
                            selectedColor: lightGreen,
                            onSelected: (val) {
                              if (val) _clearForm();
                              setState(() => _isAddNew = true);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (!_isAddNew && c.addresses.isNotEmpty)
                    _buildSavedAddressesList(c)
                  else
                    _buildAddressForm(c),

                  const SizedBox(height: 24),

                  // Section 2: Order Summary
                  _buildSectionHeader(Icons.receipt_long_outlined, 'Order Summary'),
                  const SizedBox(height: 12),
                  _buildOrderSummaryCard(checkoutItems, subtotal, deliveryCharge, grandTotal),

                  const SizedBox(height: 24),

                  // Section 3: Payment Options
                  _buildSectionHeader(Icons.payment_outlined, 'Payment Method'),
                  const SizedBox(height: 12),
                  _buildPaymentOptionsCard(),

                  const SizedBox(height: 28),

                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isSubmitting ? null : () => _handlePlaceOrder(c, checkoutItems),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Place Order • ₹${grandTotal.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: lightGreen,
          child: Icon(icon, color: green, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
      ],
    );
  }

  Widget _buildSavedAddressesList(AppController c) {
    return Column(
      children: c.addresses.map((addr) {
        final isSelected = _selectedAddress?.id == addr.id;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isSelected ? green : const Color(0xFFE7EEE9), width: isSelected ? 2 : 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: RadioListTile<DeliveryAddress>(
            value: addr,
            groupValue: _selectedAddress,
            activeColor: green,
            onChanged: (val) => setState(() => _selectedAddress = val),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(addr.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                      onPressed: () => _fillFormForEdit(addr),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      onPressed: () => _confirmDeleteAddress(c, addr),
                    ),
                  ],
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📱 ${addr.mobile}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark)),
                const SizedBox(height: 4),
                Text(addr.formattedAddress, style: TextStyle(fontSize: 13, color: textDark.withOpacity(0.7))),
                if (addr.instructions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Note: ${addr.instructions}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _confirmDeleteAddress(AppController c, DeliveryAddress addr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Address?'),
        content: Text('Are you sure you want to remove ${addr.fullName}\'s address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              c.deleteAddress(addr.id);
              if (_selectedAddress?.id == addr.id) {
                _selectedAddress = c.addresses.isNotEmpty ? c.addresses.first : null;
              }
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressForm(AppController c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EEE9)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter full name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Number *', prefixIcon: Icon(Icons.phone_android_outlined), hintText: '10-digit mobile number'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter mobile number';
                if (!DeliveryAddress.isValidMobile(v)) return 'Enter valid 10-digit Indian mobile number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _houseCtrl,
                    decoration: const InputDecoration(labelText: 'House / Flat No *', prefixIcon: Icon(Icons.home_outlined)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter house/flat no' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pincodeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pincode *', prefixIcon: Icon(Icons.pin_drop_outlined), hintText: '6-digit pincode'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter pincode';
                      if (!DeliveryAddress.isValidPincode(v)) return 'Enter valid 6-digit pincode';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _streetCtrl,
              decoration: const InputDecoration(labelText: 'Street / Area / Colony *', prefixIcon: Icon(Icons.map_outlined)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter street / area' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _landmarkCtrl,
              decoration: const InputDecoration(labelText: 'Landmark (Optional)', prefixIcon: Icon(Icons.nature_people_outlined), hintText: 'Near hospital, school, etc.'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(labelText: 'City *', prefixIcon: Icon(Icons.location_city_outlined)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter city' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _districtCtrl,
                    decoration: const InputDecoration(labelText: 'District *', prefixIcon: Icon(Icons.landscape_outlined)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter district' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stateCtrl,
              decoration: const InputDecoration(labelText: 'State *', prefixIcon: Icon(Icons.flag_outlined)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter state' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructionsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Delivery Instructions (Optional)', prefixIcon: Icon(Icons.note_alt_outlined), hintText: 'Leave at door, call before arrival, etc.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(List<OrderItem> items, double subtotal, double deliveryCharge, double grandTotal) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EEE9)),
      ),
      child: Column(
        children: [
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    item.imagePath,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center, size: 30, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${item.brand} • Qty: ${item.quantity}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          )),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(color: Colors.grey, fontSize: 14)),
              Text('₹${subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Charge', style: TextStyle(color: Colors.grey, fontSize: 14)),
              Text(
                deliveryCharge == 0 ? 'FREE' : '₹${deliveryCharge.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: deliveryCharge == 0 ? green : textDark),
              ),
            ],
          ),
          if (deliveryCharge == 0) ...[
            const SizedBox(height: 4),
            Row(
              children: const [
                Icon(Icons.stars_rounded, color: green, size: 14),
                SizedBox(width: 4),
                Text('Free delivery applied on order above ₹999!', style: TextStyle(color: green, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
              Text('₹${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EEE9)),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            value: 'Cash on Delivery',
            groupValue: _paymentMethod,
            activeColor: green,
            onChanged: (val) => setState(() => _paymentMethod = val!),
            title: Row(
              children: const [
                Icon(Icons.payments_outlined, color: green, size: 20),
                SizedBox(width: 10),
                Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            subtitle: const Text('Pay cash upon delivery at your doorstep'),
          ),
          const Divider(height: 1),
          RadioListTile<String>(
            value: 'UPI',
            groupValue: _paymentMethod,
            activeColor: green,
            onChanged: (val) => setState(() => _paymentMethod = val!),
            title: Row(
              children: const [
                Icon(Icons.qr_code_scanner_rounded, color: Colors.blue, size: 20),
                SizedBox(width: 10),
                Text('UPI (Google Pay / PhonePe / Paytm)', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            subtitle: const Text('Instant & secure payment via UPI app'),
          ),
          if (_paymentMethod == 'UPI')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextFormField(
                controller: _upiCtrl,
                decoration: const InputDecoration(
                  labelText: 'UPI ID (Optional)',
                  hintText: 'e.g. mobile@upi or username@okaxis',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
            ),
          const Divider(height: 1),
          RadioListTile<String>(
            value: 'Card',
            groupValue: _paymentMethod,
            activeColor: green,
            onChanged: (val) => setState(() => _paymentMethod = val!),
            title: Row(
              children: const [
                Icon(Icons.credit_card_rounded, color: Colors.purple, size: 20),
                SizedBox(width: 10),
                Text('Credit / Debit Card', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            subtitle: const Text('Visa, MasterCard, RuPay supported'),
          ),
          if (_paymentMethod == 'Card')
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _cardNumberCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Card Number', prefixIcon: Icon(Icons.credit_card), hintText: '16-digit card number'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cardExpiryCtrl,
                          decoration: const InputDecoration(labelText: 'Expiry (MM/YY)', hintText: '12/28'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _cardCvvCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'CVV', hintText: '3 digits'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handlePlaceOrder(AppController c, List<OrderItem> checkoutItems) async {
    DeliveryAddress activeAddr;

    if (_isAddNew || c.addresses.isEmpty) {
      if (!_formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required address fields correctly'), backgroundColor: Colors.redAccent),
        );
        return;
      }
      activeAddr = DeliveryAddress(
        id: _editingAddressId ?? 'addr-${DateTime.now().millisecondsSinceEpoch}',
        fullName: _nameCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        houseNo: _houseCtrl.text.trim(),
        street: _streetCtrl.text.trim(),
        landmark: _landmarkCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        instructions: _instructionsCtrl.text.trim(),
        isDefault: c.addresses.isEmpty,
      );
      await c.saveAddress(activeAddr);
    } else {
      if (_selectedAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or add a delivery address'), backgroundColor: Colors.redAccent),
        );
        return;
      }
      activeAddr = _selectedAddress!;
    }

    setState(() => _isSubmitting = true);

    try {
      final order = await c.placeOrder(
        address: activeAddr,
        paymentMethod: _paymentMethod,
        directItems: widget.directProduct != null ? checkoutItems : null,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/order_confirmation', arguments: order);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class OrderConfirmationScreen extends StatelessWidget {
  final ShopOrder order;
  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final estDate = DateTime.now().add(const Duration(days: 3));
    final estStr = '${estDate.day} ${_getMonthName(estDate.month)} ${estDate.year}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Placed', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: lightGreen,
              child: Icon(Icons.check_circle_rounded, color: green, size: 64),
            ),
            const SizedBox(height: 20),
            const Text(
              'Thank you for your order!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order has been confirmed and is being processed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: textDark.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            
            // Order ID Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tag_rounded, color: green, size: 18),
                  const SizedBox(width: 6),
                  Text('Order ID: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: green, fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Order Details Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFCFB),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE7EEE9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: green, size: 20),
                      const SizedBox(width: 8),
                      Text('Estimated Delivery: $estStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 20),
                  Text('Delivering to:', style: TextStyle(fontSize: 12, color: textDark.withOpacity(0.6))),
                  const SizedBox(height: 4),
                  Text(order.address.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(order.address.formattedAddress, style: TextStyle(fontSize: 13, color: textDark.withOpacity(0.7))),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Payment: ${order.paymentMethod}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('Total: ₹${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pushReplacementNamed(context, '/orders'),
                child: const Text('Track Order in My Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: green),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false),
                child: const Text('Continue Shopping', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: green)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[month - 1];
  }
}

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = Scope.of(context);
      await c.loadOrders();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Scope.of(context);
    final orders = c.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: green,
        child: _loading && orders.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: green),
                ),
              )
            : _error != null && orders.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.redAccent,
                            child: Icon(Icons.error_outline, color: Colors.white, size: 40),
                          ),
                          const SizedBox(height: 16),
                          const Text('Failed to load orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _fetchOrders,
                            style: ElevatedButton.styleFrom(backgroundColor: green),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : orders.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircleAvatar(
                                  radius: 56,
                                  backgroundColor: lightGreen,
                                  child: Icon(Icons.local_shipping_outlined, color: green, size: 48),
                                ),
                                const SizedBox(height: 20),
                                const Text('No orders yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('Place your first order from our Shop tab!', textAlign: TextAlign.center, style: TextStyle(color: textDark.withOpacity(0.6))),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(backgroundColor: green),
                                  child: const Text('Explore Shop', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: orders.length,
                        itemBuilder: (ctx, idx) {
                          final order = orders[idx];
                          return _OrderCard(order: order);
                        },
                      ),
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final ShopOrder order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;
  bool _actionLoading = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final c = Scope.of(context);
    final dateStr = '${o.date.day} ${_getMonthName(o.date.month)} ${o.date.year}';

    final isCancelable = o.status == 'Confirmed' || o.status == 'Packed';
    final isDelivered = o.status == 'Delivered';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EEE9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: green)),
                      const SizedBox(height: 2),
                      Text('Ordered on $dateStr', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: o.status == 'Cancelled' ? Colors.redAccent.withOpacity(0.1) : green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    o.status,
                    style: TextStyle(
                      color: o.status == 'Cancelled' ? Colors.redAccent : green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (o.status == 'Cancelled') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text('This order was cancelled.', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              _buildTimeline(o.status),
              const SizedBox(height: 12),
            ],

            const Divider(height: 20),

            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: o.items.map((item) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFCFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE7EEE9)),
                        ),
                        child: Image.asset(
                          item.imagePath,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 24, color: Colors.grey),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total Amount', style: TextStyle(fontSize: 11, color: textDark.withOpacity(0.6))),
                    Text('₹${o.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: green, size: 18),
                  label: Text(_expanded ? 'Hide Details' : 'View Order Details', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: green)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
                const Spacer(),
                if (isCancelable)
                  ElevatedButton(
                    onPressed: _actionLoading ? null : () => _confirmCancelOrder(c, o.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel Order', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                if (isDelivered)
                  ElevatedButton(
                    onPressed: _actionLoading ? null : () => _handleBuyAgain(c, o),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Buy Again', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),

            if (_expanded) ...[
              const Divider(height: 20),
              const Text('Items Ordered:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              ...o.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.productName} (x${item.quantity})', style: const TextStyle(fontSize: 13))),
                    Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              )),
              const Divider(height: 16),
              const Text('Shipping Address:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(o.address.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('📱 ${o.address.mobile}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text(o.address.formattedAddress, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (o.address.instructions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Delivery Note: ${o.address.instructions}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Method:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(o.paymentMethod, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Status:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    o.paymentStatus,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: o.paymentStatus == 'Paid' ? green : (o.paymentStatus == 'Cancelled' ? Colors.redAccent : Colors.orange),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('₹${o.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              if (o.deliveryCharge > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Charge:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('₹${o.deliveryCharge.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final stages = ['Confirmed', 'Packed', 'Shipped', 'Out for Delivery', 'Delivered'];
    int currentIdx = stages.indexOf(currentStatus);
    if (currentIdx < 0) currentIdx = 0;

    return Row(
      children: List.generate(stages.length, (index) {
        final isCompleted = index <= currentIdx;
        final isLast = index == stages.length - 1;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: isCompleted ? green : Colors.grey.shade300,
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle,
                      size: 11,
                      color: isCompleted ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stages[index],
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? green : Colors.grey,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted && index < currentIdx ? green : Colors.grey.shade300,
                    margin: const EdgeInsets.only(bottom: 14),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _confirmCancelOrder(AppController c, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Order?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No, Keep Order')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _actionLoading = true);
              try {
                await c.cancelOrder(orderId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order cancelled successfully'), backgroundColor: Colors.redAccent),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error cancelling order: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              } finally {
                if (mounted) setState(() => _actionLoading = false);
              }
            },
            child: const Text('Yes, Cancel Order', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBuyAgain(AppController c, ShopOrder o) async {
    setState(() => _actionLoading = true);
    try {
      await c.buyAgain(o);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Items added back to your cart!'),
            backgroundColor: green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[month - 1];
  }
}

class AITrainerScreen extends StatelessWidget {
  const AITrainerScreen({super.key});
  @override Widget build(BuildContext context) {
    final c = Scope.of(context);
    final p = c.profile;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.aiTrainer), backgroundColor: Colors.white, elevation: 0, foregroundColor: textDark),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                CircleAvatar(radius: 32, backgroundColor: Colors.white, child: Icon(Icons.smart_toy, color: green, size: 36)),
                SizedBox(height: 16),
                Text(c.latestAIAdvice, style: const TextStyle(fontSize: 18, color: textDark, height: 1.5), textAlign: TextAlign.center),
              ],
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.refreshAdvice),
            onPressed: () {
              if (p != null) {
                final g = p.goal.isNotEmpty ? p.goal : 'General Fitness';
                final f = p.food.isNotEmpty ? p.food : 'Eggetarian';
                final l = p.location.isNotEmpty ? p.location : 'Home Workout';
                c.addAIAdvice(aiAdvice(g, f, l));
              }
            },
          ),
          if (c.aiHistory.length > 1) ...[
            SizedBox(height: 40),
            Text('Past Advice', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
            SizedBox(height: 16),
            ...c.aiHistory.reversed.skip(1).take(5).map((h) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EEE9))),
              child: Row(children: [Icon(Icons.history, color: Colors.grey), SizedBox(width: 12), Expanded(child: Text(h, style: const TextStyle(color: Colors.black87)))]),
            )),
          ]
        ],
      ),
    );
  }
}

class BudgetFoodSection extends StatefulWidget {
  final AppController controller;
  const BudgetFoodSection({super.key, required this.controller});

  @override
  State<BudgetFoodSection> createState() => _BudgetFoodSectionState();
}

class _BudgetFoodSectionState extends State<BudgetFoodSection> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.allProducts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.fetchBudgetProducts();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Today\'s Deals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textDark)),
            TextButton.icon(
              onPressed: c.fetchBudgetProducts,
              icon: Icon(Icons.refresh, size: 18, color: green),
              label: Text('Refresh', style: TextStyle(color: green)),
            )
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Cheapest', 'Highest Protein', 'Vegetarian', 'Non-Vegetarian', 'Under ₹100', 'Under ₹200'].map((f) {
              final sel = c.budgetFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: sel,
                  onSelected: (_) => c.setBudgetFilter(f),
                  selectedColor: lightGreen,
                  checkmarkColor: green,
                  labelStyle: TextStyle(color: sel ? darkGreen : Colors.black87),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: sel ? green : Colors.grey.shade300),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Text('Sort by: ', style: TextStyle(color: Colors.grey)),
            DropdownButton<String>(
              value: c.budgetSort,
              items: ['Lowest Price', 'Highest Protein', 'Best Value', 'Biggest Discount'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) {
                if (v != null) c.setBudgetSort(v);
              },
              underline: SizedBox(),
              icon: Icon(Icons.keyboard_arrow_down, color: green),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (c.isLoadingBudget)
          Center(child: CircularProgressIndicator(color: green))
        else if (c.visibleProducts.isEmpty && c.allProducts.isEmpty)
          Container(
            padding: EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                Icon(Icons.inbox, size: 40, color: Colors.grey),
                SizedBox(height: 10),
                Text('No budget products available right now.', style: TextStyle(color: Colors.grey, fontSize: 16), textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ...c.visibleProducts.map((p) => BudgetProductCard(product: p)),
      ],
    );
  }
}

class BudgetProductCard extends StatelessWidget {
  final BudgetProduct product;
  const BudgetProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFE7EEE9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  product.imagePath,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 80),
                ),
              ),
              if (product.isBestValue)
                Positioned(
                  top: 10, left: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                    child: Text('Best Value Today', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (product.discountPercentage > 0)
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                    child: Text('-${product.discountPercentage.toStringAsFixed(0)}%', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(product.productName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (product.storeName.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                        child: Text(product.storeName, style: TextStyle(fontSize: 10, color: Colors.black54)),
                      )
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text('₹${product.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: green)),
                    SizedBox(width: 8),
                    if (product.originalPrice != null && product.originalPrice! > product.price)
                      Text('₹${product.originalPrice!.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                    Spacer(),
                    Text('Est. Local Price', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.scale, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(product.quantity, style: TextStyle(fontSize: 12, color: Colors.black87)),
                    SizedBox(width: 16),
                    Icon(product.category == 'Vegetarian' ? Icons.eco : Icons.restaurant, size: 14, color: product.category == 'Vegetarian' ? Colors.green : Colors.red),
                    SizedBox(width: 4),
                    Text(product.category, style: TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.fitness_center, size: 14, color: Colors.blue),
                    SizedBox(width: 4),
                    Text('${product.protein.toStringAsFixed(1)}g Protein', style: TextStyle(fontSize: 12, color: Colors.black87)),
                    SizedBox(width: 16),
                    Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text('${product.calories.toStringAsFixed(0)} kcal', style: TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Budget Score: ${product.budgetScore.toStringAsFixed(1)}', style: TextStyle(fontSize: 12, color: darkGreen, fontWeight: FontWeight.w600)),
                    Text('Updated: ${product.updatedAt.hour}:${product.updatedAt.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.productName} added to diet plan!')));
                    },
                    icon: Icon(Icons.add_shopping_cart, size: 16),
                    label: Text('Add to Diet Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: Size(0, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
