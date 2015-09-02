# out: ../lib/main.js
module.exports = (samjs) ->
  samjs.mongo.plugins deletion: (options={}) ->
    deleted = type: Boolean, default: false
    if options.delete?
      deleted.read = options.delete
      deleted.restricted = allowed: options.delete, find: {}
      deleted.restricted.find[samjs.options.deletionName] = false
    deleted.write = options.write if options.write?
    properties = {}
    properties[samjs.options.deletionName] = deleted
    @schema.add(properties)
    @delete = (query, socket, addName) ->
      query = cond: query, doc: {}
      query.doc[samjs.options.deletionName] = true
      @processMutators.bind(@)(query, socket, "update")
      .then (query) =>
        new Promise (resolve, reject) =>
          return reject() unless query.cond?
          dbModel = if addName then @dbModels[addName+"."+@name] else @dbModel
          dbModel.update query.cond, query.doc, (err) ->
            return reject err if err?
            dbModel.find query.cond, "_id", (err, data) ->
              return reject err if err?
              resolve data
    @interfaceGenerators[@name].push (addName) -> return (socket) ->
      socket.on "delete", (request) =>
        if request?.token?
          @delete request.content, socket, addName
          .then (count) -> success:true , content:count
          .catch (err)  -> success:false, content:undefined
          .then (response) -> socket.emit "delete.#{request.token}", response
    @undelete = (query, socket, addName) ->
      @processMutators.bind(@)({find:query}, socket, "find")
      .then (query) =>
        new Promise (resolve, reject) =>
          unless query.find? and Object.keys(query.find).length > 0
            return reject()
          query = cond: query.find, doc: {}
          query.doc[samjs.options.deletionName] = false
          dbModel = if addName then @dbModels[addName+"."+@name] else @dbModel
          dbModel.update query.cond, query.doc, (err) ->
            return reject err if err?
            dbModel.find query.cond, "_id", (err, data) ->
              return reject err if err?
              resolve data
    @interfaceGenerators[@name].push (addName) -> return (socket) ->
      socket.on "undelete", (request) =>
        if request?.token?
          @undelete request.content, socket, addName
          .then (count) -> success:true , content:count
          .catch (err)  -> success:false, content:undefined
          .then (response) -> socket.emit "undelete.#{request.token}", response
    @mutators.remove.push (query, socket) ->
      throw new Error("No query provided") unless query?
      throw new Error("No socket provided") unless socket?
      if group = socket?.client?.auth?.getGroup()
        if (not @schema.tree[samjs.options.deletionName].read?) or
            @schema.tree[samjs.options.deletionName].read.indexOf(group) < 0
          throw new Error("No permission")
      else
        unless @schema.tree[samjs.options.deletionName].read
          throw new Error("No permission")
    return @
  return {
    name: "deletion"
    options:
      deletionName: "deleted"
    }
