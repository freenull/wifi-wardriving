/* Authors:
 * - Jakub Utko
 */

import pg from "pg";
import * as rest from "./rest";
import * as engagement from "./engagement";
import session from "express-session";

export enum AuthType {
    None,
    WEP,
    WPA,
    WPA2,
}

export interface SubmitCommentRequest {
    datapoint_id?: number;
    content?: string;
}

export interface RetrieveCommentRequest {
    comment_id?: number;
}

export interface RetrieveAllCommentsRequest {
    datapoint_id?: number;
}

export async function submitComment(
    db: pg.PoolClient,
    sessionData: session.SessionData,
    req: SubmitCommentRequest,
): Promise<rest.Response> {
    if (sessionData.userId === undefined) {
        return rest.errorResponse(
            rest.ErrorCode.LoginOnly,
            "Must be logged in to use this endpoint",
        );
    }

    if (req.datapoint_id === undefined)
        return rest.errorResponse(
            rest.ErrorCode.MissingParameter,
            "Missing parameter 'datapoint_id'",
        );
    if (req.content === undefined)
        return rest.errorResponse(
            rest.ErrorCode.MissingParameter,
            "Missing parameter 'content'",
        );
    if (req.content === "")
        return rest.errorResponse(
            rest.ErrorCode.MissingParameter,
            "Comment is empty",
        );

    let result = await db.query(
        "select from datapoints where datapoint_id = $1;",
        [req.datapoint_id],
    );
    if (result.rows.length < 1) {
        return rest.errorResponse(
            rest.ErrorCode.DbFail,
            `Datapoint with ID ${req.datapoint_id} doesn't exist`,
        );
    }

    result = await db.query(
        "insert into comments (submitter, datapoint, content) values ($1, $2, $3) returning comment_id;",
        [sessionData.userId, req.datapoint_id, req.content],
    );
    if (result.rows.length < 1) {
        return rest.errorResponse(
            rest.ErrorCode.DbFail,
            "Failed adding comment to database",
        );
    }

    let commentId = result.rows[0].comment_id;

    await engagement.checkAndGrantAchievementsFor(db, sessionData.userId);
    return new rest.Response(200, {
        comment_id: commentId,
        submitter_id: sessionData.userId,
        datapoint_id: req.datapoint_id,
    });
}

export async function retrieveComment(
    db: pg.PoolClient,
    sessionData: session.SessionData,
    req: RetrieveCommentRequest,
): Promise<rest.Response> {
    if (req.comment_id === undefined)
        return rest.errorResponse(
            rest.ErrorCode.MissingParameter,
            "Missing parameter 'comment_id'",
        );

    let result = await db.query(
        "select comment_id, submitter, datapoint, content from comments where comment_id = $1;",
        [req.comment_id],
    );
    if (result.rows.length < 1) {
        return rest.errorResponse(
            rest.ErrorCode.DbFail,
            `No such comment with ID ${req.comment_id}`,
        );
    }

    let commentId = result.rows[0].comment_id;
    let submitterId = result.rows[0].submitter;
    let datapointId = result.rows[0].datapoint;
    let content = result.rows[0].content;

    return new rest.Response(200, {
        comment_id: commentId,
        submitter_id: submitterId,
        datapoint_id: datapointId,
        content: content,
    });
}

export async function retrieveAllComments(
    db: pg.PoolClient,
    sessionData: session.SessionData,
    req: RetrieveAllCommentsRequest,
): Promise<rest.Response> {
    if (req.datapoint_id === undefined)
        return rest.errorResponse(
            rest.ErrorCode.MissingParameter,
            "Missing parameter 'datapoint_id'",
        );

    let result = await db.query(
        "select comment_id, submitter, content from comments where datapoint = $1;",
        [req.datapoint_id],
    );
    if (result.rows.length < 1) {
        return new rest.Response(200, { comments: [] });
    }

    let commentsList = [];
    for (let i = 0; i < result.rows.length; i++) {
        let row = result.rows[i];
        commentsList.push({
            comment_id: row.comment_id,
            submitter_id: row.submitter,
            content: row.content,
        });
    }

    return new rest.Response(200, { comments: commentsList });
}
