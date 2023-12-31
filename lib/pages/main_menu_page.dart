import 'dart:async';
import 'dart:io';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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

  bool noInternet = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(checkLength);
    _controller.text = '';
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
            const SizedBox(height: 32),
            topBar(),
            Expanded(
              child: Container(),
            ),
            description(),
            Expanded(
              child: Container(),
            ),
            examplesWidget(),
            const SizedBox(height: 16),
            promptInput(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget examplesWidget() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(25),
        ),
        child: IconButton(
          icon: Icon(
            Icons.help_outline_rounded,
            color: Colors.grey[900],
            size: 26,
          ),
          onPressed: () {
            showExamples();
          },
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width - 88,
          child: TextField(
            autofocus: false,
            showCursor: true,
            maxLength: 80,
            maxLines: 3,
            minLines: 1,
            controller: _controller,
            cursorColor: Colors.orange,
            style: TextStyle(
              color: Colors.grey[200],
              fontSize: 16,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[600],
              helperText: "complete_sentence".tr(),
              hintText: "generate_a_quiz".tr(),
              helperStyle: TextStyle(
                color: Colors.grey[200],
                fontSize: 12,
              ),
              contentPadding: const EdgeInsets.only(left: 14.0, bottom: 10.0, top: 10.0),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              enabledBorder: UnderlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        goButton(),
      ],
    );
  }

  Widget goButton() {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: isLongEnough ? Colors.orange : Colors.grey[700],
        borderRadius: BorderRadius.circular(50),
      ),
      child: Center(
        child: IconButton(
          onPressed: () async {
            goButtonPressed();
          },
          icon: Icon(
            Icons.arrow_forward,
            size: 32,
            color: Colors.grey[900],
          ),
        ),
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
