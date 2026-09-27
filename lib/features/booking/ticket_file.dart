import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/domain.dart';
import '../../state/travel_store.dart';

/// Builds with a ticket's file, fetching the family's cloud copy first if
/// it isn't on this phone yet.
class TicketFileBuilder extends StatefulWidget {
  const TicketFileBuilder({super.key, required this.attachment, required this.builder});

  final Attachment attachment;

  /// [file] is null while loading ([loading] true) or when there's no copy.
  final Widget Function(BuildContext context, File? file, bool loading) builder;

  @override
  State<TicketFileBuilder> createState() => _TicketFileBuilderState();
}

class _TicketFileBuilderState extends State<TicketFileBuilder> {
  late Future<File?> _file = _load();

  Future<File?> _load() => context.read<TravelStore>().ticketFile(widget.attachment);

  @override
  void didUpdateWidget(TicketFileBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.fileName != widget.attachment.fileName ||
        oldWidget.attachment.remotePath != widget.attachment.remotePath) {
      _file = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _file,
      builder: (context, snapshot) => widget.builder(
        context,
        snapshot.data,
        snapshot.connectionState != ConnectionState.done,
      ),
    );
  }
}
