import sqlalchemy as sa
import pymysql, json, datetime

from flask import Flask, request, Response
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.exc import IntegrityError
from pymysql.err import MySQLError

# Create the application instance
app = Flask(__name__)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://soundhub:soundhubpassword@localhost/soundhub'
pymysql.install_as_MySQLdb()
db = SQLAlchemy(app)

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
        errval = error[30:34]
        return int(errval)

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
    gender_name = db.Column(db.Integer, db.ForeignKey('gender.name'))

    def __init__(self, email, name, password, birthdate, gender_name):
        self.email = email
        self.name = name
        self.password = password
        self.birthdate = birthdate
        self.gender_name = gender_name
    
    @property
    def serialize(self):
        d = Serializer.serialize(self)
        del d['password']
        return d

class Gender(db.Model):
    __tablename__ = 'gender'

    name = db.Column(db.String(255), primary_key=True)

    def __init__(self, name):
        self.name = name

    @property
    def serialize(self):
        return Serializer.serialize(self)

# List of all routes
@app.route('/gender', methods = ['GET'])
def getGenders():
    genders = db.session.query(Gender).all()
    return JSONRequest.sendAnswer(Serializer.serialize_list(genders), 200)

@app.route('/user', methods = ['GET'])
def getUsers():
    users = db.session.query(User).all()
    return JSONRequest.sendAnswer(Serializer.serialize_list(users), 200)

@app.route('/user', methods = ['POST'])
def addUser():
    if (request.is_json == False):
        return "Request headers are not in json"

    try:
        content = request.get_json()
    except:
        return "Could not parse body as json"

    try:
        user = User(content['email'], content['name'], content['password'], content['birthdate'], content['gender_name'])
        db.session.add(user)
        db.session.commit()
    except IntegrityError as error:
        if (JSONRequest.getErrorCode(error.args[0]) == 1062):
            return JSONRequest.sendError("Duplicate keys for " + content['email'], 409)
        return JSONRequest.sendError(error.args[0], 500)

    db.session.refresh(user)
    return JSONRequest.sendAnswer(user.serialize, 200)

@app.route('/user', methods = ['PUT'])
def updateUser():
    if (request.is_json == False):
        return "Request headers are not in json"

    try:
        content = request.get_json()
    except:
        return "Could not parse body as json"

    try:
        email = content['email']
        user = db.session.query(User).filter_by(email=email).first()
        user.name = content['name']
        user.password = content['password']
        user.birthdate = content['birthdate']
        user.gender_name = content['gender_name']
        db.session.commit()
    except IntegrityError as error:
        return JSONRequest.sendError(error.args[0], 500)

    return JSONRequest.sendEmptyAnswer(200)

@app.route('/user/<email>', methods = ['DELETE'])
def deleteUser(email):
    try:
        user = db.session.query(User).filter_by(email=email).first()
        db.session.delete(user)
        db.session.commit()
    except IntegrityError as error:
        return JSONRequest.sendError(error.args[0], 500)

    return JSONRequest.sendEmptyAnswer(200)

# Try to connect to the database
def isConnected():
    try:
        db.session.query(Gender).first()
        return True
    except:
        return False

# Main entry to run the server
if __name__ == '__main__':
    if (isConnected() == False):
        print("Could not connect to the specified database, please verify your credentials")
    else:
        app.run(debug=True, port= 8080)