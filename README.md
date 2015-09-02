# samjs-mongo-deletion

Deletion module for the mongo plugin for samjs.
Use it when you want a user to be able flag an document as deleted.
Afterwards only authenticated users can find, unflag or really remove it.

Client: [samjs-mongo-deletion-client](https://github.com/SAMjs/samjs-mongo-deletion-client)

## Example
```coffee
samjs = require "samjs"

samjs.plugins(require("samjs-mongo"),
  require("samjs-mongo-auth"),require("samjs-mongo-deletion"))
.options({config:"config.json"})
.configs()
.models({
  name: "someModel"
  db: "mongo"
  plugins:
    auth: null
    deletion:
      delete: "root"
      write: "all"
  schema:
    someProp:
      type: String
      read: "all"
      write: "root"
}).startup().io.listen(3000)

#will be in config mode, then in install mode, after install:
samjs.started.then -> # not in install mode anymore

#client in browser

samjs = require("samjs-client")({url: window.location.host+":3000/"})
samjs.plugins(require "samjs-mongo-client",
  require "samjs-mongo-auth-client",require "samjs-mongo-deletion-client")

## after configuration and install (see samjs-mongo-auth for example)

someModel = new samjs.Mongo("someModel")
# has insert / count / find / update / remove
someModel.insert someProp:"someValue"
.then (result) ->
  someModel.delete result
.then (result) ->
  someModel.find result
.then (result) ->
  result # []
samjs.auth.login {name:#rootName,pwd:#rootpw}
.then -> #success
  someModel.find someProp:"someValue"
.then (result) ->
  result # [{someProp:"someValue",_id:"#theID"}]
```
