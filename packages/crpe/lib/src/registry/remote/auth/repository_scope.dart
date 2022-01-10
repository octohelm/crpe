class RepositoryScope {
  String repository;
  String className;
  List<String> actions;

  factory RepositoryScope.fromUri(String method, Uri uri) {
    return RepositoryScope(
      uri.path
          .substring("/v2/".length)
          .split(RegExp(r'/(tags|blobs|manifests)/'))
          .first,
      actions: [
        (method == "POST" || method == "PUT" || method == "DELETE")
            ? "push"
            : "pull",
      ],
    );
  }

  RepositoryScope(
    this.repository, {
    required this.actions,
    this.className = "",
  });

  @override
  String toString() {
    if (repository == "") {
      return "";
    }
    var repoType = "repository";
    if (className != "" && className != "image") {
      repoType = "$repoType($className)";
    }
    return "$repoType:$repository:${actions.join(",")}";
  }
}
