(function() {
  module.exports = function(samjs) {
    samjs.mongo.plugins({
      deletion: function(options) {
        var deleted, properties;
        if (options == null) {
          options = {};
        }
        deleted = {
          type: Boolean,
          "default": false
        };
        if (options["delete"] != null) {
          deleted.read = options["delete"];
          deleted.restricted = {
            allowed: options["delete"],
            find: {}
          };
          deleted.restricted.find[samjs.options.deletionName] = false;
        }
        if (options.write != null) {
          deleted.write = options.write;
        }
        properties = {};
        properties[samjs.options.deletionName] = deleted;
        this.schema.add(properties);
        this["delete"] = function(query, socket, addName) {
          query = {
            cond: query,
            doc: {}
          };
          query.doc[samjs.options.deletionName] = true;
          return this.processMutators.bind(this)(query, socket, "update").then((function(_this) {
            return function(query) {
              return new Promise(function(resolve, reject) {
                var dbModel;
                if (query.cond == null) {
                  return reject();
                }
                dbModel = addName ? _this.dbModels[addName + "." + _this.name] : _this.dbModel;
                return dbModel.update(query.cond, query.doc, function(err) {
                  if (err != null) {
                    return reject(err);
                  }
                  return dbModel.find(query.cond, "_id", function(err, data) {
                    if (err != null) {
                      return reject(err);
                    }
                    return resolve(data);
                  });
                });
              });
            };
          })(this));
        };
        this.interfaceGenerators[this.name].push(function(addName) {
          return function(socket) {
            return socket.on("delete", (function(_this) {
              return function(request) {
                if ((request != null ? request.token : void 0) != null) {
                  return _this["delete"](request.content, socket, addName).then(function(count) {
                    return {
                      success: true,
                      content: count
                    };
                  })["catch"](function(err) {
                    return {
                      success: false,
                      content: void 0
                    };
                  }).then(function(response) {
                    return socket.emit("delete." + request.token, response);
                  });
                }
              };
            })(this));
          };
        });
        this.undelete = function(query, socket, addName) {
          return this.processMutators.bind(this)({
            find: query
          }, socket, "find").then((function(_this) {
            return function(query) {
              return new Promise(function(resolve, reject) {
                var dbModel;
                if (!((query.find != null) && Object.keys(query.find).length > 0)) {
                  return reject();
                }
                query = {
                  cond: query.find,
                  doc: {}
                };
                query.doc[samjs.options.deletionName] = false;
                dbModel = addName ? _this.dbModels[addName + "." + _this.name] : _this.dbModel;
                return dbModel.update(query.cond, query.doc, function(err) {
                  if (err != null) {
                    return reject(err);
                  }
                  return dbModel.find(query.cond, "_id", function(err, data) {
                    if (err != null) {
                      return reject(err);
                    }
                    return resolve(data);
                  });
                });
              });
            };
          })(this));
        };
        this.interfaceGenerators[this.name].push(function(addName) {
          return function(socket) {
            return socket.on("undelete", (function(_this) {
              return function(request) {
                if ((request != null ? request.token : void 0) != null) {
                  return _this.undelete(request.content, socket, addName).then(function(count) {
                    return {
                      success: true,
                      content: count
                    };
                  })["catch"](function(err) {
                    return {
                      success: false,
                      content: void 0
                    };
                  }).then(function(response) {
                    return socket.emit("undelete." + request.token, response);
                  });
                }
              };
            })(this));
          };
        });
        this.mutators.remove.push(function(query, socket) {
          var group, ref, ref1;
          if (query == null) {
            throw new Error("No query provided");
          }
          if (socket == null) {
            throw new Error("No socket provided");
          }
          if (group = socket != null ? (ref = socket.client) != null ? (ref1 = ref.auth) != null ? ref1.getGroup() : void 0 : void 0 : void 0) {
            if ((this.schema.tree[samjs.options.deletionName].read == null) || this.schema.tree[samjs.options.deletionName].read.indexOf(group) < 0) {
              throw new Error("No permission");
            }
          } else {
            if (!this.schema.tree[samjs.options.deletionName].read) {
              throw new Error("No permission");
            }
          }
        });
        return this;
      }
    });
    return {
      name: "deletion",
      options: {
        deletionName: "deleted"
      }
    };
  };

}).call(this);
