# Ig

A small client for the [Instagram API with Unified Login](https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-unified-login):
send a client through Meta's login, get their Business Integration System User
Access Token, and read their Instagram professional accounts, media and insights
from `graph.facebook.com`. No dependencies beyond the Ruby standard library.

## Installation

```ruby
gem "ig", github: "lininglink/ig", branch: "master"
```

## Usage

```ruby
Ig.configure do |config|
  config.client_id = ENV["META_APP_ID"]         # App settings > Basic
  config.client_secret = ENV["META_APP_SECRET"]
  config.config_id = ENV["IG_CONFIG_ID"]        # API setup with Unified login > configuration
  # config.api_version = "v27.0"
end

# 1. Send the client to log in; they pick their business portfolio and Instagram account(s)
redirect_to Ig::OAuth.authorize_url(redirect_uri: callback_url, state: state)

# 2. On the callback, exchange the code. A "Never" expiration configuration gives
#    a token without expires_at.
token = Ig::OAuth.exchange_code(params[:code], redirect_uri: callback_url)

system_user = Ig::SystemUser.new(access_token: token.access_token)
system_user.client_business_id    # => "9001"
system_user.instagram_account_ids # => ["17841400000000001"]

# 3. Read an account
account = Ig::User.new(id: "17841400000000001", access_token: token.access_token)
account.profile                   # => {"id" => ..., "username" => ..., "followers_count" => ...}
account.media(limit: 25)          # => [Ig::Media, ...], newest first
account.insights_total(:reach, from: Date.new(2026, 10, 1), to: Date.new(2026, 10, 31))
```

`insights_total` asks for at most 30 days per request and adds the pieces up.
Days start at midnight in `Time.zone` when ActiveSupport is loaded (as in Rails),
otherwise in the local time zone.

API errors raise `Ig::HTTPError`; `invalid_token?` is true for code 190, which
means the client removed the app from their business portfolio.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ig. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/ig/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ig project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/ig/blob/master/CODE_OF_CONDUCT.md).
