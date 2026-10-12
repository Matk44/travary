import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/widgets/travi_cameo.dart';
import 'package:travary/logic/travi_cameos.dart';

/// Travi making his cameo for [moment].
Finder traviCameo(TraviMoment moment) =>
    find.byWidgetPredicate((widget) => widget is TraviCameo && widget.moment == moment);
