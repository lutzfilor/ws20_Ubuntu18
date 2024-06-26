#   Owner       Lutz Filor
#   Created     10/14/2020
# 
#   Synopsys    How to use make as a tool, for making things
# 
#args= `arg="$(filter-out $@,$(MAKECMDGOALS))" && echo $${arg:-${1}}`
#args= `arg="$(filter-out $@,$(MAKECMDGOALS))" ;  echo $${arg:-${1}}`

test:
	@echo $(call args, defaultstring)

init:
	@echo   project/$(arg1)
	@mkdir -p 'project/$(arg1)'

action:
	@echo    Hi, Lutz !!
	@echo action $(filter-out $@,$(MAKECMDGOALS))

%:      #   Catch all Command goals
	@:  #   Silent do nothing - suppress error messages
