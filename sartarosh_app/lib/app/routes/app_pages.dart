import 'package:get/get.dart';
import 'app_routes.dart';
import '../modules/startup/bindings/splash_binding.dart';
import '../modules/startup/views/splash_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/phone_login_view.dart';
import '../modules/auth/views/otp_view.dart';
import '../modules/auth/views/profile_setup_view.dart';
import '../modules/auth/views/welcome_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/barber_detail/bindings/barber_detail_binding.dart';
import '../modules/barber_detail/views/barber_detail_view.dart';
import '../modules/booking/bindings/booking_binding.dart';
import '../modules/booking/views/booking_view.dart';
import '../modules/services/bindings/services_binding.dart';
import '../modules/services/views/services_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/add_barber/bindings/add_barber_binding.dart';
import '../modules/add_barber/views/add_barber_view.dart';
import '../modules/favorites/bindings/favorites_binding.dart';
import '../modules/favorites/views/favorites_view.dart';
import '../modules/my_bookings/bindings/my_bookings_binding.dart';
import '../modules/my_bookings/views/my_bookings_view.dart';
import '../modules/support_chat/bindings/support_chat_binding.dart';
import '../modules/support_chat/views/support_chat_view.dart';
import '../modules/barber_dashboard/bindings/barber_dashboard_binding.dart';
import '../modules/barber_dashboard/views/barber_dashboard_view.dart';
import '../modules/region/bindings/region_binding.dart';
import '../modules/region/views/region_view.dart';
import '../../core/middleware/auth_middleware.dart';
import '../../core/middleware/barber_middleware.dart';

class AppPages {
  static const String initial = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => OnboardingView(),
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.phoneLogin,
      page: () => PhoneLoginView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.otp,
      page: () => OtpView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.profileSetup,
      page: () => ProfileSetupView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.welcome,
      page: () => WelcomeView(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.home,
      page: () => HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.barberDetail,
      page: () => BarberDetailView(),
      binding: BarberDetailBinding(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: Routes.booking,
      page: () => BookingView(),
      binding: BookingBinding(),
      transition: Transition.rightToLeftWithFade,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.services,
      page: () => ServicesView(),
      binding: ServicesBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.profile,
      page: () => ProfileView(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeftWithFade,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.addBarber,
      page: () => AddBarberView(),
      binding: AddBarberBinding(),
      transition: Transition.downToUp,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.favorites,
      page: () => FavoritesView(),
      binding: FavoritesBinding(),
      transition: Transition.rightToLeftWithFade,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.myBookings,
      page: () => MyBookingsView(),
      binding: MyBookingsBinding(),
      transition: Transition.rightToLeftWithFade,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.supportChat,
      page: () => SupportChatView(),
      binding: SupportChatBinding(),
      transition: Transition.rightToLeftWithFade,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.barberDashboard,
      page: () => BarberDashboardView(),
      binding: BarberDashboardBinding(),
      transition: Transition.fadeIn,
      middlewares: [BarberMiddleware()],
    ),
    GetPage(
      name: Routes.region,
      page: () => RegionView(),
      binding: RegionBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}
