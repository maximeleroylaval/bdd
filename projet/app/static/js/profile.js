import { SDK } from './sdk/sdk';

export class Profile {
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

                document.getElementById("spinner_profil_detail").hidden = true;
                document.getElementById("profil_detail").hidden = false;
                Profile.loadUserPlaylist(userEmail);
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

                document.getElementById("spinner_profil_detail").hidden = true;
                document.getElementById("profil_detail").hidden = false;
                Profile.loadUserPlaylist(userEmail);
            });
        }
    }

    static loadFollowedPlaylist(userEmail) {
        document.getElementById("playlists-container").hidden = true;
        document.getElementById("spinner_playlist").hidden = false;

        if (userEmail !== null) {
            SDK.getFollowedPlaylist(userEmail).then(playlists => {
                playlists.forEach(element => {
                    Profile.playlistGenerator(element);
                });

                document.getElementById("playlists-container").hidden = false;
                document.getElementById("spinner_playlist").hidden = true;
            });
        }
    }

    static loadUserPlaylist(userEmail) {
        document.getElementById("playlists-container").hidden = true;
        document.getElementById("spinner_playlist").hidden = false;

        if (userEmail !== null) {
            SDK.getUserPlaylists(userEmail).then(playlists => {
                playlists.forEach(element => {
                    Profile.playlistGenerator(element);
                });

                document.getElementById("playlists-container").hidden = false;
                document.getElementById("spinner_playlist").hidden = true;
            });
        }
    }

    static playlistGenerator(element) {
        let ul = document.getElementById("playlists-container");

        // li
        let li = document.createElement("li");
        li.setAttribute("class", "list-group-item playlist-list-item");

        //containeur
        let cont = document.createElement("div");
        cont.setAttribute("class", "container");

        //row
        let row = document.createElement("div");
        row.setAttribute("class", "row");

        // First column, img

        let c1 = document.createElement("div");
        c1.setAttribute("class", "col-2");

        let img = document.createElement("img");
        img.setAttribute("class", "img-fluid rounded");
        img.setAttribute("src", element.picture);

        // link the image to the first column
        c1.appendChild(img);

        // link the first column to the row
        row.appendChild(c1);


        // Second column, name

        let c2 = document.createElement("div");
        c2.setAttribute("class", "col-2");

        let name = document.createElement("h3");
        //name.setAttribute("class", "playlist-item-centered");
        name.innerText = element.name;

        // link the image to the first column
        c2.appendChild(name);

        // link the second column to the row
        row.appendChild(c2);


        // Third column, description

        let c3 = document.createElement("div");
        c3.setAttribute("class", "col-6");

        let desc = document.createElement("p");
        desc.innerText = element.descritpion;

        // link the image to the first column
        c3.appendChild(desc);

        // link the second column to the row
        row.appendChild(c3);


        // 4th column, button

        let c4 = document.createElement("div");
        c4.setAttribute("class", "col-2");

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


        // link row to the container
        cont.appendChild(row);

        // link container to the li
        li.appendChild(cont);

        // link the li to the ul
        ul.appendChild(li);
    }
}
