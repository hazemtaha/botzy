require 'facebook/messenger'
require_relative 'fb_connector'

run Facebook::Messenger::Server

log = File.new("app.log", "a+")
$stdout.reopen(log)
$stderr.reopen(log)
