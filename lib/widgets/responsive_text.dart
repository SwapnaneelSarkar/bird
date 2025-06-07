// lib/ui_components/responsive_text.dart
import 'package:flutter/material.dart';

import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double? maxFontSize;
  final double? minFontSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText({
    Key? key,
    required this.text,
    required this.style,
    this.maxFontSize,
    this.minFontSize,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate responsive font size
    double responsiveFontSize = style.fontSize ?? 14.0;
    
    if (maxFontSize != null && minFontSize != null) {
      // Scale based on screen width (assuming 375 as base width)
      final scaleFactor = screenWidth / 375.0;
      responsiveFontSize = (style.fontSize ?? 14.0) * scaleFactor;
      
      // Clamp between min and max
      responsiveFontSize = responsiveFontSize.clamp(minFontSize!, maxFontSize!);
    }
    
    return Text(
      text,
      style: style.copyWith(fontSize: responsiveFontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}


class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final double? borderRadius;
  final double? elevation;
  final Widget? icon;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.width,
    this.height,
    this.borderRadius,
    this.elevation,
    this.icon,
    this.isLoading = false,
    this.padding,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      width: width,
      height: height ?? screenHeight * 0.07,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? ColorManager.black,
          elevation: elevation ?? 0,
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.015,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? screenWidth * 0.02),
            side: borderColor != null
                ? BorderSide(color: borderColor!, width: 1)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? ColorManager.textWhite,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    SizedBox(width: screenWidth * 0.02),
                  ],
                  ResponsiveText(
                    text: text,
                    style: textStyle ?? TextStyle(
                      fontFamily: FontFamily.Montserrat,
                      fontSize: FontSize.s16,
                      fontWeight: FontWeightManager.semiBold,
                      color: textColor ?? ColorManager.textWhite,
                    ),
                    maxFontSize: screenWidth * 0.045,
                    minFontSize: screenWidth * 0.035,
                  ),
                ],
              ),
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  final String? text;
  final Color? color;
  final double? size;

  const LoadingWidget({
    Key? key,
    this.text,
    this.color,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? screenWidth * 0.08,
            height: size ?? screenWidth * 0.08,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? ColorManager.black,
              ),
              strokeWidth: 3,
            ),
          ),
          if (text != null) ...[
            SizedBox(height: screenHeight * 0.02),
            ResponsiveText(
              text: text!,
              style: TextStyle(
                fontFamily: FontFamily.Montserrat,
                fontSize: FontSize.s16,
                fontWeight: FontWeightManager.regular,
                color: ColorManager.black,
              ),
              maxFontSize: screenWidth * 0.045,
              minFontSize: screenWidth * 0.035,
            ),
          ],
        ],
      ),
    );
  }
}


class CustomErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final IconData? icon;

  const CustomErrorWidget({
    Key? key,
    required this.message,
    this.onRetry,
    this.retryButtonText,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: screenWidth * 0.15,
              color: Colors.red,
            ),
            SizedBox(height: screenHeight * 0.02),
            ResponsiveText(
              text: message,
              style: TextStyle(
                fontFamily: FontFamily.Montserrat,
                fontSize: FontSize.s16,
                fontWeight: FontWeightManager.regular,
                color: ColorManager.black,
              ),
              textAlign: TextAlign.center,
              maxFontSize: screenWidth * 0.045,
              minFontSize: screenWidth * 0.035,
            ),
            if (onRetry != null) ...[
              SizedBox(height: screenHeight * 0.03),
              CustomButton(
                text: retryButtonText ?? 'Try Again',
                onPressed: onRetry,
                width: screenWidth * 0.4,
                height: screenHeight * 0.06,
              ),
            ],
          ],
        ),
      ),
    );
  }
}



class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? customIcon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.customIcon,
    this.onAction,
    this.actionText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customIcon ?? Icon(
              icon ?? Icons.inbox_outlined,
              size: screenWidth * 0.15,
              color: ColorManager.black.withOpacity(0.3),
            ),
            SizedBox(height: screenHeight * 0.02),
            ResponsiveText(
              text: title,
              style: TextStyle(
                fontFamily: FontFamily.Montserrat,
                fontSize: FontSize.s18,
                fontWeight: FontWeightManager.semiBold,
                color: ColorManager.black,
              ),
              textAlign: TextAlign.center,
              maxFontSize: screenWidth * 0.05,
              minFontSize: screenWidth * 0.04,
            ),
            if (subtitle != null) ...[
              SizedBox(height: screenHeight * 0.01),
              ResponsiveText(
                text: subtitle!,
                style: TextStyle(
                  fontFamily: FontFamily.Montserrat,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.regular,
                  color: ColorManager.black.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
                maxFontSize: screenWidth * 0.04,
                minFontSize: screenWidth * 0.035,
              ),
            ],
            if (onAction != null && actionText != null) ...[
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.black,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: screenHeight * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                ),
                child: ResponsiveText(
                  text: actionText!,
                  style: TextStyle(
                    fontFamily: FontFamily.Montserrat,
                    fontSize: FontSize.s16,
                    fontWeight: FontWeightManager.medium,
                    color: ColorManager.textWhite,
                  ),
                  maxFontSize: screenWidth * 0.04,
                  minFontSize: screenWidth * 0.035,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}