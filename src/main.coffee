natural = require('natural')
yaml    = require('js-yaml')
unfluff = require('unfluff')
request = require('request')
fs      = require('fs')
async   = require('async')

# Hack to increase listeners before an error is reported
# See: http://stackoverflow.com/questions/8313628/node-js-request-how-to-emitter-setmaxlisteners
require('events').EventEmitter.prototype._maxListeners = 100

usage = () ->
  console.log("Usage: #{process.argv[1]} story-list.yaml classifier-results.json")
  process.exit(1)

classify = (story, classifier, callback) ->
    return callback() if not story.urls
    async.map(
      story.urls,
      (url, icallback) ->
        request url, (err, resp, body) ->
          if err
            console.error err #Log error
            icallback() #And continue ignoring error
            return
          return icallback() if !resp.headers['content-type']
          return icallback() if !resp.headers['content-type'].includes('text/html')
          console.log "Classifying: #{story.title}"
          text = unfluff(body).text
          for tag in story.tags
            classifier.addDocument(text, tag)
          icallback()
      ,callback
    )
       
# ----------------- MAIN --------------------------

storiesfile = process.argv[2]
classifierfile = process.argv[3]
if !storiesfile || !classifierfile
  usage()

fs.readFile storiesfile, 'utf-8', (err, data) ->
  if err
    console.error(err)
    process.exit(1)
  else
    items = yaml.safeLoad(data)
    classifier = new natural.BayesClassifier()
    async.map items
    , (item, cb) ->
        classify(item.story, classifier, cb)
    , (err, results) ->
        if err
          console.error err
          process.exit(1)
        console.log "Training classifier"
        classifier.train()
        console.log "Saving classifier to #{classifierfile}"
        classifier.save classifierfile, (err, classifier) ->
          if err
            console.error(err)
            process.exit(1)
