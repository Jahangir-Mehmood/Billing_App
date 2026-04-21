  // import 'package:flutter/material.dart';

  // import 'package:get/get.dart';

  // import '../controllers/splash_controller.dart';

  // class SplashView extends GetView<SplashController> {
  //   const SplashView({super.key});
  //   @override
  //   Widget build(BuildContext context) {
  //     return SafeArea(
  //         child: Scaffold(
  //             body: Container(
  //               height: Get.size.height,
  //               width: Get.size.width,
  //               alignment: Alignment.center,
  //               // decoration: const BoxDecoration(image: DecorationImage(image: AssetImage(Assets.imagesTwo), fit: BoxFit.cover)),
  //               child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
  //                 Image.asset('assets/images/black_app_logo.png'),
  //                 const Text('Billing App'),
  //               ]),
  //             ),
  //             // bottomNavigationBar: Container(height: cHeight(5), decoration: const BoxDecoration(gradient: kDcsLinearGreenBottom), child: Image.asset(Assets.imagesPoweredByDigicop))
  //             ));
  //   }
  // }
import 'package:billing_app/app/modules/splash/controllers/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class SplashView extends GetView<SplashController>  {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
Get.put(SplashController());
    return SafeArea(
      child: Scaffold(
        body: Container(
          height: Get.size.height,
          width: Get.size.width,
          alignment: Alignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/images/black_app_logo.png'),
              const SizedBox(height: 20),
              const Text('Billing App'),
            ],
          ),
        ),
      ),
    );
  }
}