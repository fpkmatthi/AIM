ifdef TAGS
tags = --tags $(TAGS)
endif
ifdef SKIPTAGS
skiptags = --skip-tags $(SKIPTAGS)
endif


plan:
	@echo '[+] Terraform: Planning deploy'
	cd terraform && terraform init && terraform plan -out tfplan

deploy:
	@echo '[+] Terraform: Deploying infra to Azure'
	cd terraform && terraform apply tfplan
	cd terraform && python3 ./tf-parse-ips.py > ../ansible/inventory

provision:
	@echo '[+] Ansible: Provisioning infra'
	cd ansible && ansible-playbook -i inventory site.yml

destroy:
	@echo '[+] Ansible: Provisioning infra'
	cd terraform && terraform destroy -auto-approve
	rm ./ssh-keys/*
