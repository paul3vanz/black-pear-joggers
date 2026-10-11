import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'open_link.g.dart';

/// Opens a URL outside the app (browser, mail app...). A provider so tests can
/// replace it with a fake instead of trying to launch a real browser; same idea
/// as mocking `window.open` in Jest.
@Riverpod(keepAlive: true)
Future<bool> Function(Uri url) urlOpener(Ref ref) =>
    (url) => launchUrl(url, mode: LaunchMode.externalApplication);

/// Opens [url] externally, or shows a SnackBar if nothing could handle it.
Future<void> openLink(BuildContext context, WidgetRef ref, Uri url) async {
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    opened = await ref.read(urlOpenerProvider)(url);
  } on Object {
    opened = false;
  }
  if (!opened) {
    messenger.showSnackBar(const SnackBar(content: Text("Couldn't open link")));
  }
}
