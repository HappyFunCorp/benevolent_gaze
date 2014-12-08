# BenevolentGaze

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'benevolent_gaze'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install benevolent_gaze

## Usage
Benevolent Gaze has two parts. You will add the benevolent_gaze gem to your Gemfile and add the following to your routes:
```Ruby
require 'benevolent_gaze/bgapp'

mount BenevolentGaze::BGApp, at: "/register"
```
What this does is mount the registration portal at yoursite.com/register.
When users hit that url, they will be able to upload an image and change their name on the benevolent gaze board.

The second part is what runs on your local network.  It contains two things: A tracker that checks your network to see who has joined and what their devices are.
The second thing is the kiosk. This is the interface that everyone will look at.

The below is how to set up the second part.

To use Benevolent Gaze you must install install foreman.
```ruby
gem install foreman
```

Then you will want to create a Procfile for foreman to use as well as a .env file.
Your Procfile should look like the following.

```
redis: redis-server
kiosk: kiosk 
tracker: tracker 
browser: open -a Google\ Chrome --args -url http://localhost:4567
```

Your .env file should have the following variables included.

```
AWS_ACCESS_KEY_ID='_insert_your_aws_access_key_here_'
AWS_CDN_BUCKET='_insert_your_aws_bucket_here_'
AWS_SECRET_ACCESS_KEY='_insert_your_aws_secret_access_key_here_'
BG_COMPANY_URL="http://www.yourcompanywebsite.com/where_you_mounted_the_benevolent_gaze_app"
PORT=4567
```
The port indicated above is correct. Leave this as 4567.

Now, when you run 
```
foreman start
```
Redis, the kiosk and the tracker will start doing their thing. It will also open up Chrome.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/benevolent_gaze/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
