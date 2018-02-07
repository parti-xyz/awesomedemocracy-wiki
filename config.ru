require 'rubygems'
require 'bundler'
Bundler.setup

require 'rack'
require 'rack/showexceptions'
require 'rack-legacy'
require 'rack-legacy-phpcli'
require 'rack-rewrite'

INDEXES = ['index.html','index.php', 'index.cgi']
ENV['SERVER_PROTOCOL'] = "HTTP/1.1"

use Rack::Rewrite do
  # Rewrite rule for
  # rewrite %r{.*/files/(.+)}, 'xx'

  # redirect /foo to /foo/ - emulate the canonical WP .htaccess rewrites
  # r301 %r{(^.*/[\w\-_]+$)}, '$1/'

  rewrite %r{(.*/$)}, lambda {|match, rack_env|
    rack_env['CUSTOM_REQUEST_URI'] = rack_env['PATH_INFO']

    if !File.exists?(File.join(Dir.getwd, rack_env['PATH_INFO']))
      return '/index.php'
    end

    to_return = rack_env['PATH_INFO']
    INDEXES.each do |index|
      if File.exists?(File.join(Dir.getwd, rack_env['PATH_INFO'], index))
        to_return = File.join(rack_env['PATH_INFO'], index)
      end
    end
    to_return
  }

  # also rewrite /?p=1 type requests
  rewrite %r{(.*/\?.*$)}, lambda {|match, rack_env|
    rack_env['CUSTOM_REQUEST_URI'] = rack_env['PATH_INFO']
    query = match[1].split('?').last

    if !File.exists?(File.join(Dir.getwd, rack_env['PATH_INFO']))
      return '/index.php?' + query
    end

    to_return = rack_env['PATH_INFO'] + '?' + query
    INDEXES.each do |index|
      if File.exists?(File.join(Dir.getwd, rack_env['PATH_INFO'], index))
        to_return = File.join(rack_env['PATH_INFO'], index) + '?' + query
      end
    end
    to_return
  }
end

use Rack::ShowExceptions
use Rack::Legacy::Index
use Rack::Legacy::PhpCli
run Rack::File.new Dir.getwd
