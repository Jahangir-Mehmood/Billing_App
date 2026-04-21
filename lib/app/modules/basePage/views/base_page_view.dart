import 'package:billing_app/domain/Widgets/appbar/appbar.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/base_page_controller.dart';

class BasePageView extends GetView<BasePageController>{
  const BasePageView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     body:  UAppbar(),
    );
  }
}
