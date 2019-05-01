Changelog for the bc-lightstep-ruby gem.

h3. Pending Release

- Add `frozen_string_literal: true` to all files
- Deprecate ruby 2.2 support

h3. 1.3.3

- Updates gemspec to allow for newer Faraday versions

h3. 1.3.2

- Fix compatibility issues with resque-scheduler and redis instrumentation

h3. 1.3.1

- Add various options to suppress redis trace spam
- Fix issue with pipeline commands in redis instrumentation

h3. 1.3.0

- Adds automatic Redis instrumentation support

h3. 1.2.2

- Allow for usage of blank access tokens, which can be used with disabled token checking + project-specific satellites

h3. 1.2.1

- Fix issue where in Rails controllers before the action occurs that an uninitialized reporter would cause a
  NoMethodError to occur (this most commonly occurs in test suites)

h3. 1.2.0

- Bump lightstep gem to 0.13
- Add LIGHTSTEP_MAX_BUFFERED_SPANS config ENV + setting for maximum number of spans to buffer
- Add LIGHTSTEP_MAX_LOG_RECORDS config ENV + setting for maximum number of log records that can be on a span
- Add LIGHTSTEP_MAX_REPORTING_INTERVAL_SECONDS config ENV + setting for max reporting flush interval to collector

h3. 1.1.8

- Handle issue that occurs if lightstep is disabled but the start_span method is still called
- Remove FORMAT_TEXT_MAP reference as this is no longer present in later lightstep gem versions

h3. 1.1.7

- Better handling of exceptions and tagged errors
- Lower timeouts for collector connections to reduce impact if collector is down/unreachable
- Always ensure spans are reported even in the case of exceptional failure 

h3. 1.1.6

- First OSS release

h3. 1.1.5

- Pin lightstep gem to 0.11.x due to backwards-incompatible change in 0.12.x
 
h3. 1.1.4

- Add enabled setting to explicitly disable lightstep at runtime. Can be toggled with LIGHTSTEP_ENABLED ENV var.

h3. 1.1.3

- Have http1 errors only flag as error if they are 500+ status codes

h3. 1.1.2

- Prevent span from starting if the reporter is not yet configured, as LightStep gem does not guard this case 

h3. 1.1.1

- Fix issues where Rack/Rails is prepending HTTP_ to headers, ensure right key format into carrier

h3. 1.1.0

- Add Faraday middleware for automatic tracing of outbound service calls
 
h3. 1.0.5

- Do not send GET params in rails controller instrumentation for http.url tag

h3. 1.0.4

- Rename span tags to fit the BigCommerce standardized tags
- Handle 500 errors in H1 requests properly

h3. 1.0.3

- Fix bug where active parent span was persisting between requests in rails controller requests
 
h3. 1.0.2

- Add Bigcommerce::Lightstep::Rails::ControllerInstrumentation module for tracing H1 controllers in Rails

h3. 1.0.0

- Initial public release
