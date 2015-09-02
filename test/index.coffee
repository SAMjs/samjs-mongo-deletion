chai = require "chai"
should = chai.should()
samjs = require "samjs"
samjsMongo = require "samjs-mongo"
samjsMongoAuth = require "samjs-mongo-auth"
samjsMongoDeletion = require("../src/main")
samjsClient = require "samjs-client"
samjsMongoClient = require "samjs-mongo-client"
samjsMongoAuthClient = require "samjs-mongo-auth-client"
samjsMongoDeletionClient = require "samjs-mongo-deletion-client"

fs = samjs.Promise.promisifyAll(require("fs"))
port = 3050
url = "http://localhost:"+port+"/"
testConfigFile = "test/testConfig.json"
mongodb = "mongodb://localhost/test"

testmodel = {
  name:"test"
  db:"mongo"
  plugins:
    auth: null
    deletion:
      delete: "root"
      write: "all"
  schema:
    item:
      type: String
      read: "all"
      write: "all"
}

describe "samjs", ->
  client = null
  model = null
  entry = null
  before (done) ->
    samjs.reset()
    .plugins(samjsMongo,samjsMongoAuth,samjsMongoDeletion)
    .options({config:testConfigFile})
    fs.unlinkAsync testConfigFile
    .catch -> return true
    .finally ->
      done()

  describe "mongo", ->
    describe "deletion", ->
      it "should configure", (done) ->
        samjs.configs().models(testmodel).startup().io.listen(port)
        client = samjsClient({
          url: url
          ioOpts:
            reconnection: false
            autoConnect: false
          })()
        client.install.onceInConfigMode
        .return client.install.set "mongoURI", mongodb
        .then -> done()
        .catch done
      it "should install", (done) ->
        client.plugins(samjsMongoClient,
          samjsMongoDeletionClient, samjsMongoAuthClient)
        client.install.onceInInstallMode
        .then -> client.auth.install {name:"root",pwd:"rootroot"}
        .then -> done()
        .catch done
      it "should be started up", (done) ->
        samjs.started
        .then -> samjs.models.test.remove(item:"test")
        .then -> done()
        .catch done
      it "should insert an entry", (done) ->
        model = new client.Mongo("test")
        model.insert item:"test"
        .then (result) ->
          entry = result
          done()
        .catch done
      it "should be unable to remove that entry", (done) ->
        model.remove entry
        .then (result) ->
          should.not.exist result
          done()
        .catch -> done()
      it "should be able to 'delete' that entry", (done) ->
        model.delete entry
        .then (result) ->
          should.exist result
          done()
        .catch done
      it "should be unable to find that entry", (done) ->
        model.find find: entry
        .then (result) ->
          should.exist result
          should.not.exist result[0]
          done()
        .catch done
      it "should auth", (done) ->
        client.auth.login {name:"root",pwd:"rootroot"}
        .then (result) ->
          result.name.should.equal "root"
          result.group.should.equal "root"
          done()
        .catch done
      describe "once authenticated", ->
        it "should be able to find that entry", (done) ->
          model.find find: entry
          .then (result) ->
            should.exist result
            should.exist result[0]
            should.exist result[0].deleted
            result[0].deleted.should.be.true
            done()
          .catch done
        it "should be able to undelete that entry", (done) ->
          model.undelete entry
          .then (result) ->
            should.exist result
            should.exist result[0]
            done()
          .catch done
        it "should be able to remove that entry", (done) ->
          model.remove entry
          .then (result) ->
            should.exist result
            should.exist result[0]
            done()
          .catch done

  after (done) ->
    if samjs.shutdown?
      if samjs.models.users?
        model = samjs.models.users?.dbModel
        model.remove {group:"root"}
        .then -> done()
      else
        samjs.shutdown().then -> done()
    else
      done()
