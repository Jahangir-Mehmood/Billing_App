import 'package:billing_app/app/modules/splash/controllers/splash_controller.dart';
import 'package:get/get.dart';

// class SplashBinding extends Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<SplashController>(() => SplashController());
//   }
// }

class SplashBinding extends Binding {
  @override
  List<Bind<dynamic>> dependencies() => <Bind<dynamic>>[Bind.lazyPut<SplashController>(() => SplashController(), fenix: true)];
}
