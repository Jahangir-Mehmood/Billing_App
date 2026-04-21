// import 'package:billing_app/app/routes/app_pages.dart';
// import 'package:get/get.dart';

// class SplashController extends GetxController {

//  @override
//   void onInit() {
//     super.onInit();
//     checkFunc();
//   }

// void checkFunc() async {
//   print("SplashController: checkFunc called"); // Debug print
//   await Future.delayed(const Duration(seconds: 3));
//   print("Navigating to HOME");
//   // await Get.offAllNamed(Routes.HOME);
//   await Get.offAllNamed(Routes.HOME);
// }
// }

import 'package:billing_app/app/modules/home/views/home_view.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // print("SPLASH INIT RUNNING");  // debug
    checkFunc();
  }

  void checkFunc() async {
    // print("CHECK FUNC RUNNING"); // debug
    await Future<dynamic>.delayed(const Duration(seconds: 2));
    // print("GOING TO HOME"); // debug

    // await Get.offAllNamed(Routes.HOME);
    await Get.to(() => HomeView());
  }
}
