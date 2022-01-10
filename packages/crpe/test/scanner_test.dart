import 'package:crpe/registryserver.dart';
import 'package:test/test.dart';

void main() {
  test("Scanner", () async {
    var s = NodeAdapter(port: 36060);

    var endpoint = await s.scan("172.31.1.131").first;

    print(endpoint);
  });
}
