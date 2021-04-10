import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'generateMaterialColor.dart';
import 'setupLogging.dart';
import 'screens/UserSelector.dart';
import 'screens/MusicScreen.dart';
import 'screens/ViewSelector.dart';
import 'screens/AlbumScreen.dart';
import 'screens/PlayerScreen.dart';
import 'screens/SplashScreen.dart';
import 'screens/DownloadsErrorScreen.dart';
import 'screens/DownloadsScreen.dart';
import 'screens/ArtistScreen.dart';
import 'screens/LogsScreen.dart';
import 'screens/SettingsScreen.dart';
import 'screens/TranscodingSettingsScreen.dart';
import 'services/AudioServiceHelper.dart';
import 'services/JellyfinApiData.dart';
import 'services/DownloadsHelper.dart';
import 'models/JellyfinModels.dart';
import 'models/FinampModels.dart';

void main() async {
  // If the app has failed, this is set to true. If true, we don't attempt to run the main app since the error app has started.
  bool hasFailed = false;
  try {
    setupLogging();
    await setupHive();
    _setupJellyfinApiData();
    await _setupDownloader();
    _setupDownloadsHelper();
    _setupAudioServiceHelper();
  } catch (e) {
    hasFailed = true;
    runApp(FinampErrorApp(
      error: e,
    ));
  }

  if (!hasFailed) {
    runApp(Finamp());
  }
}

void _setupJellyfinApiData() {
  GetIt.instance.registerSingleton(JellyfinApiData());
}

void _setupDownloadsHelper() {
  GetIt.instance.registerSingleton(DownloadsHelper());
}

Future<void> _setupDownloader() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
}

// TODO: move this function somewhere else since it's also run in MusicPlayerBackgroundTask.dart
Future<void> setupHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(BaseItemDtoAdapter());
  Hive.registerAdapter(UserItemDataDtoAdapter());
  Hive.registerAdapter(NameIdPairAdapter());
  Hive.registerAdapter(DownloadedSongAdapter());
  Hive.registerAdapter(DownloadedParentAdapter());
  Hive.registerAdapter(MediaSourceInfoAdapter());
  Hive.registerAdapter(MediaStreamAdapter());
  Hive.registerAdapter(AuthenticationResultAdapter());
  Hive.registerAdapter(FinampUserAdapter());
  Hive.registerAdapter(UserDtoAdapter());
  Hive.registerAdapter(SessionInfoAdapter());
  Hive.registerAdapter(UserConfigurationAdapter());
  Hive.registerAdapter(UserPolicyAdapter());
  Hive.registerAdapter(AccessScheduleAdapter());
  Hive.registerAdapter(PlayerStateInfoAdapter());
  Hive.registerAdapter(SessionUserInfoAdapter());
  Hive.registerAdapter(ClientCapabilitiesAdapter());
  Hive.registerAdapter(DeviceProfileAdapter());
  Hive.registerAdapter(DeviceIdentificationAdapter());
  Hive.registerAdapter(HttpHeaderInfoAdapter());
  Hive.registerAdapter(XmlAttributeAdapter());
  Hive.registerAdapter(DirectPlayProfileAdapter());
  Hive.registerAdapter(TranscodingProfileAdapter());
  Hive.registerAdapter(ContainerProfileAdapter());
  Hive.registerAdapter(ProfileConditionAdapter());
  Hive.registerAdapter(CodecProfileAdapter());
  Hive.registerAdapter(ResponseProfileAdapter());
  Hive.registerAdapter(SubtitleProfileAdapter());
  Hive.registerAdapter(FinampSettingsAdapter());
  Hive.registerAdapter(FinampLogRecordAdapter());
  Hive.registerAdapter(FinampLevelAdapter());
  await Future.wait([
    Hive.openBox<DownloadedParent>("DownloadedParents"),
    Hive.openBox<DownloadedSong>("DownloadedItems"),
    Hive.openBox<DownloadedSong>("DownloadIds"),
    Hive.openBox<FinampUser>("FinampUsers"),
    Hive.openBox<String>("CurrentUserId"),
    Hive.openBox<FinampSettings>("FinampSettings"),
  ]);

  // If the settings box is empty, we add an initial settings value here.
  Box<FinampSettings> finampSettingsBox = Hive.box("FinampSettings");
  if (finampSettingsBox.isEmpty)
    finampSettingsBox.put("FinampSettings", FinampSettings());

  // Initial releases of the app used Hive to store logs. This removes the logs box from the disk if it exists.
  // TODO: Remove this (and the hive adapters for FinampLogRecord and FinampLevel) in a few months (added 2021-04-09)
  if (await Hive.boxExists("FinampLogs")) {
    await Hive.openBox("FinampLogs");
    await Hive.box("FinampLogs").deleteFromDisk();
  }
}

void _setupAudioServiceHelper() {
  GetIt.instance.registerSingleton(AudioServiceHelper());
}

class Finamp extends StatelessWidget {
  const Finamp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFF00A4DC);
    const Color raisedDarkColor = Color(0xFF202020);
    const Color backgroundColor = Color(0xFF101010);
    return AudioServiceWidget(
      child: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);

          if (!currentFocus.hasPrimaryFocus &&
              currentFocus.focusedChild != null) {
            FocusManager.instance.primaryFocus.unfocus();
          }
        },
        child: MaterialApp(
          title: "Finamp",
          routes: {
            "/": (context) => SplashScreen(),
            "/login/userSelector": (context) => UserSelector(),
            "/settings/views": (context) => ViewSelector(),
            "/music": (context) => MusicScreen(),
            "/music/albumscreen": (context) => AlbumScreen(),
            "/music/artistscreen": (context) => ArtistScreen(),
            "/nowplaying": (context) => PlayerScreen(),
            "/downloads": (context) => DownloadsScreen(),
            "/downloads/errors": (context) => DownloadsErrorScreen(),
            "/logs": (context) => LogsScreen(),
            "/settings": (context) => SettingsScreen(),
            "/settings/transcoding": (context) => TranscodingSettingsScreen(),
          },
          initialRoute: "/",
          darkTheme: ThemeData(
              primarySwatch: generateMaterialColor(accentColor),
              brightness: Brightness.dark,
              scaffoldBackgroundColor: backgroundColor,
              appBarTheme: AppBarTheme(
                color: raisedDarkColor,
              ),
              cardColor: raisedDarkColor,
              accentColor: accentColor,
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                  backgroundColor: raisedDarkColor),
              canvasColor: raisedDarkColor,
              toggleableActiveColor:
                  generateMaterialColor(accentColor).shade200),
          themeMode: ThemeMode.dark,
        ),
      ),
    );
  }
}

class FinampErrorApp extends StatelessWidget {
  const FinampErrorApp({Key key, @required this.error}) : super(key: key);

  final dynamic error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Finamp",
      home: Scaffold(
        body: Center(
          child: Text(
              "Something went wrong during app startup! The error was: ${error.toString()}\n\nPlease create a Github issue on github.com/UnicornsOnLSD/finamp with a screenshot of this page. If this page keeps showing, clear your app data to reset the app."),
        ),
      ),
    );
  }
}
