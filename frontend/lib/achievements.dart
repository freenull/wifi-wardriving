/* Authors:
 * - Dominik Banaszak
 * - Oliwier Strachota
 */

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
              child: Center(child: CircularProgressIndicator(value: null)));
        });
  }

  Future<Widget> asyncBuild(BuildContext context) async {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(title: const Text("Achievements")),
          body: const Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Scrollbar(
                  child: SingleChildScrollView(
                      physics: const ScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      child: Column(children: [
                        SingleChildScrollView(
                            physics: const ScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            child: AchievementList())
                      ])))),
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
              child: Center(child: CircularProgressIndicator(value: null)));
        });
  }

  Image assetImage(String path) {
    return Image(
      image: AssetImage(path),
      color: null,
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
    );
  }

  ListTile achievementEntry(Map<String, Achievement> achiev, String key,
      String file, String description) {
    var unlocked = achiev.containsKey(key);

    return ListTile(
        leading: unlocked
            ? assetImage("assets/$file.png")
            : assetImage("assets/lock.png"),
        title: Text(description),
        subtitle:
            unlocked ? Text("Unlocked: ${achiev[key]!.unlockTime}") : null);
  }

  Future<Widget> asyncBuild(BuildContext context) async {
    final achievementEntries = <Widget>[];
    final achievements =
        await Backend().retrieveOwnAchievements(ScaffoldMessenger.of(context));
    var achievementMap = Map<String, Achievement>();

    if (achievements != null) {
      for (var achiev in achievements) {
        achievementMap[achiev.key] = achiev;
      }
    }

    achievementEntries.add(achievementEntry(achievementMap, "comments_1",
        "1-comment", "Comment on a submitted network"));
    achievementEntries.add(const SizedBox(height: 10));
    achievementEntries.add(achievementEntry(achievementMap, "comments_10",
        "10-comment", "Comment on 10 submitted networks"));
    achievementEntries.add(const SizedBox(height: 10));
    achievementEntries.add(achievementEntry(achievementMap, "comments_100",
        "100-comment", "Comment on 100 submitted networks"));
    achievementEntries.add(const SizedBox(height: 10));

    achievementEntries.add(achievementEntry(
        achievementMap, "networks_1", "1-network", "Submit a network"));
    achievementEntries.add(const SizedBox(height: 10));
    achievementEntries.add(achievementEntry(
        achievementMap, "networks_10", "10-network", "Submit 10 networks"));
    achievementEntries.add(const SizedBox(height: 10));
    achievementEntries.add(achievementEntry(
        achievementMap, "networks_100", "100-network", "Submit 100 networks"));

    return Column(children: [
      ListView(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: achievementEntries)
    ]);
  }
}
