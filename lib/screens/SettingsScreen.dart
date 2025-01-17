import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

import '../components/SettingsScreen/LogoutListTile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () async {
              PackageInfo packageInfo = await PackageInfo.fromPlatform();

              showAboutDialog(
                context: context,
                applicationName: packageInfo.appName,
                applicationVersion: packageInfo.version,
                applicationLegalese:
                    "Licensed with the Mozilla Public License 2.0. Source code available at:\n\ngithub.com/UnicornsOnLSD/finamp",
              );
            },
          )
        ],
      ),
      body: Scrollbar(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.compress),
              title: const Text("Transcoding"),
              onTap: () =>
                  Navigator.of(context).pushNamed("/settings/transcoding"),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text("Download Locations"),
              onTap: () => Navigator.of(context)
                  .pushNamed("/settings/downloadlocations"),
            ),
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text("Audio Service"),
              onTap: () =>
                  Navigator.of(context).pushNamed("/settings/audioservice"),
            ),
            ListTile(
              leading: const Icon(Icons.tab),
              title: const Text("Tabs"),
              onTap: () => Navigator.of(context).pushNamed("/settings/tabs"),
            ),
            const LogoutListTile(),
          ],
        ),
      ),
    );
  }
}
