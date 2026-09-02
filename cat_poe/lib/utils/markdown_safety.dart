import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

/// Absolute http(s) URLs with a non-empty host are the only thing we accept
/// from admin-controlled markdown — everything else (javascript:, intent:,
/// file:, sms:, data:, etc.) is dropped on link tap and image render.
bool isSafeWebUrl(Uri? url) {
  if (url == null) return false;
  if (url.scheme != 'http' && url.scheme != 'https') return false;
  if (!url.hasAuthority || url.host.isEmpty) return false;
  return true;
}

/// `onTapLink` handler for [MarkdownBody] / [Markdown] backed by admin content.
/// Drops anything that isn't an absolute http(s) URL.
Future<void> safeOnTapMarkdownLink(String text, String? href, String title) async {
  if (href == null) return;
  final Uri? url = Uri.tryParse(href);
  if (!isSafeWebUrl(url)) return;
  if (await canLaunchUrl(url!)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

/// `imageBuilder` for [MarkdownBody] / [Markdown] backed by admin content.
/// Refuses to fetch images from non-http(s) origins.
Widget safeMarkdownImageBuilder(Uri uri, String? title, String? alt) {
  if (!isSafeWebUrl(uri)) return const SizedBox.shrink();
  return Image.network(
    uri.toString(),
    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
  );
}
