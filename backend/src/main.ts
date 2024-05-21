import http from "http";
import express from "express";
import session from "express-session";
import pg from 'pg'
import connectPgSimple from "connect-pg-simple";
import crypto from 'crypto';

import * as rest from "./rest";
import * as users from "./users";
import * as datapoints from "./datapoints";
import * as comments from "./comments";

const pgSessionStore = connectPgSimple(session);

const dbPool = new pg.Pool({
    host: process.env.PGHOST,
    user: process.env.PGUSER,
    password: process.env.PGPASSWORD,
    database: process.env.PGDATABASE,
    max: 2
});
const db = await dbPool.connect();

const app = express();

app.use(express.json());
app.use(session({
    name: "wifi-wardriving-session-cookieid",
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: {
        expires: null
    },
    store: new pgSessionStore({
        createTableIfMissing: true,
        pool: dbPool
    })
}));

app.get("/", (req, res) => {
    res.setHeader("Content-Type", "application/json");
    res.send("{ \"ok\": true }");
});

app.post("/register", async (req, res) => {
    let resp = await users.registerUser(db, req.session as session.SessionData, req.body);
    res.status(resp.status);
    res.send(resp.data);
});

app.post("/login", async (req, res) => {
    let resp = await users.loginUser(db, req.session as session.SessionData, req.body);
    res.status(resp.status);
    res.send(resp.data);
});

app.post("/logout", async (req, res) => {
    let resp = await users.logoutUser(db, req.session as session.SessionData);
    if (resp.destroySessionData) await new Promise<void>((resolve) => req.session.destroy(() => { resolve(); }));
    res.status(resp.status);
    res.send(resp.data);
});

app.get("/me", async (req, res) => {
    let resp = await users.myUserData(db, req.session as session.SessionData);
    res.status(resp.status);
    res.send(resp.data);
});

app.get("/user", async (req, res) => {
    let resp = await users.userData(db, req.session as session.SessionData, req.query);
    res.status(resp.status);
    res.send(resp.data);
});

app.post("/datapoint", async (req, res) => {
    let resp = await datapoints.submitDatapoint(db, req.session as session.SessionData, req.body);
    res.status(resp.status);
    res.send(resp.data);
});

app.post("/comment", async (req, res) => {
    let resp = await comments.submitComment(db, req.session as session.SessionData, req.body);
    res.status(resp.status);
    res.send(resp.data);
});

app.get("/comment", async (req, res) => {
    let resp = await comments.retrieveComment(db, req.session as session.SessionData, req.query);
    res.status(resp.status);
    res.send(resp.data);
});

app.get("/comments", async (req, res) => {
    let resp = await comments.retrieveAllComments(db, req.session as session.SessionData, req.query);
    res.status(resp.status);
    res.send(resp.data);
});

app.listen(8000, () => {
    console.log("Server running");
});
