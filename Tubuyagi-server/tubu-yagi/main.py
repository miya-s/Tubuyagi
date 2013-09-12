# -*- coding: utf-8 -*-
import webapp2
import cgi
import datetime
import urllib
import json
import logging

from google.appengine.ext import db
from google.appengine.api import users

class TubuyagiPost(db.Model):
    random_pass = db.StringProperty()
    yagi_name = db.StringProperty()
    content = db.StringProperty()
    wara = db.IntegerProperty()
    date = db.DateTimeProperty()
    def get_user(self):
        return userByRandomPass(self.random_pass)

class Wara(db.Model):
    random_pass = db.StringProperty()
    post_id = db.IntegerProperty()
    date = db.DateTimeProperty()
    def get_user(self):
        return userByRandomPass(self.random_pass)

#TODO: yagi_nameはuserに持たせるべき？
class User(db.Model):
    user_name = db.StringProperty()
    wara = db.IntegerProperty()
    random_pass = db.StringProperty()
    date = db.DateTimeProperty()
    
def TubuyagiPostKey():
    return db.Key.from_path('Tubuyagi','default_blog')

def UserKey():
    return db.Key.from_path('User','default_user')

def WaraKey():
    return db.Key.from_path('Wara','default_wara')

def TubuyagiById(id):
    return TubuyagiPost.get_by_id(id,parent=TubuyagiPostKey())

def modifyUserName(user, new_user_name):
    user.user_name = new_user_name
    user.put()

def checkUser(user_name, random_pass):
    user = db.GqlQuery("select * from User where random_pass = '%s'" % random_pass).get()
    if not user:
        newuser = User(parent=UserKey())
        newuser.user_name = user_name
        newuser.random_pass = random_pass
        newuser.wara = 0
        newuser.date = datetime.datetime.now() + datetime.timedelta(hours=9)
        newuser.put()
        return newuser
    if not user.user_name == user_name:
        modifyUserName(user, user_name)
    return user 

def userByRandomPass(random_pass):
    user = db.GqlQuery("select * from User where random_pass = '%s'" % random_pass).get()
    return user 
    

##################################################

class main_page(webapp2.RequestHandler):
    def get(self):
        self.response.write(
            '<html>'
                '<body>'
                    '<a href="/api/">api page</a>'
            )
        self.response.write('</body></html>')

class api_page(webapp2.RequestHandler):
    def get(self):
        self.response.write(
            '<html>'
                '<body>'
                   '<a href="/api/add_post>add post</a></br>'
                   '<a href="/api/add_user">add user</a>'
            )

        self.response.write('<h1>Post一覧</h1>')
        TubuyagiPosts = db.GqlQuery("select * from TubuyagiPost order by date desc limit 10")

        self.response.write('<ul>')

        for post in TubuyagiPosts:
            user = post.get_user()
            self.response.write('<li>USERNAME: {user_name};YAGINAME: {yagi_name};CONTENT: {content}; WARA:{wara}; DATE:{date}; key: {key};<a href="/api/edit_post?id={key}">Edit</a></li>'
                .format(user_name=user.user_name.encode("utf-8"),yagi_name=post.yagi_name.encode("utf-8"),content=post.content.encode("utf-8"),wara=post.wara,date=post.date,key=post.key().id()))

        self.response.write('</ul>')
        self.response.write('<h1>user一覧</h1>')
        users = db.GqlQuery("select * from User order by date desc limit 10")
        self.response.write('<ul>')

        for user in users:
            self.response.write('<li>USERNAME: {user_name};WARA:{wara}; DATE:{date}; key: {key};</li>'
                .format(user_name=user.user_name.encode("utf-8"),wara=user.wara,date=user.date,key=user.key().id()))

        self.response.write('</ul>')

        self.response.write('</body></html>')


class add_post(webapp2.RequestHandler):
    def get(self):
        self.response.write(
            '<html>'
                '<body>'
                '<form action="/api/add_post" method="POST">'
                    'USER_NAME:<input type=text name=user_name value=""/>'
                    '<br>RANDOM_PASS:<input type=text name=random_pass value=""/>'
                    '<br>YAGI_NAME:<input type=text name=yagi_name value=""/>'
                    '<br>CONTENT:<input type=text name=content value=""/>'
                    '<br><input type=submit text="submit"/>'
                '</form>'
                '</body>'
            '</html>')
    def post(self):
        user_name = self.request.get('user_name')
        yagi_name = self.request.get('yagi_name')
        content = self.request.get('content')
        random_pass = self.request.get('random_pass')
        
        if not checkUser(user_name, random_pass):
            self.response.out.write(json.dumps([{"result":"fail"}]))
            return
        newpost = TubuyagiPost(parent=TubuyagiPostKey())
        newpost.random_pass = random_pass
        newpost.yagi_name = yagi_name
        newpost.content = content
        newpost.wara = 1
        newpost.date = datetime.datetime.now() + datetime.timedelta(hours=9)
        newpost.put()
        self.response.out.write(json.dumps([{"result":"success", "id": newpost.key().id()}]))

class edit_post(webapp2.RequestHandler):
    def get(self):
        id = int(self.request.get('id'))
        newpost = TubuyagiById(id)
        user = newpost.get_user
        self.response.write(
            '<html>'
                '<body>'
                '<form action="/api/edit_post" method="POST">'
                    '<input type="hidden" value="{id}" name="id">'
                    'USER_NAME:<input type=text name=user_name value="{user_name}"/>'
                    '<br>YAGI_NAME:<input type=text name=yagi_name value="{yagi_name}"/>'
                    '<br>RANDOM PASS(*needed):<input type=text name=random_pass value=""/>'
                    '<br>CONTENT:<input type=text name=content value="{content}"/>'
                    '<br>WARA:<input type=text name=wara value="{wara}"/>'
                    '<br><input type=submit value="Save"/>'
                '</form>'
                '<form action="/api/delete_post" method="POST">'
                    '<input type="hidden" value="{id}" name="id">'
                    'RANDOM PASS(*needed):<input type=text name=random_pass value=""/>'
                    '<br><input type=submit value="delete"/>'
                '</form>'
                '</body>'
            '</html>'
            .format(user_name=user.user_name.encode("utf-8"),yagi_name=newpost.yagi_name.encode("utf-8"),content=newpost.content.encode("utf-8"),wara=newpost.wara,id=newpost.key().id()))
    def post(self):
        user_name = self.request.get('user_name')
        yagi_name = self.request.get('yagi_name')
        content = self.request.get('content')
        random_pass = self.request.get('random_pass')
        wara = self.request.get('wara')
        id = int(self.request.get('id'))
        newpost = TubuyagiById(id)
        if not checkUser(user_name, random_pass):
            self.response.out.write(json.dumps({"result":"fail"}))
            return
        newpost.random_pass = random_pass
        newpost.yagi_name = yagi_name
        newpost.content = content
        newpost.wara = int(wara)
        newpost.put()
        self.response.out.write(json.dumps({"result":"success"}))
        return

class delete_post(webapp2.RequestHandler):
    def post(self):
        id = int(self.request.get('id'))
        newpost = TubuyagiById(id)
        random_pass = self.request.get('random_pass')

        user = newpost.get_user()
        if checkUser(user.user_name, random_pass):
            newpost.delete()
            self.response.out.write(json.dumps({"result":"success"}))
        else:
            self.response.out.write(json.dumps({"result":"fail"}))

##user##
class add_user(webapp2.RequestHandler):
    def get(self):
        self.response.write(
            '<html>'
                '<body>'
                '<form action="/api/add_user" method="POST">'
                    'USER_NAME:<input type=text name=user_name value=""/>'
                    '<br>RANDOM PASS:<input type=text name=random_pass value=""/>'
                    '<br><input type=submit text="submit"/>'
                '</form>'
                '</body>'
            '</html>')

    def post(self):
        user_name = self.request.get('user_name')
        random_pass = self.request.get('random_pass')
        if checkUser(user_name, random_pass):
            self.response.out.write(json.dumps({"result":"the user is already made( name may be changed)"}))
            return
        newuser = User(parent=UserKey())
        newuser.user_name = user_name
        newuser.random_pass = random_pass
        newuser.wara = 0
        newuser.date = datetime.datetime.now() + datetime.timedelta(hours=9)
        newuser.put()
        self.response.out.write(json.dumps({"result":"success"}))        


class add_wara(webapp2.RequestHandler):
    def get(self):
        self.response.write(
            '<html>'
                '<body>'
                '<form action="/api/add_wara" method="POST">'
                    'USER_NAME:<input type=text name=user_name value=""/>'
                    '<br>RANDOM PASS:<input type=text name=random_pass value=""/>'
                    '<br>POST ID:<input type=text name=post_id value=""/>'                    
                    '<br><input type=submit text="submit"/>'
                '</form>'
                '</body>'
            '</html>')

    def post(self):
        user_name = self.request.get('user_name')
        random_pass = self.request.get('random_pass')
        post_id = int(self.request.get('post_id'))
        newwara = Wara(parent=WaraKey())
        #post = TubuyagiById(post_id)
        if not checkUser(user_name, random_pass):
            self.response.out.write(json.dumps({"result":"failed"}))
            return
        newwara.random_pass = random_pass
        newwara.post_id = post_id
        newwara.date = datetime.datetime.now() + datetime.timedelta(hours=9)
        newwara.put()

        post = TubuyagiById(post_id)
        post.wara += 1
        post.put()
        target_user = post.get_user()
        target_user.wara += 1
        target_user.put()
        self.response.out.write(json.dumps({"result":"success"}))        
        return 


##jsons##

def output_list(self,query):
        self.response.headers['Content-Type'] = 'application/json'   
        cursor = self.request.get('cursor')
        if not cursor: cursor = "0"
        cursor = int(cursor)
        num = self.request.get('num')
        if not num: num = "20"
        num = int(num)

        TubuyagiPosts = db.GqlQuery(query).fetch(limit=num, offset=cursor)

        recents = []
        for post in TubuyagiPosts:
            dic = {}
            if post.get_user():
                dic["user_name"] = post.get_user().user_name
            else:
                dic["user_name"] = u"(unknown)"
            dic["yagi_name"] = post.yagi_name
            dic["content"] = post.content
            dic["wara"] = post.wara
            dic["date"] = post.date.strftime('%Y/%m/%d %H:%M:%S') 
            dic["id"] = post.key().id()
            recents.append(dic)

        self.response.out.write(json.dumps(recents))        


class json_recent(webapp2.RequestHandler):
    def get(self):
        output_list(self,"select * from TubuyagiPost order by date desc")

class json_top(webapp2.RequestHandler):
    def get(self):
        output_list(self,"select * from TubuyagiPost order by wara desc")

class json_wara(webapp2.RequestHandler):
    def get(self):
        self.response.headers['Content-Type'] = 'application/json'   
        random_pass = self.request.get('random_pass')
        user = userByRandomPass(random_pass)
        if not user:
            logging.error("failed to catch the user")
            self.response.out.write(json.dumps([{"user_name":"unknown user","wara":"0"}]))        
        else:
            wara = [{"user_name":user.user_name, "wara":user.wara}]
            self.response.out.write(json.dumps(wara))        
        #最近のふぁぼられpostとか見えないとアレ

app = webapp2.WSGIApplication([ ('/', main_page),
                                ('/api/',api_page),
                                ('/api/add_post',add_post),
                                ('/api/add_wara',add_wara),
                                ('/api/edit_post',edit_post),
                                ('/api/delete_post',delete_post),
                                ('/api/add_user',add_user),
                                ('/json/wara',json_wara),
                                ('/json/recent',json_recent),
                                ('/json/top',json_top),
                               ],
                              debug=True)
