import pg from "pg";
import session from "express-session";

import * as rest from "./rest";
import * as engagement from "./engagement";

export interface SubmitRequest
{
    latitude?: number;
    longitude?: number;

    ssid?: string;
    bssid?: number;
    auth_type?: string;
    cluster_max_distance?: number;
}

export interface RetrieveRequest
{
    latitude?: number;
    longitude?: number;
    radius?: number;
}

export interface RetrieveClustersRequest
{
    latitude?: number;
    longitude?: number;
    radius?: number;
    cluster_max_distance?: number;
}

export interface RetrieveByIdRequest
{
    datapoint_id?: number;
    radius?: number;
}

function validateAuthType(authType : string) {
    switch(authType) {
    case "none": return true;
    case "wep": return true;
    case "wpa": return true;
    case "wpa2": return true;
    default:
        return false;
    }
}

function macDecimalToHex(mac : number) {
    return mac.toString(16).padStart(12, "0").match(/../g).reverse().slice(0, 6).reverse().join(":");
}

export async function submitDatapoint(db : pg.PoolClient, sessionData : session.SessionData, req : SubmitRequest) : Promise<rest.Response>
{
    if (sessionData.userId === undefined)
    {
        return rest.errorResponse(rest.ErrorCode.LoginOnly, "Must be logged in to use this endpoint");
    }

    if (req.latitude === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'latitude'");
    if (req.longitude === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'longitude'");
    if (req.ssid === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'ssid'");
    if (req.bssid === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'bssid'");
    if (req.auth_type === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'auth_type'");
    if (!validateAuthType(req.auth_type)) return rest.errorResponse(rest.ErrorCode.InvalidAuthType, `Invalid authentication type '${req.auth_type}'`);

    let result = await db.query("update datapoints set last_seen = now() where earth_distance(ll_to_earth(latitude, longitude), ll_to_earth($1, $2)) <= $3 and bssid = $4::macaddr returning datapoint_id;", [
        req.latitude, req.longitude,
        req.cluster_max_distance ?? 100,
        macDecimalToHex(req.bssid)
    ]);
    if (result.rows.length > 0) {
        return new rest.Response(200, { "datapoint_id": result.rows[0].datapoint_id });
    }

    result = await db.query("insert into datapoints (latitude, longitude, ssid, bssid, auth_type, submitter, first_seen, last_seen) values ($1, $2, $3, $4, $5, $6, now(), now()) returning datapoint_id;", [
        req.latitude, req.longitude,
        req.ssid, macDecimalToHex(req.bssid), req.auth_type,
        sessionData.userId
    ]);

    if (result.rows.length < 1)
    {
        return rest.errorResponse(rest.ErrorCode.DbFail, "Failed adding datapoint to database");
    }

    let datapointId = result.rows[0].datapoint_id;

    await engagement.checkAndGrantAchievementsFor(db, sessionData.userId);
    return new rest.Response(200, { "datapoint_id": datapointId });
}

export async function retrieveDatapoint(db : pg.PoolClient, sessionData : session.SessionData, req : RetrieveByIdRequest) : Promise<rest.Response>
{
    if (req.datapoint_id === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'datapoint_id'");

    let result = await db.query("select latitude, longitude, ssid, bssid, auth_type, submitter, first_seen, last_seen from datapoints where datapoint_id = $1;", [
        req.datapoint_id
    ]);

    if (result.rows.length < 1)
    {
        return rest.errorResponse(rest.ErrorCode.InvalidDatapointId, `Datapoint with ID ${req.datapoint_id} doesn't exist`);
    }

    let row = result.rows[0];
    return new rest.Response(200, {
        datapoint_id: req.datapoint_id,
        latitude: row.latitude,
        longitude: row.longitude,
        ssid: row.ssid,
        bssid: row.bssid,
        auth_type: row.auth_type,
        submitter: row.submitter,
        first_seen: row.first_seen.getTime(),
        last_seen: row.last_seen.getTime(),
    });
}

export async function retrieveDatapoints(db : pg.PoolClient, sessionData : session.SessionData, req : RetrieveRequest) : Promise<rest.Response>
{
    if (req.latitude === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'latitude'");
    if (req.longitude === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'longitude'");

    let result = await db.query("select datapoint_id, latitude, longitude, ssid, bssid, auth_type, submitter, first_seen, last_seen from datapoints where earth_distance(ll_to_earth(latitude, longitude), ll_to_earth($1, $2)) <= $3;", [
        req.latitude, req.longitude,
        req.radius ?? 10000
    ]);

    if (result.rows.length < 1)
    {
        return new rest.Response(200, []);
    }

    let datapoints = [];
    for (let row of result.rows) {
        datapoints.push({
            datapoint_id: row.datapoint_id,
            latitude: row.latitude,
            longitude: row.longitude,
            ssid: row.ssid,
            bssid: row.bssid,
            auth_type: row.auth_type,
            submitter: row.submitter,
            first_seen: row.first_seen.getTime(),
            last_seen: row.last_seen.getTime(),
        });
    }

    return new rest.Response(200, datapoints);
}

function earthDistance(lat1 : number, long1 : number, lat2 : number, long2 : number){
    // Formula adapted from
    // https://stackoverflow.com/a/11172685
    
    var R = 6378137;
    var dLat = lat2 * Math.PI / 180 - lat1 * Math.PI / 180;
    var dLon = long2 * Math.PI / 180 - long1 * Math.PI / 180;
    var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2);
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    var d = R * c;
    return d;
}

export async function retrieveClusters(db : pg.PoolClient, sessionData : session.SessionData, req : RetrieveClustersRequest) : Promise<rest.Response>
{
    var resp = await retrieveDatapoints(db, sessionData, req);
    if (resp.status != 200) return resp;

    var cluster_max_distance = req.cluster_max_distance ?? 100;

    var clusters = [];
    for (let datapoint of resp.data) {
        let foundAny = false;

        for (let cluster of clusters) {
            var distance = earthDistance(cluster.latitude, cluster.longitude, datapoint.latitude, datapoint.longitude);
            if (distance <= cluster_max_distance) {
                cluster.datapoints.push(datapoint);
                foundAny = true;
                break;
            }
        }

        if (!foundAny) {
            clusters.push({
                latitude: datapoint.latitude,
                longitude: datapoint.longitude,
                datapoints: [ datapoint ]
            });
        }
    }

    return new rest.Response(200, clusters);
}
