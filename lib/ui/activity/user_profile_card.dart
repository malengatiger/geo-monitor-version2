import 'package:flutter/material.dart';
import 'package:geo_monitor/library/functions.dart';

class UserProfileCard extends StatelessWidget {
  const UserProfileCard(
      {Key? key,
      this.padding,
      this.width,
      this.avatarRadius,
      this.textStyle,
      required this.userName,
      this.userThumbUrl,
      this.elevation,
      required this.namePictureHorizontal})
      : super(key: key);

  final String userName;
  final String? userThumbUrl;
  final double? padding, width, avatarRadius;
  final TextStyle? textStyle;
  final double? elevation;
  final bool namePictureHorizontal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 240,
      child: Card(
        elevation: elevation ?? 8.0,
        shape: getRoundedBorder(radius: 16),
        child: Padding(
          padding: EdgeInsets.all(padding ?? 8),
          child: namePictureHorizontal
              ? Row(
                  children: [
                    userThumbUrl == null
                        ? const CircleAvatar(
                            radius: 8,
                          )
                        : CircleAvatar(
                            radius: avatarRadius ?? 16,
                            backgroundImage: NetworkImage(userThumbUrl!),
                          ),
                    const SizedBox(
                      width: 16,
                    ),
                    Flexible(
                      child: Text(
                        userName,
                        style: textStyle ?? myTextStyleSmall(context),
                      ),
                    ),
                  ],
                )
              : SizedBox(height: 90,
                child: Column(
                    children: [
                      const SizedBox(height: 8,),
                      userThumbUrl == null
                          ? const CircleAvatar(
                              radius: 8,
                            )
                          : CircleAvatar(
                              radius: avatarRadius ?? 16,
                              backgroundImage: NetworkImage(userThumbUrl!),
                            ),
                      const SizedBox(
                        height: 8,
                      ),
                      Flexible(
                        child: Text(
                          userName,
                          style: textStyle ?? myTextStyleSmall(context),
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
