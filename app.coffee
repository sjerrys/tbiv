html = require 'pithy'

request = require 'request'
Iconv  = require('iconv').Iconv


mongo = require 'mongodb'
Db = mongo.Db
Connection = mongo.Connection
Server = mongo.Server
format = require('util').format

renderResult = []

Model = (cb)->
  Db.connect format("mongodb://%s:%s/guo-fm-production?w=1", "127.0.0.1", 27018), (err, db)->
    Item = db.collection 'items'
    Item.find().toArray (err,items)->
      db.close()
      console.log items.length
      cb items

requestUrls = (items,cb)->
  result = []
  urls = (->
    for item in items
      if item.link.indexOf('detail.tmall.com/')>=0
        delete item.recommend
        item 
      else
  )()

  batch: ->
    self = this
    renderResult = result
    if urls.length<=0 
      urls = ""
      return cb result
    console.log urls.length+';'+result.length
    setTimeout (-> requestUrls.reqestUrl urls.shift(),requestUrls.batch),6000
  reqestUrl:(url,cb)->
    afterRequest = (error, response, body)->
      gbk_to_utf8_iconv = new Iconv 'GBK', 'UTF-8'
      try
        body = String gbk_to_utf8_iconv.convert body
      catch error
        body = String body
      if body.indexOf('下架')>=0 or body.indexOf('您查看的商品找不到了')>=0
        result.push url
      cb()
    options = 
      url:url.link
      encoding:null
      timeout:30000
    request options,afterRequest


      






express = require 'express'
app = express()

app.get "/",(req,res)->

  render = (results)->
    str = []
    links = []
    ids = []
    for i in [0..results.length-1]
      r = results[i]
      str.push html.div '.item',[
        html.a href:"http://guofm.com/items/#{r._id}",target:"_blank",[html.img src:"http://guofm.com/image/#{r.picture}_1.jpg"]
      ]
      links.push r.link
      ids.push "http://guofm.com/items/#{r._id}"
    res.send "<html><body><div>#{str.join ''}</div><hr /><small>#{links.join '<br />'}</small><hr /><div>#{ids.join '<br />'}</div></body></html>" 

  if renderResult.length>0 then return render renderResult

  Model (items)->
    requestUrls = requestUrls items,render
    requestUrls.batch()


  

app.listen 3000