#!/usr/bin/perl

use strict;
use warnings;

my $hadoop_master_instance_template;
my $hadoop_slave_instance_template;

my $master_template = `cat phd_cloudformation.template`;

my $master_nodes = 4;
my $master_node_type = 'm3.xlarge';
my $master_start_address = 100;
my $slave_nodes = 3; 
my $slave_node_type = 'i2.4xlarge';
my $slave_start_address = 100;

my $master_address = $master_start_address;
my $slave_address = $slave_start_address;
my $instances_info;

populate_templates();

my $master_count = 0;
while ( $master_count < $master_nodes ) {
  my $master_config = $hadoop_master_instance_template;
  $master_count++;
  $master_address++;
  
  grep(s/10.100.1.100/10.100.1.${master_address}/g,$master_config);
  grep(s/"Hadoopmaster.domain.local"/"HadoopMaster${master_count}.domain.local"/g,$master_config);
  grep(s/HadoopMasterInstance/HadoopMasterInstance${master_count}/,$master_config);
  
  $instances_info .= $master_config;
  }

my $slave_count = 0;
while ( $slave_count < $slave_nodes ) {
  my $slave_config = $hadoop_slave_instance_template;
  $slave_count++;
  $slave_address++;
  
  grep(s/10.100.2.100/10.100.2.${slave_address}/g,$slave_config);
  grep(s/"Hadoopslave.domain.local"/"HadoopSlave${slave_count}.domain.local"/g,$slave_config);
  grep(s/HadoopSlaveInstance/HadoopSlaveInstance${slave_count}/,$slave_config);
  
  $instances_info .= $slave_config;
  }

grep(s/"HadoopInstances" : "List",/$instances_info/g,$master_template);

print $master_template;

exit;


sub populate_templates {

$hadoop_master_instance_template = q~
    "HadoopMasterInstance" : {
      "Type" : "AWS::EC2::Instance",
      "Properties" : {
        "ImageId" : { "Fn::FindInMap" : [ "RHELRegionMap", { "Ref" : "AWS::Region" }, "AMI" ] },
        "PlacementGroupName" : { "Ref": "PlacementGroup" },
        "AvailabilityZone" : { "Fn::Select" : [ "1", { "Fn::GetAZs" : "" } ] },
        "Tags" : [ {
          "Key" : "Name",
          "Value" : "Hadoopmaster.domain.local"
        } ],
        "BlockDeviceMappings" : [
          { "DeviceName"  : "/dev/xvdc", "VirtualName" : "ephemeral0" },
          { "DeviceName"  : "/dev/xvdd", "VirtualName" : "ephemeral1" },
          { "DeviceName"  : "/dev/xvde", "VirtualName" : "ephemeral2" },
          { "DeviceName"  : "/dev/xvdf", "VirtualName" : "ephemeral3" },
          { "DeviceName"  : "/dev/xvdg", "VirtualName" : "ephemeral4" },
          { "DeviceName"  : "/dev/xvdh", "VirtualName" : "ephemeral5" },
          { "DeviceName"  : "/dev/xvdi", "VirtualName" : "ephemeral6" },
          { "DeviceName"  : "/dev/xvdj", "VirtualName" : "ephemeral7" }
        ],
        "InstanceType" : { "Ref" : "HadoopMasterInstanceType" },
        "PrivateIpAddress" : "10.100.1.100",
        "SubnetId" : { "Ref" : "HadoopClusterSubnetAz1" },
        "KeyName" : { "Ref" : "HadoopClusterPrivateKey" },
        "UserData": {
          "Fn::Base64": {
            "Fn::Join": [
              "\n",
              [
                "#!/bin/bash -v",
                "sleep 10",
                "",
                "yum update -y aws-cfn-bootstrap",
                "#disable things that complain about sudo and tty",
                "sed -i 's,Defaults    requiretty,#Defaults    requiretty,g' /etc/sudoers",
                "",
                ""
              ]
            ]
          }
        },
        "SecurityGroupIds" : [ { "Ref" : "HadoopClusterSecurityGroup" } ]
      }
    },
~;

$hadoop_slave_instance_template = q~
    "HadoopSlaveInstance" : {
      "Type" : "AWS::EC2::Instance",
      "Properties" : {
        "PlacementGroupName" : { "Ref": "PlacementGroup" },
        "ImageId" : { "Fn::FindInMap" : [ "RHELRegionMap", { "Ref" : "AWS::Region" }, "AMI" ] },
        "AvailabilityZone" : { "Fn::Select" : [ "1", { "Fn::GetAZs" : "" } ] },
        "Tags" : [ {
          "Key" : "Name",
          "Value" : "Hadoopslave.domain.local"
        } ],
        "BlockDeviceMappings" : [
          { "DeviceName"  : "/dev/xvdc", "VirtualName" : "ephemeral0" },
          { "DeviceName"  : "/dev/xvdd", "VirtualName" : "ephemeral1" },
          { "DeviceName"  : "/dev/xvde", "VirtualName" : "ephemeral2" },
          { "DeviceName"  : "/dev/xvdf", "VirtualName" : "ephemeral3" },
          { "DeviceName"  : "/dev/xvdg", "VirtualName" : "ephemeral4" },
          { "DeviceName"  : "/dev/xvdh", "VirtualName" : "ephemeral5" },
          { "DeviceName"  : "/dev/xvdi", "VirtualName" : "ephemeral6" },
          { "DeviceName"  : "/dev/xvdj", "VirtualName" : "ephemeral7" }
        ],
        "InstanceType" : { "Ref" : "HadoopSlaveInstanceType" },
        "PrivateIpAddress" : "10.100.2.100",
        "SubnetId" : { "Ref" : "HadoopClusterSubnetAz2" },
        "KeyName" : { "Ref" : "HadoopClusterPrivateKey" },
        "UserData": {
          "Fn::Base64": {
            "Fn::Join": [
              "\n",
              [
                "#!/bin/bash -v",
                "sleep 10",
                "",
                "yum update -y aws-cfn-bootstrap",
                "#disable things that complain about sudo and tty",
                "sed -i 's,Defaults    requiretty,#Defaults    requiretty,g' /etc/sudoers",
                "",
                ""
              ]
            ]
          }
        },
        "SecurityGroupIds" : [ { "Ref" : "HadoopClusterSecurityGroup" } ]
      }
    },
~;
}
