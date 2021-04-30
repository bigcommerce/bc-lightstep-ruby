# frozen_string_literal: true

# Copyright (c) 2018-present, BigCommerce Pty. Ltd. All rights reserved
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
$:.push File.expand_path('lib', __dir__)
require 'bigcommerce/lightstep/version'

Gem::Specification.new do |spec|
  spec.name          = 'bc-lightstep-ruby'
  spec.version       = Bigcommerce::Lightstep::VERSION
  spec.authors       = ['Shaun McCormick']
  spec.email         = ['shaun.mccormick@bigcommerce.com']

  spec.summary       = %q{Gem for lightstep distributed tracing}
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/bigcommerce/bc-lightstep-ruby'
  spec.license       = 'MIT'

  spec.files         = Dir['README.md', 'CHANGELOG.md', 'CODE_OF_CONDUCT.md', 'lib/**/*', 'bc-lightstep-ruby.gemspec']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.6'

  spec.add_development_dependency 'activerecord', '> 4'
  spec.add_development_dependency 'bundler-audit', '~> 0.6'
  spec.add_development_dependency 'rake', '>= 12.0'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.4'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'simplecov', '~> 0.15'
  spec.add_development_dependency 'pry', '>= 0.12'

  spec.add_development_dependency 'null-logger', '~> 0.1'
  spec.add_development_dependency 'redis', '~> 4'

  spec.add_runtime_dependency 'activesupport', '>= 4'
  spec.add_runtime_dependency 'lightstep', '~> 0.17.0'
  spec.add_runtime_dependency 'faraday', ['>= 0.8', '< 2.0']
end
