#!/bin/bash
# To set template parameters, add the -p options
# to the end of the stacker command:
#
# stacker launch -n <%= app_name %> -t <%= app_name %>.json --disable-rollback \
# -p VpcId:$VPC_ID \
# SubnetId:$SUBNET_ID \
# RemoteAccessSG:$REMOTE_ACCESS_SG \
# KeyPairName:$KEYPAIR_NAME \
# InstanceType:$INSTANCE_TYPE \
# ImageId:$IMAGE_ID
stacker launch -n <%= app_name %> -t <%= app_name %>.json --disable-rollback
