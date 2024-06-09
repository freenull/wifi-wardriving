import pg from "pg";
import crypto from "node:crypto";
import session from "express-session";
import * as rest from "./rest";

declare module "express-session"
{
    interface SessionData
    {
        userId: number
    }
}

export interface UserRequest
{
    username?: string;
    password?: string;
    remember_me?: boolean;
};

export interface UserDataRequest
{
    user_id?: number;
};

// https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#scrypt
const SCRYPT_OPTIONS : any = {
    N: 2**17,
    r: 8,
    p: 1,
    maxmem: 256 * 1024 * 1024
};

export async function registerUser(db : pg.PoolClient, sessionData : session.SessionData, req : UserRequest) : Promise<rest.Response>
{
    if (sessionData.userId !== undefined)
    {
        return rest.errorResponse(rest.ErrorCode.NoLoginOnly, "Cannot use this endpoint while logged in");
    }

    if (req.username === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'username'");
    if (req.password === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'password'");

    let result = await db.query("select user_id from users where username = $1::text;", [ req.username ])
    if (result.rows.length > 0)
    {
        return rest.errorResponse(rest.ErrorCode.UserRegistered, `User '${req.username}' already registered`);
    }

    let salt = await new Promise<Buffer>((resolve) => {
        crypto.randomBytes(128, (err, buf) => {
            if (err) throw err;
            resolve(buf);
        });
    });
    console.log(typeof(req.password));
    console.log(salt instanceof Buffer);
    let derivedKey = await new Promise<any>((resolve) => {
        crypto.scrypt(req.password, salt, 64, SCRYPT_OPTIONS, (err, derivedKey) => {
            if (err) throw err;
            resolve(derivedKey);
        });
    });

    result = await db.query("insert into users (username, key, salt) values ($1, $2, $3) returning user_id;", [ req.username, derivedKey, salt ]);
    if (result.rows.length < 1)
    {
        return rest.errorResponse(rest.ErrorCode.UserRegistered, `Failed registering username '${req.username}'`);
    }
    sessionData.userId = result.rows[0].user_id;

    if (req.remember_me)
    {
        sessionData.cookie.maxAge = 2629746000; // 1 month
    }

    return new rest.Response(200, { "user_id": sessionData.userId });
}

export async function loginUser(db : pg.PoolClient, sessionData : session.SessionData, req : UserRequest) : Promise<rest.Response>
{
    if (sessionData.userId !== undefined)
    {
        return rest.errorResponse(rest.ErrorCode.NoLoginOnly, "Cannot use this endpoint while logged in");
    }

    if (req.username === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'username'");
    if (req.password === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'password'");

    let result = await db.query("select user_id, salt from users where username = $1::text;", [ req.username ])
    if (result.rows.length < 1)
    {
        return rest.errorResponse(rest.ErrorCode.InvalidCredentials, `Invalid credentials for user '${req.username}'`);
    }
    let user_id = result.rows[0].user_id;
    let salt = result.rows[0].salt;

    let derivedKey = await new Promise<any>((resolve) => {
        crypto.scrypt(req.password, salt, 64, SCRYPT_OPTIONS, (err, derivedKey) => {
            if (err) throw err;
            resolve(derivedKey);
        });
    });

    result = await db.query("select user_id from users where user_id = $1 and key = $2;", [ user_id, derivedKey ]);
    if (result.rows.length < 1)
    {
        return rest.errorResponse(rest.ErrorCode.InvalidCredentials, `Invalid credentials for user '${req.username}'`);
    }

    sessionData.userId = user_id;
    if (req.remember_me)
    {
        sessionData.cookie.maxAge = 2629746000; // 1 month
    }

    return new rest.Response(200, { "user_id": user_id });
}

export async function logoutUser(db : pg.PoolClient, sessionData : session.SessionData) : Promise<rest.Response>
{
    if (sessionData.userId === undefined)
    {
        return rest.errorResponse(rest.ErrorCode.LoginOnly, "Must be logged in to use this endpoint");
    }

    return new rest.Response(200, { }, true);
}

export async function myUserData(db : pg.PoolClient, sessionData : session.SessionData) : Promise<rest.Response>
{
    if (sessionData.userId === undefined)
    {
        return rest.errorResponse(rest.ErrorCode.LoginOnly, "Must be logged in to use this endpoint");
    }
    
    let result = await db.query("select username from users where user_id = $1;", [ sessionData.userId ]);
    if (result.rows.length < 1)
    {
        return rest.errorResponse(rest.ErrorCode.DbFail, "Failed getting user data from database");
    }

    let username = result.rows[0].username;
    
    return new rest.Response(200, { "user_id": sessionData.userId, "username": username });
}

export async function userData(db : pg.PoolClient, sessionData : session.SessionData, req : UserDataRequest) : Promise<rest.Response>
{
    if (req.user_id === undefined) return rest.errorResponse(rest.ErrorCode.MissingParameter, "Missing parameter 'user_id'");
    
    let result = await db.query("select username from users where user_id = $1;", [ req.user_id ]);
    if (result.rows.length < 1)
    {
        return rest.errorResponse(rest.ErrorCode.DbFail, "Failed getting user data from database");
    }

    let username = result.rows[0].username;
    
    return new rest.Response(200, { "username": username });
}
