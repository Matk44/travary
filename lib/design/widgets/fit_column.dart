import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A column for controls that shouldn't make anyone scroll (the pass desk):
/// within [height] it shows its optional children ([FitItem]) most wanted
/// first (the highest [FitItem.keep]) while they fit, stopping at the first
/// that doesn't, so a less wanted one never shows in place of a more wanted
/// one. The room left over goes above child [bottomFrom], so the children
/// from there sit at the bottom. Children it can't leave out are never squeezed: when they need
/// more than [height] the column is as tall as they are (and the screen
/// scrolls). With an infinite [height] it's a plain column.
class FitColumn extends MultiChildRenderObjectWidget {
  const FitColumn({super.key, required this.height, this.bottomFrom, super.children});

  final double height;
  final int? bottomFrom;

  @override
  RenderFitColumn createRenderObject(BuildContext context) => RenderFitColumn(height: height, bottomFrom: bottomFrom);

  @override
  void updateRenderObject(BuildContext context, RenderFitColumn renderObject) {
    renderObject
      ..height = height
      ..bottomFrom = bottomFrom;
  }
}

/// An optional child of a [FitColumn], shown when there's room: the highest
/// [keep] first (an earlier child first when they're equal).
class FitItem extends ParentDataWidget<FitColumnParentData> {
  const FitItem({super.key, required this.keep, required super.child});

  final int keep;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as FitColumnParentData;
    if (data.keep == keep) return;
    data.keep = keep;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => FitColumn;
}

class FitColumnParentData extends ContainerBoxParentData<RenderBox> {
  /// Null for a child that's always shown.
  int? keep;
  bool shown = true;
}

class RenderFitColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FitColumnParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FitColumnParentData> {
  RenderFitColumn({required double height, int? bottomFrom}) : _height = height, _bottomFrom = bottomFrom;

  double _height;
  double get height => _height;
  set height(double value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  int? _bottomFrom;
  int? get bottomFrom => _bottomFrom;
  set bottomFrom(int? value) {
    if (value == _bottomFrom) return;
    _bottomFrom = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FitColumnParentData) child.parentData = FitColumnParentData();
  }

  static FitColumnParentData _data(RenderBox child) => child.parentData! as FitColumnParentData;

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final children = getChildrenAsList();
    var total = 0.0;
    for (final child in children) {
      child.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      final data = _data(child);
      data.shown = data.keep == null;
      if (data.shown) total += child.size.height;
    }
    final optional = [
      for (final (index, child) in children.indexed)
        if (_data(child).keep case final keep?) (keep: keep, index: index, child: child),
    ]..sort((a, b) => a.keep != b.keep ? b.keep.compareTo(a.keep) : a.index.compareTo(b.index));
    for (final item in optional) {
      if (total + item.child.size.height > _height) break;
      _data(item.child).shown = true;
      total += item.child.size.height;
    }
    final own = _height.isFinite ? math.max(_height, total) : total;
    size = constraints.constrain(Size(width, own));
    var y = 0.0;
    for (final (index, child) in children.indexed) {
      if (index == _bottomFrom) y += math.max(0, size.height - total);
      final data = _data(child)..offset = Offset(0, y);
      if (data.shown) y += child.size.height;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final data = _data(child);
      if (data.shown) context.paintChild(child, data.offset + offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (var child = lastChild; child != null; child = childBefore(child)) {
      final data = _data(child);
      if (!data.shown) continue;
      final box = child;
      final hit = result.addWithPaintOffset(
        offset: data.offset,
        position: position,
        hitTest: (result, transformed) => box.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if (_data(child).shown) visitor(child);
    }
  }
}
