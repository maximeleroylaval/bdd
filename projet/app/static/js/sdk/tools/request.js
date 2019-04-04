import {Token} from "./token";

const base = 'http://localhost:56878/';
const mode = 'cors';
const cache = 'no-cache';

export class Request {

    static addTokenToHeader(headers){
        headers.append("Content-Type","application/json; charset=utf-8");
        if (Token.get() !== '') {
            headers.append('Authorization', 'Bearer ' + Token.get());
        }
        return headers;
    }

    static BuildURL(route) {
        return base + route;
    }

    static setToken(token) {
        Token.set(token)
    }

    static Get(route) {
        const header = Request.addTokenToHeader(new Headers());

        return fetch(Request.BuildURL(route), {
            method: "GET",
            mode: mode,
            cache: cache,
            headers: header,
        }).then(res => res.json())
    }

    static Post(route, data) {
        const header = Request.addTokenToHeader(new Headers());

        return fetch(Request.BuildURL(route), {
            method: "POST",
            mode: mode,
            cache: cache,
            headers: header,
            body: JSON.stringify(data),
        }).then(res => res.json())
    }

    static Put(route, data) {
        const header = Request.addTokenToHeader(new Headers());

        return fetch(Request.BuildURL(route), {
            method: "PUT",
            mode: mode,
            cache: cache,
            headers: header,
            body: JSON.stringify(data),
        }).then(res => res.json())
    }

    static Delete(url) {
        const header = Request.addTokenToHeader(new Headers());

        return fetch(Request.BuildURL(route), {
            method: "DELETE",
            mode: mode,
            cache: cache,
            headers: header,
        }).then(res => res.json())
    }
}
