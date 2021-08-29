TIMESTAMP=$(shell date +%Y%m%d-%H%M%S)


.PHONY: cpuinfo
cpuinfo:
	grep processor /proc/cpuinfo

.PHONY: services
services:
	systemctl list-units --type=service --state=running


.PHONY: enable-ruby
enable-ruby:
	sudo systemctl disable --now isucondition.go.service && sudo systemctl enable --now isucondition.ruby.service

.PHONY: enable-go
enable-go:
	cd webapp/go && go build -o isucondition main.go && sudo systemctl disable --now isucondition.ruby.service && sudo systemctl enable --now isucondition.go.service

.PHONY: status-ruby
status-ruby:
	systemctl status isucondition.ruby.service --no-pager

.PHONY: status-go
status-go:
	systemctl status isucondition.go.service --no-pager

.PHONY: rackup
rackup:
	bin/rackup.sh


.PHONY: bench-ruby
bench-ruby: enable-ruby clear-log restart-mysql restart-ruby restart-nginx bench

.PHONY: bench-go
bench-go: enable-go clear-log restart-mysql restart-go restart-nginx bench

.PHONY: bench
bench:
	cd ~/bench && stdbuf -o0 ./bench -all-addresses 127.0.0.11 -target 127.0.0.11:443 -tls -jia-service-url http://127.0.0.1:4999 | tee ../result/bench.log.${TIMESTAMP}


.PHONY: mysql
mysql:
	mysql -p isucondition


.PHONY: copy-ruby-conf
copy-ruby-conf:
	sudo cp setting/isucondition.ruby.service /etc/systemd/system/isucondition.ruby.service

.PHONY: copy-nginx-conf
copy-nginx-conf:
	sudo cp setting/nginx.conf /etc/nginx/nginx.conf

.PHONY: copy-mysql-conf
copy-mysql-conf:
	sudo cp setting/my.cnf /etc/my.cnf


.PHONY: restart-ruby
restart-ruby:
	sudo systemctl daemon-reload && sudo systemctl restart isucondition.ruby.service

.PHONY: restart-go
restart-go:
	sudo systemctl daemon-reload && sudo systemctl restart isucondition.go.service

.PHONY: restart-nginx
restart-nginx:
	sudo nginx -s reload

.PHONY: restart-mysql
restart-mysql: 
	sudo systemctl restart mariadb.service


.PHONY: clear-log
clear-log: clear-app-log clear-nginx-log clear-slow-log

.PHONY: clear-app-log
clear-app-log:
	rm -f /var/log/puma/stderr.log

.PHONY: clear-nginx-log
clear-nginx-log:
	sudo rm -f /var/log/nginx/*.log

.PHONY: clear-slow-log
clear-slow-log:
	sudo rm -f /var/log/mysql/slow.log


.PHONY: analyze-slow-log
analyze-slow-log:
	sudo pt-query-digest /var/log/mysql/slow.log | tee result/analyzed-slow-log.${TIMESTAMP}

.PHONY: analyze-access-log
analyze-access-log:
	sudo alp ltsv -m '/isu/[0-9a-f-]+/graph,/isu/[0-9a-f-]+,/api/condition/[0-9a-f-]+' --sort=sum -r --file /var/log/nginx/access.log | tee result/analyzed-access.log.${TIMESTAMP}
