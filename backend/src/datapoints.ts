import pg from "pg";
import * as rest from "./rest";
import session from "express-session";

export enum AuthType
{
    None,
    WEP,
    WPA,
    WPA2
}

export interface SubmitRequest
{
    latitude?: number;
    longitude?: number;

    ssid?: string;
    auth_type?: AuthType;
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
    if (req.auth_type === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'auth_type'");

    let result = await db.query("insert into datapoints (latitude, longitude, ssid, auth_type, submitter, first_seen, last_seen) values ($1, $2, $3, $4, $5, now(), now()) returning datapoint_id;", [
        req.latitude, req.longitude,
        req.ssid, req.auth_type,
        sessionData.userId
    ]);
    if (result.rows.length < 1)
    {
        return rest.errorResponse(rest.ErrorCode.DbFail, "Failed adding datapoint to database");
    }

    let datapointId = result.rows[0].datapoint_id;

    return new rest.Response(200, { "datapoint_id": datapointId });
}
