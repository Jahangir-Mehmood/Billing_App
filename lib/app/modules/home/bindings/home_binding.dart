import 'package:get/get.dart';

import '../controllers/home_controller.dart';
class HomeBinding extends Binding {
  @override
  List<Bind<dynamic>> dependencies() => <Bind<dynamic>>[Bind.lazyPut<HomeController>(() => HomeController(), fenix: true)];
}