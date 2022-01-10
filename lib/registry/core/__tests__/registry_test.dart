import 'package:crpe/registry/registry.dart';
import 'package:test/test.dart';

main() async {
  var r = LocalRegistry("./tmp/registry");

  group("repo flow", () {
    test("sync", () async {
      var repo = await r.repository("docker.io/library/nginx");
      var tag = repo.tags();
      var tags = await tag.all();
      expect(tags, ["alpine"]);
    });

    test("tag", () async {
      var repo = await r.repository("docker.io/library/nginx");
      var ts = repo.tags();

      var d = await ts.get("alpine");

      await ts.tag("alpine-suffix", d);
      expect(await ts.lookup(d), ["alpine", "alpine-suffix"]);

      await ts.untag("alpine-suffix");
      expect(await ts.lookup(d), ["alpine"]);
    });
  });

  test("repositories", () async {
    var repos = await r.repositories();
    expect([
      ...repos.map((e) => e.name),
    ], [
      "docker.io/library/nginx"
    ]);
  });
}
