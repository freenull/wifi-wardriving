import pg from "pg";
import * as rest from "./rest";
import session from "express-session";

export async function grantAchievement(db : pg.PoolClient, userId : number, key : string) : Promise<number | null>
{
    let result = await db.query("insert into achievements (recipient, key, unlock_time) values ($1, $2, now()) on conflict (recipient, key) do nothing returning achievement_id;", [
        userId, key
    ]);

    if (result.rows.length < 1) return null;
    return result.rows[0].achievement_id;
}

export async function getNetworkCountFor(db : pg.PoolClient, userId : number) {
    let result = await db.query("select count(*)::int as count from datapoints left join users on users.user_id = datapoints.submitter where user_id = $1;", [ userId ]);
    return result.rows[0].count;
}

export async function checkAndGrantAchievementsFor(db : pg.PoolClient, userId : number) {
    let networkCount = await getNetworkCountFor(db, userId);
    if (networkCount >= 100) await grantAchievement(db, userId, "networks_100");
    else if (networkCount >= 10) await grantAchievement(db, userId, "networks_10");
    else if (networkCount >= 1) await grantAchievement(db, userId, "networks_1");

    let commentCount = await getCommentCountFor(db, userId);
    if (commentCount >= 100) await grantAchievement(db, userId, "comments_100");
    else if (commentCount >= 10) await grantAchievement(db, userId, "comments_10");
    else if (commentCount >= 1) await grantAchievement(db, userId, "comments_1");
}

export async function getCommentCountFor(db : pg.PoolClient, userId : number) {
    let result = await db.query("select count(*)::int as count from comments left join users on users.user_id = comments.submitter where user_id = $1;", [ userId ]);
    return result.rows[0].count;
}

export interface RetrieveAchievementsRequest {
    user_id?: number;
}

export async function retrieveAchievements(db : pg.PoolClient, sessionData : session.SessionData, req : RetrieveAchievementsRequest) : Promise<rest.Response>
{
    if (req.user_id === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'user_id'");

    let result = await db.query("select key, unlock_time from achievements where recipient = $1;", [ req.user_id ]);

    let achievs = [];
    for (let row of result.rows) {
        achievs.push({ key: row.key, unlock_time: row.unlock_time.getTime() });
    }

    return new rest.Response(200, achievs);
}

export interface LeaderboardEntry {
    userId: number;
    submittedDatapoints: number;
};

export interface RetrieveLeaderboardRequest {
    limit?: number;
    start?: number;
}

export async function retrieveLeaderboard(db : pg.PoolClient, sessionData : session.SessionData, req : RetrieveLeaderboardRequest) : Promise<rest.Response>
{
    if (req.limit === undefined) req.limit = 100;
    if (req.start === undefined) req.start = 0;

    let result = await db.query("select user_id, count(datapoint_id)::int as submitted_datapoints from users left join datapoints on users.user_id = datapoints.submitter group by users.user_id order by submitted_datapoints desc limit $1 offset $2;", [ req.limit, req.start ]);

    let entries = [];
    for (let row of result.rows) {
        entries.push({ userId: row.user_id, submittedDatapoints: row.submitted_datapoints });
    }

    return new rest.Response(200, entries);
}
