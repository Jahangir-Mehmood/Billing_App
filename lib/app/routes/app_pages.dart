import 'package:get/get.dart';

import '../modules/basePage/bindings/base_page_binding.dart';
import '../modules/basePage/views/base_page_view.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/logout/bindings/logout_binding.dart';
import '../modules/logout/views/logout_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/signup/bindings/signup_binding.dart';
import '../modules/signup/views/signup_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(name: _Paths.HOME, page: () => const HomeView(), binding: HomeBinding()),
    GetPage(name: _Paths.LOGIN, page: () => const LoginView(), binding: LoginBinding()),
    GetPage(name: _Paths.SIGNUP, page: () => const SignupView(), binding: SignupBinding()),
    GetPage(name: _Paths.DASHBOARD, page: () => const DashboardView(), binding: DashboardBinding()),
    GetPage(name: _Paths.SPLASH, page: () => const SplashView(), binding: SplashBinding()),
    GetPage(name: _Paths.ONBOARDING, page: () => const OnboardingView(), binding: OnboardingBinding()),
    GetPage(name: _Paths.BASE_PAGE, page: () => const BasePageView(), binding: BasePageBinding()),
    GetPage(name: _Paths.LOGOUT, page: () => const LogoutView(), binding: LogoutBinding()),
  ];
}
