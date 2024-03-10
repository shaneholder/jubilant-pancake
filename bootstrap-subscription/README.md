# Bootstrap the subscription

A storage account for Subscription bootstrap remote state needs to exist first this will
use a local plan file.  Make sure to login to the Azure subscription using `az login -o none`.

## Generate remote state storage

This storage account will contain the remote state for the subscription bootstrap.

### Run from the root of the repo
```
terraform -chdir=bootstrap-subscription/create-remote-state init
terraform -chdir=bootstrap-subscription/create-remote-state plan -out=plan.out
terraform -chdir=bootstrap-subscription/create-remote-state apply plan.out
```

This should generate the init.conf file used by the Subscription bootstrap process

## Bootstrap the Subscription and GitHub

When plan is executed 2 variables need to be supplied, the name of the GitHub org (usually a username) and the 
name of the repository containing this code.

```
terraform -chdir=bootstrap-subscription init -backend-config=init.conf
terraform -chdir=bootstrap-subscription plan -out=plan.out 
terraform -chdir=bootstrap-subscription apply plan.out
```

The apply will configure the currently selected subscription and the GitHub repository provided
by the `repo` variable.


## Cleanup

```
terraform -chdir=bootstrap-subscription destroy -auto-approve
terraform -chdir=bootstrap-subscription/create-remote-state destroy -auto-approve
```
