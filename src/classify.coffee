natural = require('natural')
unfluff = require('unfluff')
request = require('request')
fs      = require('fs')
async   = require('async')

usage = () ->
    console.log("Usage: #{process.argv[1]} classifer.json story_url")
    process.exit(1)

classifyStory = (storyUrl, classifier, callback) ->
    request storyUrl, (err, resp, body) ->
        if err
            callback(err)
        else
            contentType = resp.headers['content-type']
            return callback("Content type not found") if !contentType
            return callback("Content type is not text/html") if !contentType.includes('text/html')
            text = unfluff(body).text
            cls = classifier.getClassifications(text)
            cls = cls.sort (a, b) ->
                return b.value - a.value #Sort with highest values first
            callback(null, cls)
            
 
 

# ---------------------- MAIN ----------------------
classifierfile = process.argv[2]
storyUrl = process.argv[3]
if !classifierfile || !storyUrl
    usage()

natural.BayesClassifier.load classifierfile, null, (err, classifier) ->
    if err
        console.log(err)
        process.exit(1)
    else
        classifyStory storyUrl, classifier, (err, cls) ->
            if err
                console.log(err)
                process.exit(1)
            else
                console.log(cls)

