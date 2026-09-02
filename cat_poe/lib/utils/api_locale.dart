import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';

/// Primary language subtag for `?lang=` on public config endpoints.
String apiLanguageCodeFromContext(BuildContext context) {
  try {
    return Provider.of<LocaleProvider>(context, listen: false)
        .locale
        .languageCode
        .toLowerCase();
  } catch (_) {
    return (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en')
        .toLowerCase();
  }
}
