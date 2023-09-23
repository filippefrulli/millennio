import 'dart:async';
import 'dart:io';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:millennio/pages/quiz_page.dart';
import 'package:millennio/widgets/toast_widget.dart';
import 'package:oktoast/oktoast.dart';
import 'package:millennio/pages/settings_page.dart';
import 'package:millennio/utils/secrets.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({Key? key}) : super(key: key);

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int currentIndex = -1;

  final openAI = OpenAI.instance
      .build(token: openApiKey, baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 20)), enableLog: true);

  final _controller = TextEditingController();

  bool isLongEnough = false;
  bool isValidQuery = false;
  bool enableLoading = false;
  bool hideExample = false;

  bool noInternet = false;
  int typeIsMovie = 0; //0 = movie 1 = show

  @override
  void initState() {
    super.initState();
    _controller.addListener(checkLength);
    _controller.text = '';
    hideExample = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: body(),
    );
  }

  Widget body() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            topBar(),
            Expanded(
              flex: 2,
              child: Container(),
            ),
            description(),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(
                  Icons.help_outline_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 26,
                ),
                onPressed: () {
                  showExamples();
                },
              ),
            ),
            const SizedBox(height: 2),
            promptInput(),
            const SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: Container(),
            ),
            goButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget topBar() {
    return Row(
      children: [
        const SizedBox(
          width: 48,
        ),
        Expanded(
          child: Container(),
        ),
        DelayedDisplay(
          fadingDuration: const Duration(milliseconds: 1000),
          child: Text(
            "hey_there".tr(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: Container(),
        ),
        settingsButton(),
      ],
    );
  }

  Widget settingsButton() {
    return IconButton(
      icon: Icon(
        Icons.settings,
        color: Colors.grey[400],
        size: 28,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsPage(),
          ),
        );
      },
    );
  }

  Widget description() {
    return Text(
      "quiz_about".tr(),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.displayMedium,
    );
  }

  Widget promptInput() {
    return SizedBox(
      height: 80,
      child: TextField(
        autofocus: false,
        maxLength: 60,
        showCursor: true,
        maxLines: 1,
        minLines: 1,
        controller: _controller,
        cursorColor: Theme.of(context).focusColor,
        style: Theme.of(context).textTheme.titleMedium,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).primaryColorDark,
          helperText: "complete_sentence".tr(),
          hintText: "generate_a_quiz".tr(),
          prefixStyle: Theme.of(context).textTheme.displaySmall!.copyWith(fontSize: 12),
          suffixText: "",
          helperStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
          contentPadding: const EdgeInsets.only(left: 14.0, bottom: 10.0, top: 10.0),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).focusColor, width: 2.0),
            borderRadius: BorderRadius.circular(15),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).focusColor, width: 2.0),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget goButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(0),
            ),
            onPressed: () async {
              goButtonPressed();
            },
            child: Container(
              height: 50,
              width: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.circular(25),
                ),
                color: isLongEnough ? Theme.of(context).focusColor : Colors.grey[600],
              ),
              child: Center(
                child: enableLoading
                    ? LoadingAnimationWidget.threeArchedCircle(
                        color: Colors.grey[900]!,
                        size: 30,
                      )
                    : Text(
                        "go".tr(),
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[900],
                        ),
                      ),
              ),
            ),
          ),
          Expanded(
            child: Container(),
          ),
        ],
      ),
    );
  }

  void checkLength() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.text.length > 3 && mounted) {
        setState(() {
          isLongEnough = true;
        });
      }
      if (_controller.text.length < 3 && mounted) {
        setState(() {
          isLongEnough = false;
        });
      }
    });
  }

  validateQuery() async {
    final request = ChatCompleteText(
      messages: [
        Messages(role: Role.assistant, content: 'validation_prompt'.tr() + _controller.text),
      ],
      maxToken: 400,
      model: GptTurbo0301ChatModel(),
    );

    final response = await openAI.onChatCompletion(request: request);
    if (response!.choices[0].message!.content == "YES" && mounted) {
      setState(() {
        isValidQuery = true;
        enableLoading = false;
      });
    } else {
      setState(() {
        isValidQuery = false;
        enableLoading = false;
      });
    }
  }

  Future<void> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          noInternet = false;
        });
      }
    } on SocketException catch (_) {
      setState(() {
        noInternet = true;
      });
    }
  }

  void goButtonPressed() async {
    FocusScope.of(context).unfocus();
    await checkConnection();
    if (noInternet) {
      showToastWidget(
        ToastWidget(
          title: "connect_to_internet".tr(),
          icon: const Icon(Icons.cloud_off, color: Colors.orange, size: 36),
        ),
        duration: const Duration(seconds: 4),
      );
    } else {
      if (isLongEnough && mounted) {
        setState(() {
          enableLoading = true;
        });
        await validateQuery();
        if (isValidQuery && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => QuizPage(requestString: _controller.text),
            ),
          );
        } else {
          showToastWidget(
            ToastWidget(
              title: "invalid_input".tr(),
              icon: const Icon(Icons.dangerous_outlined, color: Colors.red, size: 36),
            ),
            duration: const Duration(seconds: 4),
          );
        }
      }
    }
  }

  void showExamples() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: ShapeBorder.lerp(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          1,
        )!,
        backgroundColor: Colors.grey[900]!,
        title: Text("need_inspiration".tr()),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "example_1".tr(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_2".tr(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_3".tr(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_4".tr(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 12),
            Text(
              "example_5".tr(),
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ],
        ),
      ),
    );
  }
}
