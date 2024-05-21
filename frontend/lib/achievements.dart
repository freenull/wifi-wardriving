import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "main.dart";
import "backend.dart";

class AchievementPage extends StatefulWidget {
    const AchievementPage({super.key});

    @override
    State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
    _AchievementPageState();

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
                        title: const Text("Achievements")
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
                                            child: AchievementList()
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

class AchievementList extends StatefulWidget {
    const AchievementList({super.key});

    @override
    State<AchievementList> createState() => _AchievementListState();
}

class _AchievementListState extends State<AchievementList> {
    _AchievementListState();
    
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

    ListTile achievementEntry(bool locked, String file, String description, String? whenUnlocked) {
        return ListTile(
            leading: locked ? assetImage("assets/lock.png") : assetImage("assets/$file.png"),
            title: Text(description),
            subtitle: whenUnlocked == null ? null : Text("Unlocked: $whenUnlocked")
        );
    }

    Future<Widget> asyncBuild(BuildContext context) async {
        final achievementEntries = <Widget>[];

        achievementEntries.add(achievementEntry(false, "1-comment", "Comment on a submitted network", "13.05.2024 14:20:42"));
        achievementEntries.add(const SizedBox(height: 10));
        achievementEntries.add(achievementEntry(false, "10-comment", "Comment on 10 submitted networks", "13.05.2024 17:48:44"));
        achievementEntries.add(const SizedBox(height: 10));
        achievementEntries.add(achievementEntry(true, "100-comment", "Comment on 100 submitted networks", null));
        achievementEntries.add(const SizedBox(height: 10));

        achievementEntries.add(achievementEntry(false, "1-network", "Submit a network", "13.05.2024 13:05:33"));
        achievementEntries.add(const SizedBox(height: 10));
        achievementEntries.add(achievementEntry(true, "10-network", "Submit 10 networks", null));
        achievementEntries.add(const SizedBox(height: 10));
        achievementEntries.add(achievementEntry(true, "100-network", "Submit 100 networks", null));

        return Column(children: [
            ListView(physics: NeverScrollableScrollPhysics(), shrinkWrap: true, children: achievementEntries)
        ]);
    }
}
