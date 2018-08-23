Changelog for the bc-lightstep-ruby gem.

h3. Pending Release



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
