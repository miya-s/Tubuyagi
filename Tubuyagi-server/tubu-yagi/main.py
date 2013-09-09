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
    user_name = db.StringProperty()
    yagi_name = db.StringProperty()
    content = db.StringProperty()
    wara = db.IntegerProperty()
    date = db.DateTimeProperty()

class User(db.Model):
    user_name = db.StringProperty()
    wara = db.IntegerProperty()
    random_pass = db.StringProperty()
    date = db.DateTimeProperty()
    def auth(self, given_pass):
        return (given_pass == self.random_pass)
    


def TubuyagiPostKey():
    return db.Key.from_path('Tubuyagi','default_blog')

def UserKey():
    return db.Key.from_path('User','default_user')

def TubuyagiById(id):
    return TubuyagiPost.get_by_id(id,parent=TubuyagiPostKey())


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
                   '<a href="/api/add_post">add post</a></br>'
                   '<a href="/api/add_user">add user</a>'
            )

        self.response.write('<h1>Post一覧</h1>')
        TubuyagiPosts = db.GqlQuery("select * from TubuyagiPost order by date desc limit 10")

        self.response.write('<ul>')

        for post in TubuyagiPosts:
            self.response.write('<li>USERNAME: {user_name};YAGINAME: {yagi_name}; WARA:{wara}; DATE:{date}; key: {key};<a href="/api/edit_post?id={key}">Edit</a></li>'
                .format(user_name=post.user_name.encode("utf-8"),yagi_name=post.yagi_name.encode("utf-8"),content=post.content.encode("utf-8"),wara=post.wara,date=post.date,key=post.key().id()))

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
        
        user = db.GqlQuery("select * from User where user_name = '" + user_name + "'").get()
        if not user.auth(random_pass):
            self.response.out.write(json.dumps({"result":"fail"})) 
            return
        newpost = TubuyagiPost(parent=TubuyagiPostKey())
        newpost.user_name = user_name
        newpost.yagi_name = yagi_name
        newpost.content = content
        newpost.wara = 0
        newpost.date = datetime.datetime.now() + datetime.timedelta(hours=9)
        newpost.put()
        self.response.out.write(json.dumps({"result":"success"}))

class edit_post(webapp2.RequestHandler):
    def get(self):
        id = int(self.request.get('id'))
        newpost = TubuyagiById(id)
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
            .format(user_name=newpost.user_name.encode("utf-8"),yagi_name=newpost.yagi_name.encode("utf-8"),content=newpost.content.encode("utf-8"),wara=newpost.wara,id=newpost.key().id()))
    def post(self):
        user_name = self.request.get('user_name')
        yagi_name = self.request.get('yagi_name')
        content = self.request.get('content')
        random_pass = self.request.get('random_pass')
        wara = self.request.get('wara')
        id = int(self.request.get('id'))
        newpost = TubuyagiById(id)
        user = db.GqlQuery("select * from User where user_name = '%s'" % user_name).get()
        if not user.auth(random_pass):
            self.response.out.write(json.dumps({"result":"fail"}))
            return
        newpost.user_name = user_name
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
        user = db.GqlQuery("select * from User where user_name = '%s'" % newpost.user_name).get()
        random_pass = self.request.get('random_pass')
        if user.auth(random_pass):
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
        newuser = User(parent=UserKey())
        newuser.user_name = user_name
        newuser.random_pass = random_pass
        newuser.wara = 0
        newuser.date = datetime.datetime.now() + datetime.timedelta(hours=9)
        newuser.put()
        self.response.out.write(json.dumps({"result":"success"}))        


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

        recents = {}
        i = 0
        for post in TubuyagiPosts:
            i += 1
            recents[i] = {}
            recents[i]["user_name"] = post.user_name
            recents[i]["yagi_name"] = post.yagi_name
            recents[i]["wara"] = post.wara
            recents[i]["date"] = post.date.strftime('%Y/%m/%d %H:%M:%S') 

        self.response.out.write(json.dumps(recents))        


class json_recent(webapp2.RequestHandler):
    def get(self):
        output_list(self,"select * from TubuyagiPost order by wara desc")

class json_top(webapp2.RequestHandler):
    def get(self):
        output_list(self,"select * from TubuyagiPost order by wara desc")


app = webapp2.WSGIApplication([ ('/', main_page),
                                ('/api/',api_page),
                                ('/api/add_post',add_post),
                                ('/api/edit_post',edit_post),
                                ('/api/delete_post',delete_post),
                                ('/api/add_user',add_user),
                                ('/json/recent',json_recent),
                                ('/json/top',json_top),
                               ],
                              debug=True)
