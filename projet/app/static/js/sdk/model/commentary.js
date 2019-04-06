export class Commentary {
    constructor(result) {
        if (result !== undefined)
            this.deserialize(result)
    }

    static newInstance(description, title_id) {
        const commentary = new Commentary();
        commentary.description = description;
        commentary.title_id = title_id;
        return commentary;
    }

    deserialize(result) {
        this.id = result.id;
        this.description = result.description;
        this.publication = result.publication;
        this.user_email = result.user_email;
        this.title_id = result.title_id;
    }

    serialize() {
        let obj = {};
        obj.description = this.description;
        obj.title_id = this.title_id;
        return obj;
    }
}
