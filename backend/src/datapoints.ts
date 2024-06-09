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
}

export interface RetrieveRequest
{
    latitude?: number;
    longitude?: number;
    radius?: number;
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

    let result = await db.query("insert into datapoints (latitude, longitude, ssid, bssid, auth_type, submitter, first_seen, last_seen) values ($1, $2, $3, $4, $5, $6, now(), now()) returning datapoint_id;", [
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
    if (sessionData.userId === undefined)
    {
        return rest.errorResponse(rest.ErrorCode.LoginOnly, "Must be logged in to use this endpoint");
    }

    if (req.datapoint_id === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'datapoint_id'");

    let result = await db.query("select latitude, longitude, ssid, bssid, auth_type, submitter from datapoints where datapoint_id = $1;", [
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
    });
}

export async function retrieveDatapoints(db : pg.PoolClient, sessionData : session.SessionData, req : RetrieveRequest) : Promise<rest.Response>
{
    if (sessionData.userId === undefined)
    {
        return rest.errorResponse(rest.ErrorCode.LoginOnly, "Must be logged in to use this endpoint");
    }

    if (req.latitude === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'latitude'");
    if (req.longitude === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'longitude'");

    let result = await db.query("select datapoint_id, latitude, longitude, ssid, bssid, auth_type, submitter from datapoints where earth_distance(ll_to_earth(latitude, longitude), ll_to_earth($1, $2)) <= $3;", [
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
        });
    }

    return new rest.Response(200, datapoints);
}
