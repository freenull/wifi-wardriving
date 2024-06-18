import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";
import 'package:latlong2/latlong.dart';
import "dart:io";
import "dart:async";
import "dart:convert";

class Comment {
  final int id;
  final int submitterId;
  final String content;

  const Comment(this.id, this.submitterId, this.content);

  @override
  String toString() {
    return "[$id] $content";
  }
}

class UserData {
  final int id;
  final String username;

  const UserData(this.id, this.username);

  @override
  String toString() {
    return "[$id] $username";
  }
}

class Datapoint {
  final int? id;
  final LatLng position;
  final String bssid;
  final String ssid;
  final String authType;
  final int submitterId;
  final DateTime? firstSeen;
  final DateTime? lastSeen;

  Datapoint.fromDynamic(dynamic jsonData)
      : id = jsonData["datapoint_id"],
        position = LatLng(jsonData["latitude"], jsonData["longitude"]),
        bssid = jsonData["bssid"],
        ssid = jsonData["ssid"],
        authType = jsonData["auth_type"],
        submitterId = jsonData["submitter"],
        firstSeen = DateTime.fromMillisecondsSinceEpoch(jsonData["first_seen"]),
        lastSeen = DateTime.fromMillisecondsSinceEpoch(jsonData["last_seen"]);

  Datapoint(LatLng position, String bssid, String ssid, String authType)
      : this.id = null,
        this.position = position,
        this.bssid = bssid,
        this.ssid = ssid,
        this.authType = authType,
        this.submitterId = 0,
        this.firstSeen = null,
        this.lastSeen = null;

  String displayName() {
    if (ssid == "") return "<anonymous>";
    return ssid;
  }

  int bssidAsNumber() {
    return int.parse(bssid.split(":").join(""), radix: 16);
  }

  dynamic toDynamic() {
    return {
      "latitude": position.latitude,
      "longitude": position.longitude,
      "bssid": bssidAsNumber(),
      "ssid": ssid,
      "auth_type": authType,
    };
  }
}

class Cluster {
  List<Datapoint> datapoints;
  LatLng position;

  Cluster.fromDynamic(dynamic data)
      : datapoints = List<Datapoint>.from(data["datapoints"]
            .map((datapointData) => Datapoint.fromDynamic(datapointData))),
        position = LatLng(data["latitude"], data["longitude"]);
}

class Achievement {
  DateTime unlockTime;
  String key;

  Achievement.fromDynamic(dynamic data)
      : unlockTime = DateTime.fromMillisecondsSinceEpoch(data["unlock_time"]),
        key = data["key"];
}

class LeaderboardEntry {
  int userId;
  int submittedDatapoints;

  LeaderboardEntry.fromDynamic(dynamic data)
      : userId = data["user_id"],
        submittedDatapoints = data["submitted_datapoints"];
}

class Backend {
  static const String API_PATH = "https://wd.zatherz.eu";
  static const String SESSION_COOKIE_NAME = "wifi-wardriving-session-cookieid";

  static Backend? _instance;
  Backend._ctor();
  factory Backend() => _instance ??= Backend._ctor();

  int? userId;
  String? username;
  StreamController changeAccountController =
      StreamController<String?>.broadcast();
  Stream get changeAccount => changeAccountController.stream;

  Uri url(String resource) {
    return Uri.parse("$API_PATH/$resource");
  }

  void sendError(ScaffoldMessengerState msgr, String msg) {
    msgr.showSnackBar(SnackBar(content: Text("Error: $msg")));
  }

  Future clearSessionCookie(ScaffoldMessengerState msgr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("session");
  }

  Future<bool> storeSessionCookie(
      ScaffoldMessengerState msgr, HttpClientResponse res) async {
    Cookie? sessionCookie = null;
    for (final cookie in res.cookies) {
      if (cookie.name == SESSION_COOKIE_NAME) {
        sessionCookie = cookie;
        break;
      }
    }

    if (sessionCookie == null) {
      sendError(msgr, "Server didn't respond with a session cookie");
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("session", sessionCookie.value);
    return true;
  }

  Future<String?> retrieveSessionCookie(ScaffoldMessengerState msgr) async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString("session");
    if (cookie == null) {
      return null;
    }
    return cookie;
  }

  Future<dynamic> doGet(ScaffoldMessengerState msgr, String resource,
      {bool requireSession = false}) async {
    final sessionCookie = await retrieveSessionCookie(msgr);
    if (sessionCookie == null && requireSession) return null;

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);

    print("get: ${url(resource)}");
    final req = await client.getUrl(url(resource));
    if (sessionCookie != null)
      req.cookies.add(Cookie(SESSION_COOKIE_NAME, sessionCookie));
    req.headers.contentType =
        ContentType("application", "json", charset: "utf-8");
    final res = await req.close();

    final dynamic data =
        await res.transform(utf8.decoder).transform(json.decoder).first;

    if (res.statusCode != 200) {
      if (data != null) {
        final message = data?["message"];
        if (message != null) {
          sendError(msgr, message.toString());
          return null;
        }
      }

      sendError(
          msgr, "server replied with unexpected status code ${res.statusCode}");
      return null;
    }

    return data;
  }

  Future<Map<String, dynamic>?> doPost(
      ScaffoldMessengerState msgr, String resource, dynamic dataToSend,
      {bool setsSessionCookie = false}) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    final req = await client.postUrl(url(resource));
    final sessionCookie = await retrieveSessionCookie(msgr);
    if (sessionCookie != null) {
      req.cookies.add(Cookie(SESSION_COOKIE_NAME, sessionCookie));
    }
    req.headers.contentType =
        ContentType("application", "json", charset: "utf-8");
    req.write(json.encode(dataToSend));
    final res = await req.close();

    final dynamic data =
        await res.transform(utf8.decoder).transform(json.decoder).first;

    if (res.statusCode != 200) {
      if (data != null) {
        final message = data?["message"];
        if (message != null) {
          sendError(msgr, message.toString());
          return null;
        }
      }

      sendError(
          msgr, "server replied with unexpected status code ${res.statusCode}");
      return null;
    }

    if (setsSessionCookie) {
      storeSessionCookie(msgr, res);
    }

    return data;
  }

  Future<Map<String, dynamic>?> doDelete(
      ScaffoldMessengerState msgr, String resource,
      {bool setsSessionCookie = false}) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    final req = await client.deleteUrl(url(resource));
    final sessionCookie = await retrieveSessionCookie(msgr);
    if (sessionCookie != null) {
      req.cookies.add(Cookie(SESSION_COOKIE_NAME, sessionCookie));
    }
    final res = await req.close();

    final dynamic data =
        await res.transform(utf8.decoder).transform(json.decoder).first;
    if (res.statusCode != 200) {
      if (data != null) {
        final message = data?["message"];
        if (message != null) {
          sendError(msgr, message.toString());
          return null;
        }
      }

      sendError(
          msgr, "server replied with unexpected status code ${res.statusCode}");
      return null;
    }

    if (setsSessionCookie) {
      storeSessionCookie(msgr, res);
    }

    return data;
  }

  Future<bool> ensureUserDataRetrieved(ScaffoldMessengerState msgr) async {
    if (username != null) return true;

    final data = await doGet(msgr, "users/session", requireSession: true);
    if (data == null) return false;

    username = data["username"].toString();
    userId = data["user_id"];
    return true;
  }

  Future<bool> isLoggedIn(ScaffoldMessengerState msgr) async {
    await ensureUserDataRetrieved(msgr);
    return username != null;
  }

  Future<bool> registerAccount(ScaffoldMessengerState msgr, String username,
      String password, bool rememberMe) async {
    if (await isLoggedIn(msgr)) {
      sendError(msgr, "Already logged in.");
      return false;
    }

    final data = await doPost(msgr, "users",
        {"username": username, "password": password, "remember_me": rememberMe},
        setsSessionCookie: true);
    if (data == null) return false;

    userId = data["user_id"];
    await ensureUserDataRetrieved(msgr);
    changeAccountController.add(this.username);

    return true;
  }

  Future<bool> loginAccount(ScaffoldMessengerState msgr, String username,
      String password, bool rememberMe) async {
    if (await isLoggedIn(msgr)) {
      sendError(msgr, "Already logged in.");
      return false;
    }

    final data = await doPost(msgr, "users/$username",
        {"password": password, "remember_me": rememberMe},
        setsSessionCookie: true);
    if (data == null) return false;

    userId = data["user_id"];
    await ensureUserDataRetrieved(msgr);
    print("fire ev");
    changeAccountController.add(this.username);

    return true;
  }

  Future<bool> logoutAccount(ScaffoldMessengerState msgr) async {
    if (!await isLoggedIn(msgr)) {
      sendError(msgr, "Must be logged in to log out.");
      return false;
    }

    final data = await doDelete(msgr, "users/session");
    if (data == null) return false;

    await clearSessionCookie(msgr);
    userId = null;
    username = null;
    changeAccountController.add(username);

    return true;
  }

  Future<UserData?> userData(ScaffoldMessengerState msgr, int userId) async {
    final data = await doGet(msgr, "users/$userId");
    if (data == null) return null;

    return UserData(userId, data["username"]);
  }

  Future<List<Comment>?> retrieveAllComments(
      ScaffoldMessengerState msgr, int datapointId) async {
    final data = await doGet(msgr, "datapoints/$datapointId/comments");
    if (data == null) return null;

    final List<Comment> commentsList = [];
    for (final comment in data["comments"]) {
      commentsList.add(Comment(
          comment["comment_id"], comment["submitter_id"], comment["content"]));
    }

    return commentsList;
  }

  Future<bool> sendComment(
      ScaffoldMessengerState msgr, int datapointId, String comment) async {
    if (!await isLoggedIn(msgr)) {
      sendError(msgr, "Must be logged in to post comments.");
      return false;
    }

    final data = await doPost(
        msgr, "datapoints/$datapointId/comments", {"content": comment});
    if (data == null) return false;

    return true;
  }

  Future<List<Datapoint>?> retrieveDatapoints(
      ScaffoldMessengerState msgr, LatLng center) async {
    final data =
        await doGet(msgr, "datapoints/${center.latitude}/${center.longitude}");
    if (data == null) return null;

    final List<Datapoint> datapointsList = [];
    for (final datapoint in data) {
      datapointsList.add(Datapoint.fromDynamic(datapoint));
    }

    return datapointsList;
  }

  Future<List<Cluster>?> retrieveClusters(
      ScaffoldMessengerState msgr, LatLng center) async {
    final data =
        await doGet(msgr, "clusters/${center.latitude}/${center.longitude}");
    if (data == null) return null;

    final List<Cluster> clusterList = [];
    for (final cluster in data) {
      clusterList.add(Cluster.fromDynamic(cluster));
    }

    return clusterList;
  }

  Future<Datapoint?> retrieveDatapoint(
      ScaffoldMessengerState msgr, int datapointId) async {
    final data = await doGet(msgr, "datapoints/${datapointId}");
    if (data == null) return null;

    return Datapoint.fromDynamic(data);
  }

  Future<bool> sendDatapoint(
      ScaffoldMessengerState msgr, Datapoint datapoint) async {
    var postData = datapoint.toDynamic();
    postData["submitter"] = userId;
    var result = await doPost(msgr, "datapoints", postData);
    if (result == null) return false;
    return true;
  }

  Future<List<Achievement>?> retrieveOwnAchievements(
      ScaffoldMessengerState msgr) async {
    if (!await isLoggedIn(msgr)) {
      sendError(msgr, "Must be logged in to retrieve own achievements.");
      return null;
    }
    await ensureUserDataRetrieved(msgr);

    final data = await doGet(msgr, "users/$userId/achievements");
    if (data == null) return null;

    return List<Achievement>.from(
        data.map((achiev) => Achievement.fromDynamic(achiev)));
  }

  Future<List<LeaderboardEntry>?> retrieveLeaderboard(
      ScaffoldMessengerState msgr, int limit) async {
    final data = await doGet(msgr, "users/leaderboard?start=0&limit=$limit");
    if (data == null) return null;

    return List<LeaderboardEntry>.from(
        data.map((achiev) => LeaderboardEntry.fromDynamic(achiev)));
  }
}
