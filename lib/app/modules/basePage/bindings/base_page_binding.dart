import 'package:get/get.dart';

import '../controllers/base_page_controller.dart';

class BasePageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BasePageController>(
      () => BasePageController(),
    );
  }
}
