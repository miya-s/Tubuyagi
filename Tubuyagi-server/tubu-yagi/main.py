import webapp2
import cgi
import datetime
import urllib

from google.appengine.ext import db
from google.appengine.api import users

#blog###################################################
class BlogPost(db.Model):
    title = db.StringProperty()
    content = db.StringProperty()
    date = db.DateTimeProperty(auto_now_add=True)

def BlogPostKey():
    return db.Key.from_path('Blog','default_blog')

def BlogById(id):
    return BlogPost.get_by_id(id,parent=BlogPostKey())


#PAGES#################################################
class MainPage(webapp2.RequestHandler):
    def get(self):
        self.response.write(
            '<html>'
                '<body>'
                    '<a href="/AddPost">AddPost</a>')

        BlogPosts = db.GqlQuery("select * from BlogPost order by date desc limit 10")

        self.response.write('<ul>')

        for post in BlogPosts:
            self.response.write('<li>{title} at {date} key: {key}<a href="/EditPost?id={key}">Edit</a></li>'
                .format(title=post.title,date=post.date,key=post.key().id()))

        self.response.write('</ul>')
        self.response.write('</body></html>')


class AddPost(webapp2.RequestHandler):
    def get(self):
        self.response.write(
            '<html>'
                '<body>'
                '<form action="/AddPost" method="POST">'
                    'TITLE:<input type=text name=title value=""/>'
                    '<br>CONTENT:<input type=text name=content value=""/>'
                    '<br><input type=submit text="submit"/>'
                '</form>'
                '</body>'
            '</html>')
    def post(self):
        title = self.request.get('title')
        content = self.request.get('content')
        newpost = BlogPost(parent=BlogPostKey())
        newpost.title = title
        newpost.content = content
        newpost.put()
        self.redirect('/')

class EditPost(webapp2.RequestHandler):
    def get(self):
        id = int(self.request.get('id'))
        newpost = BlogById(id)
        self.response.write(
            '<html>'
                '<body>'
                '<form action="/EditPost" method="POST">'
                    '<input type="hidden" value="{id}" name="id">'
                    'TITLE:<input type=text name=title value="{title}"/>'
                    '<br>CONTENT:<input type=text name=content value="{content}"/>'
                    '<br><input type=submit value="Save"/>'
                '</form>'
                '<form action="/DeletePost" method="POST">'
                    '<input type="hidden" value="{id}" name="id">'
                    '<br><input type=submit value="delete"/>'
                '</form>'
                '</body>'
            '</html>'
            .format(title=newpost.title,content=newpost.content,id=newpost.key().id()))
    def post(self):
        title = self.request.get('title')
        content = self.request.get('content')
        id = int(self.request.get('id'))
        newpost = BlogById(id)
        newpost.title = title
        newpost.content = content
        newpost.put()
        self.redirect('/')

class DeletePost(webapp2.RequestHandler):
    def post(self):
        id = int(self.request.get('id'))
        newpost = BlogById(id)
        newpost.delete()
        self.redirect('/')


app = webapp2.WSGIApplication([('/', MainPage),
                                ('/AddPost',AddPost),
                                ('/EditPost',EditPost),
                                ('/DeletePost',DeletePost)],
                              debug=True)
