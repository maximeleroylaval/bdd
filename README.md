# Soundhub

Réalisation d'un projet "Soundcloud-like" dans le cadre du cours GLO-2005

### Dépendance
[Installez Docker](https://www.docker.com/)

### Installation

[Activez l'hyper-V (Windows)](https://bit.ly/2kDg6Sw)

### Démarrage

Lancez docker et attendez bien qu'il se soit exécuté.
Une fois que docker est prêt, ouvrez l'application PowerShell à la racine du dossier [projet](./projet)

**Attention, si docker vous demande de partager l'accès à votre disque dur, acceptez la proposition**
**Si vous vous retrouvez dans ce cas, assurez-vous de posséder un accès à un compte administrateur avec un mot de passe d'enregistré en raison des [politiques de sécurité docker](https://github.com/docker/for-win/issues/616)** 

```bash
docker-compose up
```

Consultez votre terminal PowerShell et attendez d'obtenir le message suivant:
```bash
* Serving Flask app "server" (lazy loading)
flask_container |  * Environment: production
flask_container |    WARNING: Do not use the development server in a production environment.
flask_container |    Use a production WSGI server instead.
flask_container |  * Debug mode: off
flask_container |  * Running on http://0.0.0.0:80/ (Press CTRL+C to quit)
```

### Accès au site

Dans un navigateur internet, entrez le lien suivant dans la barre d'URL:

[localhost](http://localhost)

#### Compte utilisateur

Si vous ne souhaitez pas créer un compte, connectez-vous avec ces identifiants:
* Email: rap@rap.com
* Mot de passe: supermdp

**Remarque: toutes les adresses email préenregistrées dans la base de données ont pour mot de passe: supermdp**

# Auteur

* **[Maxime Leroy](https://github.com/maximeleroylaval)**
* **[Henri Longle](https://github.com/longle-h)**
