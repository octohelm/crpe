import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:io';

import 'package:crpe/flutter/flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:roundtripper/roundtripper.dart';
import 'package:url_launcher/url_launcher.dart';

import 'release.dart';

class Upgrader {
  static checkVersion(BuildContext context, String channel) async {
    var pi = await PackageInfo.fromPlatform();

    try {
      var lr = await Upgrader(channel: channel).latestRelease();

      var buildNumber = pi.buildNumber;

      if (buildNumber == pi.version) {
        buildNumber = "0";
      }

      if (Platform.isAndroid && lr.shouldUpgrade(pi.version, buildNumber)) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.headline6,
                      child: const Text("是否更新应用？"),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: MarkdownBody(
                      shrinkWrap: true,
                      data: """
新版本 ${lr.version}(build ${lr.buildNumber}) 已发布

**更新日志**

${lr.description?.let((description) => description) ?? "无"}
""",
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("取消"),
                        ),
                        TextButton(
                          onPressed: () {
                            launch(lr.downloadURL);
                          },
                          child: const Text("确认"),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      log("check version failed", error: e);
    }
  }

  final String channel;

  Upgrader({
    required this.channel,
  });

  Client client = Client();

  String get baseUrl => "https://ghproxy.com/https://raw.githubusercontent.com";

  String get uri =>
      "$baseUrl/octohelm/crpe/release/$channel/android/latest.json";

  Future<Release> latestRelease() async {
    var resp = await client.fetch(Request.uri(uri));
    return Release.fromJson(jsonDecode(await resp.text()));
  }
}
