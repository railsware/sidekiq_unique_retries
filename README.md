# Unique Retries for Sidekiq [![Build Status](https://travis-ci.org/railsware/sidekiq_unique_retries.svg?branch=master)](https://travis-ci.org/railsware/sidekiq_unique_retries)

This is extension for sidekiq that allows to have unique retries for your unique jobs.
It should work for any sidekiq unique job extension if it guarantees that only one unique job can be performing at the same time.
Currently this gem supports SidekiqUniqueJobs extension but you may wrote own adapter.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq_unique_retries'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq_unique_retries

## Authors

* [Andriy Yanko](http://ayanko.github.io)

## References

* https://github.com/mperham/sidekiq
* https://github.com/mhenrixon/sidekiq-unique-jobs
