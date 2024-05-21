import "package:flutter/material.dart";
import "package:flutter_osm_plugin/flutter_osm_plugin.dart";
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

class _MyHomePageState extends State<MyHomePage> {
    MapController _mapController;

    _MyHomePageState()
    : _mapController = MapController(
        initPosition: GeoPoint(latitude: 51.10967, longitude: 17.05977),
        areaLimit: BoundingBox(
            east: 10,
            north: 10,
            west: 10,
            south: 10
        )
    ) {
       Backend().changeAccount.listen((username) {
           print("change acc $username");
           setState(() {});
        });
    }

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
                onPressed: () async {
                   await _mapController.currentLocation();
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
                    await nav.push(MaterialPageRoute(builder: (context) => const NetworksPage()));
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
                child: OSMFlutter(
                    controller: _mapController,
                    osmOption: OSMOption(
                        userTrackingOption: const UserTrackingOption(enableTracking: true, unFollowUser: false),
                        zoomOption: const ZoomOption(
                            initZoom: 16,
                            minZoomLevel: 3,
                            maxZoomLevel: 19,
                            stepZoom: 1.0
                        ),
                        userLocationMarker: UserLocationMaker(
                            personMarker: const MarkerIcon(
                                icon: Icon(
                                    Icons.location_pin,
                                    color: Colors.deepOrange,
                                    size: 128,
                                ),
                            ),
                            directionArrowMarker: const MarkerIcon(
                                icon: Icon(
                                    Icons.double_arrow,
                                    color: Colors.deepOrange,
                                    size: 128,
                                ),
                            ),
                        ),
                    ),
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
