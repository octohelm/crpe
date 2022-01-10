import 'package:crpe/kubepkg.dart';
import 'package:crpe/registryserver.dart';
import 'package:crpeapp/flutter/flutter.dart';

import 'cluster_state.dart';

class BlocCluster extends HydratedCubit<ClusterState> {
  static BlocCluster read(BuildContext context) {
    return context.read<BlocCluster>();
  }

  static BlocCluster watch(BuildContext context) {
    return context.watch<BlocCluster>();
  }

  BlocCluster() : super(ClusterState());

  @override
  ClusterState? fromJson(Map<String, dynamic> json) {
    return ClusterState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(ClusterState state) {
    return state.toJson();
  }

  Cluster cluster(String name) {
    return state.cluster(name);
  }

  Cluster get current => state.cluster(state.current);

  NodeAdapter get adapter => NodeAdapter(port: 6060);

  void update(
    clusterName,
    Cluster Function(Cluster cluster) update,
  ) {
    emit(state.update(clusterName, update));
  }

  void updateClusterInfo(Cluster cluster) {
    update(cluster.name, (ci) {
      return ci.copyWith(
        desc: cluster.desc,
      );
    });
  }

  void connectNode(String clusterName, ClusterNode clusterNode) {
    update(clusterName, (ci) {
      return ci.copyWith(nodes: {
        ...?ci.nodes,
        clusterNode.id: clusterNode,
      });
    });
  }

  void disconnectNode(String clusterName, String clusterNodeId) {
    update(clusterName, (ci) {
      var next = ci.nodes?..removeWhere((key, value) => key == clusterNodeId);

      return ci.copyWith(
        nodes: next,
      );
    });
  }

  void updatePkg(String clusterName, KubePkg kubePkg) {
    update(clusterName, (ci) {
      return ci.copyWith(pkgs: {
        ...?ci.pkgs,
        kubePkg.metadata.name: kubePkg,
      });
    });
  }

  void switchCluster(String name) {
    emit(state.copyWith(
      selected: name,
    ));
  }
}
