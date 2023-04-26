#!/usr/bin/env python3
import json, yaml, sys, getopt, csv, time

TF_STATE_FILE='./terraform.tfstate'
TF_DATA=''

def loadTerraformState():
    try:
        with open(TF_STATE_FILE) as f:
            return json.load(f)
    except Exception as e:
        print('Error loading Terraform state file (%s)' % TF_STATE_FILE)
        exit()

TF_DATA=loadTerraformState()

def moduleExits(module_name):
    for res in TF_DATA['resources']:
        if 'module' in res:
            module = res['module'].split('.')[1]
            if module == module_name:
                return True
    return False

def extractHostsInfo():
    ini_output = ''

    output = {
        'all': {}
    }
    for module in TF_DATA['outputs']:
        mod = module.split('-')[1]
        output['all'][mod] = {
            'hosts': {}
        }
        if 'ips' in TF_DATA['outputs'][module]['value'] and moduleExits(mod):
            hosts = TF_DATA['outputs'][module]['value']['ips']
            for host in hosts:
                ansible_user = ''
                for rsrc in TF_DATA['resources']:
                    if 'module' in rsrc: 
                        mod2 = rsrc['module'].split('.')[1]
                        if mod == mod2 and rsrc['type']=='azurerm_linux_virtual_machine':
                            for instance in rsrc['instances']:
                                if instance['attributes']['computer_name'] == host:
                                    ansible_user = instance['attributes']['admin_username']
                    # else:
                    #     break
                # print(mod)
                # print(hosts[host])
                ini_output += '\n['+mod+']\n'+host+' ansible_host='+hosts[host][0]+' ansible_user='+ansible_user+' ansible_ssh_private_key_file=../ssh_keys/'+host+' ansible_ssh_extra_args="-o StrictHostKeyChecking=no"\n'
                output['all'][mod]['hosts'][host] = {
                        'ansible_host': hosts[host][0],
                        'ansible_user': ansible_user,
                        'ssh-key': '../ssh_keys/'+host
                }
    print(ini_output)
    return output




hostsinfo = extractHostsInfo()


# print(yaml.safe_dump(hostsinfo, default_flow_style=False))


