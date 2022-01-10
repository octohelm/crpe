import 'package:crpe/kubepkg.dart';
import 'package:crpe/registryserver.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '__generated__/cluster_state.freezed.dart';
part '__generated__/cluster_state.g.dart';

@freezed
class ClusterState with _$ClusterState {
  ClusterState._();

  factory ClusterState({
    @Default({}) Map<String, Cluster> clusters,
    String? selected,
  }) = _ClusterState;

  factory ClusterState.fromJson(Map<String, dynamic> json) =>
      _ClusterState.fromJson(json);

  String get current =>
      clusters[selected ?? ""]?.name ?? clusters.keys.firstOrNull ?? "";

  Cluster cluster(String name) {
    return clusters[name]!;
  }

  ClusterState update(
    String name,
    Cluster Function(Cluster cluster) update,
  ) {
    return copyWith(
      clusters: {
        ...clusters,
        name: update(clusters[name] ?? Cluster(name: name)).copyWith(
          updatedAt: DateTime.now(), // ugly but useful to trigger data changed
        ),
      },
    );
  }
}

@freezed
class Cluster with _$Cluster {
  Cluster._();

  factory Cluster({
    required String name,
    String? desc,
    Map<String, ClusterNode>? nodes,
    Map<String, KubePkg>? pkgs,
    DateTime? updatedAt,
  }) = _Cluster;

  factory Cluster.fromJson(Map<String, dynamic> json) =>
      _Cluster.fromJson(json);

  ClusterNode? node(String id) {
    return nodes?[id];
  }
}

@freezed
class ClusterNode with _$ClusterNode {
  ClusterNode._();

  factory ClusterNode({
    required String id,
    required String ip,
    String? name,
    List<String>? platforms,
  }) = _ClusterNode;

  factory ClusterNode.fromJson(Map<String, dynamic> json) =>
      _ClusterNode.fromJson(json);

  factory ClusterNode.fromNodeMeta(NodeMeta meta) {
    return ClusterNode(
      id: meta.id,
      ip: meta.ip,
      platforms: meta.platforms,
    );
  }
}
