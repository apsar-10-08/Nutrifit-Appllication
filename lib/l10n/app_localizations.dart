import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('ta'),
    Locale('te'),
  ];

  /// No description provided for @num250Ml.
  ///
  /// In en, this message translates to:
  /// **'+250 ml'**
  String get num250Ml;

  /// No description provided for @num500.
  ///
  /// In en, this message translates to:
  /// **'+500'**
  String get num500;

  /// No description provided for @num5MinBriskWalk.
  ///
  /// In en, this message translates to:
  /// **'5 Min Brisk Walk'**
  String get num5MinBriskWalk;

  /// No description provided for @aiTrainer.
  ///
  /// In en, this message translates to:
  /// **'AI Trainer'**
  String get aiTrainer;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @armCircles.
  ///
  /// In en, this message translates to:
  /// **'Arm Circles'**
  String get armCircles;

  /// No description provided for @calculateSleep.
  ///
  /// In en, this message translates to:
  /// **'Calculate Sleep'**
  String get calculateSleep;

  /// No description provided for @carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// No description provided for @catCowStretch.
  ///
  /// In en, this message translates to:
  /// **'Cat-Cow Stretch'**
  String get catCowStretch;

  /// No description provided for @chooseGymOrHomeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Choose gym or home workout.'**
  String get chooseGymOrHomeWorkout;

  /// No description provided for @createYourNutrifitAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your NutriFit account'**
  String get createYourNutrifitAccount;

  /// No description provided for @demoModeWorksWhenSupabaseKeysAreEmptyAddSupabaseUrlAndAnonKeyInEnvForRealAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Demo mode works when Supabase keys are empty. Add Supabase URL and anon key in .env for real authentication.'**
  String
  get demoModeWorksWhenSupabaseKeysAreEmptyAddSupabaseUrlAndAnonKeyInEnvForRealAuthentication;

  /// No description provided for @dynamicHamstringStretch.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Hamstring Stretch'**
  String get dynamicHamstringStretch;

  /// No description provided for @en.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get en;

  /// No description provided for @editProfileMetrics.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile Metrics'**
  String get editProfileMetrics;

  /// No description provided for @editOnboardingDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit onboarding details'**
  String get editOnboardingDetails;

  /// No description provided for @fats.
  ///
  /// In en, this message translates to:
  /// **'Fats'**
  String get fats;

  /// No description provided for @fitnessShoppingModuleWithWishlistAndCart.
  ///
  /// In en, this message translates to:
  /// **'Fitness shopping module with wishlist and cart.'**
  String get fitnessShoppingModuleWithWishlistAndCart;

  /// No description provided for @hipRotation.
  ///
  /// In en, this message translates to:
  /// **'Hip Rotation'**
  String get hipRotation;

  /// No description provided for @lightPushUp.
  ///
  /// In en, this message translates to:
  /// **'Light Push-up'**
  String get lightPushUp;

  /// No description provided for @lightlyActive.
  ///
  /// In en, this message translates to:
  /// **'Lightly Active'**
  String get lightlyActive;

  /// No description provided for @moderatelyActive.
  ///
  /// In en, this message translates to:
  /// **'Moderately Active'**
  String get moderatelyActive;

  /// No description provided for @nutrifit.
  ///
  /// In en, this message translates to:
  /// **'NutriFit'**
  String get nutrifit;

  /// No description provided for @nutrifitReminder.
  ///
  /// In en, this message translates to:
  /// **'NutriFit Reminder'**
  String get nutrifitReminder;

  /// No description provided for @nutrifitWillPersonalizeYourWorkoutAndDiet.
  ///
  /// In en, this message translates to:
  /// **'NutriFit will personalize your workout and diet.'**
  String get nutrifitWillPersonalizeYourWorkoutAndDiet;

  /// No description provided for @pleaseCompleteYourProfileFirstToCalculateYourPreciseCalories.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile first to calculate your precise calories.'**
  String get pleaseCompleteYourProfileFirstToCalculateYourPreciseCalories;

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @refreshAdvice.
  ///
  /// In en, this message translates to:
  /// **'Refresh Advice'**
  String get refreshAdvice;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @sedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get sedentary;

  /// No description provided for @sendResetLinkUsingSupabaseAuth.
  ///
  /// In en, this message translates to:
  /// **'Send reset link using Supabase Auth'**
  String get sendResetLinkUsingSupabaseAuth;

  /// No description provided for @ta.
  ///
  /// In en, this message translates to:
  /// **'TA'**
  String get ta;

  /// No description provided for @thankYouForShoppingWithNutrifitYourOrderHasBeenPlacedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Thank you for shopping with NutriFit. Your order has been placed successfully.'**
  String get thankYouForShoppingWithNutrifitYourOrderHasBeenPlacedSuccessfully;

  /// No description provided for @thisHelpsCalculateBetterRecommendations.
  ///
  /// In en, this message translates to:
  /// **'This helps calculate better recommendations.'**
  String get thisHelpsCalculateBetterRecommendations;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'VIEW'**
  String get view;

  /// No description provided for @veryActive.
  ///
  /// In en, this message translates to:
  /// **'Very Active'**
  String get veryActive;

  /// No description provided for @yourDietPlanWillMatchYourPreference.
  ///
  /// In en, this message translates to:
  /// **'Your diet plan will match your preference.'**
  String get yourDietPlanWillMatchYourPreference;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'age'**
  String get age;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'ai'**
  String get ai;

  /// No description provided for @app.
  ///
  /// In en, this message translates to:
  /// **'app'**
  String get app;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'budget'**
  String get budget;

  /// No description provided for @calorie.
  ///
  /// In en, this message translates to:
  /// **'calorie'**
  String get calorie;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'dashboard'**
  String get dashboard;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'email'**
  String get email;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'food'**
  String get food;

  /// No description provided for @forgot.
  ///
  /// In en, this message translates to:
  /// **'forgot'**
  String get forgot;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'gender'**
  String get gender;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'goal'**
  String get goal;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'google'**
  String get google;

  /// No description provided for @habits.
  ///
  /// In en, this message translates to:
  /// **'habits'**
  String get habits;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'height'**
  String get height;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'language'**
  String get language;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'location'**
  String get location;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'logout'**
  String get logout;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get name;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'password'**
  String get password;

  /// No description provided for @plans.
  ///
  /// In en, this message translates to:
  /// **'plans'**
  String get plans;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'settings'**
  String get settings;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'shop'**
  String get shop;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'signup'**
  String get signup;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'sleep'**
  String get sleep;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get steps;

  /// No description provided for @tag.
  ///
  /// In en, this message translates to:
  /// **'tag'**
  String get tag;

  /// No description provided for @trackers.
  ///
  /// In en, this message translates to:
  /// **'trackers'**
  String get trackers;

  /// No description provided for @warmup.
  ///
  /// In en, this message translates to:
  /// **'warmup'**
  String get warmup;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'water'**
  String get water;

  /// No description provided for @weeklydiet.
  ///
  /// In en, this message translates to:
  /// **'weeklyDiet'**
  String get weeklydiet;

  /// No description provided for @weeklyworkout.
  ///
  /// In en, this message translates to:
  /// **'weeklyWorkout'**
  String get weeklyworkout;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'weight'**
  String get weight;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'🛒 Added to cart'**
  String get addedToCart;

  /// No description provided for @continueKey.
  ///
  /// In en, this message translates to:
  /// **'continue'**
  String get continueKey;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'en',
    'hi',
    'kn',
    'ml',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
