require "./app/main"
# require "./lib/middleware/custom_logger"

use Rack::CommonLogger
use Rack::MethodOverride
run OmniApp
