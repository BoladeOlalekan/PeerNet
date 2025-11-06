import 'package:flutter/material.dart';
import 'package:peer_net/base/media.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:fluentui_icons/fluentui_icons.dart';

class UploadSuccessScreen extends StatelessWidget {
  const UploadSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Image
                Image.asset(
                  AppMedia.thankyou,
                  //height: 200,
                ),
                 SizedBox(height: 32),

                // ✅ Text
                Text(
                  "Thank you for contributing!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppStyles.primaryColor,
                  ),
                ),
                 SizedBox(height: 12),
                Text(
                  "Your file has been uploaded and is now awaiting admin approval.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),

                 SizedBox(height: 40),

                // ✅ Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon:  Icon(
                      FluentSystemIcons.ic_fluent_home_filled,
                      color: Colors.white,
                    ),
                    label:  Text(
                      "Go to Home",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.primaryColor,
                      foregroundColor: Colors.white,
                      padding:  EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
