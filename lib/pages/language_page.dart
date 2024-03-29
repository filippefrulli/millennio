import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:millennio/pages/main_menu_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({Key? key}) : super(key: key);

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  static List<String> languages = [
    'English',
    'Deutsch',
    'Italiano',
    'Français',
    'Español',
  ];

  static List<String> lang = ['en', 'de', 'it', 'fr', 'es'];

  static List<String> regions = ['US', 'DE', 'IT', 'FR', 'ES'];

  int selected = 21;

  double opacity = 1.0;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: body(),
    );
  }

  Widget body() {
    return Column(
      children: [
        const SizedBox(height: 48),
        Text(
          'Select your language',
          maxLines: 1,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        Expanded(
          child: Container(),
        ),
        _languages(),
        Expanded(
          child: Container(),
        ),
        _next(),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _next() {
    if (selected < 10) {
      return DelayedDisplay(
        delay: const Duration(milliseconds: 100),
        child: TextButton(
          onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            bool seen = prefs.getBool('skip_intro') ?? false;
            prefs.setBool('skip_intro', true);
            if (context.mounted && seen) {
              Navigator.of(context).pop();
            } else if (mounted && !seen) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const MainMenuPage(),
                ),
              );
            }
          },
          child: Text(
            "done".tr(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    } else {
      return Container(height: 48);
    }
  }

  Widget _languages() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
        height: 260,
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: ListView.builder(
            itemCount: languages.length,
            itemBuilder: (context, index) {
              return _listTile(languages[index], lang[index], regions[index], index);
            },
          ),
        ),
      ),
    );
  }

  Widget _listTile(String language, String lang, String region, int index) {
    return TextButton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _text(language, index),
          const SizedBox(height: 12),
        ],
      ),
      onPressed: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (mounted) {
          context.setLocale(Locale(lang, region));

          prefs.setInt('language_number', index);
          prefs.setString('lang', '$lang-$region');

          setState(() {
            selected = index;
          });
        }
      },
    );
  }

  Widget _text(String language, int index) {
    if (selected == index) {
      return Text(
        language,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    } else {
      return Text(
        language,
        style: Theme.of(context).textTheme.displayMedium,
      );
    }
  }
}
