import sqlalchemy as sa
import pymysql, json, datetime
import uuid
import time

from flask import Flask, request, Response, g, render_template, redirect
from flask_sqlalchemy import SQLAlchemy
from flask_httpauth import HTTPTokenAuth
from flask_cors import CORS
from sqlalchemy.exc import IntegrityError, InternalError
from pymysql.err import MySQLError

# Create the application instance
app = Flask(__name__)
CORS(app)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://soundhub:soundhubpassword@localhost/soundhub'
pymysql.install_as_MySQLdb()
db = SQLAlchemy(app)
auth = HTTPTokenAuth(scheme='Bearer')

# Object to return on every route
class Answer():
    def __init__(self, data, message, code):
        self.data = data
        self.message = message
        self.code = code

    @property
    def serialize(self):
        return {
            "data" : self.data,
            "message" : self.message,
            "code" : self.code,
            "time" : datetime.datetime.now().__str__()
        }

# Class helper to send responses in json
class JSONRequest():
    @staticmethod
    def getErrorCode(error):
        pos = error.find(')')
        errval = error[pos+3:pos+7]
        try:
            return int(errval)
        except:
            return 0

    @staticmethod
    def getJSONError():
        return "Missing field(s) in json object"

    @staticmethod
    def getJSON(request):
        if (request.is_json == False):
            return {}

        try:
            content = request.get_json()
            return content
        except:
            return {}

    @staticmethod
    def checkFields(content, fields):
        for field in fields:
            isOk = False
            for attr, _ in content.items():
                if (attr == field):
                    isOk = True
                    break
            if (isOk == False):
                return False
        return True

    @staticmethod
    def sendJSON(obj, code):
        resp = Response(response=json.dumps(obj),
                        status=code,
                        mimetype="application/json")
        return resp

    @staticmethod
    def sendAnswer(data, code):
        answer = Answer(data, "", code)
        return JSONRequest.sendJSON(answer.serialize, answer.code)

    @staticmethod
    def sendEmptyAnswer(code):
        answer = Answer({}, "", code)
        return JSONRequest.sendJSON(answer.serialize, answer.code)

    @staticmethod
    def sendError(message, code):
        answer = Answer([], message, code)
        return JSONRequest.sendJSON(answer.serialize, answer.code)

class Auth():
    @staticmethod
    @auth.verify_token
    def verify_token(token):
        token = db.session.query(Token).filter_by(token=token).first()
        if (token is None):
            return False
        else:
            g.user_email = token.user_email
            return True
        return False

    @auth.error_handler
    def auth_error():
        return JSONRequest.sendError("Unauthorized Access (invalid token)", 401)

    # Try to connect to the database
    @staticmethod
    def isConnected():
        try:
            db.session.query(Gender).first()
            return True
        except:
            return False

# Automatic sqlalchemy model serialization
class Serializer(object):

    @staticmethod
    def fieldConverter(o):
        if isinstance(o, datetime.datetime):
            return o.__str__()
        return o
    
    def serialize(self):
        jsonObj = {}
        for c in db.inspect(self).attrs.keys():
            jsonObj[c] = Serializer.fieldConverter(getattr(self, c))
        return jsonObj

    @staticmethod
    def serialize_list(mylist):
        return [item.serialize for item in mylist]

# List of database models
class User(db.Model):
    __tablename__ = 'user'

    email = db.Column(db.String(255), primary_key=True)
    name =  db.Column(db.String(255))
    password =  db.Column(db.String(255))
    birthdate =  db.Column(db.TIMESTAMP(timezone=False))
    picture = db.Column(db.String(255))
    publication = db.Column(db.TIMESTAMP(timezone=False), default=datetime.datetime.utcnow)
    gender_name = db.Column(db.String(255), db.ForeignKey('gender.name'))

    def __init__(self, email, name, password, birthdate, picture, gender_name):
        self.email = email
        self.name = name
        self.password = password
        self.birthdate = birthdate
        self.picture = picture
        self.gender_name = gender_name

    @property
    def serialize(self):
        d = Serializer.serialize(self)
        del d['password']
        return d

class Token(db.Model):
    __tablename__ = 'token'

    token = db.Column(db.String(255), primary_key=True)
    user_email = db.Column(db.String(255), db.ForeignKey('user.email'))

    def __init__(self, token, user_email):
        self.token = token
        self.user_email = user_email

    @property
    def serialize(self):
        d = Serializer.serialize(self)
        return d

class Gender(db.Model):
    __tablename__ = 'gender'

    name = db.Column(db.String(255), primary_key=True)

    def __init__(self, name):
        self.name = name

    @property
    def serialize(self):
        return Serializer.serialize(self)

class Playlist(db.Model):
    __tablename__ = 'playlist'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255))
    picture = db.Column(db.String(255))
    publication = db.Column(db.TIMESTAMP(timezone=False))
    user_email = db.Column(db.String(255), db.ForeignKey('user.email'))

    def __init__(self, name, picture, user_email):
        self.name = name
        self.picture = picture
        self.user_email = user_email

    @property
    def serialize(self):
        return Serializer.serialize(self)

class Title(db.Model):
    __tablename__ = 'title'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255))
    url = db.Column(db.String(512))
    publication = db.Column(db.TIMESTAMP(timezone=False))
    user_email = db.Column(db.String(255), db.ForeignKey('user.email'))
    playlist_id = db.Column(db.Integer, db.ForeignKey('playlist.id'))

    def __init__(self, name, publication, url, user_email, playlist_id):
        self.name = name
        self.url = url
        self.user_email = user_email
        self.playlist_id = playlist_id

    @property
    def serialize(self):
        return Serializer.serialize(self)

class Commentary(db.Model):
    __tablename__ = 'commentary'

    id = db.Column(db.Integer, primary_key=True)
    description = db.Column(db.String(512))
    publication = db.Column(db.TIMESTAMP(timezone=False))
    user_email = db.Column(db.String(255), db.ForeignKey('user.email'))
    title_id = db.Column(db.Integer, db.ForeignKey('title.id'))

    def __init__(self, description, user_email, title_id):
        self.description = description
        self.user_email = user_email
        self.title_id = title_id

    @property
    def serialize(self):
        return Serializer.serialize(self)

# List of all routes
@app.route('/')
def home():
    return redirect("static/index.html", code=200)

@app.route('/login', methods = ['POST'])
def loginUser():
    content = JSONRequest.getJSON(request)
    if (JSONRequest.checkFields(content, ['email', 'password']) == False):
        return JSONRequest.sendError(JSONRequest.getJSONError(), 403)
    try:
        user = db.session.query(User).filter_by(email=content['email'], password=content['password']).first()
        if (user is None):
            return JSONRequest.sendError("Email and password combinaison does not match", 401)
        token = Token(uuid.uuid4().__str__(), user.email)
        db.session.add(token)
        db.session.commit()
    except IntegrityError as error:
        return JSONRequest.sendError(error.args[0], 500)

    db.session.refresh(token)
    return JSONRequest.sendAnswer(token.serialize, 200)

@app.route('/register', methods = ['POST'])
def addUser():
    content = JSONRequest.getJSON(request)
    if (JSONRequest.checkFields(content, ['email', 'name', 'password', 'birthdate', 'gender_name']) == False):
        return JSONRequest.sendError(JSONRequest.getJSONError(), 403)
    try:
        if ('content' not in content):
            content['picture'] = ""
        user = User(content['email'], content['name'], content['password'], content['birthdate'], content['picture'], content['gender_name'])
        db.session.add(user)
        db.session.commit()
    except (IntegrityError, InternalError) as error:
        if (JSONRequest.getErrorCode(error.args[0]) == 1062):
            return JSONRequest.sendError("Duplicate keys for " + content['email'], 409)
        return JSONRequest.sendError(error.args[0], 500)

    db.session.refresh(user)
    return JSONRequest.sendAnswer(user.serialize, 200)

@app.route('/user', methods = ['GET'])
@auth.login_required
def getUsers():
    users = db.session.query(User).all()
    return JSONRequest.sendAnswer(Serializer.serialize_list(users), 200)

@app.route('/user/<email>', methods = ['GET'])
@auth.login_required
def getUser(email):
    user = db.session.query(User).filter_by(email=email).first()
    return JSONRequest.sendAnswer(user.serialize, 200)

@app.route('/profile', methods = ['GET'])
@auth.login_required
def getUserProfile():
    user = db.session.query(User).filter_by(email=g.user_email).first()
    return JSONRequest.sendAnswer(user.serialize, 200)

@app.route('/profile', methods = ['PUT'])
@auth.login_required
def updateUserProfile():
    content = JSONRequest.getJSON(request)
    if (JSONRequest.checkFields(content, ['name', 'password', 'birthdate', 'gender_name']) == False):
        return JSONRequest.sendError(JSONRequest.getJSONError(), 403)
    try:
        user = db.session.query(User).filter_by(email=g.user_email).first()
        user.name = content['name']
        user.password = content['password']
        user.birthdate = content['birthdate']
        user.gender_name = content['gender_name']
        db.session.commit()
    except IntegrityError as error:
        return JSONRequest.sendError(error.args[0], 500)

    return JSONRequest.sendEmptyAnswer(200)

@app.route('/user/<email>', methods = ['DELETE'])
@auth.login_required
def deleteUser(email):
    if (g.user_email != email):
        return JSONRequest.sendError("Delete on user email " + email + " is not authorized", 401)

    try:
        user = db.session.query(User).filter_by(email=email).first()
        db.session.delete(user)
        db.session.commit()
    except IntegrityError as error:
        return JSONRequest.sendError(error.args[0], 500)

    return JSONRequest.sendEmptyAnswer(200)


@app.route('/user/<email>/playlists', methods = ['GET'])
@auth.login_required
def getUserPlaylists(email):
    playlists = db.session.query(Playlist).filter_by(user_email=email)
    return JSONRequest.sendAnswer(Serializer.serialize_list(playlists), 200)

@app.route('/gender', methods = ['GET'])
@auth.login_required
def getGenders():
    genders = db.session.query(Gender).all()
    return JSONRequest.sendAnswer(Serializer.serialize_list(genders), 200)

@app.route('/playlist', methods = ['GET'])
@auth.login_required
def getPlaylists():
    playlists = db.session.query(Playlist).all()
    return JSONRequest.sendAnswer(Serializer.serialize_list(playlists), 200)

@app.route('/playlist/<id>', methods = ['GET'])
@auth.login_required
def getPlaylist(id):
    playlist = db.session.query(Playlist).filter_by(id=id).first()
    return JSONRequest.sendAnswer(playlist.serialize, 200)

@app.route('/playlist', methods = ['POST'])
@auth.login_required
def addPlaylist():
    content = JSONRequest.getJSON(request)
    if (JSONRequest.checkFields(content, ['name']) == False):
        return JSONRequest.sendError(JSONRequest.getJSONError(), 403)
    try:
        playlist = Playlist(content['name'], g.user_email)
        db.session.add(playlist)
        db.session.commit()
    except (IntegrityError, InternalError) as error:
        return JSONRequest.sendError(error.args[0], 500)

    db.session.refresh(playlist)
    return JSONRequest.sendAnswer(playlist.serialize, 200)

@app.route('/playlist/<id>/title', methods = ['GET'])
@auth.login_required
def getTitlesByPlaylist(id):
    titles = db.session.query(Title).filter_by(playlist_id=id).all()
    return JSONRequest.sendAnswer(Serializer.serialize_list(titles), 200)

@app.route('/title', methods = ['GET'])
@auth.login_required
def getTitles():
    titles = db.session.query(Title).all()
    return JSONRequest.sendAnswer(Serializer.serialize_list(titles), 200)

@app.route('/title/<id>', methods = ['GET'])
@auth.login_required
def getTitle(id):
    title = db.session.query(Title).filter_by(id=id).first()
    return JSONRequest.sendAnswer(title.serialize, 200)

@app.route('/title', methods = ['POST'])
@auth.login_required
def addTitle():
    content = JSONRequest.getJSON(request)
    if (JSONRequest.checkFields(content, ['name', 'publication', 'url', 'playlist_id']) == False):
        return JSONRequest.sendError(JSONRequest.getJSONError(), 403)
    try:
        playlist = db.session.query(Playlist).filter_by(playlist_id=content['playlist_id']).first()
        if (playlist.user_email != g.user_email):
            return JSONRequest.sendError("Adding a title on a playlist owned by " + playlist.user_email + " is not authorized", 401)
        title = Title(content['name'], content['publication'], content['url'], g.user_email, content['playlist_id'])
        db.session.add(title)
        db.session.commit()
    except (IntegrityError, InternalError) as error:
        return JSONRequest.sendError(error.args[0], 500)

    db.session.refresh(title)
    return JSONRequest.sendAnswer(title.serialize, 200)

@app.route('/title/<id>/commentary', methods = ['GET'])
@auth.login_required
def getCommentariesByTitle(id):
    commentaries = db.session.query(Commentary).filter_by(title_id=id).all()
    return JSONRequest.sendAnswer(Serializer.serialize_list(commentaries), 200)

@app.route('/title/<id>/commentary', methods = ['POST'])
@auth.login_required
def addCommentary(id):
    content = JSONRequest.getJSON(request)
    if (JSONRequest.checkFields(content, ['description']) == False):
        return JSONRequest.sendError(JSONRequest.getJSONError(), 403)
    try:
        commentary = Commentary(content['description'], g.user_email, id)
        db.session.add(commentary)
        db.session.commit()
    except (IntegrityError, InternalError) as error:
        return JSONRequest.sendError(error.args[0], 500)

    db.session.refresh(commentary)
    return JSONRequest.sendAnswer(commentary.serialize, 200)

# Main entry to run the server
if __name__ == '__main__':
    if (Auth.isConnected() == False):
        print("Waiting for database...")
    else:
        app.run(debug=False, host='0.0.0.0', port=80)
