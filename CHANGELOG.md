Changelog for the bc-lightstep-ruby gem.

h3. 1.0.4

- Rename span tags to fit the BigCommerce standardized tags
- Handle 500 errors in H1 requests properly

h3. 1.0.3

- Fix bug where active parent span was persisting between requests in rails controller requests
 
h3. 1.0.2

- Add Bigcommerce::Lightstep::Rails::ControllerInstrumentation module for tracing H1 controllers in Rails

h3. 1.0.0

- Initial public release
