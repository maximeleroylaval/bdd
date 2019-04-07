import { SDK } from './sdk/sdk';

export class ProfileController {
    static loadProfile(userEmail) {
        if (userEmail !== undefined) {
            SDK.getUser(userEmail).then(profil => {
                document.getElementById("pp").src = profil.picture;
                document.getElementById("username").textContent = profil.name;
                let d = new Date(profil.birthdate);
                let day = (d.getDate() < 10 ? "0" + d.getDate() : d.getDate());
                let month = ((d.getMonth() + 1) < 10 ? "0" + (d.getMonth() + 1) : (d.getMonth() + 1));
                document.getElementById("birthdate").textContent = day + "/" + month + "/" + d.getFullYear();
                document.getElementById("email").textContent = profil.email;
                userEmail = profil.email;
                if (profil.gender_name === "Man") {
                    document.getElementById("gender").innerHTML = "<i class=\"fas fa-mars\" style='\"color: blue\";'></i>"
                } else {
                    document.getElementById("gender").innerHTML = "<i class=\"fas fa-venus\" style='\"color: rose\";'></i>"
                }

                ProfileController.loadUserPlaylist(userEmail);
            });
        } else {
            SDK.getUserProfile().then(profil => {
                document.getElementById("pp").src = profil.picture;
                document.getElementById("username").textContent = profil.name;
                let d = new Date(profil.birthdate);
                let day = (d.getDate() < 10 ? "0" + d.getDate() : d.getDate());
                let month = ((d.getMonth() + 1) < 10 ? "0" + (d.getMonth() + 1) : (d.getMonth() + 1));
                document.getElementById("birthdate").textContent = day + "/" + month + "/" + d.getFullYear();
                document.getElementById("email").textContent = profil.email;
                userEmail = profil.email;
                if (profil.gender_name === "Man") {
                    document.getElementById("gender").innerHTML = "<i class=\"fas fa-mars\" style='\"color: blue\";'></i>"
                } else {
                    document.getElementById("gender").innerHTML = "<i class=\"fas fa-venus\" style='\"color: rose\";'></i>"
                }
                ProfileController.loadUserPlaylist(userEmail);
            });
        }
        document.getElementById("spinner_profil_detail").hidden = true;
        document.getElementById("profil_detail").hidden = false;
        document.getElementById("playlists-container").hidden = false;
        document.getElementById("spinner_playlist").hidden = true;
    }

    static loadFollowedPlaylist(userEmail) {
        if (userEmail !== undefined && userEmail !== null) {
            SDK.getFollowedPlaylist(userEmail).then(playlists => {
                playlists.forEach(element => {
                    SDK.getPlaylist(element.playlist_id).then(playlist => {
                        ProfileController.playlistGenerator(playlist);
                    })
                });

            });
        } else {
            SDK.getUserProfile().then(profil => {
                userEmail = profil.email;
                SDK.getFollowedPlaylist(userEmail).then(playlists => {
                    playlists.forEach(element => {
                        SDK.getPlaylist(element.playlist_id).then(playlist => {
                            ProfileController.playlistGenerator(playlist);
                        })
                    });
                });
            })
        }
    }

    static loadUserPlaylist(userEmail) {
        if (userEmail !== undefined && userEmail !== null) {
            SDK.getUserPlaylists(userEmail).then(playlists => {
                playlists.forEach(element => {
                    ProfileController.playlistGenerator(element);
                });

            });
        } else {
            SDK.getUserProfile().then(profil => {
                userEmail = profil.email;
                SDK.getUserPlaylists(userEmail).then(playlists => {
                    playlists.forEach(element => {
                        ProfileController.playlistGenerator(element);
                    });
                });
            })
        }
    }

    static getFriends(userEmail) {
        if (userEmail !== undefined && userEmail !== null) {
            SDK.getFriends(userEmail).then(friends => {
                friends.forEach(element => {
                });

            });
        } else {
            SDK.getUserProfile().then(profil => {
                userEmail = profil.email;
                SDK.getFriends(userEmail).then(friends => {
                        ProfileController.usersGenerator(friends)
                    });
            })
        }
    }

    static usersGenerator(users) {
        let container = document.getElementById("friends-container");
        let rowContainer;

        rowContainer = document.createElement("div");
        rowContainer.setAttribute("class", "row align-items-stretch");
        container.appendChild(rowContainer);


        users.forEach(element => {
            SDK.getUser(element.follow_email).then(user => {

                // Création de la card
                let card = document.createElement("div");
                card.setAttribute("class", "card user-card");
                card.addEventListener('click', (e) => {
                    window.open("profile.html?email=" + user.email, "_self");
                });

                rowContainer.appendChild(card);

                // Affichage de la pp
                let pp = document.createElement("img");
                pp.src = user.picture;
                pp.setAttribute("class", "card-img-top");
                card.appendChild(pp);

                // Creéation du body de la card
                let cardBody = document.createElement("div");
                cardBody.setAttribute("class", "card-body");
                card.appendChild(cardBody);

                // Card title, ,om de profil
                let cardTitle = document.createElement("h5");
                cardTitle.setAttribute("class", "card-title");
                cardTitle.innerText = user.name;
                cardBody.appendChild(cardTitle);
            })
        });
    }

    static playlistGenerator(element) {
        let ul = document.getElementById("playlists-container");
        // li
        let li = document.createElement("li");
        li.setAttribute("class", "list-group-item playlist-list-item row nav-link");


        //row
        let row = document.createElement("div");
        row.setAttribute("class", "row");
        row.addEventListener('click', (e) => {
            window.open("playlist.html?id=" + element.id, "_self");
        });
        // First column, img

        let c1 = document.createElement("div");
        c1.setAttribute("class", "col-2 align-self-center");

        let img = document.createElement("img");
        img.setAttribute("class", "img-fluid rounded");
        img.setAttribute("src", element.picture);

        // link the image to the first column
        c1.appendChild(img);

        // link the first column to the row
        row.appendChild(c1);


        // Second column, name

        let c2 = document.createElement("div");
        c2.setAttribute("class", "col-2 align-self-center");

        let name = document.createElement("h3");
        //name.setAttribute("class", "playlist-item-centered");
        name.innerText = element.name;

        // link the image to the first column
        c2.appendChild(name);

        // link the second column to the row
        row.appendChild(c2);


        // Third column, description

        let c3 = document.createElement("div");
        c3.setAttribute("class", "col-6 align-self-center");

        let desc = document.createElement("p");
        desc.innerText = element.description;

        // link the image to the first column
        c3.appendChild(desc);

        // link the second column to the row
        row.appendChild(c3);


        // 4th column, button

        let c4 = document.createElement("div");
        c4.setAttribute("class", "col-2 align-self-center");

        let butt = document.createElement("button");
        butt.setAttribute("type", "button");
        butt.setAttribute("class", "btn btn-outline-info");
        butt.innerText = "Accèder à la playlist";
        butt.addEventListener('click', (e) => {
            window.open("playlist.html?id=" + element.id, "_self");
        });

        // link the image to the first column
        c4.appendChild(butt);

        // link the second column to the row
        row.appendChild(c4);

        li.addEventListener('focus', () => {
 //           row.style.backgroundColor = "blue";
        });

        li.addEventListener('focusout', () => {
//            row.style.backgroundColor = "white";
        });
        // link to the lo
        li.appendChild(row);

        // link the li to the ul
        ul.appendChild(li);
    }

    static getEmail() {
        let params = SDK.getQueryParameters(window.location.href);
        return params.email;
    }
}
