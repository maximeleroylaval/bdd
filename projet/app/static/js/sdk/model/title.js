export class Title {
    constructor(result) {
        if (result !== undefined)
            this.deserialize(result)
    }

    static newInstance(name, publication, url, playlist_id) {
        const title = new Title();
        title.name = name;
        title.publication = publication;
        title.url = url;
        title.playlist_id = playlist_id;
        return title;
    }

    deserialize(result) {
        this.id = result.id;
        this.name = result.name;
        this.publication = result.publication;
        this.url = result.url;
        this.user_email = result.user_email;
        this.playlist_id = result.playlist_id;
    }

    serialize() {
        let obj = {};
        obj.name = this.name;
        obj.publication = this.publication;
        obj.url = this.url;
        obj.playlist_id = this.playlist_id;
        return obj;
    }
}
