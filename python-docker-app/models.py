from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from flask_bcrypt import Bcrypt
from sqlalchemy.ext.hybrid import hybrid_property
db = SQLAlchemy()


class UsersModel(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True, autoincrement = True)
    name= db.Column(db.String(100), nullable=False)
    username = db.Column(db.String(25), nullable=False, unique = True)
    email = db.Column(db.String(100), nullable = False)
    password = db.Column(db.String(256), nullable = False)
    pub_date = db.Column(db.DateTime, nullable=False,  default=datetime.utcnow)

    def __init__(self, name, username, email, password):
        self.name = name
        self.username = username
        self.email = email
        self.password = password


    def __repr__(self):
        return self.name

class Articles(db.Model):
    __tablename__ = 'articles'
    id = db.Column(db.Integer, primary_key = True, autoincrement = True)
    title = db.Column(db.String(256), nullable = False)
    author = db.Column(db.String(100), nullable = False)  
    body = db.Column(db.Text)   
    pub_date = db.Column(db.DateTime, nullable=False,  default=datetime.utcnow)  


    def __init__(self, title, author, body):
        self.title = title
        self.author = author
        self.body = body 

    def __repr__(self):
        return self.title    