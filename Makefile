ifdef TAGS
tags = --tags $(TAGS)
endif
ifdef SKIPTAGS
skiptags = --skip-tags $(SKIPTAGS)
endif


plan:
	@echo '[+] Terraform: Planning deploy'
	cd terraform && terraform init && terraform plan -out tfplan
	cd ..

deploy:
	@echo '[+] Terraform: Deploying infra to Azure'
	cd terraform && terraform apply tfplan
	python3 ./tf-parse-ips.py > ../ansible/inventory
	cd ..

provision:
	@echo '[+] Ansible: Provisioning infra'
	ansible-playbook -i inventory ./ansible/site.yml

destroy:
	@echo '[+] Ansible: Provisioning infra'
	cd terraform && terraform destroy -auto-approve
	cd ..
	rm ./ssh-keys/*
