# Bash::Rb

TODO

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bash-rb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bash-rb

## Usage

```ruby
require 'bash-rb'

session = BashRb::Session.new

session.ls
=> ["Gemfile", "Gemfile.lock", "README.md", "Rakefile", "bash-rb.gemspec", "lib", "spec"]

session.ls('-l').each { |i| puts i }
total 40
-rw-r--r--  1 user  staff   92 29 Dec 11:23 Gemfile
-rw-r--r--  1 user  staff  632 29 Dec 11:25 Gemfile.lock
-rw-r--r--  1 user  staff  367 29 Dec 12:52 README.md
-rw-r--r--  1 user  staff  117 29 Dec 11:17 Rakefile
-rw-r--r--  1 user  staff  863 29 Dec 11:25 bash-rb.gemspec
drwxr-xr-x  4 user  staff  128 29 Dec 11:23 lib
drwxr-xr-x  4 user  staff  128 29 Dec 11:45 spec

session.pwd
=> ["../bash-rb"]

# Establish an SSH session
session.ssh("-i ~/.ssh/some-ec2.pem ec2-user@0.0.0.0")
session.pwd
=> ["/home/ec2-user"]

BashRb::Session.define_repl({
  "ruby" => BashRb::Handlers::Ruby
})

session.repl("ruby") { "bundle exec rails c" }
session.push("Rails::VERSION::STRING")
=> "3.2.22.1"

session.close
```