/* Authors:
 * - Dominik Banaszak
 */

export enum ErrorCode {
    MissingParameter = 0,
    UserRegistered = 1,
    InvalidCredentials = 2,
    LoginOnly = 3,
    DbFail = 4,
    NoLoginOnly = 5,
    InvalidAuthType = 6,
    InvalidDatapointId = 7,
}

export class Response {
    status: number;
    data: any;
    destroySessionData: boolean;

    constructor(status: number, data: any, destroySessionData = false) {
        this.status = status;
        this.data = data;
        this.destroySessionData = destroySessionData;
    }
}

export function errorResponse(code: ErrorCode, msg: string): Response {
    return new Response(400, { message: msg, code: code as number });
}
