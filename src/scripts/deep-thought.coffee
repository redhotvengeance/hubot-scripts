# Description:
#   Deploy smart, not hard. Use Hubot + Deep Thought for happy deploying good times.
#
# Dependencies:
#   request
#
# Configuration:
#   HUBOT_DEEP_THOUGHT_URL - Deep Thought API endpoint
#   HUBOT_DEEP_THOUGHT_TOKEN - Deep Thought access token for authentication
#
# Commands:
#   hubot deploy <project>[/<action>...] <branch> to <environment>/<box> [<key>=<value>...] - Deploy a Deep Thought project
#   hubot deploy/setup <project name> repo=<repo url> - Setup new Deep Thought project
#   hubot deploy/status - Get the status of Deep Thought
#   hubot deploy ? - Show Deep Thought help/commands/examples
#
# Author:
#   redhotvengeance

request = require 'request'

module.exports = (robot) ->
  unless process.env.HUBOT_DEEP_THOUGHT_URL?
    robot.logger.warning 'The HUBOT_DEEP_THOUGHT_URL environment variable is not set - it is required.'

  unless process.env.HUBOT_DEEP_THOUGHT_TOKEN?
    robot.logger.warning 'The HUBOT_DEEP_THOUGHT_TOKEN environment variable is not set - it is required.'

  if process.env.HUBOT_DEEP_THOUGHT_URL?
    deepThoughtUrl = process.env.HUBOT_DEEP_THOUGHT_URL
    deepThoughtUrl = deepThoughtUrl.substring(0, deepThoughtUrl.length - 1) if deepThoughtUrl.charAt(deepThoughtUrl.length - 1) is '/'

  if process.env.HUBOT_DEEP_THOUGHT_TOKEN?
    deepThoughtToken = process.env.HUBOT_DEEP_THOUGHT_TOKEN

  robot.respond /deploy( +)?( \?)?( +)?$/i, (msg) ->
    msg.send [
      'deploy <project>[/<action>...] <branch> to <environment>/<box> [<key>=<value>...]'
      '  examples:'
      '    deploy my-project'
      '    deploy my-project/task'
      '    deploy my-project topic-branch'
      '    deploy my-project topic-branch to production'
      '    deploy my-project topic-branch to production/prod1'
      '    deploy my-project topic-branch to production/prod1 force=true'
      '    deploy my-project topic-branch to production/prod1 force=true deepthought=awesome'
      'deploy/setup <project name> repo=<repo url>'
      '  examples:'
      '    deploy/setup new-project repo=http://github.com/me/myrepo'
      'deploy/status'
      'deploy ? - Show Deep Thought help/commands/examples'
      ].join '\n'

  robot.respond /deploy ([-_\.0-9a-zA-Z]+)((\/[-_\.0-9a-zA-Z]+)+)?( [-_\.0-9a-zA-Z]+)?( to [-_\.0-9a-zA-Z]+(\/[-_\.0-9a-zA-Z]+)?)?(( [-_\.0-9a-zA-Z]+=[-_\.0-9a-zA-Z]+)+)?/i, (msg) ->
    data = {}
    data.name = msg.match[1]
    data.actions = msg.match[2].substring(1, msg.match[2].length).split('/') if msg.match[2]
    data.branch = msg.match[4].replace(' ', '') if msg.match[4]
    envBox = msg.match[5].replace(' to ', '').split('/') if msg.match[5]
    data.environment = envBox[0] if envBox and envBox.length > 0
    data.box = envBox[1] if envBox and envBox.length > 1

    if msg.match[7]
      data.variables = {}
      data.variables[variable.split('=')[0]] = variable.split('=')[1] for variable in msg.match[7].substring(1, msg.match[7].length).split(' ')

    data.on_behalf_of = msg.message.user.name

    request
      method: 'POST'
      uri: "#{deepThoughtUrl}/deploy/#{data.name}"
      headers:
        'Authorization': 'Token token="' + deepThoughtToken + '"'
      json: data
      (error, response, body) ->
        msg.send body

  robot.respond /deploy\/setup ([-_\.0-9a-zA-Z]+) repo=([-_\.0-9a-zA-Z]+)/i, (msg) ->
    data = {}
    data.name = msg.match[1]
    data['repo_url'] = msg.match[2]

    request
      method: 'POST'
      uri: "#{deepThoughtUrl}/deploy/setup/#{data.name}"
      headers:
        'Authorization': 'Token token="' + deepThoughtToken + '"'
      json: data
      (error, response, body) ->
        msg.send body

  robot.respond /deploy\/status/i, (msg) ->
    request
      method: 'GET'
      uri: "#{deepThoughtUrl}/deploy/status"
      headers:
        'Authorization': 'Token token="' + deepThoughtToken + '"'
      json: {}
      (error, response, body) ->
        msg.send body

  robot.router.post "/deep-thought/notify/:room", (req, res) ->
    robot.messageRoom req.params.room, req.body.message
    res.end 'Notified, thank you.'
