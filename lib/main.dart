import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:tune_your_headphones/notificationHandler.dart';
import 'dart:ui' as ui;
import 'dart:io' as io

if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'FrequencyLists.dart';

import 'package:flutter/services.dart';



//TODO libraries dart:js and dart:html cannot be loaded into Android as they are - a fix would be nice
//import "dart:js" as js;
//import 'dart:html' as html;


void main() async {
  if (!kIsWeb) {
    AwesomeNotifications().initialize(
      null,
      [NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          defaultColor: Colors.grey,
          importance: NotificationImportance.High,
          channelShowBadge: false,
          channelDescription: 'Media player controller',
          playSound: false
      )
      ],
    );

    runApp(const MyApp());
  }}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Headphone Tuning App',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          toolbarOpacity: 0.5,
          toolbarHeight: 1,
        ),
        body: const App(),
      ),
    );
  }
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with TickerProviderStateMixin {


  //mute buttons state
  List<bool> isMuteSelected = [true, false];
  List<bool> isNoiseSelected = [true, false];

  //bool list for chosen frequency/volume highlighted mark initiation
  List<bool> setFrequency = List<bool>.filled(36, false);
  List<bool> setVolume = List<bool>.filled(11, false);

  //stereo /L/R initiation
  bool _flagL = false;
  bool _flagC = true;
  bool _flagR = false;
  bool areChannelsSeparated = false;

  bool volumeWarningSnackBarDisplayed = false;
  bool frequencyWarningSnackBarDisplayed = false;
  bool appPlaybackNotificationDisplayed = false;

  // booleans for animated control buttons
  bool tapAnimationPlus = true;
  bool tapAnimationMinus = true;
  bool tapAnimForward = true;
  bool tapAnimPrevious = true;

  //audioPlayers package instancePlaybacks (sound and noise) initiation
  //playerId set to '1' to prevent memory bugs
  AudioCache audioCache = AudioCache(fixedPlayer: AudioPlayer(playerId: '1'));
  dynamic instancePlayback;
  dynamic instancePlayback2;

//control sliders state initiation
  double frequencySliderValue = 13;
  double frequencyVolumeSet = 0;
  double noiseVolume = 0.6;

//AudioPlayers package initiation for white noise; low_latency mode prevents the loop clipping
  static AudioPlayer noisePlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
  static AudioCache playerNoise = AudioCache(fixedPlayer: noisePlayer);


  //Center/L/R buttons initiation
  String channel = 'C';

  //preview graph variable colors 
  var graphPreviewColor = Colors.grey.shade800;
  var graphPreviewColor2 = Colors.black;

  //preview graph
  double iconSize = 10.0;
  double iconSize2 = 10.0;
  double lineThickness = 1.0;
  double lineThickness2 = 3.0;

  //buttons and background color
  final greyTone1 = Colors.grey[100];

  //greyTone2 is also MaterialAPP's Scaffold background color
  final greyTone2 = Colors.grey[200];
  final greyTone3 = Colors.grey[400];
  final textColor = Colors.black;
  final rightButtonTone = const Color.fromRGBO(
      255, 170, 170, 0.3);
  final leftButtonTone = const Color.fromRGBO(
      170, 255, 170, 0.3);


  //lists initiation - for 3 preview graphs, for main graph, for wavelet file generator
  var curveStateList = List<int>.filled(36, 0);
  var curveStateListCompensated = List<int>.filled(36, 0);
  final list36 = List<dynamic>.generate(36, (i) => i++);
  var curveStateListLeft = List<int>.filled(36, 0);
  var curveStateListRight = List<int>.filled(36, 0);
  var graphDrawingListStereo = List<int>.filled(36, 0);
  var graphDrawingListSeparateChannels = List<int>.filled(72, 0);
  var previewGraphList = List<int>.filled(36, 0);
  var waveletListGenerator = [];

  final double graphHeight = 180;
  double buttonHeight = 40;

  final lineListHorizontal = List<int>.generate(36, (i) => i++);
  final lineListVertical = List<int>.generate(11, (i) => i++);


  //it suggest the user not to touch certain frequencies
  List<int> redFrequencies = const [0, 32, 33, 34, 35];

//volume slider init
  double setVolumeSlider = 0;

  //instructions

  final instructionStyle = const TextStyle(color: Colors.white, fontSize: 16);
  final instructionsController = PageController();

  //instruction page number indicator list
  //change the page number when adding instruction pages
  var listPageNumberBool = List.filled(5, false);
  final listPage = List<int>.generate(5, (i) => i++);

  late final TabController _tabController;


  List <BoxShadow>buttonShadow =
  [BoxShadow(
      color: Colors.grey[400]!,
      offset: const Offset(3, 3),
      blurRadius: 15,
      spreadRadius: 2),
    const BoxShadow(
        color: Colors.white,
        offset: Offset(-3, -3),
        blurRadius: 5,
        spreadRadius: 2)
  ];

  List <BoxShadow>buttonShadowReversed =
  [
    BoxShadow(
        color: Colors.grey[400]!,
        offset:
        const Offset(-3, -3),
        blurRadius: 15,
        spreadRadius: 2),

    const BoxShadow(
        color: Colors.white,
        offset: Offset(3, 3),
        blurRadius: 5,
        spreadRadius: 2)
  ];

  List <Shadow>channelButtonTextShadow = <Shadow>[
    const Shadow(
      offset:
      Offset(-0.5, 0.5),
      blurRadius: 3.0,
      color: Colors.white,
    ),
    const Shadow(
      offset:
      Offset(0.5, -0.5),
      blurRadius: 3.0,
      color: Colors.white,
    ),
  ];

  Widget spacerBox(BuildContext context, int notSmallerThan) {
    return SizedBox(
        height: ([(notSmallerThan + (MediaQuery
            .of(context)
            .size
            .height - 600).abs() / 6).toInt(), 20].reduce((curr, next) =>
        curr < next ? curr : next)).toDouble()
    );
  }

  final volumeWarningSnackBar = const SnackBar(
      content: Text('Niezalecane, by ustawiać korekcję większą niż +6dB'),
      duration: Duration(seconds: 3)
  );
  final frequencyWarningSnackBar = const SnackBar(
      content: Text(
          'Niezalecane, by korygować ustawienia skrajnych częstotliwości'),
      duration: Duration(seconds: 3)
  );

List <Widget> startMessage=const [
  Text(" Upewnij się, żeby na spokojnie przeczytać Instrukcje"),
  SizedBox(height: 10),
  Text("Po więcej informacji zapraszamy na nasz fanpage"),
  SizedBox(height: 10),
  Text(
  " Aplikacja podczas działania korzysta z powiadomienia o odtwarzaniu w tle, przechodząc dalej wyrażasz zgodę"),
  ];




  final instructionsImgList = [
    "assets/pictures/icon.bmp",
    "assets/pictures/preview.gif",
    "assets/pictures/icon.bmp",
    "assets/pictures/icon.bmp",
    "assets/pictures/icon.bmp",

  ];


  //TODO instructions are very long. I imagine that making a video tutorial would be better
  //TODO would be awesome to have them translated in languages other than polish and english

  final instructionsTextList = [
    "Strojenie słuchawek (ustawienie korektora EQ) proponowaną tutaj metodą zajmuje 5 minut i zapewnia zdecydowany, pozytywny efekt dla słuchawek z niższej i średniej półki jakosciowej",
    "Zmierz profil swojego słyszenia - ustaw suwaki głośności tak, żeby sygnał na każdej częstotliwości był takiej samej odczuwalnej głośności. Postaraj się subiektywnie ocenić moc sygnału - niektóre częstotliwości są naturalnie nieprzyjemne w odbiorze",
    "Jeśli robisz to po raz pierwszy, pomiń ustawianie skrajnych częstotliwości (zaznaczonych na czerwono). Nie wzmacniaj też sygnałów, których wcale nie słyszysz. Po zaawansowane instrukcje zapraszam na fanpage naszego projektu",
    "Aplikacja nie jest korektorem samym w sobie! Przenieś wyniki do swojego ulubionego EQ aby korzystać z nich na codzień. Wygeneruj preset do programu Wavelet, lub ręcznie przenieś wyniki do innego programu. Aby uzyskać racjonalny wynik korzystaj z EQ mającego ponad 30 punktów korekcji",
    "Skonfiguruj swój wybrany korektor i ciesz się neutralnym, czystszym dźwiękiem. Eksperymentuj z uzyskanymi wynikami i nie zapomnij podzielić się doświadczeniem w dyskusji na naszym fanpage!",

  ];

  String footerText = 'Check out our Twitter and Youtube channel';


  //Methods:
//signal playback
  //TODO short signals are pre-recorded for each frequency, volume and channel config (Stereo/L/R) and played in loop
  //TODO I've assumed that 100mb of .wav files are acceptable + I did not want to dwell into signal generators
  //TODO It would probably be better to generate signal programmatically

  void playback() async {
    audioCache = AudioCache(fixedPlayer: AudioPlayer(playerId: '1'));


    instancePlayback?.release();
    if (isMuteSelected[1] == true) {
      instancePlayback = await audioCache.loop("30/" +
          (frequencySliderValue).round().toString() +
          channel +
          (((previewGraphList[frequencySliderValue.round()] + 10) / 2) + 1)
              .round()
              .toString() +
          '.wav');
      await instancePlayback.setVolume(1.0);
    } else {
      null;
    }
    //show Android notification "app is active in background" - requested by users. 
    // This also is a workaround for playback state management bug whilst in background
    if (!kIsWeb) {

      !appPlaybackNotificationDisplayed ? Future(createNotification) : null;

      appPlaybackNotificationDisplayed = true;

    }
  }

//  stop playback
  void playbackStop() {
    setState(() {
      instancePlayback?.release();
    });
    instancePlayback?.release();
  }


//void for channel button
  void _left() {
    setState(() {
      previewGraphList = curveStateListLeft;
      graphPreviewColor = Colors.lightGreen.shade800;
      graphPreviewColor2 = Colors.lightGreenAccent.shade400;
      channel = 'L';
      _flagL = true;
      _flagC = false;
      _flagR = false;
      areChannelsSeparated = true;
    });
  }

//void for channel button
  void _center() {
    setState(() {
      previewGraphList = curveStateList;
      graphPreviewColor = Colors.grey.shade800;
      graphPreviewColor2 = Colors.black;
      channel = 'C';
      _flagL = false;
      _flagC = true;
      _flagR = false;
      areChannelsSeparated = false;
    });
  }

//void for channel button
  void _right() {
    setState(() {
      previewGraphList = curveStateListRight;
      graphPreviewColor = Colors.deepOrange.shade900;
      graphPreviewColor2 = Colors.deepOrangeAccent.shade200;
      channel = 'R';
      _flagL = false;
      _flagC = false;
      _flagR = true;
      areChannelsSeparated = true;
    });
  }


  void muteToggle() async {
    if (isMuteSelected[0] == true) {
      isMuteSelected[0] = false;
      isMuteSelected[1] = true;
      playback();
      appPlaybackNotificationDisplayed = false;
    } else {
      isMuteSelected[0] = true;
      isMuteSelected[1] = false;
      playbackStop();
      appPlaybackNotificationDisplayed = true;
    }
  }

//this checks what channel you are on to set the correct channel volume starting point whilst using controllers
  void _stateEQChannelSet() async {
    _flagC
        ?
    frequencyVolumeSet = curveStateList[frequencySliderValue.round()].toDouble()
        : _flagL
        ? frequencyVolumeSet =
        curveStateListLeft[frequencySliderValue.round()].toDouble()
        : frequencyVolumeSet =
        curveStateListRight[frequencySliderValue.round()].toDouble();
  }

//"next" frequency button
  void _next() async {
    instancePlayback?.release();

    setState(() {
      if (frequencySliderValue.round() < 35) {
        frequencySliderValue++;
      }
      setFrequency.fillRange(0, 36, false);
      setFrequency[frequencySliderValue.round()] = true;
    });

    if (isMuteSelected[1] == true) {
      instancePlayback = await audioCache.loop("30/" +
          frequencySliderValue.round().toString() +
          channel +
          (((previewGraphList[frequencySliderValue.round()] + 10) / 2) + 1)
              .round()
              .toString() +
          '.wav');
      await instancePlayback.setVolume(1.0);
    } else {
      null;
    }
  }

//"prev" frequency button
  void _prev() async {
    instancePlayback?.release();

    setState(() {
      if (frequencySliderValue.round() > 0) {
        frequencySliderValue--;
      }
      setFrequency.fillRange(0, 36, false);
      setFrequency[frequencySliderValue.round()] = true;
    });

    if (isMuteSelected[1] == true) {
      instancePlayback = await audioCache.loop("30/" +
          frequencySliderValue.round().toString() +
          channel +
          (((previewGraphList[frequencySliderValue.round()] + 10) / 2) + 1)
              .round()
              .toString() +
          '.wav');
      await instancePlayback.setVolume(1.0);
    } else {
      null;
    }
  }

  void noiseMuteButton(int index2) {
    setState(() {
      for (int buttonIndex2 = 0;
      buttonIndex2 < isNoiseSelected.length;
      buttonIndex2++) {
        if (buttonIndex2 == index2) {
          isNoiseSelected[buttonIndex2] = true;
        } else {
          isNoiseSelected[buttonIndex2] = false;
        }
      }
      if (isNoiseSelected[0] == false) {
        playerNoise.fixedPlayer?.stop();
        playerNoise.loop("30/noise.wav", volume: noiseVolume);
      } else {
        playerNoise.fixedPlayer?.stop();
      }
    });
  }


//preGain is a value to set in Equalizer to prevent headphones from over-driving (clipping)
  // it is safe to assume that for most uses it should equal the negative value of the highest setting
  //for example when user had set the highest point on "+8db" it will be "-8db"
  int _preGain() {
    final maxStereoVolume = (curveStateList.reduce((curr, next) =>
    curr > next
        ? curr
        : next));

    final maxLeftVolume = (curveStateListLeft.reduce((curr, next) =>
    curr > next
        ? curr
        : next));
    final maxRightVolume = (curveStateListRight.reduce((curr, next) =>
    curr > next
        ? curr
        : next));

    final maxSeparateChannelVolume = [maxLeftVolume, maxRightVolume].reduce((
        curr, next) => curr > next ? curr : next);

    final preGainValue = areChannelsSeparated ?
    -maxSeparateChannelVolume : -maxStereoVolume;

    return preGainValue.toInt();
  }


//pop-up window with results for parametric EQ (the table of EQ values)
  void parametricEQResults() {
    final lengthList36 = List.generate(36, (a) => a++);
//previewed list dynamically switches between stereo and separated channel results
    final changesListStereo = List<dynamic>.generate(
        0, (index) => 0, growable: true);
    final changesListSeparatedChannels = List<dynamic>.generate(
        0, (index) => 0, growable: true);

    final tableScrollController = ScrollController();

    for (var a in lengthList36) {
      if (curveStateList[a] != 0) {
        changesListStereo.add((frequencyList[a]).toString() + " Hz");
        changesListStereo.add(curveStateList[a].toString() + " dB");
      }
    }

    for (var a in lengthList36) {
      if (curveStateListLeft[a] != 0) {
        changesListSeparatedChannels.add("Lewy kanał");
        changesListSeparatedChannels.add((frequencyList[a]).toString() + " Hz");
        changesListSeparatedChannels.add(
            curveStateListLeft[a].toString() + " dB");
      }
    }
    for (var a in lengthList36) {
      if (curveStateListRight[a] != 0) {
        changesListSeparatedChannels.add("Prawy kanał");
        changesListSeparatedChannels.add((frequencyList[a]).toString() + " Hz");
        changesListSeparatedChannels.add(
            curveStateListRight[a].toString() + " dB");
      }
    }


    //generate list of elements that user had set to non-zero, adding their number from left and right channel,
    // multiplying by 3 - as in 3 columns, then filling the list with changesListSeparateChannels data
    final changedListSeparatedChannels = List.generate(

        ((curveStateListLeft
            .map((element) =>
        element != 0 ? 1 : 0)
            .reduce((value, element) =>
        value + element) *
            3) +
            (curveStateListRight
                .map((element) =>
            element != 0 ? 1 : 0)
                .reduce((value, element) =>
            value + element) *
                3)
        ), (index) {
      return Center(
        child: Text(
          changesListSeparatedChannels[index],
          style:
          Theme
              .of(context)
              .textTheme
              .bodyText1,
        ),
      );
    });

    final separatedChannelsBoxHeight = (10 *
        (curveStateList
            .map((element) => element != 0 ? 1 : 0)
            .reduce(
                (value, element) => value + element) *
            3)).toDouble();


    //generate list of non-zero elements that user had set - counting the changed elements and
    // multiplying by 2- as in 2 columns, then filling the list with changesListStereo data
    final changedListStereo = List.generate(
        (curveStateList
            .map((element) =>
        element != 0 ? 1 : 0)
            .reduce((value, element) =>
        value + element) *
            2), (index) {
      return Center(
        child: Text(
          changesListStereo[index],
          style:
          Theme
              .of(context)
              .textTheme
              .bodyText1,
        ),
      );
    });

    final stereoBoxHeight = 10 * (
        (curveStateListLeft
            .map((element) => element != 0 ? 1 : 0)
            .reduce(
                (value, element) => value + element) *
            3) +
            (curveStateListRight
                .map((element) => element != 0 ? 1 : 0)
                .reduce(
                    (value, element) => value + element) *
                3)).toDouble();

    showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(
              insetPadding: const EdgeInsets.all(10),
              contentPadding: const EdgeInsets.all(16.0),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              title: const Text('Tabela wyników dla parametrycznych EQ'),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                        "Ręcznie skopiuj poniższe wyniki do Poweramp lub innego parametrycznego EQ:"),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                          "Ustaw wartość pre-amp: " + _preGain().toString() +
                              "dB",
                          style: const TextStyle(

                              fontSize: 16,
                              fontWeight: FontWeight.bold)
                      ),
                    ),
                    ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxHeight: 200,
                            minHeight: 100,
                            maxWidth: 300,
                            minWidth: 300),
                        child: SizedBox(
                          height: areChannelsSeparated
                              ? separatedChannelsBoxHeight
                              : stereoBoxHeight,
                          child: Scrollbar(
                              controller: tableScrollController,
                              isAlwaysShown: true,
                              interactive: true,
                              thickness: 6,
                              child: GridView.count(
                                  controller: tableScrollController,
                                  crossAxisCount: areChannelsSeparated ? 3 : 2,
                                  childAspectRatio: 4,
                                  physics: const ScrollPhysics(),
                                  children: areChannelsSeparated
                                      ? changedListSeparatedChannels
                                      : changedListStereo
                              )),
                        )),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Wstecz'),
                    ),
                  ]),
            ));
  }

  Future<void> _writePreset(String waveletFile) async {
//Generates .txt files for presets - Wavelet format for Android and
    // Equalizer APO for Web (windows), then shows up pop-up window

    var filenameWavelet = 'WaveletPreset';
    final myController = TextEditingController(text: 'MojPreset');
    filenameWavelet = myController.text;
    final waveletFileGenerator = List<dynamic>.generate(128, (e) => e++);
//ignore Android storage permissions for web version
    bool storagePermission = !kIsWeb ? await Permission.manageExternalStorage
        .isGranted : true;


//generate file for Wavelet - on Android
    //it is a function that graphically puts a volume value of each frequency from the generator to the frequency list of Wavelet (on Android)
    //then it makes a series of windows to save the preset
    //crossover list tells us Where wavelet frequency list (127 values) crosses Generator list (36 values)
    //it is crucial as primitive code generates frequency list of values for Wavelet (127) proportionally to the generator list set (36)
    //Imagine it as drawing lines from each point of the generator values, then knowing that Wavelet graph looks the same, but just has
    //more points on each line you can easily calculate any point on the curve
    //last value has a little bug but at the last frequency, but after consideration I left it, as
    // the very high frequencies (18k+) tend to drop drastically in volume either way and 100% of users had some sort of a boost in this region.
    // Moreover user is instructed not to create sharp nor drastic changes in this region and in testing it had no audible impact on result

    //TODO It is the worst made part of the app. It would be awesome to have the function output the preset in a smoothed curve.
    //TODO In this version you can clearly see the edges of generator's 36-point curve in the Wavelet higher resolution 127-point curve.

    if (!kIsWeb) {
      final waveletValCalc = List<dynamic>.generate(127, (i) => i++);

      for (int i in waveletValCalc) {
        int a = crossover[i];

        if (a == 0) {
          waveletValCalc[(i).toInt()] =
          (curveStateListCompensated[a].toStringAsFixed(1));
        } else if (a == 35) {
          waveletValCalc[(i).toInt()] =
          (curveStateListCompensated[a].toStringAsFixed(1));
        } else if (a >= 1) {
          if (curveStateListCompensated[a - 1] <=
              curveStateListCompensated[a]) {
            waveletValCalc[(i).toInt()] = (((curveStateListCompensated[a - 1]) -
                (((waveletList[(i).toInt()] - frequencyList[a - 1]) /
                    (frequencyList[a] - frequencyList[a - 1])) *
                    -((curveStateListCompensated[a]) -
                        (curveStateListCompensated[a - 1]))))
                .toDouble())
                .toStringAsFixed(1);
          } else {
            waveletValCalc[(i).toInt()] = (((curveStateListCompensated[a - 1]) +
                (((waveletList[(i).toInt()] - frequencyList[a - 1]) /
                    (frequencyList[a] - frequencyList[a - 1])) *
                    -((curveStateListCompensated[a - 1]) -
                        (curveStateListCompensated[a]))))
                .toDouble())
                .toStringAsFixed(1);
          }
        }
      }


      for (int e in waveletFileGenerator) {
        if (e == 0) {
          waveletFileGenerator[e] = "GraphicEQ:";
        } else if (e == 127) {
          waveletFileGenerator[e] = waveletList[e - 1].toString() +
              " " +
              waveletValCalc[e - 1].toString();
        } else {
          waveletFileGenerator[e] = waveletList[e - 1].toString() +
              " " +
              waveletValCalc[e - 1].toString() +
              ";";
        }
      }
    }
    //TODO Not used in android APP, but maybe it would be nice to have the ability to generate the PC (Equalizer APO) curve from Android?
    // files only for Equalizer APO (WEB)




    if (storagePermission == false) {
      Permission.manageExternalStorage.request();
    } else {
      showDialog(
          context: context,
          builder: (_) =>
              AlertDialog(
                title: const Text('Zapisywanie presetu',
                    style: TextStyle(fontSize: 16)),
                content:
                Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  const Text("Nazwij plik (bez polskich znaków): "),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'MojPreset',
                      ),
                      controller: myController,
                      showCursor: true,
                    ),
                  ),
                  Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        GestureDetector(
                            onTap: () {
                              if (!kIsWeb) {
                                final io.File file = io.File(
                                    '/storage/emulated/0/Download/$filenameWavelet.txt');
                                file.writeAsString(waveletFileGenerator
                                    .toString()
                                    .replaceAll(',', '')
                                    .replaceAll('[', '')
                                    .replaceAll("]", ""));
                                showDialog(
                                    context: context,
                                    builder: (_) =>
                                        AlertDialog(
                                            title: const Text(
                                                'Próba zapisu pliku'),
                                            content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                                children: <Widget>[
                                                  const Text(
                                                      "Próba zapisu do folderu \"Pobrane\": "),
                                                  const SizedBox(height: 8),
                                                  const Text(
                                                      "Jeśli nie możesz odnaleźć pliku, skopiuj całość pola poniżej do notatnika i zapisz jako plik .txt"),
                                                  TextField(
                                                    decoration: const InputDecoration(
                                                      border: OutlineInputBorder(),
                                                    ),
                                                    controller: TextEditingController(
                                                        text: waveletFileGenerator
                                                            .toString()
                                                            .replaceAll(',', '')
                                                            .replaceAll('[', '')
                                                            .replaceAll(
                                                            "]", "")),
                                                    showCursor: true,
                                                  ),
                                                ])));
                                myController.clear();
                              }
                              //TODO below method is for web version
                              else if (kIsWeb) {
                                //                              js.context.callMethod('webSaveAs', <dynamic>[
                                //                                html.Blob(<List<int>>[presetAPO]),
                                //                                '$filenameWavelet.txt'
                                //                               ]);
                                myController.clear();
                              }
                            },
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 40,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: greyTone1,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: buttonShadow,
                                ),
                                child: Center(
                                    child: Text(
                                      'Zapisz',
                                      style: TextStyle(
                                        fontSize: 18,
                                        shadows: const <Shadow>[
                                          Shadow(
                                            offset: Offset(-0.5, 0.5),
                                            blurRadius: 3.0,
                                            color: Colors.white,
                                          ),
                                          Shadow(
                                            offset: Offset(0.5, -0.5),
                                            blurRadius: 3.0,
                                            color: Colors.white,
                                          ),
                                        ],
                                        color: Colors.grey.shade800,
                                      ),
                                    )))),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Wstecz'),
                        ),
                      ]),
                ]),
              ));
    }
  }

  //EQ memory list logic
  void _stanEQ() {
    instancePlayback?.release();

    if (_flagC == true) {
      curveStateList.setAll(
          frequencySliderValue.round(), [frequencyVolumeSet.round()]);
      frequencyVolumeSet =
          curveStateList[frequencySliderValue.round()].toDouble();
    } else if (_flagL == true) {
      curveStateListLeft
          .setAll(frequencySliderValue.round(), [frequencyVolumeSet.round()]);
      frequencyVolumeSet =
          curveStateListLeft[frequencySliderValue.round()].toDouble();
    } else if (_flagR == true) {
      curveStateListRight
          .setAll(frequencySliderValue.round(), [frequencyVolumeSet.round()]);
      frequencyVolumeSet =
          curveStateListRight[frequencySliderValue.round()].toDouble();
    }

    graphDrawingListStereo = curveStateList;
    graphDrawingListSeparateChannels = curveStateListLeft + curveStateListRight;

    //lowering the whole curve down as far as the loudest signal volume, so it will "zero-out"
    // to prevent clipping whilst - for presets
    final _maxVolumeValue = curveStateList.reduce((curr, next) =>
    curr > next
        ? curr
        : next);
    for (int i in list36) {
      curveStateListCompensated[i] = curveStateList[i] - _maxVolumeValue;
    }

    if (frequencyVolumeSet >= 8) {
      !volumeWarningSnackBarDisplayed ?
      ScaffoldMessenger.of(context).showSnackBar(volumeWarningSnackBar) : null;
      volumeWarningSnackBarDisplayed = true;
    }
    if (frequencySliderValue >= 32 || frequencySliderValue == 0) {
      !frequencyWarningSnackBarDisplayed
          ?
      ScaffoldMessenger.of(context).showSnackBar(frequencyWarningSnackBar)
          : null;
      frequencyWarningSnackBarDisplayed = true;
    }
  }


  void welcomeMessage() {
    showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(
                title: const Text('Stwórz Twoją krzywą korektora słuchawek'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: startMessage),
                actions: [
                  Center(
                      child: OutlinedButton(
                        onPressed: () {
                          !kIsWeb
                              ?
                          AwesomeNotifications()
                              .requestPermissionToSendNotifications()
                              .then((isAllowed) => Navigator.pop(context))
                              : Navigator.pop(context);
                        },
                        child: const Text('OK'),
                      ))
                ]));
  }


  void _resultsWindow() async {
    final _graphScrollController = ScrollController();

    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text('Wyniki'),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Column(children: <Widget>[
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          GestureDetector(
                              onTap: () {
                                _writePreset("a");
                              },
                              child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: greyTone1,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: buttonShadow,
                                  ),
                                  child: Center(
                                      child: Text(
                                        "Wygeneruj preset dla Wavelet",
                                        style: TextStyle(
                                          fontSize: 14,
                                          shadows: const <Shadow>[
                                            Shadow(
                                              offset: Offset(-0.5, 0.5),
                                              blurRadius: 3.0,
                                              color: Colors.white,
                                            ),
                                            Shadow(
                                              offset: Offset(0.5, -0.5),
                                              blurRadius: 3.0,
                                              color: Colors.white,
                                            ),
                                          ],
                                          color: Colors.grey.shade800,
                                        ),
                                      )))),
                          Container(height: 12),
                          GestureDetector(
                              onTap: () =>
                                  showDialog(
                                      context: context,
                                      builder: (_) =>
                                          AlertDialog(
                                            title: Text('Ustaw pre-gain na ' +
                                                _preGain().toString() + "dB"),
                                            shape: const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(20))),
                                            scrollable: true,
                                            content: Scrollbar(
                                              controller: _graphScrollController,
                                              isAlwaysShown: true,
                                              interactive: true,
                                              thickness: 6,
                                              child: SingleChildScrollView(
                                                controller: _graphScrollController,
                                                scrollDirection: Axis
                                                    .horizontal,
                                                child: Column(
                                                    children: <Widget>[
                                                      CustomPaint(
                                                        foregroundPainter: areChannelsSeparated
                                                            ?
                                                        LinePainterSeparateChannels(
                                                            graphDrawingListSeparateChannels)
                                                            :
                                                        LinePainter(
                                                            graphDrawingListStereo),
                                                        child: const SizedBox(
                                                            height: 260,
                                                            width: 900),
                                                      ),
                                                      Container(height: 40),
                                                    ]),
                                              ),
                                            ),
                                            actionsAlignment: MainAxisAlignment
                                                .center,
                                            actions: [
                                              OutlinedButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Wstecz'),
                                              ),
                                            ],
                                          )),
                              child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: greyTone1,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: buttonShadow,
                                  ),
                                  child: Center(
                                      child: Text(
                                        "Pokaż wykres krzywej",
                                        style: TextStyle(
                                          fontSize: 14,
                                          shadows: const <Shadow>[
                                            Shadow(
                                              offset: Offset(-0.5, 0.5),
                                              blurRadius: 3.0,
                                              color: Colors.white,
                                            ),
                                            Shadow(
                                              offset: Offset(0.5, -0.5),
                                              blurRadius: 3.0,
                                              color: Colors.white,
                                            ),
                                          ],
                                          color: Colors.grey.shade800,
                                        ),
                                      )))),
                          Container(height: 12),
                          GestureDetector(
                              onTap: () {
                                parametricEQResults();
                              },
                              child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: greyTone1,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: buttonShadow,
                                  ),
                                  child: Center(
                                      child: Text(
                                        "Pokaż tabelę wyników dla parametrycznych EQ",
                                        style: TextStyle(
                                          fontSize: 14,
                                          shadows: const <Shadow>[
                                            Shadow(
                                              offset: Offset(-0.5, 0.5),
                                              blurRadius: 3.0,
                                              color: Colors.white,
                                            ),
                                            Shadow(
                                              offset: Offset(0.5, -0.5),
                                              blurRadius: 3.0,
                                              color: Colors.white,
                                            ),
                                          ],
                                          color: Colors.grey.shade800,
                                        ),
                                      )))),
                        ])),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Wstecz'),
                ),
              ])
            ],
          ),
    );
  }

  @override
  initState() {
    super.initState();
    //start muted and in stereo
    isMuteSelected = [true, false];
    _center();
    //start at 910 Hz and move forward to 1000 Hz (hack to initialize selected vertical line bold)
    frequencySliderValue = 12;
    _next();
    listPageNumberBool[0] == true;
    _tabController = TabController(length: listPage.length, vsync: this);
    Future(welcomeMessage);

//initialize notification
    AwesomeNotifications().actionStream.listen((notificationEvent) {
      if(notificationEvent.buttonKeyPressed == 'mute'){
        muteToggle();
        AwesomeNotifications().cancelAll();
      }
      if(notificationEvent.buttonKeyPressed == 'exit'){
        muteToggle();
        AwesomeNotifications().cancelAll();
        SystemNavigator.pop();
      }
    });


  }

  @override
  Widget build(BuildContext context) {
    //main frequency slider
    var sliderValueRounded = frequencySliderValue.round();
    var frequencyRange = frequencyList[sliderValueRounded.round()];


    //logic for channels switch (C/L/R)
    if (_flagC == true) {
      setVolumeSlider =
          curveStateList[frequencySliderValue.round()].toDouble();
    } else if (_flagL == true) {
      setVolumeSlider =
          curveStateListLeft[frequencySliderValue.round()].toDouble();
    } else if (_flagR == true) {
      setVolumeSlider =
          curveStateListRight[frequencySliderValue.round()].toDouble();
    }

    //main page scaffold widgets

    return Scaffold(
        backgroundColor: greyTone2,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),

          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Column(children: <Widget>[
                  spacerBox(context, 2),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Expanded(
                            flex: 4,
                            child: GestureDetector(
                              onTap: () =>
                                  showDialog(
                                      context: context,
                                      builder: (context) =>
                                          StatefulBuilder(
                                              builder: (context, setState) {
                                                return Dialog(
                                                    backgroundColor:
                                                    const Color.fromRGBO(
                                                        64, 64, 64, 1.0),
                                                    insetPadding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10.0,
                                                        vertical: 10.0),
                                                    shape: const RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                20))),
                                                    child: Padding(
                                                        padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 15.0,
                                                            vertical: 10.0),
                                                        child: Column(
                                                            mainAxisSize:
                                                            MainAxisSize.max,
                                                            mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceAround,
                                                            children: <
                                                                Widget>[
                                                              Expanded(
                                                                  flex: 16,
                                                                  child: PageView(
                                                                      controller:
                                                                      instructionsController,
                                                                      onPageChanged:
                                                                          (
                                                                          index) {
                                                                        setState(() {
                                                                          _tabController
                                                                              .index =
                                                                              index;
                                                                        });
                                                                      },
                                                                      children: <
                                                                          Widget>[
                                                                        for (int i
                                                                        in listPage)
                                                                          Center(
                                                                              child: SingleChildScrollView(
                                                                                  padding: const EdgeInsets
                                                                                      .all(
                                                                                      4.0),
                                                                                  child: Column(
                                                                                      children: <
                                                                                          Widget>[
                                                                                        Image
                                                                                            .asset(
                                                                                            instructionsImgList[i]),
                                                                                        const SizedBox(
                                                                                            height: 20),
                                                                                        Text(
                                                                                            instructionsTextList[i],
                                                                                            style: instructionStyle),
                                                                                      ]))),
                                                                      ])),
                                                              Expanded(
                                                                  flex: 1,
                                                                  child: Center(
                                                                      child: TabPageSelector(
                                                                          indicatorSize:
                                                                          10,
                                                                          controller:
                                                                          _tabController))),
                                                              Expanded(
                                                                  flex: 1,
                                                                  child:
                                                                  OutlinedButton(
                                                                    onPressed: () {
                                                                      setState(() {
                                                                        _tabController
                                                                            .index =
                                                                        0;
                                                                      });

                                                                      Navigator
                                                                          .pop(
                                                                          context);
                                                                    },
                                                                    child: const Text(
                                                                        '✓ Zaczynajmy! '),
                                                                  )),
                                                            ])));
                                              })),
                              child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: greyTone1,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: buttonShadow,
                                  ),
                                  child: Center(
                                      child: Text(
                                        'Instrukcje',
                                        style: TextStyle(
                                          fontSize: 18,
                                          shadows: const <Shadow>[
                                            Shadow(
                                              offset: Offset(-0.5, 0.5),
                                              blurRadius: 3.0,
                                              color: Colors.white,
                                            ),
                                            Shadow(
                                              offset: Offset(0.5, -0.5),
                                              blurRadius: 3.0,
                                              color: Colors.white,
                                            ),
                                          ],
                                          color: Colors.grey.shade800,
                                        ),
                                      ))),
                            )),
                        Expanded(flex: 1, child: Container()),
                        Expanded(
                            flex: 4,
                            child: GestureDetector(
                              onTap: () => _resultsWindow(),
                              child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: greyTone1,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: buttonShadow,
                                  ),
                                  child: Center(
                                      child: Text(
                                        'Wyniki',
                                        style: TextStyle(
                                          fontSize: 18,
                                          shadows: const <Shadow>[
                                            Shadow(
                                              offset: Offset(-0.5, 0.5),
                                              blurRadius: 3.0,
                                              color: Colors.white,
                                            ),
                                            Shadow(
                                              offset: Offset(0.5, -0.5),
                                              blurRadius: 3.0,
                                              color: Colors.white,
                                            ),
                                          ],
                                          color: Colors.grey.shade800,
                                        ),
                                      ))),
                            ))
                      ]),
                  spacerBox(context, 10),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                            flex: 6,
                            child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: greyTone1,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: buttonShadow,
                                ),
                                child: Center(

                                    child: ToggleButtons(
                                      borderWidth: 0,
                                      splashColor: Colors.white54,
                                      borderRadius: BorderRadius.circular(10),
                                      renderBorder: false,
                                      children: const <Widget>[
                                        Icon(Icons.volume_off_outlined),
                                        Icon(Icons.volume_up_outlined)
                                      ],
                                      onPressed: (_) {
                                        setState(() {
                                          muteToggle();
                                          AwesomeNotifications().cancelAll();
                                        });
                                      },
                                      color: Colors.grey.shade400,
                                      selectedColor: Colors.black,
                                      isSelected: isMuteSelected,
                                    )
                                ))),
                        Expanded(
                          flex: 1,
                          child: Container(),
                        ),
                        Expanded(
                            flex: 9,
                            child: GestureDetector(
                                onTap: _center,
                                child: AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 200),
                                    height: buttonHeight,
                                    decoration: BoxDecoration(
                                      color: _flagC
                                          ? Colors.white
                                          : greyTone1,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: !_flagC
                                          ? buttonShadow
                                          : buttonShadowReversed,
                                    ),
                                    child: Center(
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              _flagC ? 5 : 0, _flagC ? 5 : 0, 0,
                                              0),
                                          child: Text(
                                            "Stereo",
                                            style: TextStyle(
                                                fontSize: 18,
                                                shadows: _flagC
                                                    ? channelButtonTextShadow
                                                    : null,
                                                color: _flagC
                                                    ? Colors.black
                                                    : greyTone3),
                                          ),)
                                    )))),
                        Expanded(
                          flex: 1,
                          child: Container(),
                        ),
                        Expanded(
                            flex: 2,
                            child: GestureDetector(
                                onTap: _left,
                                child: AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 200),
                                    height: buttonHeight,
                                    decoration: BoxDecoration(
                                      color: _flagL
                                          ? leftButtonTone
                                          : greyTone1,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: !_flagL
                                          ? buttonShadow
                                          : buttonShadowReversed +
                                          [const BoxShadow(
                                              color: Colors.lightGreenAccent,
                                              offset: Offset(3, 3),
                                              blurRadius: 10,
                                              spreadRadius: 2)
                                          ],
                                    ),
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                            _flagL ? 5 : 0, _flagL ? 5 : 0, 0,
                                            0),
                                        child: Text("L",
                                          style: TextStyle(
                                              fontSize: 18,
                                              shadows: _flagL
                                                  ? channelButtonTextShadow
                                                  : null,
                                              color: _flagL
                                                  ? Colors.lightGreen
                                                  : greyTone3),
                                        ),),
                                    )))),
                        Expanded(
                          flex: 1,
                          child: Container(),
                        ),
                        Expanded(
                            flex: 2,
                            child: GestureDetector(
                                onTap: _right,
                                child: AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 200),
                                    height: buttonHeight,
                                    decoration: BoxDecoration(
                                      color: _flagR
                                          ? rightButtonTone
                                          : greyTone1,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: !_flagR
                                          ? buttonShadow
                                          : buttonShadowReversed +
                                          [const BoxShadow(
                                              color: Colors.deepOrangeAccent,
                                              offset: Offset(3, 3),
                                              blurRadius: 12,
                                              spreadRadius: 2)
                                          ],
                                    ),
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                            _flagR ? 5 : 0, _flagR ? 5 : 0, 0,
                                            0),
                                        child: Text("P",
                                          style: TextStyle(
                                              fontSize: 18,
                                              shadows: _flagR
                                                  ? channelButtonTextShadow
                                                  : null,
                                              color: _flagR
                                                  ? Colors.deepOrangeAccent
                                                  : greyTone3),
                                        ),),
                                    )))),
                      ]),

                ]),
                spacerBox(context, 8),
                Column(children: <Widget>[
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: graphHeight,
                      maxHeight: graphHeight,
                    ),
                    child: Stack(
                      children: <Widget>[
                        Center(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                for (int t in lineListHorizontal)
                                  Expanded(
                                      child: VerticalDivider(
                                        width: iconSize,
                                        thickness: setFrequency[t]
                                            ? lineThickness2
                                            : lineThickness,
                                        color: setFrequency[t]
                                            ? graphPreviewColor2
                                            : graphPreviewColor,
                                      ))
                              ]),
                        ),
                        Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  for (int t in lineListVertical)
                                    Divider(
                                      height: (graphHeight / 11),
                                      thickness: lineThickness,
                                      color: setVolume[10 - t]
                                          ? graphPreviewColor2
                                          : graphPreviewColor,
                                    ),
                                ])),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              for (int v in lineListHorizontal)
                                Expanded(
                                    child: AnimatedAlign(
                                      curve: Curves.fastOutSlowIn,
                                      duration: const Duration(
                                          milliseconds: 180),
                                      alignment: FractionalOffset(
                                          0.5,
                                          -(previewGraphList[v] - 10) / 20),
                                      child: Icon(
                                        !setFrequency[v]
                                            ? Icons.album_sharp
                                            : Icons.add_box_sharp,
                                        color: setFrequency[v]
                                            ? graphPreviewColor2
                                            : graphPreviewColor,
                                        size: setFrequency[v]
                                            ? iconSize2
                                            : iconSize,
                                      ),
                                    )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    alignment: Alignment(
                        ((frequencySliderValue + 1) / 17.3) - 1.07, 0.0),
                    child: const Icon(Icons.keyboard_arrow_up, size: 25),
                  ),
                  Container(
                    alignment:
                    Alignment(((frequencySliderValue + 1) / 18) - 1, 0.0),
                    child: Text(
                      frequencyRange.round().toString() + " Hz",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: const <Shadow>[
                          Shadow(
                            offset: Offset(1.5, 1.5),
                            blurRadius: 2.5,
                            color: Color.fromARGB(100, 0, 0, 0),
                          ),
                          Shadow(
                            offset: Offset(-1.5, -1.5),
                            blurRadius: 2.5,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ],
                        color: redFrequencies.any((item) =>
                        item == frequencySliderValue) ? const Color.fromARGB(
                            200, 255, 0, 0) : const Color.fromARGB(
                            200, 0, 0, 0),
                      ),
                    ),
                  ),
                ]),
                Column(children: <Widget>[
                  spacerBox(context, 10),
                  Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
                    Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTapDown: (_) {
                            super.setState(() {
                              tapAnimPrevious = false;
                            });
                          },
                          onTapCancel: () =>
                              super.setState(() {
                                tapAnimPrevious = true;
                              }),
                          onTapUp: (_) {
                            _prev();
                            tapAnimPrevious = true;
                          },
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: buttonHeight * 1.5,
                              decoration: BoxDecoration(
                                color: tapAnimPrevious
                                    ? greyTone1
                                    : greyTone2,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: tapAnimPrevious
                                    ? buttonShadow
                                    : [],
                              ),
                              child: const Center(
                                  child:
                                  Icon(Icons.arrow_back_ios_outlined))),
                        )),
                    Expanded(
                      flex: 9,
                      child: Slider(
                        value: frequencySliderValue,
                        max: 35,
                        min: 0,
                        divisions: 35,
                        onChanged: (double value) {
                          super.setState(() {
                            frequencySliderValue = value;
                            frequencyVolumeSet =
                                curveStateList[frequencySliderValue.round()] *
                                    1.0;
                            setFrequency.fillRange(0, 36, false);
                            setFrequency[frequencySliderValue.round()] = true;
                          });
                        },
                        onChangeEnd: (double z) {
                          if (isMuteSelected[0] == false) {
                            playback();
                          }
                        },
                      ),
                    ),
                    Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTapDown: (_) {
                            super.setState(() {
                              tapAnimForward = false;
                            });
                          },
                          onTapCancel: () =>
                              super.setState(() {
                                tapAnimForward = true;
                              }),
                          onTapUp: (_) {
                            _next();
                            tapAnimForward = true;
                          },
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 80),
                              height: buttonHeight * 1.5,
                              decoration: BoxDecoration(
                                color: tapAnimForward
                                    ? greyTone1
                                    : greyTone2,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: tapAnimForward
                                    ? buttonShadow
                                    : [],
                              ),
                              child: const Center(
                                  child: Icon(
                                      Icons.arrow_forward_ios_outlined))),
                        )),
                  ]),
                  spacerBox(context, 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTapDown: (_) {
                              super.setState(() {
                                tapAnimationMinus = false;
                              });
                            },
                            onTapCancel: () =>
                                super.setState(() {
                                  tapAnimationMinus = true;
                                }),
                            onTapUp: (_) {
                              super.setState(() {
                                _stateEQChannelSet();

                                if (frequencyVolumeSet >= -8) {
                                  frequencyVolumeSet = frequencyVolumeSet - 2;
                                }

                                _stanEQ();

                                if (isMuteSelected[0] == false) {
                                  playback();
                                }
                                tapAnimationMinus = true;
                              });
                            },
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 80),
                                height: buttonHeight * 1.5,
                                decoration: BoxDecoration(
                                  color: tapAnimationMinus
                                      ? greyTone1
                                      : greyTone2,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: tapAnimationMinus
                                      ? buttonShadow
                                      : [],
                                ),
                                child:
                                const Center(child: Icon(Icons.remove))),
                          )),
                      SizedBox(
                          height: (MediaQuery
                              .of(context)
                              .size
                              .height - 600).abs() / 6
                      ),

                      Expanded(
                        flex: 9,
                        child: Column(children: <Widget>[
                          Text(
                            'Korekcja:' +
                                setVolumeSlider.round().toString() +
                                ' dB',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: <Shadow>[
                                Shadow(
                                  offset: Offset(1.5, 1.5),
                                  blurRadius: 2.5,
                                  color: Color.fromARGB(100, 0, 0, 0),
                                ),
                                Shadow(
                                  offset: Offset(-1.5, -1.5),
                                  blurRadius: 2.5,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                              ],
                              color: Color.fromARGB(200, 0, 0, 0),
                            ),
                          ),
                          Slider(
                            value: setVolumeSlider,
                            min: -10,
                            max: 10,
                            divisions: 10,
                            onChanged: (double volValue) {
                              super.setState(
                                    () {
                                  frequencyVolumeSet = volValue;
                                  _stanEQ();
                                },
                              );
                            },
                            onChangeEnd: (double z) {
                              if (isMuteSelected[0] == false) {
                                playback();
                              }
                            },
                          ),
                        ]),
                      ),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTapDown: (_) {
                            super.setState(() {
                              tapAnimationPlus = false;
                            });
                          },
                          onTapCancel: () =>
                              super.setState(() {
                                tapAnimationPlus = true;
                              }),
                          onTapUp: (_) {
                            super.setState(() {
                              _stateEQChannelSet();

                              if (frequencyVolumeSet < 10) {
                                frequencyVolumeSet = frequencyVolumeSet + 2;
                              }
                              _stanEQ();
                              if (isMuteSelected[0] == false) {
                                playback();
                              }
                              tapAnimationPlus = true;
                            });
                          },
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 80),
                              height: buttonHeight * 1.5,
                              decoration: BoxDecoration(
                                color: tapAnimationPlus
                                    ? greyTone1
                                    : greyTone2,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: tapAnimationPlus
                                    ? buttonShadow
                                    : [],
                              ),
                              child: const Center(child: Icon(Icons.add))),
                        ),
                      ),
                    ],
                  ),
                ]),
                SizedBox(
                    height: (MediaQuery
                        .of(context)
                        .size
                        .height - 600).abs() / 6
                ),
                const Divider(
                  height: 10,
                  thickness: 2,
                  color: Colors.blueGrey,
                ),
                SizedBox(
                    height: (MediaQuery
                        .of(context)
                        .size
                        .height - 600).abs() / 6
                ),
                Row(children: <Widget>[
                  const Text(
                    "Szum: ",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                      child: Slider(
                        value: noiseVolume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        onChanged: (double noiseValue) {
                          super.setState(
                                () {
                              noiseVolume = noiseValue;
                              noisePlayer.setVolume(noiseVolume);
                            },
                          );
                        },
                      )),
                  ToggleButtons(
                    borderWidth: 0,
                    splashColor: Colors.white54,
                    borderRadius: BorderRadius.circular(10),
                    renderBorder: false,
                    children: const <Widget>[
                      Icon(Icons.volume_off_outlined),
                      Icon(Icons.volume_up_outlined),
                    ],
                    onPressed: noiseMuteButton,
                    color: Colors.blueGrey,
                    selectedColor: Colors.black,
                    isSelected: isNoiseSelected,
                  ),
                ]),
                SizedBox(
                    height: (MediaQuery
                        .of(context)
                        .size
                        .height - 600).abs() / 6
                ),
                Container(height: 30,

                  color: greyTone2,
                  child: Center(
                    child: Text(footerText),
                  ),

                )
              ]),


        ));
  }
}

//TODO below methods draw the curve as a graph. It would be nice to have the curve smoothed with minimal extra packages included
//TODO Whole graph could look better too

class LinePainter extends CustomPainter {
  var graphDrawingListStereo = _AppState().previewGraphList;

  LinePainter(this.graphDrawingListStereo);

  final drawingList36 = List<int>.generate(36, (i) => i++);
  final colorLines = Colors.blueGrey;

  @override
  void paint(Canvas canvas, Size size) {
    double b = 0.027;


    final pointsJoinedOffsetList = [

      for (int i in drawingList36)
        Offset(
            size.width * (i + 1) * b,
            size.height * -(graphDrawingListStereo[i] - 10) / 20),
    ];


    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;


    canvas.drawPoints(ui.PointMode.polygon, pointsJoinedOffsetList, paint);

    createLinesVertical(int d) {
      final lineList = List<int>.generate(d, (i) => i + 1);

      for (int i in lineList) {
        final paint2 = Paint()
          ..color = colorLines
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        canvas.drawPoints(
            ui.PointMode.polygon,
            [
              Offset(size.width * i * b, size.height - 2),
              Offset(size.width * i * b, 15.0)
            ],
            paint2);
      }
    }


    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 12,
    );


    createTextVertical(int e) {
      final lineListEachFirst = List<int>.generate(e, (i) => 2 * i + 1);

      for (int i in lineListEachFirst) {
        final textSpan = TextSpan(
          text: frequencyListLegend[i].toString(),
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(
          minWidth: 0,
          maxWidth: size.width,
        );
        final offset = Offset(8 + size.width / (37 / i), size.height);
        textPainter.paint(canvas, offset);
      }
    }

    createTextVertical2(int f) {
      final lineListEachSecond = List<int>.generate(f, (i) => 2 * i);

      for (int i in lineListEachSecond) {
        final textSpan = TextSpan(
          text: frequencyListLegend[i].toString(),
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(
          minWidth: 0,
          maxWidth: size.width,
        );
        final offset = Offset(8 + size.width / (37 / i), 0.0);
        textPainter.paint(canvas, offset);
      }
    }

    createTextChange(int g) {
      final lineList = List<int>.generate(g, (i) => i++);
      for (int i in lineList) {
        if (graphDrawingListStereo[i] != 0) {
          final textSpan = TextSpan(
            text: graphDrawingListStereo[i].toString() + "dB",
            style: textStyle,
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout(
            minWidth: 0,
            maxWidth: size.width,
          );
          final offset = Offset(8 + size.width / (37 / i),
              (size.height * ((-graphDrawingListStereo[i] + 12) / 28)));

          textPainter.paint(canvas, offset);
        }
      }
    }

    createLinesVertical(36);
    createTextVertical(18);
    createTextVertical2(18);
    createTextChange(36);
  }

  @override
  bool shouldRepaint(LinePainter oldDelegate) {
    return true;
  }

  @override
  bool shouldRebuildSemantics(LinePainter oldDelegate) => false;
}

class LinePainterSeparateChannels extends CustomPainter {


  var graphDrawingListSeparateChannels = _AppState().curveStateListLeft +
      _AppState().curveStateListRight;


  LinePainterSeparateChannels(this.graphDrawingListSeparateChannels);

  final drawingList36 = List<int>.generate(36, (i) => i++);
  final drawingList72 = List<int>.generate(36, (e) => 36 + e++);
  final colorLines = Colors.blueGrey;
  final colorStereo = Colors.black;
  final colorLeft = Colors.green;
  final colorRight = Colors.red;
  final colorBackground = Colors.white;
  final fontRegular = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    double b = 0.027;


    final pointsLeftOffsetList = [

      for (int i in drawingList36)
        Offset(
            size.width * (i + 1) * b,
            size.height * -(graphDrawingListSeparateChannels[i] - 10) / 20),
    ];
    final pointsRightOffsetList = [

      for (int e in drawingList72)
        Offset(
            size.width * ((e - 36) + 1) * b,
            size.height * -(graphDrawingListSeparateChannels[e] - 10) / 20),
    ];

    final paintLeft = Paint()
      ..color = colorLeft
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final paintRight = Paint()
      ..color = colorRight
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;


    canvas.drawPoints(ui.PointMode.polygon, pointsLeftOffsetList, paintLeft);
    canvas.drawPoints(ui.PointMode.polygon, pointsRightOffsetList, paintRight);

    createLinesVertical(int d) {
      final lineList = List<int>.generate(d, (i) => i + 1);

      for (int i in lineList) {
        final paint2 = Paint()
          ..color = colorLines
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        canvas.drawPoints(
            ui.PointMode.polygon,
            [
              Offset(size.width * i * b, size.height - 2),
              Offset(size.width * i * b, 15.0)
            ],
            paint2);
      }
    }


    final textStyle = TextStyle(
      color: colorStereo,
      fontSize: fontRegular,
    );
    final textStyleLeft = TextStyle(
      color: colorLeft,
      backgroundColor: colorBackground,
      fontSize: fontRegular,
    );

    final textStyleRight = TextStyle(
      color: colorRight,
      backgroundColor: colorBackground,
      fontSize: fontRegular,
    );

    createTextVertical(int e) {
      final lineListEachFirst = List<int>.generate(e, (i) => 2 * i + 1);

      for (int i in lineListEachFirst) {
        final textSpan = TextSpan(
          text: frequencyListLegend[i].toString(),
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(
          minWidth: 0,
          maxWidth: size.width,
        );
        final offset = Offset(8 + size.width / (37 / i), size.height);
        textPainter.paint(canvas, offset);
      }
    }

    createTextVertical2(int f) {
      final lineListEachSecond = List<int>.generate(f, (i) => 2 * i);

      for (int i in lineListEachSecond) {
        final textSpan = TextSpan(
          text: frequencyListLegend[i].toString(),
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(
          minWidth: 0,
          maxWidth: size.width,
        );
        final offset = Offset(8 + size.width / (37 / i), 0.0);
        textPainter.paint(canvas, offset);
      }
    }

    createTextChangeLeft(int g) {
      final lineList = List<int>.generate(g, (i) => i++);
      for (int i in lineList) {
        if (graphDrawingListSeparateChannels[i] != 0) {
          final textSpan = TextSpan(
            text: graphDrawingListSeparateChannels[i].toString() + "dB",
            style: textStyleLeft,
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout(
            minWidth: 0,
            maxWidth: size.width,
          );
          final offset = Offset(8 + size.width / (37 / i),
              (size.height *
                  ((-graphDrawingListSeparateChannels[i] + 12) / 28)));

          textPainter.paint(canvas, offset);
        }
      }
    }
    createTextChangeRight(int g) {
      final lineList = List<int>.generate(g, (i) => 36 + i++);
      for (int i in lineList) {
        if (graphDrawingListSeparateChannels[i] != 0) {
          final textSpan = TextSpan(
            text: graphDrawingListSeparateChannels[i].toString() + "dB",
            style: textStyleRight,
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout(
            minWidth: 0,
            maxWidth: size.width,
          );
          final offset = Offset(8 + size.width / (37 / (i - 36)),
              (size.height *
                  ((-graphDrawingListSeparateChannels[i] + 12) / 28)));

          textPainter.paint(canvas, offset);
        }
      }
    }

    createLinesVertical(36);
    createTextVertical(18);
    createTextVertical2(18);
    createTextChangeLeft(36);
    createTextChangeRight(36);
  }

  @override
  bool shouldRepaint(LinePainter oldDelegate) {
    return true;
  }

  @override
  bool shouldRebuildSemantics(LinePainter oldDelegate) => false;
}