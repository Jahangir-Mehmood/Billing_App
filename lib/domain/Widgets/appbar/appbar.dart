import 'package:billing_app/constant/color_constant.dart';
import 'package:billing_app/constant/import.dart';

class UAppbar extends StatelessWidget {
  const UAppbar({super.key,this.title,
    this.showBackArrow = false,
    this.leadingIcon,
    this.action,
    this.leadingOnPress,});

   final Widget? title;
  final bool showBackArrow;
  final IconData? leadingIcon;
  final List<Widget>? action;
  final VoidCallback? leadingOnPress;

  @override
  @override
  Widget build(BuildContext context) {
    bool dark = UHelperFunctions.isDarkMode(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackArrow
            ? IconButton(
                onPressed: Get.back,
                icon: Icon(Iconsax.arrow_left, color: dark ? uLight : uDark),
              )
            : leadingIcon != null
            ? IconButton(onPressed: leadingOnPress, icon: Icon(leadingIcon))
            : null,
        title: title,
        actions: action,
      ),
    );
  }

  // @override
  // Size get preferredSize => Size.fromHeight(UDeviceHelper.getAppBarHeight());
  }

