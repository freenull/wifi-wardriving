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
import "package:shared_preferences/shared_preferences.dart";

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
            }
        );
    }

    Future<Widget> asyncBuild(BuildContext context) async {
        if (!await Backend().isLoggedIn(ScaffoldMessenger.of(context))) {
            return ListView(
                shrinkWrap: true,
                children: <Widget>[
                    ListTile(
                        title: const Text("Account"),
                        onTap: () async {
                            final nav = Navigator.of(context);
                            nav.pop();
                            await nav.push(MaterialPageRoute(builder: (context) => const LoginPage()));
                            setState(() {});
                        },
                        leading: const Icon(Icons.switch_account)
                    ),
                    ListTile(
                        title: const Text("Leaderboard"),
                        onTap: () async {
                            final nav = Navigator.of(context);
                            nav.pop();
                            await nav.push(MaterialPageRoute(builder: (context) => const LeaderboardPage()));
                            setState(() {});
                        },
                        leading: const Icon(Icons.leaderboard)
                    ),
                    ListTile(
                        title: const Text("Achievements"),
                        onTap: () async {
                            final nav = Navigator.of(context);
                            nav.pop();
                            await nav.push(MaterialPageRoute(builder: (context) => const AchievementPage()));
                            setState(() {});
                        },
                        leading: const Icon(Icons.checklist)
                    ),
                    ListTile(
                        title: const Text("Discussion"),
                        onTap: () async {
                            final nav = Navigator.of(context);
                            nav.pop();
                            await nav.push(MaterialPageRoute(builder: (context) => const DiscussionPage(1)));
                            setState(() {});
                        },
                        leading: const Icon(Icons.comment)
                    )
                ]
            );
        }
        else
        {
            return ListView(
                shrinkWrap: true,
                children: <Widget>[
                    ListTile(
                        title: const Text("Account"),
                        subtitle: Text(Backend().username!),
                        leading: const Icon(Icons.switch_account)
                    ),
                    ListTile(
                        title: const Text("Logout"),
                        onTap: () async {
                            final nav = Navigator.of(context);
                            nav.pop();
                            await Backend().logoutAccount(ScaffoldMessenger.of(context));
                            setState(() {});
                        },
                        leading: const Icon(Icons.logout)
                    ),
                    ListTile(
                        title: const Text("Leaderboard"),
                        onTap: () async {
                            final nav = Navigator.of(context);
                            nav.pop();
                            await nav.push(MaterialPageRoute(builder: (context) => const LeaderboardPage()));
                            setState(() {});
                        },
                        leading: const Icon(Icons.leaderboard)
                    ),
                    ListTile(
                        title: const Text("Achievements"),
                        onTap: () async {
                            final nav = Navigator.of(context);
                            nav.pop();
                            await nav.push(MaterialPageRoute(builder: (context) => const AchievementPage()));
                            setState(() {});
                        },
                        leading: const Icon(Icons.checklist)
                    ),
                    ListTile(
                        title: const Text("Discussion"),
                        onTap: () async {
                            final nav = Navigator.of(context);
                            nav.pop();
                            await nav.push(MaterialPageRoute(builder: (context) => const DiscussionPage(1)));
                            setState(() {});
                        },
                        leading: const Icon(Icons.comment)
                    )
                ]
            );
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
    const DatapointMarker(LatLng point, Widget child) : super(point: point, child: child);
}

class _MyHomePageState extends State<MyHomePage> {
    MapController _mapController;

    _MyHomePageState()
    : _mapController = MapController()
    {
       Backend().changeAccount.listen((username) {
           print("change acc $username");
           setState(() {});
        });
    }

    late LatLng lastUpdateCenter;
    final List<Marker> markers = [];
    final StreamController<double?> _alignPositionStreamController = StreamController<double?>();

    @override
    void dispose() {
        super.dispose();
        _mapController.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return FutureBuilder<Widget>(
            future: asyncBuild(context),
            builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                if (snapshot.hasData) return snapshot.data!;
                return const CircularProgressIndicator(value: null);
            }
        );
    }

    Future<Widget> asyncBuild(BuildContext context) async {
        final floatingButtonWidgets = <Widget>[
            FloatingActionButton(
                onPressed: () {
                    _alignPositionStreamController.add(null);

                    // markers.add(Marker(
                    //     point: LatLng(_mapController.center.latitude + 0.01, _mapController.center.longitude + 0.01),
                    //     child: const Icon(Icons.flag)
                    // ));
                    print("center: ${_mapController.center}");
                    print("markers: ${markers.length}");

                    Backend().retrieveDatapoints(ScaffoldMessenger.of(context), _mapController.center).then((datapoints) {
                        print(datapoints?.length);
                        markers.clear();
                        if (datapoints == null) return;
                        for (var datapoint in datapoints) {
                            markers.add(Marker(
                                point: datapoint.position,
                                child: const Icon(Icons.star)
                            ));
                        }
                        for (var marker in markers) {
                            print(marker.point);
                        }
                        lastUpdateCenter = _mapController.center;
                        setState(() {});
                    });

                    // var loc = await _mapController.myLocation();
                    // if (lastGeoPoint != null) {
                    //     await _mapController.removeMarker(lastGeoPoint!);
                    // } else {
                    //     await _mapController.addMarker(GeoPoint(latitude: loc.latitude + 0.01, longitude: loc.longitude + 0.01), markerIcon: MarkerIcon(icon: Icon(Icons.flag)));
                    //     print("add marker $loc");
                    // }
                    // await _mapController.addMarker(GeoPoint(latitude: loc.latitude, longitude: loc.longitude), markerIcon: const MarkerIcon(icon: Icon(
                    //     Icons.location_pin,
                    //     color: Colors.deepOrange,
                    //     size: 128
                    // )));

                },
                tooltip: 'My location',
                child: const Icon(Icons.my_location)
            ),
        ];

        if (await Backend().isLoggedIn(ScaffoldMessenger.of(context))) { 
            floatingButtonWidgets.insert(0, FloatingActionButton(
                tooltip: "Add networks",
                child: const Icon(Icons.add),
                onPressed: () async {
                    print("opennet");
                    final nav = Navigator.of(context);
                    await nav.push(MaterialPageRoute(builder: (context) => NetworksPage(_mapController)));
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
                    options: MapOptions(),
                    children: [
                        TileLayer(
                            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            userAgentPackageName: "org.example.test"
                        ),
                        PopupMarkerLayer(options: PopupMarkerLayerOptions(
                            markers: markers,
                            popupDisplayOptions: PopupDisplayOptions(
                                builder: (BuildContext context, Marker marker) {
                                    print("marker: $marker");
                                    return Card(
                                        child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                    const Text("10 networks"),
                                                    TextButton.icon(icon: Icon(Icons.comment), label: Text("Comments..."), onPressed: () {}),
                                                ]
                                            )
                                        )
                                    );
                                }
                            )
                        )),
                        CurrentLocationLayer(
                            alignPositionStream: _alignPositionStreamController.stream,
                            alignPositionOnUpdate: AlignOnUpdate.once
                        )
                    ]
                ),
            ),
            drawer: Drawer(
                child: ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                        const SizedBox(
                            height: 100.0,
                            child: DrawerHeader(
                                margin: EdgeInsets.zero,
                                child: Text("WiFi Wardriving")
                            ),
                        ),
                        AccountElement()
                    ]
                )
            ),
            floatingActionButton: Align(
                alignment: Alignment.bottomRight,
                child: Wrap(
                spacing: 5,
                children: floatingButtonWidgets
            ))
        );
    }
}
