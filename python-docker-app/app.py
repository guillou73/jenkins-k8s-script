from flask import Flask, render_template, request, flash, session, logging, redirect, url_for
from wtforms import Form, StringField, TextAreaField, PasswordField, validators
from passlib.hash import sha256_crypt
from models import *
from functools import wraps
import os;

app = Flask(__name__)

app.debug = True
db_username = os.getenv('MYSQL_USER', 'root')
db_password = os.getenv('MYSQL_PASSWORD', 'password')
db_mysql_host = os.getenv('MYSQL_HOST', 'localhost')
app.config['SQLALCHEMY_DATABASE_URI'] = f'mysql://{db_username}:{db_password}@{db_mysql_host}/flask_articles'
#app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///articles.db'
app.config['SECRET_KEY'] =  os.getenv('SECRET_KEY').encode('utf-8')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)


def login_required(f):
    @wraps(f)
    def wrap(*args, **kwargs):
        if 'username' in session:
            return f(*args, **kwargs)
        else: 
            flash('Unauthorised, Please logIn to continue', 'danger')   
            return redirect(url_for('login', next= request.endpoint))
    return wrap 




@app.route('/')
def index():
    return render_template('home.html')


@app.route('/about')
@login_required
def about():
    return render_template('about.html')

@app.route('/articles')
def articles():
    data = Articles.query.all() 
    short_body_text = []
    for dat in data:
        short_body_text.append(dat.body[0:round(len(dat.body)/4)]+'....')
    return render_template('articles.html', content = data, text = short_body_text)


@app.route('/article/<int:id>')
def article(id):
    article = Articles.query.filter_by(id=id).first()
   
    return render_template('article.html', content = article)


class RegisterForm(Form):
    name = StringField('Name', [validators.Length(min=1, max=50)])
    username = StringField('Username', [validators.Length(min=4, max=25)])
    email = StringField('Email', [validators.Length(min=6, max=50)])
    password = PasswordField('Password', [validators.DataRequired(), validators.equal_to('confirm', message= 'Password doest not match')])
    confirm = PasswordField('Confirm Password')

class ArticleForm(Form):
    title = StringField('Title', [validators.Length(min=6, max=255)])    
    body = TextAreaField('Body', [validators.Length(min=4)])
       


@app.after_request
def add_header(response):
    """
    Add headers to both force latest IE rendering engine or Chrome Frame,
    and also to cache the rendered page for 10 minutes.
    """
    response.headers['X-UA-Compatible'] = 'IE=Edge,chrome=1'
    response.headers['Cache-Control'] = 'public, max-age=0'
    return response
    
@app.route('/register', methods = ['GET', 'POST'])
def register():
    form = RegisterForm(request.form)

    if request.method == 'POST' and form.validate():
        # check whether the user is already exist in database
        username = form.username.data
        exist_username = UsersModel.query.filter_by(username = username).first()
        if exist_username:
             flash('User details already exist', 'warning')
             return render_template('login.html') #TODO Change to login page once the login is implemented
        password = sha256_crypt.encrypt(str(form.password.data))
        user = UsersModel(name= form.name.data, email = form.email.data, username = username, password = password)
        db.session.add(user)
        db.session.commit()
        flash('You are now successfully registered. Please log in to continue', 'success')
        return redirect(url_for('login'))
        #return render_template('register.html', form=form)
    else:   
        return render_template('register.html', form=form)   


@app.route('/login', methods = ['POST', 'GET'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password_candidate = request.form['password']
        print(request.args.get('next'))
        exist_username = UsersModel.query.filter_by(username = username).first()
        if exist_username:
            if sha256_crypt.verify(password_candidate, exist_username.password):
                flash(f'You are successfully logged in', 'info')
                session['logged_In'] = True
                session['username'] = username
                nxt = request.args.get('next')
                #return redirect_dest(fallback=render_template('dashboard.html'))
                return  redirect( url_for(nxt)) if nxt else redirect(url_for('dashboard'))
            else:
                error = 'Invalid password'
                return render_template('login.html', error= error)   
        else:
            error = 'User not found'
            return render_template('login.html', error= error)    
    return render_template('login.html')             

@app.route('/dashboard')
@login_required
def dashboard():
    articles = Articles.query.all()
    if len(articles) == 0:
        msg = "No articles found"
        return render_template('dashboard.html', msg = msg)
    else:
        return render_template('dashboard.html', articles = articles)


@app.route('/delete/<int:id>')
@login_required
def delete(id):
    article = Articles.query.filter_by(id=id).first()
   
    if article is not None: 
        db.session.delete(article)
        db.session.commit()
    return redirect(url_for('dashboard'))    

@app.route('/edit/<int:id>', methods = ['GET', 'POST'])
@login_required
def edit(id):
    article = Articles.query.filter_by(id=id).first()
    form = ArticleForm(request.form)
    article = Articles.query.filter_by(id=id).first()
    if article is not None and request.method == 'GET':
        
        edit_data = {
            'title' : article.title,
            'body' : article.body
        }
        form.title.data = article.title
        form.body.data = article.body
        return render_template('dashboard.html',form = form,  data = edit_data)
    elif request.method == 'POST' and form.validate():
        article.title = form.title.data
        article.body = form.body.data
        db.session.add(article)
        db.session.commit()
        flash('Your article is successfully updated', 'success')
        return redirect(url_for('dashboard'))
    return render_template('dashboard.html', form = form)    


@app.route('/logout')
@login_required
def logout():
    session.clear()
    return redirect( url_for('index'))

@app.route('/add_article/<id>', methods = ['POST', 'GET'])
def add_article(id = None):
    article_form = ArticleForm(request.form)

    if request.method == 'POST' and article_form.validate():
        title = article_form.title.data
        body = article_form.body.data
        article = Articles(title= title, author = session['username'], body = body)
        db.session.add(article)
        db.session.commit()
        flash('Your article is successfully added', 'success')
        return redirect(url_for('dashboard'))
    
    return render_template('dashboard.html', form = article_form)


def create_database():
        with app.app_context():
             db.create_all()
       

if __name__ =='main':
    app.run(debug=True)
