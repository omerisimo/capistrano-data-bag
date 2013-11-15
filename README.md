[![Build Status](https://secure.travis-ci.org/omerisimo/capistrano-data-bag.png?branch=master)](http://travis-ci.org/omerisimo/capistrano-data-bag)
[![Coverage Status](https://coveralls.io/repos/omerisimo/capistrano-data-bag/badge.png)](https://coveralls.io/r/omerisimo/capistrano-data-bag)

capistrano-data-bag
===================

Capistrano tasks and methods for managing data bags.

Influenced by Chef concept of data bags, the plugin provides easy management of settings variables and sensitive data across different environments.

A data bag is a set of item variables saved as JSON. The data bag content is accessible in recipes during deploy.

Provides tasks and methods for:

* Creating data bags
* Creating encrypted data bags
* Loading data bags
* Loading a secret file


## Data bags structure

A data bag is a folder stored in the path defined by `:data_bags_path` (default location is "./config/deploy/data-bags")

You can change this location in your `deploy.rb` file:

```ruby
set :data_bags_path, "./config/some/other/folder"
```

A data bag can contain several data bag items. Each item is a JSON file with the name of the data bag item.

```
└── config
    └── deploy
        └── data-bags
        	├── data-bag-1
        	|	├── data-bag-item-1.json
        	|  	└── data-bag-item-2.json
        	└── data-bag-2
        		├── data-bag-item-3.json
        	   	└── data-bag-item-4.json
```

A data bag item will contain its data and an `:id` field matching the item's name:

``` json
# config/deploy/data-bags/staging/server.json
{
"id": "server",
"host": "some.host.com"
}
```

## Encrypted data bags

The content of a data bag can be encrypted using [shared secret encryption](https://en.wikipedia.org/wiki/Symmetric-key_algorithm).

Create a key using OpenSSL:

```sh
$ openssl rand -base64 256 > encrypted_data_bag_secret
```

Store the secret file in a safe place.

Set the path of the secret file in `deploy.rb`:

```ruby
set :data_bag_secret, "/path/to/secret"
```

or pass it to the `cap` command:

```sh
$ cap deploy -s data_bag_secret="/path/to/secret"
```
## Installation

Add this line to your application's Gemfile:

```ruby
group :development do
	gem 'capistrano-data-bag', require: false, git: "git://github.com/omerisimo/capistrano-data-bag.git"
end
```

And then execute:

``` sh
bundle
```

## Usage

Add this line to your `deploy.rb`

```ruby
require 'capistrano-data-bag'
```

Check that new tasks are available (`cap -T`):

### Tasks

#### data-bag:create

Create a new data bag item:

```sh
$ cap data_bag:create
  Enter data bag name: staging
  Enter item name: server
  Enter key: host
  Enter value for host: some.host.com
```

Or pass the `data_bag_name`, `data_bag_item` and `data_file` as arguments to the cap task:

```sh
$ cap data_bag:create -s data_bag_name=staging -s data_bag_item=server -s data_file=./data.json
```

This will create a new data bag folder named `\staging`, add a data item  file named `\staging\server.json` with the following content:

```json
{
"id": "server",
"host": "some.host.com"
}
```

#### data-bag:show

Show the content of a data bag:

```sh
$ cap data_bag:show -s data_bag_name=staging
#=> {:server=>{:host=>"some.host.com"}}
```

If the content of the data bag is encrypted, `:data_bag_secret` must be set or passed to `cap`.

#### data-bag:encrypted:create

Usage is the same as `data-bag:create`, but `:data_bag_secret` must be set or passed to `cap`.


### Usage in `deploy.rb`

You can use data bags in your `deploy.rb` file and in your recipes:

#### #load_data_bag

```ruby
# config/deploy.rb
set(:env) { "staging" }
#Read a data bag according to environment
config_bag = load_data_bag(env)
#Use the data bag to define a server
server config_bag[:server][:host], :app, :web, :db
```

To load a data bag containing encrypted content:

```ruby
# load secret from file
secret = load_data_bag_secret('/path/to/secret')
# pass the secret to the #load_data_bag method
encrypted_bag bag = load_data_bag("encrypted_bag_name", secret)
```

Or just set the `:data_bag_secret` variable:

```ruby
# Set the secret file path globally
set :data_bag_secret, "/path/to/secret"
# Method #load_data_bag will automatically load the secret according to the :data_bag_secret variable
encrypted_bag bag = load_data_bag("encrypted_bag_name")
```

#### #create_data_bag_item

```ruby
data = {key: "value"}
create_data_bag_item("bag", "item", data)
```

#### #create_encrypted_data_bag_item

Same usage as `#create_data_bag_item`, but the `:data_bag_secret` variable must be set or the secret passed to the `#create_encrypted_data_bag_item` method.

```ruby
secret = load_data_bag_secret('/path/to/secret')
data = {key: "value"}
create_encrypted_data_bag_item("bag", "item", data, secret)
```

## License

See LICENSE file for details.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Run the tests (`bundle exec rake`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
