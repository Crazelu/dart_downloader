import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final double? height;
  final FontWeight? fontWeight;
  final Color? color;
  final String? fontFamily;
  final TextStyle? style;
  final TextAlign? textAlign;
  final double? width;
  final bool? softWrap;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextDecoration? decoration;

  const CustomText({
    Key? key,
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.fontFamily,
    this.style,
    this.textAlign,
    this.width,
    this.height,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        overflow: overflow,
        softWrap: softWrap,
        textAlign: textAlign,
        maxLines: maxLines,
        style: style ??
            TextStyle(
              decoration: decoration,
              height: height,
              fontWeight: fontWeight,
              fontSize: fontSize,
              color: color,
              fontFamily: fontFamily,
            ),
      ),
    );
  }
}
