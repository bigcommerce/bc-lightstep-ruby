Changelog for the bc-lightstep-ruby gem.

### Pending Release

### 2.0.0

- Drop support for Ruby < 2.6
- Set default log level to INFO when no logger is provided

### 1.6.4

- Add `nomad.node.id` and `nomad.node.name` span tags via ENV mappings

### 1.6.3

- Add service.version to tags

### 1.6.2

- Add span.kind tags to boundary spans

### 1.6.1

- Add interception context for thread-safe interception per trace
- Fix issue when there are no interceptors configured
- Fix issue where there is more than one interceptor configured
- Only pass env tags if root span for service

### 1.6.0

- Allow for instantiation of interceptors at initialization time
- Pre-build tag values for ENV interceptor at initialization to reduce CPU usage per-span

### 1.5.2

- Add rspec helper for testing custom lightstep spans

### 1.5.1

- Add `hostname` preset for env var injection into spans

### 1.5.0

- Add interceptors that allow for global injection of tags into spans

### 1.4.0

- Add `frozen_string_literal: true` to all files
- Deprecate ruby 2.2 support

### 1.3.3

- Updates gemspec to allow for newer Faraday versions

### 1.3.2

- Fix compatibility issues with resque-scheduler and redis instrumentation

### 1.3.1

- Add various options to suppress redis trace spam
- Fix issue with pipeline commands in redis instrumentation

### 1.3.0

- Adds automatic Redis instrumentation support

### 1.2.2

- Allow for usage of blank access tokens, which can be used with disabled token checking + project-specific satellites

### 1.2.1

- Fix issue where in Rails controllers before the action occurs that an uninitialized reporter would cause a
  NoMethodError to occur (this most commonly occurs in test suites)

### 1.2.0

- Bump lightstep gem to 0.13
- Add LIGHTSTEP_MAX_BUFFERED_SPANS config ENV + setting for maximum number of spans to buffer
- Add LIGHTSTEP_MAX_LOG_RECORDS config ENV + setting for maximum number of log records that can be on a span
- Add LIGHTSTEP_MAX_REPORTING_INTERVAL_SECONDS config ENV + setting for max reporting flush interval to collector

### 1.1.8

- Handle issue that occurs if lightstep is disabled but the start_span method is still called
- Remove FORMAT_TEXT_MAP reference as this is no longer present in later lightstep gem versions

### 1.1.7

- Better handling of exceptions and tagged errors
- Lower timeouts for collector connections to reduce impact if collector is down/unreachable
- Always ensure spans are reported even in the case of exceptional failure 

### 1.1.6

- First OSS release

### 1.1.5

- Pin lightstep gem to 0.11.x due to backwards-incompatible change in 0.12.x
 
### 1.1.4

- Add enabled setting to explicitly disable lightstep at runtime. Can be toggled with LIGHTSTEP_ENABLED ENV var.

### 1.1.3

- Have http1 errors only flag as error if they are 500+ status codes

### 1.1.2

- Prevent span from starting if the reporter is not yet configured, as LightStep gem does not guard this case 

### 1.1.1

- Fix issues where Rack/Rails is prepending HTTP_ to headers, ensure right key format into carrier

### 1.1.0

- Add Faraday middleware for automatic tracing of outbound service calls
 
### 1.0.5

- Do not send GET params in rails controller instrumentation for http.url tag

### 1.0.4

- Rename span tags to fit the BigCommerce standardized tags
- Handle 500 errors in H1 requests properly

### 1.0.3

- Fix bug where active parent span was persisting between requests in rails controller requests
 
### 1.0.2

- Add Bigcommerce::Lightstep::Rails::ControllerInstrumentation module for tracing H1 controllers in Rails

### 1.0.0

- Initial public release
