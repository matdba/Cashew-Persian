import 'dart:math';

import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TappableTextEntry extends StatelessWidget {
  const TappableTextEntry({
    Key? key,
    required this.title,
    required this.placeholder,
    required this.onTap,
    this.fontSize,
    this.fontWeight,
    this.padding = const EdgeInsets.symmetric(vertical: 0),
    this.internalPadding =
        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    this.autoSizeText = false,
    this.showPlaceHolderWhenTextEquals,
    this.disabled = false,
    this.customTitleBuilder,
    this.enableAnimatedSwitcher = true,
    this.addTappableBackground = false,
  }) : super(key: key);

  final String? title;
  final String placeholder;
  final VoidCallback onTap;
  final EdgeInsets padding;
  final EdgeInsets internalPadding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool autoSizeText;
  final String? showPlaceHolderWhenTextEquals;
  final bool disabled;
  final Function(Widget Function(String? titlePassed) titleBuilder)?
      customTitleBuilder;
  final bool enableAnimatedSwitcher;
  final bool addTappableBackground;

  @override
  Widget build(BuildContext context) {
    Widget titleBuilder(String? titlePassed) {
      return TextFont(
        autoSizeText: autoSizeText,
        maxLines: 2,
        minFontSize: 16,
        textAlign: TextAlign.left,
        fontSize: fontSize ?? 35,
        fontWeight: fontWeight ?? FontWeight.bold,
        text: titlePassed == null ||
                titlePassed == "" ||
                titlePassed == showPlaceHolderWhenTextEquals
            ? placeholder
            : titlePassed ?? "",
        textColor: titlePassed == null ||
                titlePassed == "" ||
                titlePassed == showPlaceHolderWhenTextEquals
            ? getColor(context, "textLight")
            : getColor(context, "black"),
      );
    }

    return Stack(
      children: [
        if (addTappableBackground)
          Positioned(
            top: padding.top + 3,
            bottom: padding.bottom + 4,
            right: padding.right - 1,
            left: padding.left - 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: (appStateSettings["materialYou"]
                    ? dynamicPastel(context,
                        Theme.of(context).colorScheme.secondaryContainer,
                        amountLight: 0, amountDark: 0.6)
                    : getColor(context, "lightDarkAccent")),
              ),
            ),
          ),
        AnimatedSizeSwitcher(
          enabled: enableAnimatedSwitcher,
          child: Tappable(
            key: ValueKey(title),
            onTap: disabled == true ? null : onTap,
            color: Colors.transparent,
            borderRadius: getPlatform() == PlatformOS.isIOS ? 10 : 15,
            child: Padding(
              padding: padding,
              child: AnimatedContainer(
                curve: Curves.easeInOut,
                duration: Duration(milliseconds: 250),
                padding: internalPadding,
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          width: disabled ? 0 : 1.5,
                          color: disabled
                              ? Colors.transparent
                              : appStateSettings["materialYou"]
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2)
                                  : getColor(context, "lightDarkAccentHeavy"))),
                ),
                child: IntrinsicWidth(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: customTitleBuilder != null
                        ? customTitleBuilder!(titleBuilder)
                        : titleBuilder(title),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
