capistrano-data-bag
===================

Capistrano tasks and methods to manage data bags
## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-data-bag', require: false, group: :development, , :git => "git://github.com/omerisimo/capistrano-data-bag.git",

And then execute:

    $ bundle

## Usage

Add this line to your `deploy.rb`

    require 'capistrano-data-bag'

You can check that new tasks are available (cap -T):

### Tasks

#### data-bag:create

Create a new data bag item

    $ cap data_bag:create
    	Enter data bag name: staging
		Enter item name: server
		Enter key: host
		Enter value for host: some.host.com

Or you can pass the `data_bag_name`, `data_bag_item` and `data_file` as arguments to the cap task:

	$ cap data_bag:create -s data_bag_name=staging -s data_bag_item=server -s data_file=./data.json

This will create a new data bag folder named `\staging`, add a data item  file named `\staging\server.json` with the following content:

	{
		"id": "server",
		"host": "some.host.com"
	}

#### data-bag:show

Show the content data bag

    $ cap data_bag:create -s data_bag_name=staging
     #=> {:server=>{:host=>"some.host.com"}}

### Data Bags

#### Data bags folder

Data bags are stored under the folder defined by `:data_bags_path` (default location is "./config/deploy/data-bags").

You can change this location in your `deploy.rb` file:

	set :data_bags_path, "./config/some/other/folder"

#### Add data bags manually

You can also create data bags manually by adding a folder and files to the `:data_bags_path`.
A data bag item will contain its data and an `:id` field matching the item's name:

	# config/deploy/data-bags/staging/server.json
	{
		"id": "server",
		"host": "some.host.com"
	}

#### Usage in `deploy.rb`

You can use data bags in your `deploy.rb` file and in your recipes:

##### #load_data_bag

	# config/deploy.rb
	set(:env) { "staging" }

	#Read a data bag according to environment
	config_bag = load_data_bag(env)
	#Use the data bag to define a server
	server config_bag[:server][:host], :app, :web, :db

##### #create_data_bag_item

	data = {key: "value"}
	create_data_bag_item("bag", "item", data)

## License

See LICENSE file for details.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Run the tests (`bundle exec rake`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request