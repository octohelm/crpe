import 'package:crpe/registryserver.dart';
import 'package:test/test.dart';

main() async {
  test("sync", () async {
    var nm = NodeMeta(ip: "", id: "dev", platforms: ["linux/amd64"]);
    print(nm.normalize());
  });
}
