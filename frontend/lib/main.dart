/* Authors:
 * - Dominik Banaszak
 */

import "package:flutter/material.dart";
//import "package:flutter_osm_plugin/flutter_osm_plugin.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_map_location_marker/flutter_map_location_marker.dart";
import "package:flutter_map_marker_popup/flutter_map_marker_popup.dart";
import 'package:latlong2/latlong.dart';
// import "package:flutter_osm_plugin/flutter_osm_plugin.dart";
import "dart:io";
import "dart:async";
import "dart:convert";
import "dart:math";
import "package:shared_preferences/shared_preferences.dart";
import 'package:geolocator/geolocator.dart';

import "backend.dart";
import "user.dart";
import "networks.dart";
import "leaderboard.dart";
import "achievements.dart";
import "discussion.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Wardriving',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        primaryColorDark: Colors.black54,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'WiFi Wardriving'),
    );
  }
}

class AccountElement extends StatefulWidget {
  const AccountElement({super.key});

  @override
  State<AccountElement> createState() => _AccountElementState();
}

class _AccountElementState extends State<AccountElement> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
        future: asyncBuild(context),
        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.hasData) return snapshot.data!;
          return const CircularProgressIndicator(value: null);
        });
  }

  Future<Widget> asyncBuild(BuildContext context) async {
    if (!await Backend().isLoggedIn(ScaffoldMessenger.of(context))) {
      return ListView(shrinkWrap: true, children: <Widget>[
        ListTile(
            title: const Text("Account"),
            onTap: () async {
              final nav = Navigator.of(context);
              nav.pop();
              await nav.push(
                  MaterialPageRoute(builder: (context) => const LoginPage()));
              setState(() {});
            },
            leading: const Icon(Icons.switch_account)),
        ListTile(
            title: const Text("Leaderboard"),
            onTap: () async {
              final nav = Navigator.of(context);
              nav.pop();
              await nav.push(MaterialPageRoute(
                  builder: (context) => const LeaderboardPage()));
              setState(() {});
            },
            leading: const Icon(Icons.leaderboard)),
        ListTile(
            title: const Text("Achievements"),
            onTap: () async {
              final nav = Navigator.of(context);
              nav.pop();
              await nav.push(MaterialPageRoute(
                  builder: (context) => const AchievementPage()));
              setState(() {});
            },
            leading: const Icon(Icons.checklist)),
      ]);
    } else {
      return ListView(shrinkWrap: true, children: <Widget>[
        ListTile(
            title: const Text("Account"),
            subtitle: Text(Backend().username!),
            leading: const Icon(Icons.switch_account)),
        ListTile(
            title: const Text("Logout"),
            onTap: () async {
              final nav = Navigator.of(context);
              nav.pop();
              await Backend().logoutAccount(ScaffoldMessenger.of(context));
              setState(() {});
            },
            leading: const Icon(Icons.logout)),
        ListTile(
            title: const Text("Leaderboard"),
            onTap: () async {
              final nav = Navigator.of(context);
              nav.pop();
              await nav.push(MaterialPageRoute(
                  builder: (context) => const LeaderboardPage()));
              setState(() {});
            },
            leading: const Icon(Icons.leaderboard)),
        ListTile(
            title: const Text("Achievements"),
            onTap: () async {
              final nav = Navigator.of(context);
              nav.pop();
              await nav.push(MaterialPageRoute(
                  builder: (context) => const AchievementPage()));
              setState(() {});
            },
            leading: const Icon(Icons.checklist)),
      ]);
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class DatapointMarker extends Marker {
  const DatapointMarker(LatLng point, Widget child)
      : super(point: point, child: child);
}

class _MyHomePageState extends State<MyHomePage> {
  MapController _mapController;
  PopupController _popupController;

  _MyHomePageState()
      : _mapController = MapController(),
        _popupController = PopupController() {
    Backend().changeAccount.listen((username) {
      print("change acc $username");
      setState(() {});
    });
  }

  late LatLng lastUpdateCenter;
  final List<WardrivingDatapointMarker> markers = [];
  final StreamController<double?> _alignPositionStreamController =
      StreamController<double?>();
  Timer? mapUpdateTimer;

  @override
  void dispose() {
    super.dispose();
    _mapController.dispose();
    mapUpdateTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
        future: asyncBuild(context),
        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.hasData) return snapshot.data!;
          return const CircularProgressIndicator(value: null);
        });
  }

  // unit is meters
  double earthDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
        point1.latitude, point1.longitude, point2.latitude, point2.longitude);
  }

  static double MAX_JOIN_DISTANCE = 10;

  void updateMapMarkers() async {
    var currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    var currentPoint =
        LatLng(currentPosition.latitude, currentPosition.longitude);
    Backend()
        .retrieveClusters(ScaffoldMessenger.of(context), currentPoint)
        .then((clusters) {
      print(clusters?.length);
      markers.clear();

      if (clusters == null) return;
      for (var cluster in clusters) {
        print("cluster ====");

        var marker = WardrivingDatapointMarker(
            cluster.position, const Icon(Icons.circle, color: Colors.red));
        for (var datapoint in cluster.datapoints) {
          print(
              "datapoint: ${datapoint.ssid} ${datapoint.position.latitude}, ${datapoint.position.longitude} (markers: ${markers.length})");
          marker.datapoints.add(datapoint);
        }
        markers.add(marker);
      }

      print("center: ${_mapController.center}");
      print("markers: ${markers.length}");

      for (var marker in markers) {
        print(marker.point);
      }
      lastUpdateCenter = _mapController.center;
      setState(() {});
    });
  }

  Future<Widget> asyncBuild(BuildContext context) async {
    mapUpdateTimer ??= Timer.periodic(
        const Duration(seconds: 5), (Timer t) => updateMapMarkers());

    final floatingButtonWidgets = <Widget>[
      FloatingActionButton(
          heroTag: null,
          onPressed: () async {
            _alignPositionStreamController.add(null);
          },
          tooltip: 'My location',
          child: const Icon(Icons.my_location)),
    ];

    if (await Backend().isLoggedIn(ScaffoldMessenger.of(context))) {
      floatingButtonWidgets.insert(
          0,
          FloatingActionButton(
            heroTag: null,
            tooltip: "Add networks",
            child: const Icon(Icons.add),
            onPressed: () async {
              print("opennet");
              final nav = Navigator.of(context);
              await nav.push(MaterialPageRoute(
                  builder: (context) => NetworksPage(_mapController)));
              setState(() {});
            },
          ));
    }

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepOrange,
          title: Text(widget.title),
        ),
        body: Center(
          child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                  onTap: (pos, latlng) => _popupController.hideAllPopups()),
              children: [
                TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: "org.example.test"),
                CurrentLocationLayer(
                    alignPositionStream: _alignPositionStreamController.stream,
                    alignPositionOnUpdate: AlignOnUpdate.once),
                PopupMarkerLayer(
                    options: PopupMarkerLayerOptions(
                        popupController: _popupController,
                        markers: markers,
                        popupDisplayOptions: PopupDisplayOptions(
                            builder: (BuildContext context, Marker marker) {
                          if (marker is! WardrivingDatapointMarker)
                            return const Text("unimplemented");

                          var datapointMarker =
                              marker as WardrivingDatapointMarker;

                          var cardChildren = <Widget>[];
                          if (datapointMarker.datapoints.length > 1) {
                            cardChildren.add(Text(
                                "${datapointMarker.datapoints.length} networks"));
                          }
                          for (var datapoint in datapointMarker.datapoints) {
                            var networkName = datapoint.displayName();

                            for (var otherDatapoint
                                in datapointMarker.datapoints) {
                              if (datapoint.ssid == "" &&
                                  otherDatapoint.bssid != datapoint.bssid) {
                                networkName = "<${datapoint.bssid}>";
                              } else if (otherDatapoint.displayName() ==
                                      datapoint.displayName() &&
                                  otherDatapoint.bssid != datapoint.bssid) {
                                var deviceMac = datapoint.bssid.split(":");
                                var otherDeviceMac =
                                    otherDatapoint.bssid.split(":");

                                var bssidDetail = "";
                                var idxs = [0, 1, 2, 3, 4, 5];
                                for (var idx in idxs) {
                                  if (deviceMac[idx] != otherDeviceMac[idx])
                                    bssidDetail =
                                        deviceMac.sublist(idx).join(":");
                                }
                                if (bssidDetail.length < 6 * 2 + 5) {
                                  bssidDetail = "::$bssidDetail";
                                }

                                networkName =
                                    "${datapoint.ssid} (${bssidDetail})";
                                break;
                              }
                            }

                            cardChildren.add(TextButton.icon(
                                icon: Icon(Icons.network_wifi_3_bar),
                                label: Text(networkName),
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              DiscussionPage(datapoint.id!)));
                                  setState(() {});
                                }));
                          }

                          return Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: ConstrainedBox(
                                      constraints:
                                          BoxConstraints(maxHeight: 300),
                                      child: Scrollbar(
                                          child: SingleChildScrollView(
                                              scrollDirection: Axis.vertical,
                                              child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: cardChildren)
                                              // )
                                              )))));
                        }))),
              ]),
        ),
        drawer: Drawer(
            child: ListView(padding: EdgeInsets.zero, children: <Widget>[
          const SizedBox(
            height: 100.0,
            child: DrawerHeader(
                margin: EdgeInsets.zero, child: Text("WiFi Wardriving")),
          ),
          AccountElement()
        ])),
        floatingActionButton: Align(
            alignment: Alignment.bottomRight,
            child: Wrap(spacing: 5, children: floatingButtonWidgets)));
  }
}
