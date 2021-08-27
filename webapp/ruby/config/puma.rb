workers 4
preload_app!

stdout_redirect nil, '/var/log/puma/stderr.log', true
