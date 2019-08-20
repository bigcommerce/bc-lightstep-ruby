# bc-lightstep-ruby - LightStep distributed tracing

[![CircleCI](https://circleci.com/gh/bigcommerce/bc-lightstep-ruby/tree/master.svg?style=svg)](https://circleci.com/gh/bigcommerce/bc-lightstep-ruby/tree/master) [![Gem Version](https://badge.fury.io/rb/bc-lightstep-ruby.svg)](https://badge.fury.io/rb/bc-lightstep-ruby) [![Inline docs](http://inch-ci.org/github/bigcommerce/bc-lightstep-ruby.svg?branch=master)](http://inch-ci.org/github/bigcommerce/bc-lightstep-ruby)

Adds [LightStep](https://lightstep.com) tracing support for Ruby. This is an extension of the 
[LightStep ruby gem](https://github.com/lightstep/lightstep-tracer-ruby) and adds extra functionality and resiliency.

## Installation

```ruby
gem 'bc-lightstep-ruby'
```

Then in an initializer or before use:

```ruby
require 'bigcommerce/lightstep'
Bigcommerce::Lightstep.configure do |c|
  c.component_name = 'myapp'
  c.access_token = 'abcdefg'
  c.host = 'my.lightstep.service.io'
  c.port = 8080
  c.verbosity = 1
end
```

Then in your script:

```ruby
tracer = Bigcommerce::Lightstep::Tracer.instance
tracer.start_span('my-span', context: request.headers) do |span|
  span.set_tag('my-tag', 'value')
  # do thing to measure
end
```

### Environment Config

bc-lightstep-ruby can be automatically configured from these ENV vars, if you'd rather use that instead:

| Name | Description |
| ---- | ----------- |
| LIGHTSTEP_ENABLED | Flag to determine whether to broadcast spans. Defaults to (1) enabled, 0 will disable.| 1 |
| LIGHTSTEP_COMPONENT_NAME | The component name to use | '' | 
| LIGHTSTEP_ACCESS_TOKEN | The access token to use to connect to the collector. Optional. | '' | 
| LIGHTSTEP_HOST | Host of the collector. | `lightstep-collector.linkerd` |
| LIGHTSTEP_PORT | Port of the collector. | `4140` |
| LIGHTSTEP_SSL_VERIFY_PEER | If using 443 as the port, toggle SSL verification. | true |
| LIGHTSTEP_MAX_BUFFERED_SPANS | The maximum number of spans to buffer before dropping. | `1_000` |
| LIGHTSTEP_MAX_LOG_RECORDS | Maximum number of log records on a span to accept. | `1_000` |
| LIGHTSTEP_MAX_REPORTING_INTERVAL_SECONDS | The maximum number of seconds to wait before flushing the report to the collector. | 3.0 |
| LIGHTSTEP_VERBOSITY | The verbosity level of lightstep logs. | 1 |

Most systems will only need to customize the component name.

### Instrumenting Rails Controllers

Just drop this include into ApplicationController:

```ruby
include Bigcommerce::Lightstep::RailsControllerInstrumentation
```

### Faraday Middleware

To use the supplied faraday middleware, simply:

```ruby
Faraday.new do |faraday|
  faraday.use Bigcommerce::Lightstep::Middleware::Faraday, 'name-of-external-service'
end
```

Spans will be built with the external service name. It's generally _not_ a good idea to use the Faraday adapter
with internal services that are also instrumented with LightStep - use the Faraday adapter on external services
or systems outside of your instrumenting control.

### Redis

This gem will automatically detect and instrumnent Redis calls when they are made using the `Redis::Client` class.
It will set as tags on the span the host, port, db instance, and the command (but no arguments). 

Note that this will not record redis timings if they are a root span. This is to prevent trace spamming. You can 
re-enable this by setting the `redis_allow_root_spans` configuration option to `true`.

It also excludes `ping` commands, and you can provide a custom list by setting the `redis_excluded_commands` 
configuration option to an array of commands to exclude.

## RSpec

This library comes with a built-in matcher for testing span blocks. In your rspec config:

```ruby
require 'bigcommerce/lightstep/rspec'
```

Then, in a test:

```ruby
it 'should create a lightstep span' do
  expect { my_code_here }.to create_a_lightstep_span(name: 'my-span-name', tags: { tag_one: 'value-here' })
end
```

## Global Interceptors

This library has global interceptor support that will allow access to each span as it is built. This allows you to
dynamically inject tags or alter spans as they are collected. You can configure interceptors via an initializer:

```ruby
Bigcommerce::Lightstep.configure do |c|
  c.interceptors.use(MyInterceptor, an_option: 123)
  # or, alternatively:
  c.interceptors.use(MyInterceptor.new(an_option: 123)) 
end
```

It's important to note that this is a CPU-intensive operation as interceptors will be run for every `start_span` tag,
so don't build interceptors that require lots of processing power or that would impact latencies.

### ENV Interceptor

Provided out of the box is an interceptor to automatically inject ENV vars into span tags. You can configure like so:

```ruby

Bigcommerce::Lightstep.configure do |c|
  c.interceptors.use(::Bigcommerce::Lightstep::Interceptors::Env.new(
    keys: {
      version: 'VERSION'
    },
    presets: [:nomad, :hostname]
  ))
end
```

The `keys` argument allows you to pass a `span tag => ENV key` mapping that will assign those ENV vars to spans. The
`presets` argument comes with a bunch of preset mappings you can use rather than manually mapping them yourself.

Note that this interceptor _must_ be instantiated in configuration, rather than passing the class and options,
as it needs to pre-materialize the ENV values to reduce CPU usage. 

## License

Copyright (c) 2018-present, BigCommerce Pty. Ltd. All rights reserved 

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the 
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit 
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the 
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
