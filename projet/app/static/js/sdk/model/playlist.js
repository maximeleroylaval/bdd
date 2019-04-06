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
        this.picture = result.picture;
        this.descritpion = result.description;
    }

    serialize() {
        let obj = {};
        obj.name = this.name;
        obj.picture = this.picture;
        obj.description = this.descritpion;

        return obj;
    }
}
