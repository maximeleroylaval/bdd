export class Playlist {
    constructor(result) {
        if (result !== undefined)
            this.deserialize(result)
    }

    static newInstance(name) {
        const playlist = new Playlist();
        playlist.name = name;
        return playlist;
    }

    deserialize(result) {
        this.id = result.id;
        this.name = result.name;
        this.user_email = result.user_email;
    }

    serialize() {
        let obj = {};
        obj.name = this.name;
        return obj;
    }
}
