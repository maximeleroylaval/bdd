export class Playlist {
    constructor(result) {
        if (result !== undefined)
            this.deserialize(result)
    }

    static newInstance(name, description, picture) {
        const playlist = new Playlist();
        playlist.name = name;
        playlist.description = description;
        playlist.picture = picture;
        return playlist;
    }

    deserialize(result) {
        this.id = result.id;
        this.name = result.name;
        this.picture = result.picture;
        this.description = result.description;
        this.user_email = result.user_email;
    }

    serialize() {
        let obj = {};
        obj.name = this.name;
        obj.description = this.description;
        obj.picture = this.picture;
        return obj;
    }
}
