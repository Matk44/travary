import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../domain/domain.dart';
import '../../logic/flight_status_text.dart';
import '../../logic/formatters.dart';
import '../../state/travel_store.dart';
import '../booking/flight_status_panel.dart';

/// Design tools (debug builds): look up any real flight's live status, to
/// judge AeroDataBox's data before paying for it.
class FlightStatusTestScreen extends StatefulWidget {
  const FlightStatusTestScreen({super.key});

  @override
  State<FlightStatusTestScreen> createState() => _FlightStatusTestScreenState();
}

class _FlightStatusTestScreenState extends State<FlightStatusTestScreen> {
  final _number = TextEditingController();
  final _from = TextEditingController();
  late LocalDate _date = LocalDate.fromDateTime(context.read<TravelStore>().now);
  FlightLookup? _lookup;

  @override
  void dispose() {
    _number.dispose();
    _from.dispose();
    super.dispose();
  }

  void _check() {
    final number = _number.text.trim();
    if (number.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _lookup = FlightLookup(flightNumber: number, date: _date, from: airportCodeIn(_from.text.trim().toUpperCase()));
    });
  }

  Future<void> _pickDate() async {
    final today = LocalDate.fromDateTime(context.read<TravelStore>().now);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.toDateTime(),
      firstDate: today.addDays(-2).toDateTime(),
      lastDate: today.addDays(flightStatusDaysAhead).toDateTime(),
    );
    if (picked != null) setState(() => _date = LocalDate.fromDateTime(picked));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final service = store.flightStatus;
    return Scaffold(
      appBar: AppBar(title: const Text('Flight status test')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.xxl),
        children: [
          Text(
            service == null
                ? 'Live flight status needs the cloud backend.'
                : 'Any real flight from two days ago to three days ahead. Uses AeroDataBox\'s free plan '
                      '(a few hundred lookups a month); answers are shared and reused for a while.',
            style: TravaryText.bodySoft,
          ),
          const SizedBox(height: TravarySpace.lg),
          TextField(
            controller: _number,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Flight number', hintText: 'BA 283'),
            onSubmitted: (_) => _check(),
          ),
          const SizedBox(height: TravarySpace.md),
          TextField(
            controller: _from,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Leaving from (optional)', hintText: 'LHR'),
            onSubmitted: (_) => _check(),
          ),
          const SizedBox(height: TravarySpace.md),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(formatDayShort(_date)),
          ),
          const SizedBox(height: TravarySpace.md),
          FilledButton(onPressed: service == null ? null : _check, child: const Text('Check flight')),
          if (service != null && _lookup != null)
            FlightStatusPanel(service: service, lookup: _lookup!, now: () => store.now),
        ],
      ),
    );
  }
}
