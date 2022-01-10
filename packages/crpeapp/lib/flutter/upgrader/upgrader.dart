import 'dart:core';
import 'dart:developer';
import 'dart:io';

import 'package:crpeapp/flutter/flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:roundtripper/roundtripper.dart';
import 'package:url_launcher/url_launcher.dart';

import 'release.dart';

class Upgrader {
  static use(context) {
    useEffect(() {
      Upgrader.checkVersion(context, "stable");
      return null;
    }, []);
  }

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
    } catch (e, st) {
      log("check version failed", error: e, stackTrace: st);
    }
  }

  final String channel;

  Upgrader({
    required this.channel,
  });

  Client client = Client();

  String downloadProxyFor(String s) => "https://ghproxy.com/$s";

  String proxyFor(String s) => "https://now-proxy-3.vercel.app/$s";

  String get baseUrl =>
      "https://raw.githubusercontent.com/octohelm/crpe/release/$channel/";

  Future<Release> latestRelease() async {
    var req = Request.uri(
      proxyFor("$baseUrl/android/latest.json"),
      method: "GET",
    );

    var resp = await client.fetch(req);

    var json = await resp.json();

    var release = Release.fromJson(json);

    return release.downloadURL.startsWith('/')
        ? release.copyWith(
            downloadURL: downloadProxyFor("$baseUrl${release.downloadURL}"),
          )
        : release;
  }
}
