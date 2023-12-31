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
  int score = 0;
  int initalScore = 0;
  bool askingGpt = false;
  bool fetchingQuestions = false;
  bool filtering = false;

  bool showAnswer = false;
  int givenAnswer = 0;

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
              return Column(
                children: [
                  Text(
                    '${widget.requestString} Quiz',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    '$score points',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                ],
              );
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
          const SizedBox(
            height: 64,
          ),
          // Expanded(
          //   flex: 20,
          //   child: quizImage(
          //     watchObject.image,
          //   ),
          // ),
          Expanded(
            child: questionWidget(quizItem.question),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
          showAnswer
              ? Expanded(
                  flex: 3,
                  child: resultWidget(quizItem.year),
                )
              : Container(),

          Expanded(
            flex: 2,
            child: showAnswer ? okButton(quizItem.year) : answerBox(),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
        ],
      ),
    );
  }

  Widget okButton(int year) {
    return TextButton(
      onPressed: () {
        if (mounted) {
          setState(
            () {
              showAnswer = false;
              index++;
              score += calculateScore(year);
              _controller.clear();
            },
          );
        }
      },
      child: Container(
        height: 50,
        width: 80,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(25),
          ),
          color: Theme.of(context).focusColor,
        ),
        child: Center(
          child: Text(
            "OK",
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[900],
            ),
          ),
        ),
      ),
    );
  }

  Widget questionWidget(String question) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
        border: Border.all(
          color: Theme.of(context).primaryColorLight,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          question,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
    );
  }

  Widget resultWidget(int year) {
    return Column(
      children: [
        Text(
          'Answer: $year',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 16),
        Text(
          givenAnswer.toString(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            color: givenAnswer == year ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 32),
        givenAnswer == year ? Text('Correct!') : Text('${calculateScore(year)} points'),
      ],
    );
  }

  Widget answerBox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(),
        ),
        SizedBox(
          height: 120,
          width: 180,
          child: TextField(
            autofocus: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            showCursor: true,
            controller: _controller,
            cursorColor: Theme.of(context).focusColor,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).primaryColorDark,
              suffixText: "",
              contentPadding: const EdgeInsets.only(left: 14.0, bottom: 10.0, top: 10.0),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).focusColor, width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).focusColor, width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 16,
        ),
        acceptButton(),
        Expanded(
          child: Container(),
        ),
      ],
    );
  }

  Widget quizImage(String poster) {
    return const ClipRRect(
      borderRadius: BorderRadius.all(
        Radius.circular(25),
      ),
    );
  }

  Widget acceptButton() {
    return DelayedDisplay(
      delay: const Duration(milliseconds: 100),
      child: Container(
        height: 50,
        width: 60,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
          color: Colors.orange,
        ),
        child: TextButton(
          onPressed: () {
            if (mounted) {
              setState(() {
                showAnswer = true;
                givenAnswer = int.parse(_controller.text);
              });
            }
          },
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 30,
          ),
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

    setState(() {
      askingGpt = false;
    });

    return parseResponse(response!.choices[0].message!.content);
  }

  parseResponse(String response) async {
    setState(() {
      fetchingQuestions = true;
    });

    print(response);

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
            year: int.parse(
              list[1],
            ),
          ),
        );
      } else {}
    }

    getInitialScore(quizItemList);

    setState(() {
      fetchingQuestions = false;
    });

    return quizItemList;
  }

  int calculateScore(int year) {
    if (givenAnswer == year && mounted) {
      return initalScore ~/ 5;
    } else if (mounted) {
      int res = givenAnswer - year;
      if (res > 0) {
        res = res * -1;
      }
      return res;
    }
    return 0;
  }

  getInitialScore(List<QuizItem> quizItemList) {
    int min = 3000;
    int max = 0;
    for (QuizItem item in quizItemList) {
      if (item.year < min) {
        min = item.year;
      }
      if (item.year > max) {
        max = item.year;
      }
    }
    if (mounted) {
      setState(() {
        score = max - min;
        initalScore = max - min;
      });
    }
  }
}

class QuizItem {
  final String question;
  final int year;

  QuizItem({required this.question, required this.year});
}
