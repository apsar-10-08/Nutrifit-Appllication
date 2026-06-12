import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignUpScreen(),
          '/forgot': (_) => const ForgotScreen(),
          '/goal': (_) => const GoalScreen(),
          '/gender': (_) => const GenderScreen(),
          '/age': (_) => const NumberScreen(kind: 'age'),
          '/height': (_) => const NumberScreen(kind: 'height'),
          '/weight': (_) => const NumberScreen(kind: 'weight'),
          '/food': (_) => const FoodScreen(),
          '/location': (_) => const LocationScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/cart': (_) => const CartScreen(),
        },
      ),
    );
  }
}

class Profile {
  Profile({this.id='demo-user', this.name='', this.email='', this.goal='', this.gender='', this.age, this.height, this.weight, this.food='', this.location='', this.lang='en'});
  String id, name, email, goal, gender, food, location, lang;
  int? age; double? height, weight;
  bool get complete => goal.isNotEmpty && gender.isNotEmpty && age != null && height != null && weight != null && food.isNotEmpty && location.isNotEmpty;
  Profile copy({String? id, name, email, goal, gender, food, location, lang, int? age, double? height, weight}) => Profile(
    id: id ?? this.id, name: name ?? this.name, email: email ?? this.email, goal: goal ?? this.goal, gender: gender ?? this.gender,
    age: age ?? this.age, height: height ?? this.height, weight: weight ?? this.weight, food: food ?? this.food, location: location ?? this.location, lang: lang ?? this.lang);
  Map<String,dynamic> toJson() => {'id': id, 'full_name': name, 'email': email, 'goal': goal, 'gender': gender, 'age': age, 'height_cm': height, 'weight_kg': weight, 'food_preference': food, 'workout_location': location, 'preferred_language': lang};
  Map<String,dynamic> profileJson(String uid) => {'id': uid, 'full_name': name, 'email': email, 'gender': gender, 'age': age, 'height_cm': height, 'weight_kg': weight, 'food_preference': food, 'workout_location': location, 'preferred_language': lang};
  factory Profile.from(Map<String,dynamic> j) => Profile(id:(j['id']??'demo-user').toString(), name:(j['full_name']??'').toString(), email:(j['email']??'').toString(), goal:(j['goal']??'').toString(), gender:(j['gender']??'').toString(), age:int.tryParse('${j['age']??''}'), height:double.tryParse('${j['height_cm']??''}'), weight:double.tryParse('${j['weight_kg']??''}'), food:(j['food_preference']??'').toString(), location:(j['workout_location']??'').toString(), lang:(j['preferred_language']??'en').toString());
}

class Product {
  const Product(this.id, this.brand, this.name, this.category, this.description, this.price, this.image, this.rating);
  final String id, brand, name, category, description, image;
  final double price, rating;
}

class AppController extends ChangeNotifier {
  Profile? profile; bool busy=false; bool demo=false; String lang='en';
  int water=0, steps=0, tab=0, timerSeconds=0; double sleep=7;
  final wishlist=<String>{}; final cart=<String,int>{}; final habits=<String,bool>{};
  final completedWorkouts=<String>{};
  final localToDbProductId = <String, String>{};
  final dbToLocalProductId = <String, String>{};

  bool get signedIn => Supa.ready ? Supa.client.auth.currentSession != null : (demo || profile != null);
  String t(String key) => strings[lang]?[key] ?? strings['en']?[key] ?? key;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    lang = p.getString('lang') ?? 'en';
    final raw = p.getString('profile'); if (raw != null) profile = Profile.from(jsonDecode(raw));
    water = p.getInt('water') ?? 0; steps = p.getInt('steps') ?? 0; sleep = p.getDouble('sleep') ?? 7;
    wishlist.addAll(p.getStringList('wishlist') ?? []);
    completedWorkouts.addAll(p.getStringList('completedWorkouts') ?? []);
    final rawCart = p.getString('cart'); if (rawCart != null) cart.addAll((jsonDecode(rawCart) as Map<String,dynamic>).map((k,v)=>MapEntry(k, v as int)));
    if (Supa.ready) {
      Supa.client.auth.onAuthStateChange.listen((event) async {
        if (event.session != null) {
          await loadRemoteProfile();
          await syncProductsAndCart();
        }
        notifyListeners();
      });
      await loadRemoteProfile();
      await syncProductsAndCart();
    }
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    if (profile != null) await p.setString('profile', jsonEncode(profile!.toJson()));
    await p.setString('lang', lang); await p.setInt('water', water); await p.setInt('steps', steps); await p.setDouble('sleep', sleep);
    await p.setStringList('wishlist', wishlist.toList());
    await p.setStringList('completedWorkouts', completedWorkouts.toList());
    await p.setString('cart', jsonEncode(cart));
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
    await syncProductsAndCart();
  });

  Future<String?> signUp(String name, String email, String pass) async => run(() async {
    if (name.trim().isEmpty || email.trim().isEmpty || pass.length<6) throw 'Enter name, email, and 6 character password';
    if (!Supa.ready) { demo=true; profile=Profile(name:name.trim(), email:email.trim(), lang:lang); await persist(); return; }
    final r = await Supa.client.auth.signUp(email: email.trim(), password: pass.trim(), data: {'full_name': name.trim()});
    profile=Profile(id:r.user?.id ?? 'demo-user', name:name.trim(), email:email.trim(), lang:lang); await saveProfile();
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
  void draft({String? goal, String? gender, String? food, String? location, int? age, double? height, double? weight}) { profile = (profile ?? Profile()).copy(goal: goal, gender: gender, food: food, location: location, age: age, height: height, weight: weight, lang: lang); notifyListeners(); }
  
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
    final p=await SharedPreferences.getInstance();
    await p.remove('profile');
    await p.remove('cart');
    await p.remove('wishlist');
    await p.remove('completedWorkouts');
    notifyListeners();
  }

  void setLang(String v){ lang=v; profile=(profile??Profile()).copy(lang:v); persist(); notifyListeners(); }
  void waterAdd(int v){ water=(water+v).clamp(0,6000); persist(); notifyListeners(); }
  void stepsAdd(int v){ steps=(steps+v).clamp(0,50000); persist(); notifyListeners(); }
  void sleepSet(double v){ sleep=v.clamp(0,14); persist(); notifyListeners(); }
  void toggleHabit(String h){ habits[h]=!(habits[h]??false); notifyListeners(); }
  void toggleWish(Product p){ wishlist.contains(p.id) ? wishlist.remove(p.id) : wishlist.add(p.id); persist(); notifyListeners(); }
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
Product('gnc-whey','GNC','GNC Whey Protein Starter','Protein','Protein support for muscle recovery.',2499,'assets/images/product_gnc.png',4.6),
Product('gnc-multi','GNC','GNC Multivitamin Active','Wellness','Daily wellness support.',1299,'assets/images/product_gnc.png',4.5),
Product('mb-whey','MuscleBlaze','MuscleBlaze Biozyme Whey','Protein','Recovery protein for workouts.',2199,'assets/images/product_mb.png',4.7),
Product('mb-creatine','MuscleBlaze','MuscleBlaze Creatine','Performance','Performance support.',899,'assets/images/product_mb.png',4.4),
Product('ywf-band','YouWeFit','YouWeFit Resistance Band','Equipment','Home workout equipment.',499,'assets/images/product_ywf.png',4.3),
Product('ywf-shaker','YouWeFit','YouWeFit Shaker Bottle','Accessories','Protein and water shaker.',299,'assets/images/product_ywf.png',4.2),
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
List<String> budget(String food)=>['Budget protein: ${food=='Non-Vegetarian'?'eggs, chicken liver, curd, dal':food=='Eggetarian'?'eggs, dal, curd, peanuts':'dal, chana, rajma, sprouts, curd'}','Use oats + milk for energy','Cook pulses in bulk','Carry banana or peanuts','Drink water regularly'];
String aiAdvice(String goal,String food,String loc)=>'Today focus on $goal with $loc. Keep protein steady using $food choices, drink water before meals, warm up properly, and sleep 7-8 hours.';

void go(BuildContext c,String r)=>Navigator.pushNamed(c,r);
void replace(BuildContext c,String r)=>Navigator.pushReplacementNamed(c,r);
void msg(BuildContext c,String t)=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(t)));

class SplashScreen extends StatefulWidget { const SplashScreen({super.key}); @override State<SplashScreen> createState()=>_SplashScreenState(); }
class _SplashScreenState extends State<SplashScreen>{
  @override void initState(){ super.initState(); Timer(const Duration(milliseconds:1500),(){ if(!mounted)return; final c=Scope.of(context); replace(context,c.signedIn?(c.profile?.complete==true?'/dashboard':'/goal'):'/login'); }); }
  @override Widget build(BuildContext context)=>Scaffold(body:Container(decoration:const BoxDecoration(gradient:LinearGradient(colors:[Colors.white,lightGreen])),child:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Image.asset('assets/images/logo.png',width:132),const SizedBox(height:22),Text('NutriFit',style:Theme.of(context).textTheme.headlineLarge?.copyWith(color:green)),const SizedBox(height:8),Text('Your Health, Your Care',style:Theme.of(context).textTheme.titleMedium)]))));
}

class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState()=>_LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen>{ final email=TextEditingController(); final pass=TextEditingController();
  @override void dispose(){email.dispose();pass.dispose();super.dispose();}
  Future<void> submit() async { final c=Scope.of(context); final e=await c.login(email.text,pass.text); if(!mounted)return; e==null?replace(context,c.profile?.complete==true?'/dashboard':'/goal'):msg(context,e); }
  Future<void> google() async { final c=Scope.of(context); final e=await c.googleLogin(); if(!mounted)return; e==null?replace(context,c.profile?.complete==true?'/dashboard':'/goal'):msg(context,e); }
  @override Widget build(BuildContext context){ final c=Scope.of(context); return AuthScaffold(title:c.t('app'),subtitle:c.t('tag'),children:[Image.asset('assets/images/logo.png',width:92),field(email,c.t('email'),Icons.mail,false,TextInputType.emailAddress),field(pass,c.t('password'),Icons.lock,true,null),Align(alignment:Alignment.centerRight,child:TextButton(onPressed:()=>go(context,'/forgot'),child:Text(c.t('forgot')))),button(c.t('login'),submit,c.busy),OutlinedButton.icon(onPressed:c.busy?null:google,icon:const Icon(Icons.g_mobiledata_rounded,size:32),label:Text(c.t('google')),style:OutlinedButton.styleFrom(minimumSize:const Size.fromHeight(54),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)))),Row(mainAxisAlignment:MainAxisAlignment.center,children:[const Text("Don't have an account?"),TextButton(onPressed:()=>go(context,'/signup'),child:Text(c.t('signup')))]),const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('Demo mode works when Supabase keys are empty. Add Supabase URL and anon key in .env for real authentication.')))]); }
}
class SignUpScreen extends StatefulWidget { const SignUpScreen({super.key}); @override State<SignUpScreen> createState()=>_SignUpScreenState(); }
class _SignUpScreenState extends State<SignUpScreen>{ final name=TextEditingController(); final email=TextEditingController(); final pass=TextEditingController(); @override void dispose(){name.dispose();email.dispose();pass.dispose();super.dispose();}
  Future<void> submit() async{final c=Scope.of(context);final e=await c.signUp(name.text,email.text,pass.text);if(!mounted)return;e==null?replace(context,'/goal'):msg(context,e);}
  @override Widget build(BuildContext context){final c=Scope.of(context);return AuthScaffold(title:c.t('signup'),subtitle:'Create your NutriFit account',children:[Image.asset('assets/images/fitness_hero.png',height:150),field(name,c.t('name'),Icons.person,false,null),field(email,c.t('email'),Icons.mail,false,TextInputType.emailAddress),field(pass,c.t('password'),Icons.lock,true,null),button(c.t('signup'),submit,c.busy)]);}
}
class ForgotScreen extends StatefulWidget { const ForgotScreen({super.key}); @override State<ForgotScreen> createState()=>_ForgotScreenState(); }
class _ForgotScreenState extends State<ForgotScreen>{ final email=TextEditingController(); @override void dispose(){email.dispose();super.dispose();}
  @override Widget build(BuildContext context){final c=Scope.of(context);return AuthScaffold(title:c.t('forgot'),subtitle:'Send reset link using Supabase Auth',children:[field(email,c.t('email'),Icons.mail,false,TextInputType.emailAddress),button('Send Reset Link',()async{final e=await c.reset(email.text);if(context.mounted)msg(context,e??'Password reset email sent if account exists.');},c.busy)]);}
}

class AuthScaffold extends StatelessWidget{ const AuthScaffold({super.key,required this.title,required this.subtitle,required this.children}); final String title,subtitle; final List<Widget> children;
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(),body:SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.headlineLarge?.copyWith(color:green)),const SizedBox(height:8),Text(subtitle,style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:26),...children.map((w)=>Padding(padding:const EdgeInsets.only(bottom:14),child:w))]))));
}
Widget field(TextEditingController c,String label,IconData icon,bool obscure,TextInputType? type)=>TextField(controller:c,obscureText:obscure,keyboardType:type,decoration:InputDecoration(labelText:label,prefixIcon:Icon(icon)));
Widget button(String label,VoidCallback? on,bool busy)=>ElevatedButton.icon(onPressed:busy?null:on,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.arrow_forward),label:Text(label));

class SelectScreen extends StatelessWidget{ const SelectScreen({super.key,required this.title,required this.subtitle,required this.items,required this.next,required this.onSelect,required this.icon}); final String title,subtitle,next; final List<String> items; final void Function(AppController,String) onSelect; final IconData icon;
  @override Widget build(BuildContext context){final c=Scope.of(context);return Scaffold(appBar:AppBar(),body:SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.favorite,color:green,size:42),const SizedBox(height:20),Text(title,style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:8),Text(subtitle),const SizedBox(height:20),for(final it in items) SelectCard(title:it,icon:icon,onTap:(){onSelect(c,it);go(context,next);})]))));}
}
class SelectCard extends StatelessWidget{ const SelectCard({super.key,required this.title,required this.icon,required this.onTap}); final String title; final IconData icon; final VoidCallback onTap;
 @override Widget build(BuildContext context)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(22),child:Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFE7EEE9))),child:Row(children:[Icon(icon,color:green),const SizedBox(width:14),Expanded(child:Text(title,style:Theme.of(context).textTheme.titleMedium)),const Icon(Icons.chevron_right)])));
}
class GoalScreen extends StatelessWidget{ const GoalScreen({super.key}); @override Widget build(BuildContext context){final c=Scope.of(context);return SelectScreen(title:c.t('goal'),subtitle:'NutriFit will personalize your workout and diet.',items:goals,next:'/gender',icon:Icons.fitness_center,onSelect:(c,v)=>c.draft(goal:v));}}
class GenderScreen extends StatelessWidget{ const GenderScreen({super.key}); @override Widget build(BuildContext context){final c=Scope.of(context);return SelectScreen(title:c.t('gender'),subtitle:'This helps calculate better recommendations.',items:genders,next:'/age',icon:Icons.person,onSelect:(c,v)=>c.draft(gender:v));}}
class FoodScreen extends StatelessWidget{ const FoodScreen({super.key}); @override Widget build(BuildContext context){final c=Scope.of(context);return SelectScreen(title:c.t('food'),subtitle:'Your diet plan will match your preference.',items:foods,next:'/location',icon:Icons.restaurant,onSelect:(c,v)=>c.draft(food:v));}}
class LocationScreen extends StatelessWidget{ const LocationScreen({super.key}); @override Widget build(BuildContext context){final c=Scope.of(context);return SelectScreen(title:c.t('location'),subtitle:'Choose gym or home workout.',items:locations,next:'/dashboard',icon:Icons.home,onSelect:(c,v){c.draft(location:v);c.saveProfile();});}}

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
@override Widget build(BuildContext context){final c=Scope.of(context);final title=widget.kind=='age'?c.t('age'):widget.kind=='height'?c.t('height'):c.t('weight'); final unit=widget.kind=='age'?'years':widget.kind=='height'?'cm':'kg'; final next=widget.kind=='age'?'/height':widget.kind=='height'?'/weight':'/food'; return Scaffold(appBar:AppBar(),body:Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:8),Text('Enter value in $unit'),const SizedBox(height:24),field(ctrl,title,widget.kind=='age'?Icons.cake:widget.kind=='height'?Icons.height:Icons.monitor_weight,false,TextInputType.number),const SizedBox(height:20),button(c.t('continue'),(){final v=double.tryParse(ctrl.text.trim()); if(v==null){msg(context,'Enter valid value');return;} if(widget.kind=='age') c.draft(age:v.round()); if(widget.kind=='height') c.draft(height:v); if(widget.kind=='weight') c.draft(weight:v); go(context,next);},false)])));}}

class DashboardScreen extends StatefulWidget{ const DashboardScreen({super.key}); @override State<DashboardScreen> createState()=>_DashboardScreenState(); }
class _DashboardScreenState extends State<DashboardScreen>{ @override Widget build(BuildContext context){final c=Scope.of(context);final pages=[const HomeTab(),const PlansTab(),const TrackersTab(),const ShopTab(),const ProfileTab()];return Scaffold(body:SafeArea(child:pages[c.tab]),bottomNavigationBar:NavigationBar(selectedIndex:c.tab,indicatorColor:lightGreen,onDestinationSelected:(i){c.setTab(i);},destinations:[NavigationDestination(icon:const Icon(Icons.dashboard_outlined),selectedIcon:const Icon(Icons.dashboard),label:c.t('dashboard')),NavigationDestination(icon:const Icon(Icons.calendar_month_outlined),selectedIcon:const Icon(Icons.calendar_month),label:c.t('plans')),NavigationDestination(icon:const Icon(Icons.track_changes_outlined),selectedIcon:const Icon(Icons.track_changes),label:c.t('trackers')),NavigationDestination(icon:const Icon(Icons.shopping_bag_outlined),selectedIcon:const Icon(Icons.shopping_bag),label:c.t('shop')),NavigationDestination(icon:const Icon(Icons.person_outline),selectedIcon:const Icon(Icons.person),label:c.t('profile'))]));}}

class HomeTab extends StatelessWidget{ const HomeTab({super.key}); @override Widget build(BuildContext context){final c=Scope.of(context);final p=c.profile;final g=p?.goal.isNotEmpty==true?p!.goal:'General Fitness';final f=p?.food.isNotEmpty==true?p!.food:'Eggetarian';final l=p?.location.isNotEmpty==true?p!.location:'Home Workout';final w=workout(g,l);final d=diet(g,f);return ListView(padding:const EdgeInsets.all(20),children:[Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Hi, ${p?.name.isNotEmpty==true?p!.name:'Apsar'}',style:Theme.of(context).textTheme.headlineMedium),Text('Ready for ${g.toLowerCase()}?')])),CircleAvatar(radius:28,backgroundColor:lightGreen,child:Text((p?.name.isNotEmpty==true?p!.name[0]:'N').toUpperCase(),style:const TextStyle(color:green,fontWeight:FontWeight.w900,fontSize:22)))]),const SizedBox(height:20),HeroCard(title:w.first,subtitle:d.first),grid([Info('Hydration','${c.water} ml','Target 3000',Icons.water_drop),Info('Sleep','${c.sleep.toStringAsFixed(1)} h','Target 8 h',Icons.bedtime),Info('Steps','${c.steps}','Target 8000',Icons.directions_walk),Info('Goal',g,l,Icons.flag)]),section(c.t('ai')),infoBox(Icons.smart_toy,aiAdvice(g,f,l)),section('Meal Reminder'),reminder('Breakfast','7:30 AM',Icons.breakfast_dining),reminder('Lunch','1:00 PM',Icons.lunch_dining),reminder('Workout','6:00 PM',Icons.fitness_center)]);}}
class HeroCard extends StatelessWidget{ const HeroCard({super.key,required this.title,required this.subtitle}); final String title,subtitle; @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[green,darkGreen]),borderRadius:BorderRadius.circular(28)),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Today Plan',style:TextStyle(color:Colors.white70)),const SizedBox(height:8),Text(title,style:const TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:8),Text(subtitle,style:const TextStyle(color:Colors.white70))])),Image.asset('assets/images/fitness_hero.png',width:110)]));}
class Info{Info(this.title,this.value,this.sub,this.icon);String title,value,sub;IconData icon;}
Widget grid(List<Info> items)=>GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.1,children:[for(final i in items) card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[CircleAvatar(backgroundColor:lightGreen,child:Icon(i.icon,color:green)),const SizedBox(height:12),Text(i.value,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),Text(i.title),Text(i.sub,style:const TextStyle(fontSize:12,color:Colors.grey))]))]);
Widget card(Widget child)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:const Color(0xFFE7EEE9))),child:child);
Widget section(String title)=>Padding(padding:const EdgeInsets.only(top:20,bottom:10),child:Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:textDark)));
Widget infoBox(IconData icon,String text)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:lightGreen,borderRadius:BorderRadius.circular(24)),child:Row(children:[CircleAvatar(backgroundColor:Colors.white,child:Icon(icon,color:green)),const SizedBox(width:12),Expanded(child:Text(text))]));
Widget reminder(String t,String time,IconData icon)=>Card(child:ListTile(leading:CircleAvatar(backgroundColor:lightGreen,child:Icon(icon,color:green)),title:Text(t),subtitle:Text(time),trailing:Switch(value:true,onChanged:(_){ })));

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
                    child: const Row(
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: Color(0xFFE7EEE9)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubSectionHeader('Warm-up:', Icons.directions_run),
                  const SizedBox(height: 8),
                  for (final item in widget.details.warmup) _buildBulletPoint(item),
                  const SizedBox(height: 16),

                  _buildSubSectionHeader('Exercises:', Icons.fitness_center),
                  const SizedBox(height: 8),
                  for (final item in widget.details.exercises) _buildBulletPoint(item),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetaBox(
                          Icons.timer_outlined,
                          'Duration',
                          widget.details.duration,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetaBox(
                          Icons.snooze,
                          'Rest Time',
                          widget.details.restTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSubSectionHeader('Cool-down stretching:', Icons.accessibility_new),
                  const SizedBox(height: 8),
                  for (final item in widget.details.cooldown) _buildBulletPoint(item),
                  const SizedBox(height: 16),

                  if (widget.details.beginnerInstructions.isNotEmpty) ...[
                    _buildSubSectionHeader('Beginner Instructions:', Icons.info_outline),
                    const SizedBox(height: 6),
                    Text(
                      widget.details.beginnerInstructions,
                      style: const TextStyle(fontSize: 14, color: textDark),
                    ),
                    const SizedBox(height: 16),
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
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Safety Tips',
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.details.safetyTips,
                            style: const TextStyle(color: Color(0xFF9E5C2C), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
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
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: green),
                          ),
                          const SizedBox(width: 12),
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
                                  label: 'VIEW',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    widget.controller.setTab(2);
                                  },
                                ),
                              )
                            );
                          },
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Start', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                      const SizedBox(width: 8),
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
                  const SizedBox(height: 8),
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
        const SizedBox(width: 6),
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
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: green),
          ),
          const SizedBox(width: 10),
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
          const SizedBox(width: 8),
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
                  const SizedBox(width: 4),
                  Text(
                    '${widget.details.calories} kcal',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.fitness_center, size: 16, color: green),
                  const SizedBox(width: 4),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: Color(0xFFE7EEE9)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMealSection('Breakfast', widget.details.breakfast, Icons.breakfast_dining),
                  const SizedBox(height: 12),
                  _buildMealSection('Mid-morning Snack', widget.details.midMorningSnack, Icons.apple),
                  const SizedBox(height: 12),
                  _buildMealSection('Lunch', widget.details.lunch, Icons.lunch_dining),
                  const SizedBox(height: 12),
                  _buildMealSection('Evening Snack', widget.details.eveningSnack, Icons.local_cafe),
                  const SizedBox(height: 12),
                  _buildMealSection('Dinner', widget.details.dinner, Icons.dinner_dining),
                  const SizedBox(height: 16),
                  
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
                        const Row(
                          children: [
                            Icon(Icons.currency_rupee, color: darkGreen, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Budget Food Tips',
                              style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.details.budgetTips,
                          style: const TextStyle(color: darkGreen, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

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
                        const Row(
                          children: [
                            Icon(Icons.block, color: Colors.redAccent, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Foods to Avoid',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark),
              ),
              const SizedBox(height: 2),
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
        const SizedBox(height: 4),
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
        const SizedBox(height: 18),
        
        section(c.t('weeklyWorkout')),
        for (final w in workoutList) WorkoutDayCard(details: w, controller: c),
        
        section(c.t('weeklyDiet')),
        for (final d in dietList) DietDayCard(details: d),
        
        section(c.t('warmup')),
        planList([
          '5 min brisk walk',
          'Arm circles',
          'Hip rotation',
          'Cat-cow stretch',
          'Dynamic hamstring stretch',
          'Light push-up'
        ], Icons.accessibility),
        
        section(c.t('budget')),
        planList(budget(f), Icons.currency_rupee),
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
                const SizedBox(width: 12),
                Expanded(child: Text(x)),
              ],
            ),
          )
      ],
    );

class TrackersTab extends StatefulWidget{ const TrackersTab({super.key}); @override State<TrackersTab> createState()=>_TrackersTabState(); }
class _TrackersTabState extends State<TrackersTab>{ final kg=TextEditingController(text:'64'), mins=TextEditingController(text:'45'); double met=6; Timer? timer; int sec=0; @override void dispose(){kg.dispose();mins.dispose();timer?.cancel();super.dispose();}
@override Widget build(BuildContext context){final c=Scope.of(context);final cal=((double.tryParse(kg.text)??0)*((double.tryParse(mins.text)??0)/60)*met).round();return ListView(padding:const EdgeInsets.all(20),children:[Text(c.t('trackers'),style:Theme.of(context).textTheme.headlineMedium),section(c.t('water')),track(Icons.water_drop,'${c.water} ml / 3000 ml',Row(children:[Expanded(child:ElevatedButton(onPressed:()=>c.waterAdd(250),child:const Text('+250 ml'))),const SizedBox(width:10),Expanded(child:OutlinedButton(onPressed:()=>c.waterAdd(-c.water),child:const Text('Reset')))])),section(c.t('sleep')),track(Icons.bedtime,'${c.sleep.toStringAsFixed(1)} hours',Row(children:[IconButton(onPressed:()=>c.sleepSet(c.sleep-.5),icon:const Icon(Icons.remove_circle_outline)),Expanded(child:LinearProgressIndicator(value:(c.sleep/8).clamp(0,1),minHeight:10,borderRadius:BorderRadius.circular(20))),IconButton(onPressed:()=>c.sleepSet(c.sleep+.5),icon:const Icon(Icons.add_circle_outline))])),section(c.t('steps')),track(Icons.directions_walk,'${c.steps} steps',Row(children:[Expanded(child:ElevatedButton(onPressed:()=>c.stepsAdd(500),child:const Text('+500'))),const SizedBox(width:10),Expanded(child:OutlinedButton(onPressed:()=>c.stepsAdd(-c.steps),child:const Text('Reset')))])),section(c.t('calorie')),track(Icons.local_fire_department,'$cal kcal estimated',Column(children:[field(kg,'Weight kg',Icons.monitor_weight,false,TextInputType.number),const SizedBox(height:10),field(mins,'Workout minutes',Icons.timer,false,TextInputType.number),DropdownButtonFormField<double>(value:met,decoration:const InputDecoration(labelText:'Activity'),items:const [DropdownMenuItem(value:4,child:Text('Light workout')),DropdownMenuItem(value:6,child:Text('Gym workout')),DropdownMenuItem(value:8,child:Text('HIIT / Running'))],onChanged:(v)=>setState(()=>met=v??6)),const SizedBox(height:10),ElevatedButton(onPressed:()=>setState((){}),child:const Text('Calculate'))])),section('Workout Timer & Rest Timer'),track(Icons.timer,_fmt(sec),Row(children:[Expanded(child:ElevatedButton(onPressed:(){if(timer==null){timer=Timer.periodic(const Duration(seconds:1),(_)=>setState(()=>sec++));}else{timer?.cancel();timer=null;}setState((){});},child:Text(timer==null?'Start':'Pause'))),const SizedBox(width:10),Expanded(child:OutlinedButton(onPressed:()=>setState(()=>sec=0),child:const Text('Reset')))])),section(c.t('habits')),for(final h in habits) CheckboxListTile(value:c.habits[h]??false,onChanged:(_)=>c.toggleHabit(h),title:Text(h),activeColor:green,tileColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)))]);}
String _fmt(int s)=>'${(s~/60).toString().padLeft(2,'0')}:${(s%60).toString().padLeft(2,'0')}';}
Widget track(IconData icon,String title,Widget child)=>Container(margin:const EdgeInsets.only(bottom:14),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:const Color(0xFFE7EEE9))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[CircleAvatar(backgroundColor:lightGreen,child:Icon(icon,color:green)),const SizedBox(width:12),Expanded(child:Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)))]),const SizedBox(height:14),child]));

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
                  icon: const Icon(Icons.shopping_cart, color: green, size: 28),
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
        const Text('Fitness shopping module with wishlist and cart.'),
        const SizedBox(height:14),
        Wrap(spacing:8,children:[for(final b in ['All','GNC','MuscleBlaze','YouWeFit']) ChoiceChip(label:Text(b),selected:brand==b,onSelected:(_)=>setState(()=>brand=b))]),
        const SizedBox(height:14),
        GridView.builder(
          shrinkWrap:true,
          physics:const NeverScrollableScrollPhysics(),
          itemCount:list.length,
          gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:.63,crossAxisSpacing:12,mainAxisSpacing:12),
          itemBuilder:(_,i)=>productCard(context,list[i])
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
  return card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Expanded(child:Stack(children:[
      Center(child:Image.asset(p.image,fit:BoxFit.contain)),
      Align(
        alignment:Alignment.topRight,
        child:IconButton(
          onPressed:()=>c.toggleWish(p),
          icon:Icon(liked?Icons.favorite:Icons.favorite_border,color:liked?Colors.redAccent:green)
        )
      )
    ])),
    Text(p.brand,style:const TextStyle(color:green,fontWeight:FontWeight.w700)),
    Text(p.name,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),
    Text('₹${p.price.toStringAsFixed(0)} • ⭐ ${p.rating}'),
    const SizedBox(height:8),
    SizedBox(
      width:double.infinity,
      child:ElevatedButton(
        onPressed:() async {
          await c.addCart(p);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🛒 Added to cart'),
                backgroundColor: green,
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              )
            );
          }
        },
        child:const Text('Add')
      )
    )
  ]));
}

class ProfileTab extends StatelessWidget{ const ProfileTab({super.key}); @override Widget build(BuildContext context){final c=Scope.of(context);final p=c.profile;return ListView(padding:const EdgeInsets.all(20),children:[Text(c.t('profile'),style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:16),card(Row(children:[CircleAvatar(radius:34,backgroundColor:lightGreen,child:Text((p?.name.isNotEmpty==true?p!.name[0]:'N').toUpperCase(),style:const TextStyle(fontSize:28,color:green,fontWeight:FontWeight.w900))),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p?.name.isNotEmpty==true?p!.name:'NutriFit User',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),Text(p?.email.isNotEmpty==true?p!.email:'demo@nutrifit.local'),Text(p?.goal.isNotEmpty==true?p!.goal:'General Fitness',style:const TextStyle(color:green,fontWeight:FontWeight.w700))]))])),section('Progress Tracking'),detail('Age','${p?.age??'-'}'),detail('Height','${p?.height?.toStringAsFixed(0)??'-'} cm'),detail('Weight','${p?.weight?.toStringAsFixed(0)??'-'} kg'),detail('Food',p?.food??'-'),detail('Workout',p?.location??'-'),section(c.t('settings')),card(Column(children:[Row(children:[Expanded(child:Text(c.t('language'),style:const TextStyle(fontWeight:FontWeight.w800))),SegmentedButton<String>(segments:const [ButtonSegment(value:'en',label:Text('EN')),ButtonSegment(value:'ta',label:Text('TA'))],selected:{c.lang},onSelectionChanged:(s)=>c.setLang(s.first))]),const Divider(),ListTile(leading:const Icon(Icons.edit,color:green),title:const Text('Edit onboarding details'),onTap:()=>go(context,'/goal')),ListTile(leading:const Icon(Icons.logout,color:Colors.redAccent),title:Text(c.t('logout')),onTap:()async{await c.logout();if(context.mounted)Navigator.pushNamedAndRemoveUntil(context,'/login',(_)=>false);})]))]);}}
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
        title: const Text('My Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
                      child: const Icon(Icons.shopping_bag_outlined, color: green, size: 48),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your cart is empty',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore our shop tab to add nutritional supplements and fitness gear to your cart.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: textDark.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        minimumSize: const Size(0, 50),
                      ),
                      child: const Text('Go Shopping', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                child: Image.asset(p.image, fit: BoxFit.contain),
                              ),
                              const SizedBox(width: 16),
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
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
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
                                    const SizedBox(height: 6),
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
                                                child: const Icon(Icons.remove, size: 14, color: textDark),
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
                                                child: const Icon(Icons.add, size: 14, color: textDark),
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
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivery',
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                          const Text(
                            'FREE',
                            style: TextStyle(color: green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Color(0xFFF1F5F2)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Price',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              title: const Text('Order Placed Successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
                              content: const Text('Thank you for shopping with NutriFit. Your order has been placed successfully.'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    // Clear cart
                                    for (final entry in cartItems) {
                                      final p = products.firstWhere((prod) => prod.id == entry.key);
                                      c.deleteCart(p);
                                    }
                                    Navigator.pop(ctx);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Done', style: TextStyle(color: green, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
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
