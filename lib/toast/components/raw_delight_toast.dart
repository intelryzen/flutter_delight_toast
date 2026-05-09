import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RawDelightToast extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;
  final Duration snackbarDuration;
  final Curve? animationCurve;
  final bool autoDismiss;
  final DelightSnackbarPosition snackbarPosition;
  final Function() getscaleFactor;
  final Function() getPosition;
  final double? maxWidth;

  final Function() onRemove;

  const RawDelightToast({
    super.key,
    required this.child,
    required this.animationDuration,
    required this.snackbarPosition,
    required this.snackbarDuration,
    required this.onRemove,
    this.autoDismiss = true,
    required this.getPosition,
    this.animationCurve,
    required this.getscaleFactor,
    this.maxWidth,
  });

  @override
  State<RawDelightToast> createState() => RawDelightToastState();
}

class RawDelightToastState extends State<RawDelightToast> {
  final GlobalKey positionedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  Widget getChildBasedOnDissmiss(Widget child) {
    return Animate(
      onComplete: (controller) {
        if (widget.autoDismiss) {
          widget.onRemove();
        }
      },
      effects: [
        SlideEffect(
          begin: Offset(
            0,
            widget.snackbarPosition == DelightSnackbarPosition.bottom ? 2 : -2,
          ),
          end: Offset.zero,
          duration: Duration(
            milliseconds: 2 * widget.animationDuration.inMilliseconds,
          ),
          curve: widget.animationCurve ?? Curves.elasticOut,
        ),
        FadeEffect(duration: widget.animationDuration, begin: 0, end: 1),
        if (widget.autoDismiss)
          SlideEffect(
            delay: widget.snackbarDuration,
            duration: const Duration(milliseconds: 1000),
            curve: widget.animationCurve ?? Curves.easeInOut,
            begin: Offset.zero,
            end: widget.snackbarPosition == DelightSnackbarPosition.top
                ? const Offset(0, -3)
                : const Offset(-1, 0),
          ),
      ],
      child: Dismissible(
        key: UniqueKey(),
        direction: widget.snackbarPosition == DelightSnackbarPosition.top
            ? DismissDirection.up
            : DismissDirection.horizontal,
        onDismissed: (direction) {
          widget.onRemove();
        },
        child: widget.child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 시스템 UI(상태바/노치/홈 인디케이터) 높이를 고려하여 위치 계산.
    // iOS는 상태바 ~47pt, Android는 ~24dp, macOS/desktop은 0으로 플랫폼별
    // 차이를 자동 보정한다. 시스템 UI 바로 다음에 약간의 여백(gap)만 둔다.
    const gap = 8.0;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final topInset = viewPadding.top + gap;
    final bottomInset = viewPadding.bottom + gap;
    return AnimatedPositioned(
      duration: Duration(milliseconds: widget.animationDuration.inMilliseconds),
      key: positionedKey,
      curve: Curves.easeOutBack,
      top: widget.snackbarPosition == DelightSnackbarPosition.top
          ? widget.getPosition() + topInset
          : null,
      bottom: widget.snackbarPosition == DelightSnackbarPosition.bottom
          ? widget.getPosition() + bottomInset
          : null,
      left: 0,
      right: 0,
      child: Material(
        // MaterialType.transparency는 내부 _RenderInkFeatures 래퍼를 거치지
        // 않으므로 Material의 빈 영역(자식이 그려지지 않은 부분)이 hit을
        // 흡수하지 않고 뒤쪽 위젯으로 이벤트가 전달된다.
        type: MaterialType.transparency,
        // Center + ConstrainedBox로 hit 영역을 maxWidth로 제한한다.
        // Center는 자식 위치에만 hit test를 위임하므로, 좌우 빈 영역의
        // 포인터 이벤트가 뒤쪽 위젯(예: AppBar 버튼)으로 통과된다.
        // Dismissible도 ConstrainedBox 내부에 있어 동일한 폭만 가로챈다.
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: widget.maxWidth ?? double.infinity,
            ),
            child: AnimatedScale(
              duration: widget.animationDuration,
              curve: Curves.bounceOut,
              scale: widget.getPosition() == 0 ? 1 : widget.getscaleFactor(),
              child: getChildBasedOnDissmiss(widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
