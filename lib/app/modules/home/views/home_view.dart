import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        body: Container(
          height: Get.size.height,
          width: Get.size.width,
          alignment: Alignment.center,
          child: 
              Center(child: const Text('Home View')),
        ),
      ),
    );
  }
}
