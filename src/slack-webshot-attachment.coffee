# Description:
#   Take a screenshot and reply with attachment
#
# Configuration:
#   HUBOT_SLACK_TOKEN
#
# Commands:
#   hubot ss <URL> <profile>
#   hubot ss list profiles

webshot = require 'webshot'
Slack = require 'slack-node'
temp = require 'temp'
fs = require 'fs'

profiles = {
  "desktop":{
    "shotSize": {
      "height": "all"
    },
  }
  "mobile": {
    "screenSize": {
      "width": 320,
      "height": 480
    },
    "shotSize": {
      "width": 320,
      "height": "all"
    },
    "userAgent": "Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_2 like Mac OS X; en-us) AppleWebKit/531."
  }
}

module.exports = (robot) ->
  token = process.env.HUBOT_SLACK_TOKEN

  return robot.logger.error "Missing configuration HUBOT_SLACK_TOKEN" unless token?

  slack = new Slack(token)

  robot.respond /ss list profiles/i, (res) ->
    res.reply "#{Object.keys(profiles).join(", ")}"

  robot.respond /ss (https?\:\/\/.*) (.*)/i, (msg) ->

    [url, profile] = msg.match[1..2]
    renderStream = webshot url, profiles[profile]
    writeStream = temp.createWriteStream(
      prefix: new Date().toISOString().slice(0,10) + "_",
      suffix: ".png"
    );

    msg.send "Accepted: " + url

    renderStream.on "data", (data) ->
      writeStream.write data.toString('binary'), 'binary'

    renderStream.on "error", (err) ->
      console.error "Webshot error: " + err
      msg.reply "Webshot error: " + err

    renderStream.on "end", () ->
      param = {
        channels: msg.message.rawMessage.channel,
        title: url,
        file: fs.createReadStream writeStream.path
      }

      slack.api "files.upload", param, (err, response) ->

        err = response.error unless response.ok

        if (err)
          console.error "Upload error: " + err
          msg.reply "Upload error: " + err
        else
          console.log "Upload success: ", response.file.permalink