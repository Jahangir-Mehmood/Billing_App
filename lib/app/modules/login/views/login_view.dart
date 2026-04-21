import 'package:billing_app/constant/color_constant.dart';
import 'package:billing_app/constant/import.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});
  @override
 Widget build(BuildContext context) {
    // Sirf yeh simple text dikhao
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: kBlueGradientVertical
        ),
        child: const Center(
          child: Text(
            'LOGIN SCREEN LOADED SUCCESSFULLY!',
            style: TextStyle(fontSize: 20, color: Colors.blue),
          ),
        ),
      ),
    );
  }
}
