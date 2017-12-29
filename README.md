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
```