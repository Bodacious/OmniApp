require 'opal'
Opal.append_path 'browser_app'
Opal.append_path 'core_app'
server = Opal::SimpleServer.new do |s|
  # the name of the ruby file to load. To use more files they must be required from here (see app)
  s.main = 'application'
end
run(server)