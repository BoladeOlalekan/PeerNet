import 'package:flutter/material.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';

class RouteDoubleText extends StatelessWidget {
  const RouteDoubleText({super.key, required this.bigText, required this.smallText, required this.func});
  final String bigText;
  final String smallText;
  final VoidCallback func;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          bigText,
          style: AppStyles.doubleText1,
        ),

        TextButton(
          onPressed: func,
          child: Text(
            smallText,
            style: AppStyles.doubleText2,
          ),
        ),
      ],
    );
  }
}