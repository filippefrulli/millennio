import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:millennio/utils/secrets.dart';

class QuizPage extends StatefulWidget {
  final String requestString;

  const QuizPage({
    Key? key,
    required this.requestString,
  }) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final openAI = OpenAI.instance
      .build(token: openApiKey, baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 20)), enableLog: true);

  int index = 0;
  int length = 0;
  bool askingGpt = false;
  bool fetchingQuestions = false;
  bool filtering = false;

  final _controller = TextEditingController();

  late Future<dynamic> resultList;

  @override
  initState() {
    super.initState();

    resultList = askGpt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: pageBody(),
        ));
  }

  Widget pageBody() {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.05,
        ),
        FutureBuilder<dynamic>(
          future: resultList,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data.length > 0) {
              return Column(children: [
                Text(
                  "what_year".tr(),
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  length != 0 ? '${index + 1} / $length' : '',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              ]);
            } else {
              return Expanded(
                child: Container(),
              );
            }
          },
        ),
        const SizedBox(
          height: 8,
        ),
        FutureBuilder<dynamic>(
          future: resultList,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data.length > 0) {
              length = snapshot.data.length;
              return questionItem(snapshot.data[index]);
            } else {
              return loadingWidget();
            }
          },
        ),
      ],
    );
  }

  Widget questionItem(QuizItem quizItem) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // Expanded(
          //   flex: 20,
          //   child: quizImage(
          //     watchObject.image,
          //   ),
          // ),
          Expanded(
            flex: 20,
            child: Center(
              child: Text(
                quizItem.question,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
          Expanded(
            flex: 3,
            child: answerBox(),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
        ],
      ),
    );
  }

  Widget answerBox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(),
        ),
        SizedBox(
          height: 120,
          width: 200,
          child: TextField(
            autofocus: false,
            maxLength: 4,
            keyboardType: TextInputType.number,
            showCursor: true,
            controller: _controller,
            cursorColor: Theme.of(context).focusColor,
            style: Theme.of(context).textTheme.titleMedium,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).primaryColorDark,
              suffixText: "",
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
        ),
        Expanded(
          child: Container(),
        ),
      ],
    );
  }

  Widget quizImage(String poster) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(25),
      ),
    );
  }

  Widget acceptButton() {
    return Center(
      child: DelayedDisplay(
        delay: const Duration(milliseconds: 100),
        child: Container(
          height: 60,
          width: 150,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(25),
            ),
            color: Colors.orange,
          ),
          child: TextButton(
              onPressed: () async {
                //parseAnswer()
              },
              child: const Icon(Icons.check, color: Colors.white, size: 30)),
        ),
      ),
    );
  }

  Widget loadingWidget() {
    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.threeArchedCircle(
              color: Colors.orange,
              size: 50,
            ),
            const SizedBox(
              height: 46,
            ),
            askingGpt
                ? Text(
                    "generating".tr(),
                    style: Theme.of(context).textTheme.displaySmall,
                  )
                : Container(),
            const SizedBox(
              height: 46,
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> askGpt() async {
    setState(() {
      askingGpt = true;
    });
    final request = ChatCompleteText(
      messages: [
        Messages(
          role: Role.assistant,
          content: 'prompt_1'.tr() + widget.requestString + 'prompt_2'.tr(),
        ),
      ],
      temperature: 0.1,
      maxToken: 400,
      model: GptTurboChatModel(),
    );

    final response = await openAI.onChatCompletion(request: request);
    print(response!.choices[0].message!.content);

    setState(() {
      askingGpt = false;
    });

    return parseResponse(response!.choices[0].message!.content);
  }

  parseResponse(String response) async {
    setState(() {
      fetchingQuestions = true;
    });

    List<QuizItem> quizItemList = [];

    List<String> responseItems = response.split(',,');
    if (responseItems.isEmpty) {
      Navigator.pop(context);
      Fluttertoast.showToast(
        msg: "prompt_issue".tr(),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    for (String item in responseItems) {
      List<String> list = item.split('y:');
      if (list.length > 1) {
        quizItemList.add(
          QuizItem(
            question: list[0],
            year: list[1],
          ),
        );
      } else {}
    }

    setState(() {
      fetchingQuestions = false;
    });

    return quizItemList;
  }
}

class QuizItem {
  final String question;
  final String year;

  QuizItem({required this.question, required this.year});
}
