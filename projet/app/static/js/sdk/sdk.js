import { Request } from './tools/request'
import { User } from './model/user';
import { Playlist } from './model/playlist';
import { Title } from './model/title';
import { Commentary } from './model/commentary';

export class SDK {
    
    static formatDateToHuman(date) {
        var date = new Date(date);
        return "Ajoutée le " + date.toLocaleDateString("fr-FR");
    }

    static getQueryParameters(url) {
        // get query string from url (optional) or window
        var queryString = url ? url.split('?')[1] : window.location.search.slice(1);
    
        // we'll store the parameters here
        var obj = {};
    
        // if query string exists
        if (queryString) {
    
            // stuff after # is not part of query string, so get rid of it
            queryString = queryString.split('#')[0];
        
            // split our query string into its component parts
            var arr = queryString.split('&');
        
            for (var i = 0; i < arr.length; i++) {
                // separate the keys and the values
                var a = arr[i].split('=');
        
                // set parameter name and value (use 'true' if empty)
                var paramName = a[0];
                var paramValue = typeof (a[1]) === 'undefined' ? true : a[1];
        
                // (optional) keep case consistent
                paramName = paramName.toLowerCase();
                if (typeof paramValue === 'string')
                    paramValue = paramValue.toLowerCase();
        
                // if the paramName ends with square brackets, e.g. colors[] or colors[2]
                if (paramName.match(/\[(\d+)?\]$/)) {
        
                    // create key if it doesn't exist
                    var key = paramName.replace(/\[(\d+)?\]/, '');
                    if (!obj[key]) obj[key] = [];
            
                    // if it's an indexed array e.g. colors[2]
                    if (paramName.match(/\[\d+\]$/)) {
                        // get the index value and add the entry at the appropriate position
                        var index = /\[(\d+)\]/.exec(paramName)[1];
                        obj[key][index] = paramValue;
                    } else {
                        // otherwise add the value to the end of the array
                        obj[key].push(paramValue);
                    }
                } else {
                    // we're dealing with a string
                    if (!obj[paramName]) {
                        // if it doesn't exist, create property
                        obj[paramName] = paramValue;
                    } else if (obj[paramName] && typeof obj[paramName] === 'string'){
                        // if property does exist and it's a string, convert it to an array
                        obj[paramName] = [obj[paramName]];
                        obj[paramName].push(paramValue);
                    } else {
                        // otherwise add the property
                        obj[paramName].push(paramValue);
                    }
                }
            }
        }
    
        return obj;
    }

    static disconnect() {
        Request.setToken("");
        window.open("login.html", "_self");
    }

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

    static addPlaylist(name, description, picture) {
        const playlist = Playlist.newInstance(name, description, picture);
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

    static editPlaylist(name, description, picture, playlist_id) {
        const playlist = Playlist.newInstance(name, description, picture);
        return Request.Put("playlist/" + playlist_id, playlist.serialize())
            .catch(err => {
                throw err;
            }).then(response => {
                if (response.message !== '') {
                    if (response.code == 401)
                        window.open("login.html", "_self");
                    throw response.message;
                }
            });
    }

    static deletePlaylist(playlist_id) {
        return Request.Delete("playlist/" + playlist_id)
            .catch(err => {
                throw err;
            }).then(response => {
                if (response.message !== '') {
                    if (response.code == 401)
                        window.open("login.html", "_self");
                    throw response.message;
                }
            });
    }

    static getPlaylist(playlist_id) {
        return Request.Get("playlist/" + playlist_id)
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

    static addTitle(name, url, playlist_id) {
        const title = Title.newInstance(name, url);
        return Request.Post("playlist/" + playlist_id + "/title", title.serialize())
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

    static editTitle(name, url, title_id) {
        const title = Title.newInstance(name, url);
        return Request.Put("title/" + title_id, title.serialize())
            .catch(err => {
                throw err;
            }).then(response => {
                if (response.message !== '') {
                    if (response.code == 401)
                        window.open("login.html", "_self");
                    throw response.message;
                }
            });
    }

    static getTitles() {
        return Request.Get("title")
            .catch(err => {
                throw err;
            }).then(response => {
                if (response.message !== '') {
                    if (response.code == 401)
                        window.open("login.html", "_self");
                    throw response.message;
                }
                let titles = [];
                response.data.forEach(title => {
                    titles.push(new Title(title));
                });
                return titles;
            });
    }

    static getTitlesByPlaylist(playlist_id) {
        return Request.Get("playlist/" + playlist_id + "/title")
            .catch(err => {
                throw err;
            }).then(response => {
                if (response.message !== '') {
                    if (response.code == 401)
                        window.open("login.html", "_self");
                    throw response.message;
                }
                let titles = [];
                response.data.forEach(title => {
                    titles.push(new Title(title));
                });
                return titles;
            });
    }

    static getTitle(title_id) {
        return Request.Get("title/" + title_id)
            .catch(err => {
                throw err;
            }).then(response => {
                if (response.message !== '') {
                    if (response.code == 401)
                        window.open("login.html", "_self");
                    throw response.message;
                }
                return new Title(response.data);
            });
    }

    static getCommentariesByTitle(title_id) {
        return Request.Get("title/" + title_id + "/commentary")
            .catch(err => {
                throw err;
            }).then(response => {
                if (response.message !== '') {
                    if (response.code == 401)
                        window.open("login.html", "_self");
                    throw response.message;
                }
                let commentaries = [];
                response.data.forEach(commentary => {
                    commentaries.push(new Commentary(commentary));
                });
                return commentaries;
            });
    }

    static addCommentary(description, title_id) {
        const commentary = Commentary.newInstance(description, title_id);
        return Request.Post("title/" + title_id + "/commentary", commentary.serialize())
            .catch(err => {
                throw err;
            }).then(response => {
                if (response.message !== '') {
                    if (response.code == 401)
                        window.open("login.html", "_self");
                    throw response.message;
                }
                return new Commentary(response.data);
            });
    }

    static deleteCommentary(commentary_id) {
        return Request.Delete("commentary/" + commentary_id)
            .catch(err => {
                throw err;
            }).then(response => {
                if (response.message !== '') {
                    if (response.code == 401)
                        window.open("login.html", "_self");
                    throw response.message;
                }
            });
    }

    static getUserProfile() {
        return Request.Get("profile")
            .catch(err => {
                throw err;
            }).then(response => {
                if (response.message !== '') {
                    if (response.code == 401)
                        window.open("login.html", "_self");
                    throw response.message;
                }
                return new User(response.data);
            });
    }

    static getFollowedPlaylist(email) {
        return Request.Get("user/" + email + "/followed_playlists").catch(err => {
            throw err;
        }).then(response => {
            if (response.message !== '') {
                if (response.code == 401)
                    window.open("login.html", "_self");
                throw response.message;
            }
            let playlists = [];
            response.data.forEach(playlist => {
                playlists.push(playlist);
            });
            return playlists;
        });
    }

    static getUserPlaylists(email) {
        return Request.Get("user/" + email + "/playlists").catch(err => {
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
                if (response.message !== '') {
                    if (response.code == 401)
                        window.open("login.html", "_self");
                    throw response.message;
                }
                let users = [];
                response.data.forEach(element => {
                    users.push(new User(element));
                });
                return users
            });
    }

    static getUser(user_email) {
        return Request.Get("user/" + user_email)
            .catch(err => {
                throw err;
            }).then(response => {
                if (response.message !== '') {
                    if (response.code == 401)
                        window.open("login.html", "_self");
                    throw response.message;
                }
                return new User(response.data);
            });
    }

    static getFriends(user_email) {
        return Request.Get('user/' + user_email + '/friends').catch(err => {
            throw err;
        }).then(response => {
            if (response.message !== '') {
                throw response.message;
            }
            let friend_ids = [];
            response.data.forEach(friend_id => {
                friend_ids.push(friend_id);
            });
            return friend_ids;
        });
    }
}
