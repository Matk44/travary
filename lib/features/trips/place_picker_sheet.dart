import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../logic/destinations.dart';

/// Choose where a trip goes: any country, or a well-known region or city
/// (or only countries, with [countriesOnly]). Returns the place, or null if
/// the traveller backs out.
Future<Place?> showPlacePicker(
  BuildContext context, {
  bool countriesOnly = false,
  String title = 'Where is it?',
  String subtitle = 'The trip takes on its look.',
}) => showModalBottomSheet<Place>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: TravaryColors.linen,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: FractionallySizedBox(
      heightFactor: 0.85,
      child: PlacePicker(countriesOnly: countriesOnly, title: title, subtitle: subtitle),
    ),
  ),
);

class PlacePicker extends StatefulWidget {
  const PlacePicker({
    super.key,
    this.countriesOnly = false,
    this.title = 'Where is it?',
    this.subtitle = 'The trip takes on its look.',
  });

  final bool countriesOnly;
  final String title;
  final String subtitle;

  @override
  State<PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = [
      for (final place in searchPlaces(_query.text))
        if (!widget.countriesOnly || place.isCountry) place,
    ];
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TravarySpace.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.title, style: TravaryText.headline),
                const SizedBox(height: TravarySpace.xs),
                Text(widget.subtitle, style: TravaryText.bodySoft),
                const SizedBox(height: TravarySpace.md),
                TextField(
                  controller: _query,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: widget.countriesOnly ? 'Country' : 'Country, region or city',
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: TravarySpace.sm),
          Expanded(
            child: results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(TravarySpace.gutter),
                    child: Text(
                      'Not on our list. Pick its country, or leave it: Travary works it out from your bookings.',
                      style: TravaryText.bodySoft,
                    ),
                  )
                : ListView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final place = results[i];
                      return ListTile(
                        leading: Icon(place.isCountry ? Icons.public_rounded : Icons.place_outlined),
                        title: Text(place.name),
                        subtitle: place.isCountry ? null : Text(place.countryName),
                        onTap: () => Navigator.of(context).pop(place),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
