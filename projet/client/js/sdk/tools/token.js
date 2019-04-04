export class Token {
    static set(token) {
        Token.token = token;
    }

    static get() {
        return Token.token;
    }
}

Token.token = '';
