import 'package:flutter/material.dart';

import '../../app/theme/kasyaba_tokens.dart';

/// Single bottom-sheet chrome: r32 top corners, handle, navy surface.
class AppSheet extends StatelessWidget {
  final Widget child;
  final Color color;
  final bool showHandle;
  final EdgeInsetsGeometry padding;

  const AppSheet({
    super.key,
    required this.child,
    this.color = KasyabaTokens.bigStone,
    this.showHandle = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxAllowedHeight = screenHeight - topPadding - 32;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxAllowedHeight),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(KasyabaTokens.radiusSheetTop),
          ),
          border: const Border(
            top: BorderSide(color: KasyabaTokens.poloBlue30),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHandle)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 12),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: KasyabaTokens.poloBlue40,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  padding: padding,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showKasyabaSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  Color barrierColor = const Color(0xB8000000),
}) {
  final topPadding = MediaQuery.paddingOf(context).top;
  final screenHeight = MediaQuery.sizeOf(context).height;

  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: isScrollControlled,
    barrierColor: barrierColor,
    constraints: BoxConstraints(maxHeight: screenHeight - topPadding - 32),
    builder: builder,
  );
}
