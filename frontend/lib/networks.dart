import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:wifi_scan/wifi_scan.dart";
import "main.dart";

class NetworksPage extends StatelessWidget {
  const NetworksPage({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Submit networks"),
          ),
          body: const Padding(padding: EdgeInsets.only(bottom: 60), child: Scrollbar(child: SingleChildScrollView(physics: ScrollPhysics(), scrollDirection: Axis.vertical, child: Column(
          children: [
              FractionallySizedBox(widthFactor: 0.8, child: Text("You may unselect networks that you do not wish to send data about.", textAlign: TextAlign.center)),
              SingleChildScrollView(physics: ScrollPhysics(), scrollDirection: Axis.vertical, child: NetworksList())
          ])))),
          bottomSheet:
              ElevatedButton(
                  child: const Text("Submit"),
                  onPressed: () {},
                  style: ElevatedButton.styleFrom( 
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2))),
                      minimumSize: Size.fromHeight(60)
                  ),
              )
        ),
      ),
    );
  }
}


class NetworksList extends StatefulWidget {
    const NetworksList({super.key});

    @override
    State<NetworksList> createState() => _NetworksListState();
}

class _NetworksListState extends State<NetworksList> {
    List<WiFiAccessPoint>? _accessPoints = null;

    @override
    Widget build(BuildContext context) {
        print("building");
        return FutureBuilder<Widget>(
            future: asyncBuild(context),
            builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                if (snapshot.hasData) return snapshot.data!;
                if (snapshot.hasError) throw snapshot.error!;
                return const CircularProgressIndicator(value: null);
            }
        );
    }

    Future<bool> scan() async {
        if (CanStartScan.yes != await WiFiScan.instance.canStartScan(askPermissions: true)) return false;
        if (!await WiFiScan.instance.startScan()) return false;
        if (CanGetScannedResults.yes != await WiFiScan.instance.canGetScannedResults(askPermissions: true)) return false;
        _accessPoints = await WiFiScan.instance.getScannedResults();
        return true;
    }

    void reload() {
        setState(() { _accessPoints = null; });
    }

    List<String> parseCapabilities(String capString) {
        var list = List<String>.empty(growable: true);
        if (!capString.startsWith("[")) return list;
        capString = capString.substring(1);
        var splitCaps = capString.split("][");
        for (var i = 0; i < splitCaps.length; i++) {
            var splitCap = splitCaps[i];
            if (i == splitCaps.length - 1 && splitCap.endsWith("]")) {
                splitCap = splitCap.substring(0, splitCap.length - 1);
            }

            list.add(splitCap);
        }
        return list;
    }

    Future<Widget> asyncBuild(BuildContext context) async {
        if (_accessPoints == null) await scan();
        if (_accessPoints == null) {
            // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: const Text("Failed loading WiFi networks")));
            Navigator.of(context).pop();
            return const Text("No access points");
        }

        var elems = <Widget>[];
        for (final ap in _accessPoints!) {
            print(ap.ssid);
            var caps = parseCapabilities(ap.capabilities);
            elems.add(Row(
                children: <Widget>[
                    Checkbox(value: true, onChanged: (value) {}),
                    Flexible(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(ap.ssid),
                            Text(caps.join(", ")),
                            Text("freq: ${ap.frequency}, chan: ${ap.channelWidth}"),
                    ]))
                ]
            ));
        }

        return ListView(physics: NeverScrollableScrollPhysics(), shrinkWrap: true, children: elems);
    }
}
