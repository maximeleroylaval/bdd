import { Request } from './tools/request'
import { User } from './model/user';
import { Playlist } from './model/playlist';

export class SDK {

    static login(email, password) {
        const user = new User();
        user.email = email;
        user.password = password;
        return Request.Post("login", user.serializeLogin())
            .catch(err => {
                    throw err;
            }).then(response => {
                if (response.message !== '')
                    throw response.message;
                Request.setToken(response.data.token);
            });
    }

    static register(email, password, name, birthdate, gender_name) {
        const user = User.newInstance(email, password, name, birthdate, gender_name);
        return Request.Post("register", user.serialize())
            .catch(err => {
                    throw err;
            }).then(response => {
                if (response.message !== '')
                    throw response.message;
                return new User(response.data);
            });
    }

    static addPlaylist(name) {
        const playlist = Playlist.newInstance(name);
        return Request.Post("playlist", playlist.serialize())
            .catch(err => {
                throw err;
            }).then(response => {
                if (response.message !== '') {
                    if (response.code == 401)
                        window.open("login.html", "_self");
                    throw response.message;
                }
                return new Playlist(response.data);
            });
    }

    static getPlaylists() {
        return Request.Get("playlist")
            .catch(err => {
                throw err;
            }).then(response => {
                if (response.message !== '') {
                    if (response.code == 401)
                        window.open("login.html", "_self");
                    throw response.message;
                }
                let playlists = [];
                response.data.forEach(playlist => {
                    playlists.push(new Playlist(playlist));
                });
                return playlists;
            });
    }

    static getUsers() {
        return Request.Get("user")
            .catch(err => {
                throw err;
            }).then(response => {
                if (response.message !== '')
                    throw response.message;
                let users = [];
                response.data.forEach(element => {
                    users.push(new User(element));
                });
                return users
            });
    }
}
