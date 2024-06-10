import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "main.dart";
import "backend.dart";

class LeaderboardPage extends StatefulWidget {
    const LeaderboardPage({super.key});

    @override
    State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
    _LeaderboardPageState();

    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
        return FutureBuilder<Widget>(
            future: asyncBuild(context),
            builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                if (snapshot.hasData) return snapshot.data!;
                if (snapshot.hasError) throw snapshot.error!;
                return const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator(value: null)
                ));
            }
        );
    }

    Future<Widget> asyncBuild(BuildContext context) async {
        return Scaffold(
            body: DefaultTabController(
                length: 2,
                child: Scaffold(
                    appBar: AppBar(
                        title: const Text("Leaderboards")
                    ),
                    body: const Padding(
                        padding: const EdgeInsets.only(bottom: 60),
                        child: Scrollbar(
                            child: SingleChildScrollView(
                                physics: const ScrollPhysics(),
                                scrollDirection: Axis.vertical,
                                child: Column(
                                    children: [
                                        SingleChildScrollView(
                                            physics: const ScrollPhysics(),
                                            scrollDirection: Axis.vertical,
                                            child: LeaderboardList()
                                        )
                                    ]
                                )
                            )
                        )
                    ),
                ),
            ),
        );
    }
}

class LeaderboardList extends StatefulWidget {
    const LeaderboardList({super.key});

    @override
    State<LeaderboardList> createState() => _LeaderboardListState();
}

class _LeaderboardListState extends State<LeaderboardList> {
    _LeaderboardListState();
    
    @override
    Widget build(BuildContext context) {
        return FutureBuilder<Widget>(
            future: asyncBuild(context),
            builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                if (snapshot.hasData) return snapshot.data!;
                if (snapshot.hasError) throw snapshot.error!;
                return const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator(value: null)
                ));
            }
        );
    }

    Image assetImage(String path) {
        return Image(
            image: AssetImage(path),
            color: null,
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
        );
    }

    ListTile leaderboardEntry(int n, String username, int networkCount) {
        return ListTile(
            leading: n == 1 ? Icon(Icons.grade) : Icon(Icons.account_box),
            title: Text("$n. $username"),
            subtitle: Text("$networkCount networks submitted")
        );
    }

    Future<Widget> asyncBuild(BuildContext context) async {
        var leaderboardEntries = await Backend().retrieveLeaderboard(ScaffoldMessenger.of(context), 10);

        final widgets = <Widget>[];

        if (leaderboardEntries != null) {
            var n = 1;
            for (var entry in leaderboardEntries) {
                var userData = await Backend().userData(ScaffoldMessenger.of(context), entry.userId);
                var username = "<deleted account>";
                if (userData != null) username = userData.username;
                widgets.add(leaderboardEntry(n, username, entry.submittedDatapoints));
                widgets.add(const SizedBox(height: 10));
                n += 1;
            }
        }

        return Column(children: [
            ListView(physics: NeverScrollableScrollPhysics(), shrinkWrap: true, children: widgets)
        ]);
    }
}
