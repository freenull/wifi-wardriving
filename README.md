# WiFi Wardriving

Android application for WiFi wardriving, with features such as user accounts and an interactive map.

Developed as part of the Mobile applications course at the Wrocław University of Science and Technology.

## Frontend

The frontend is built with Flutter using the Dart programming language. It is intended to be built for Android only.

### Building

You must either set up an emulator or a real device connection in Flutter and the environment according to the [official documentation](https://docs.flutter.dev/get-started/install).

To build the project, use:

```sh
flutter build apk
```

To install, run:
```sh
flutter install -d <DEVICE>
```

Alternatively, you can run it with live debugging using the following command:
```sh
flutter run -d <DEVICE>
```

### Layout

* `android` contains Gradle scripts generated by Flutter.
* `assets` contains assets packaged with the application.
* `lib` contains the Dart source code.
  * `achievements.dart` contains code related to the user achievements view.
  * `backend.dart` contains code for interfacing with the Node backend.
  * `discussion.dart` contains code implementing the network details and comments view.
  * `leaderboard.dart` contains the global leaderboard view.
  * `main.dart` contains the main interactive map view and is the entry point for the application.
  * `networks.dart` contains code implementing the network submit view.
  * `user.dart` contains code implementing the login/register page.
* `web` contains files related to the web export. The web export is possible, but not officially supported.
* `pubspec.yaml` contains configuration of the Flutter project and a list of Dart dependencies.
* `analysis_options.yaml` contains options related to Dart static analysis.

## Backend

The backend is built with Node using the TypeScript programming language. It was written primarily to run on Linux, but should work on other operating systems.

### Building

To build the project, pull dependencies first:

```sh
npm install
```

PostgreSQL must be running. To initialize the database, run the `init.sql` file with:
```sh
psql -U postgres -v "password='PASSWORD'" -f init.sql
```

Replace `PASSWORD` with the desired password for the new dedicated database user `wifiwardriving`.

To run the server, you must place an `.env` file in the `backend` directory with the following contents:
```
PGHOST=localhost
PGUSER=wifiwardriving
PGPASSWORD=
PGDATABASE=wifiwardriving
SESSION_SECRET=
```

Fill in the `PGPASSWORD` field with the password passed to `psql` in the previous command. Fill in `SESSION_SECRET` with a randomly generated password. This password will be used to encrypt session data.

Finally, run with the `start` script:

```sh
npm run start
```

This will run the project using `npx` on the local interface on port 8000. There is no way to change the port from the commandline.

### Layout

* `src` contains the TypeScript source code.
  * `comments.ts` contains code related to the discussion page feature.
  * `datapoints.ts` contains code related to storage and accessing of network datapoints.
  * `engagement.ts` contains code related to achievements and the leaderboard.
  * `main.ts` contains the server's entry point.
  * `rest.ts` contains primitives related to REST API results and error codes.
  * `users.ts` contains code related to authentication, user login and registration.
* `init.sql` contains SQL code intended to be run in a PostgreSQL server to initialize the database. The script can be ran again to reset the state of the database.
* `package.json` contains the Node package configuration and dependency list.
* `tsconfig.json` contains TypeScript language configuration.
