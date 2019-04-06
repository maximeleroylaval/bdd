export class User {
    constructor(result) {
        if (result !== undefined)
            this.deserialize(result)
    }

    static newInstance(email, password, name, birthdate, gender_name) {
        const user = new User();
        user.email = email;
        user.password = password;
        user.name = name;
        user.birthdate = birthdate;
        user.gender_name = gender_name;
        user.picture = null;
        return user;
    }

    deserialize(result) {
        this.email = result.email;
        this.name = result.name;
        this.password = result.password;
        this.birthdate = result.birthdate;
        this.gender_name = result.gender_name;
        this.picture = result.picture;
    }

    serialize() {
        let obj = {};
        obj.email = this.email;
        obj.name = this.name;
        obj.password = this.password;
        obj.birthdate = this.birthdate;
        obj.gender_name = this.gender_name;
        obj.picture = this.picture;
        return obj;
    }

    serializeLogin() {
        let obj = {};
        obj.email = this.email;
        obj.password = this.password;
        return obj;
    }
}
