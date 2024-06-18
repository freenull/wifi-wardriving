/* Authors:
 * - Dominik Banaszak
 * - Jakub Utko
 * - Oliwier Strachota
 */

import http from "http";
import express from "express";
import session from "express-session";
import pg from "pg";
import connectPgSimple from "connect-pg-simple";
import crypto from "crypto";
import swaggerJsDoc from "swagger-jsdoc";
import swaggerUiExpress from "swagger-ui-express";
import path from "path";
import url from "url";

import * as rest from "./rest";
import * as users from "./users";
import * as datapoints from "./datapoints";
import * as comments from "./comments";
import * as engagement from "./engagement";

const __filename = url.fileURLToPath(import.meta.url);
console.log(__filename);

const swaggerSpec = swaggerJsDoc({
    swaggerDefinition: {
        openapi: "3.0.0",
        info: {
            title: "API for WiFi Wardriving",
            version: "1.0.0",
        },
    },
    apis: ["**/*.ts"],
});

const pgSessionStore = connectPgSimple(session);

const dbPool = new pg.Pool({
    host: process.env.PGHOST,
    user: process.env.PGUSER,
    password: process.env.PGPASSWORD,
    database: process.env.PGDATABASE,
    max: 2,
});
const db = await dbPool.connect();

const app = express();

app.use(express.json());
app.use(
    session({
        name: "wifi-wardriving-session-cookieid",
        secret: process.env.SESSION_SECRET,
        resave: false,
        saveUninitialized: false,
        cookie: {
            expires: null,
        },
        store: new pgSessionStore({
            createTableIfMissing: true,
            pool: dbPool,
        }),
    }),
);

app.use("/api", swaggerUiExpress.serve, swaggerUiExpress.setup(swaggerSpec));

app.get("/", (req, res) => {
    res.setHeader("Content-Type", "application/json");
    res.send('{ "ok": true }');
});

/**
 * @swagger
 * /users:
 *   post:
 *     summary: Register a new account
 *     description: Register a new account.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               username:
 *                 type: string
 *                 description: Desired username
 *               password:
 *                 type: string
 *                 description: Desired password
 *               remember_me:
 *                 type: boolean
 *                 description: If true, session expiration is extended to a month
 *     responses:
 *       200:
 *         description: Registered
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 user_id:
 *                   type: integer
 *                   description: Numeric user ID
 *
 *       400:
 *         description: User error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Human readable error message
 *                 code:
 *                   type: integer
 *                   description: Numeric error code
 *
 */
app.post("/users", async (req, res) => {
    let resp = await users.registerUser(
        db,
        req.session as session.SessionData,
        req.body,
    );
    res.status(resp.status);
    res.send(resp.data);
});

/**
 * @swagger
 * /users/{username}:
 *   post:
 *     summary: Login into an existing account
 *     description: Login into an existing account.
 *     parameters:
 *       - in: path
 *         name: username
 *         required: true
 *         description: Username of the account
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               password:
 *                 type: string
 *                 required: true
 *                 description: Password
 *               remember_me:
 *                 type: boolean
 *                 required: true
 *                 description: If true, session expiration is extended to a month
 *     responses:
 *       200:
 *         description: Logged in
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 user_id:
 *                   type: integer
 *                   description: Numeric user ID
 *
 *       400:
 *         description: User error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Human readable error message
 *                 code:
 *                   type: integer
 *                   description: Numeric error code
 *
 */
app.post("/users/:username", async (req, res) => {
    let resp = await users.loginUser(db, req.session as session.SessionData, {
        username: req.params.username,
        password: req.body.password,
        remember_me: req.body.remember_me,
    });
    res.status(resp.status);
    res.send(resp.data);
});

/**
 * @swagger
 * /users/session:
 *   get:
 *     summary: Get information about current session
 *     description: Get information about current session. Must be logged in.
 *     responses:
 *       200:
 *         description: Session exists
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 user_id:
 *                   type: integer
 *                   description: Numeric user ID
 *                 username:
 *                   type: string
 *                   description: Username
 *
 *       400:
 *         description: User error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Human readable error message
 *                 code:
 *                   type: integer
 *                   description: Numeric error code
 *
 */
app.get("/users/session", async (req, res) => {
    let resp = await users.myUserData(db, req.session as session.SessionData);
    res.status(resp.status);
    res.send(resp.data);
});

/**
 * @swagger
 * /users/leaderboard:
 *   get:
 *     summary: Retrieve users sorted by amount of networks submitted
 *     description: Retrieve users sorted by amount of networks submitted.
 *     parameters:
 *       - in: query
 *         name: start
 *         type: number
 *         required: false
 *         default: 0
 *         description: Offset into the list
 *       - in: query
 *         name: limit
 *         type: number
 *         required: false
 *         default: 100
 *         max: 100
 *         description: Maximum amount of entries to return
 *
 *     responses:
 *       200:
 *         description: User exists
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   user_id:
 *                     type: int
 *                     description: ID of the user
 *                   submitted_datapoints:
 *                     type: int
 *                     description: Number of new datapoints submitted by the user
 *
 *
 *       400:
 *         description: User error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Human readable error message
 *                 code:
 *                   type: integer
 *                   description: Numeric error code
 *
 */
app.get("/users/leaderboard", async (req, res) => {
    let resp = await engagement.retrieveLeaderboard(
        db,
        req.session as session.SessionData,
        {
            limit:
                req.query?.limit !== undefined
                    ? Number(req.query?.limit)
                    : undefined,
            start:
                req.query?.start !== undefined
                    ? Number(req.query?.start)
                    : undefined,
        },
    );
    res.status(resp.status);
    res.send(resp.data);
});

/**
 * @swagger
 * /users/{userid}:
 *   get:
 *     summary: Get information about a user with a particular ID
 *     description: Get information about a user with a particular ID.
 *     parameters:
 *       - in: path
 *         name: userid
 *         required: true
 *         description: Numeric ID of the user
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: User exists
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 username:
 *                   type: string
 *                   description: The user's username
 *
 *       400:
 *         description: User error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Human readable error message
 *                 code:
 *                   type: integer
 *                   description: Numeric error code
 *
 */
app.get("/users/:userid", async (req, res) => {
    let resp = await users.userData(db, req.session as session.SessionData, {
        user_id: Number(req.params.userid),
    });
    res.status(resp.status);
    res.send(resp.data);
});

/**
 * @swagger
 * /users/{userid}/achievements:
 *   get:
 *     summary: Retrieve achievements unlocked by a user with a particular ID
 *     description: Retrieve achievements unlocked by a user with a particular ID.
 *     parameters:
 *       - in: path
 *         name: userid
 *         required: true
 *         description: Numeric ID of the user
 *         schema:
 *           type: integer
 *
 *     responses:
 *       200:
 *         description: User exists
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   key:
 *                     type: string
 *                     description: Unique key identifying the achievement
 *                   unlock_time:
 *                     type: number
 *                     description: Timestamp of when the achievement was unlocked
 *
 *
 *       400:
 *         description: User error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Human readable error message
 *                 code:
 *                   type: integer
 *                   description: Numeric error code
 *
 */
app.get("/users/:userid/achievements", async (req, res) => {
    let resp = await engagement.retrieveAchievements(
        db,
        req.session as session.SessionData,
        { user_id: Number(req.params.userid) },
    );
    res.status(resp.status);
    res.send(resp.data);
});

/**
 * @swagger
 * /users/session:
 *   delete:
 *     summary: Log out of the current session
 *     description: Log out of the current session. Must be logged in.
 *     responses:
 *       200:
 *         description: Logged out
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *
 *       400:
 *         description: User error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Human readable error message
 *                 code:
 *                   type: integer
 *                   description: Numeric error code
 *
 */
app.delete("/users/session", async (req, res) => {
    let resp = await users.logoutUser(db, req.session as session.SessionData);
    if (resp.destroySessionData)
        await new Promise<void>((resolve) =>
            req.session.destroy(() => {
                resolve();
            }),
        );
    res.status(resp.status);
    res.send(resp.data);
});

/**
 * @swagger
 * /datapoints:
 *   post:
 *     summary: Submit a new data point
 *     description: Submit a new data point. Must be logged in.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               latitude:
 *                 type: number
 *                 required: true
 *                 description: Latitude of the data point
 *               longitude:
 *                 type: number
 *                 required: true
 *                 description: Longitude of the data point
 *               ssid:
 *                 type: string
 *                 required: true
 *                 description: SSID of the network
 *               bssid:
 *                 type: number
 *                 required: true
 *                 description: BSSID of the network
 *               auth_type:
 *                 type: string
 *                 required: true
 *                 description: BSSID of the network
 *                 enum: [none, wep, wpa, wpa2]
 *     responses:
 *       200:
 *         description: Submitted
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 datapoint_id:
 *                   type: integer
 *                   description: Numeric datapoint ID
 *
 *       400:
 *         description: User error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Human readable error message
 *                 code:
 *                   type: integer
 *                   description: Numeric error code
 *
 */
app.post("/datapoints", async (req, res) => {
    let resp = await datapoints.submitDatapoint(
        db,
        req.session as session.SessionData,
        req.body,
    );
    res.status(resp.status);
    res.send(resp.data);
});

/**
 * @swagger
 * /datapoints/{lat}/{long}:
 *   get:
 *     summary: Retrieve data points
 *     description: Retrieve data points.
 *     parameters:
 *       - in: path
 *         name: lat
 *         required: true
 *         description: Latitude of the center of the scan area
 *         schema:
 *           type: number
 *       - in: path
 *         name: long
 *         required: true
 *         description: Longitude of the center of the scan area
 *         schema:
 *           type: number
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               radius:
 *                 type: number
 *                 required: true
 *                 description: Radius (in m) of the circular scan area
 *                 default: 10000
 *                 max: 20000
 *     responses:
 *       200:
 *         description: Retrieved
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   datapoint_id:
 *                     type: integer
 *                     description: Numeric datapoint ID
 *                   latitude:
 *                     type: integer
 *                     description: Latitude of the datapoint
 *                   longitude:
 *                     type: integer
 *                     description: Longitude of the datapoint
 *                   ssid:
 *                     type: string
 *                     description: SSID
 *                   bssid:
 *                     type: integer
 *                     description: BSSID
 *                   auth_type:
 *                     type: string
 *                     description: Authentication type
 *                     enum: [none, wep, wpa, wpa2]
 *                   submitter:
 *                     type: integer
 *                     description: Submitter's user ID
 *       400:
 *         description: User error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Human readable error message
 *                 code:
 *                   type: integer
 *                   description: Numeric error code
 *
 */
app.get("/datapoints/:lat/:long", async (req, res, next) => {
    var lat = Number(req.params.lat);
    var long = Number(req.params.long);
    if (Number.isNaN(lat) || Number.isNaN(long)) {
        console.log("go next");
        next();
        return;
    }

    let resp = await datapoints.retrieveDatapoints(
        db,
        req.session as session.SessionData,
        {
            latitude: lat,
            longitude: long,
            radius: req.body.radius,
        },
    );
    res.status(resp.status);
    res.send(resp.data);
});

/**
 * @swagger
 * /datapoints/{datapointid}:
 *   get:
 *     summary: Retrieve a data point by ID
 *     description: Retrieve a data point by ID.
 *     parameters:
 *       - in: path
 *         name: datapointid
 *         required: true
 *         description: ID of the datapoint
 *         schema:
 *           type: number
 *     responses:
 *       200:
 *         description: Retrieved
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 datapoint_id:
 *                   type: integer
 *                   description: Numeric datapoint ID
 *                 latitude:
 *                   type: integer
 *                   description: Latitude of the datapoint
 *                 longitude:
 *                   type: integer
 *                   description: Longitude of the datapoint
 *                 ssid:
 *                   type: string
 *                   description: SSID
 *                 bssid:
 *                   type: integer
 *                   description: BSSID
 *                 auth_type:
 *                   type: string
 *                   description: Authentication type
 *                   enum: [none, wep, wpa, wpa2]
 *                 submitter:
 *                   type: integer
 *                   description: Submitter's user ID
 *       400:
 *         description: User error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Human readable error message
 *                 code:
 *                   type: integer
 *                   description: Numeric error code
 *
 */
app.get("/datapoints/:datapointid", async (req, res, next) => {
    var id = Number(req.params.datapointid);

    let resp = await datapoints.retrieveDatapoint(
        db,
        req.session as session.SessionData,
        {
            datapoint_id: id,
        },
    );
    res.status(resp.status);
    res.send(resp.data);
});

/**
 * @swagger
 * /datapoints/{datapointid}/comments:
 *   post:
 *     summary: Submit a comment on a datapoint
 *     description: Submit a comment on a datapoint. Must be logged in.
 *     parameters:
 *       - in: path
 *         name: datapointid
 *         required: true
 *         description: Numeric ID of the datapoint
 *         schema:
 *           type: number
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               content:
 *                 type: string
 *                 required: true
 *                 description: Content of the comment
 *     responses:
 *       200:
 *         description: Submitted
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   comment_id:
 *                     type: integer
 *                     description: Numeric comment ID
 *                   submitter_id:
 *                     type: integer
 *                     description: Numeric user ID of the submitter
 *                   content:
 *                     type: string
 *                     description: Comment text
 *       400:
 *         description: User error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Human readable error message
 *                 code:
 *                   type: integer
 *                   description: Numeric error code
 *
 */
app.post("/datapoints/:datapointid/comments", async (req, res) => {
    let resp = await comments.submitComment(
        db,
        req.session as session.SessionData,
        {
            datapoint_id: Number(req.params.datapointid),
            content: req.body.content,
        },
    );
    res.status(resp.status);
    res.send(resp.data);
});

/**
 * @swagger
 * /clusters/{lat}/{long}:
 *   get:
 *     summary: Retrieve clusters of data points
 *     description: Retrieve clusters of data points.
 *     parameters:
 *       - in: path
 *         name: lat
 *         required: true
 *         description: Latitude of the center of the scan area
 *         schema:
 *           type: number
 *       - in: path
 *         name: long
 *         required: true
 *         description: Longitude of the center of the scan area
 *         schema:
 *           type: number
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               radius:
 *                 type: number
 *                 required: true
 *                 description: Radius (in m) of the circular scan area
 *                 default: 10000
 *                 max: 20000
 *               cluster_max_distance:
 *                 type: number
 *                 required: true
 *                 description: Max distance between datapoints to form a cluster
 *     responses:
 *       200:
 *         description: Retrieved
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   latitude:
 *                     type: integer
 *                     description: Latitude of the datapoint
 *                   longitude:
 *                     type: integer
 *                     description: Longitude of the datapoint
 *                   datapoints:
 *                      type: array
 *                      description: List of datapoint objects within this cluster
 *                      items:
 *                        type: object
 *                        properties:
 *                          datapoint_id:
 *                            type: integer
 *                            description: Numeric datapoint ID
 *                          latitude:
 *                            type: integer
 *                            description: Latitude of the datapoint
 *                          longitude:
 *                            type: integer
 *                            description: Longitude of the datapoint
 *                          ssid:
 *                            type: string
 *                            description: SSID
 *                          bssid:
 *                            type: integer
 *                            description: BSSID
 *                          auth_type:
 *                            type: string
 *                            description: Authentication type
 *                            enum: [none, wep, wpa, wpa2]
 *                          submitter:
 *                            type: integer
 *                            description: Submitter's user ID
 *       400:
 *         description: User error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Human readable error message
 *                 code:
 *                   type: integer
 *                   description: Numeric error code
 *
 */
app.get("/clusters/:lat/:long", async (req, res, next) => {
    var lat = Number(req.params.lat);
    var long = Number(req.params.long);
    if (Number.isNaN(lat) || Number.isNaN(long)) {
        next();
        return;
    }

    let resp = await datapoints.retrieveClusters(
        db,
        req.session as session.SessionData,
        {
            latitude: lat,
            longitude: long,
            radius: req.body.radius,
            cluster_max_distance: req.body.cluster_max_distance,
        },
    );
    res.status(resp.status);
    res.send(resp.data);
});

/**
 * @swagger
 * /comments/{commentid}:
 *   get:
 *     summary: Retrieve comment by numeric ID
 *     description: Retrieve comment by numeric ID.
 *     parameters:
 *       - in: path
 *         name: commentid
 *         required: true
 *         description: Numeric ID of the comment
 *         schema:
 *           type: number
 *     responses:
 *       200:
 *         description: Retrieved
 *         content:
 *           application/json:
 *             type: object
 *             properties:
 *               comment_id:
 *                 type: integer
 *                 description: Numeric comment ID
 *               submitter_id:
 *                 type: integer
 *                 description: Numeric user ID of the submitter
 *               content:
 *                 type: string
 *                 description: Comment text
 *       400:
 *         description: User error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Human readable error message
 *                 code:
 *                   type: integer
 *                   description: Numeric error code
 *
 */
app.get("/comments/:commentid", async (req, res) => {
    let resp = await comments.retrieveComment(
        db,
        req.session as session.SessionData,
        {
            comment_id: Number(req.params.commentid),
        },
    );
    res.status(resp.status);
    res.send(resp.data);
});

/**
 * @swagger
 * /datapoints/{datapointid}/comments:
 *   get:
 *     summary: Retrieve comments on a datapoint
 *     description: Retrieve comments on a datapoint.
 *     parameters:
 *       - in: path
 *         name: datapointid
 *         required: true
 *         description: Numeric ID of the datapoint
 *         schema:
 *           type: number
 *     responses:
 *       200:
 *         description: Retrieved
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   comment_id:
 *                     type: integer
 *                     description: Numeric comment ID
 *                   submitter_id:
 *                     type: integer
 *                     description: Numeric user ID of the submitter
 *                   content:
 *                     type: string
 *                     description: Comment text
 *       400:
 *         description: User error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Human readable error message
 *                 code:
 *                   type: integer
 *                   description: Numeric error code
 *
 */
app.get("/datapoints/:datapointid/comments", async (req, res) => {
    let resp = await comments.retrieveAllComments(
        db,
        req.session as session.SessionData,
        {
            datapoint_id: Number(req.params.datapointid),
        },
    );
    res.status(resp.status);
    res.send(resp.data);
});

app.listen(8000, () => {
    console.log("Server running");
});
