/* Authors:
 * - Dominik Banaszak
 */

import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:wifi_scan/wifi_scan.dart";
import "package:flutter_map/flutter_map.dart";
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
// import "package:flutter_osm_plugin/flutter_osm_plugin.dart";
import "main.dart";
import "backend.dart";

class ToggleableAccessPoint {
  WiFiAccessPoint ap;
  bool enabled;
  bool alreadySent;

  ToggleableAccessPoint(WiFiAccessPoint ap)
      : this.ap = ap,
        enabled = true,
        alreadySent = false;
}

class WardrivingDatapointMarker extends Marker {
  List<Datapoint> datapoints;

  WardrivingDatapointMarker(LatLng point, Widget child)
      : this.datapoints = [],
        super(point: point, child: child);
}

class NetworksPage extends StatefulWidget {
  final MapController mapController;
  const NetworksPage(MapController mapController, {super.key})
      : this.mapController = mapController;

  @override
  State<NetworksPage> createState() => _NetworksPageState(mapController);
}

class _NetworksPageState extends State<NetworksPage> {
  _NetworksPageState(MapController mapController)
      : accessPoints = [],
        mapController = mapController;

  final List<ToggleableAccessPoint> accessPoints;
  final MapController mapController;
  bool submitButtonEnabled = true;

  static String accessPointAuthType(WiFiAccessPoint ap) {
    if (ap.capabilities.contains("[WPA2-")) return "wpa2";
    if (ap.capabilities.contains("[WPA-")) return "wpa";
    if (ap.capabilities.contains("[WEP-")) return "wep";
    return "none";
  }

  static Datapoint accessPointToDatapoint(LatLng position, WiFiAccessPoint ap) {
    print("caps for ${ap.ssid} (${ap.bssid}): ${ap.capabilities}");
    return Datapoint(position, ap.bssid, ap.ssid, accessPointAuthType(ap));
  }

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
            body: Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Scrollbar(
                    child: SingleChildScrollView(
                        physics: ScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        child: Column(children: [
                          const FractionallySizedBox(
                              widthFactor: 0.8,
                              child: Text(
                                  "You may unselect networks that you do not wish to send data about.",
                                  textAlign: TextAlign.center)),
                          SingleChildScrollView(
                              physics: const ScrollPhysics(),
                              scrollDirection: Axis.vertical,
                              child: NetworksList(accessPoints))
                        ])))),
            bottomSheet: ElevatedButton(
              child: const Text("Submit"),
              onPressed: submitButtonEnabled
                  ? (() async {
                      // var pos = await mapController.myLocation();
                      // print("lat: ${pos.latitude}");
                      // print("long: ${pos.longitude}");
                      setState(() {
                        submitButtonEnabled = false;
                      });

                      try {
                        for (var ap in accessPoints) {
                          if (!ap.enabled) continue;

                          var currentPosition =
                              await Geolocator.getCurrentPosition(
                                  desiredAccuracy: LocationAccuracy.high);
                          var result = await Backend().sendDatapoint(
                              ScaffoldMessenger.of(context),
                              accessPointToDatapoint(
                                  LatLng(currentPosition.latitude,
                                      currentPosition.longitude),
                                  ap.ap));
                          if (result) {
                            setState(() {
                              ap.alreadySent = true;
                            });
                          }
                        }
                      } finally {
                        setState(() {
                          submitButtonEnabled = true;
                        });
                      }

                      Navigator.of(context).pop();
                    })
                  : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(2))),
                  minimumSize: Size.fromHeight(60)),
            )),
      ),
    );
  }
}

class NetworksList extends StatefulWidget {
  final List<ToggleableAccessPoint> _accessPoints;
  const NetworksList(this._accessPoints, {super.key});

  @override
  State<NetworksList> createState() => _NetworksListState(_accessPoints);
}

class _NetworksListState extends State<NetworksList> {
  List<ToggleableAccessPoint>? _accessPoints = null;

  _NetworksListState(this._accessPoints);

  @override
  Widget build(BuildContext context) {
    print("building");
    return FutureBuilder<Widget>(
        future: asyncBuild(context),
        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.hasData) return snapshot.data!;
          if (snapshot.hasError) throw snapshot.error!;
          return const CircularProgressIndicator(value: null);
        });
  }

  Future<bool> scan() async {
    print("SCAN");
    if (CanStartScan.yes !=
        await WiFiScan.instance.canStartScan(askPermissions: true))
      return false;
    if (!await WiFiScan.instance.startScan()) return false;
    if (CanGetScannedResults.yes !=
        await WiFiScan.instance.canGetScannedResults(askPermissions: true))
      return false;
    var newAccessPoints = await WiFiScan.instance.getScannedResults();

    _accessPoints?.clear();
    for (final ap in newAccessPoints) {
      _accessPoints?.add(ToggleableAccessPoint(ap));
    }

    return true;
  }

  void reload() {
    setState(() {
      _accessPoints = null;
    });
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
    if (_accessPoints?.isEmpty == true) await scan();
    if (_accessPoints?.isEmpty == true) {
      // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: const Text("Failed loading WiFi networks")));
      Navigator.of(context).pop();
      return const Text("No access points");
    }

    var elems = <Widget>[];
    for (final ap in _accessPoints!) {
      if (ap.alreadySent) continue;
      var caps = parseCapabilities(ap.ap.capabilities);

      elems.add(Row(children: <Widget>[
        Checkbox(
            value: ap.enabled,
            onChanged: (value) {
              ap.enabled = !ap.enabled;
              setState(() {});
            }),
        Flexible(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ap.ap.ssid),
          Text(caps.join(", ")),
          // Text("freq: ${ap.frequency}, chan: ${ap.channelWidth}"),
        ]))
      ]));
    }

    return ListView(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: elems);
  }
}
