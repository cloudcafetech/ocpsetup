#!/bin/bash
# Install script for Accessing Strimzi KAFKA Outside of OCP/KUBE

PLAFORM=$1
PROJECT=streaming
KAFKACLUSTER=prod-cluster
USER=test
PASSWORD=admin2675

if [[ ! $PLAFORM =~ ^( |ocp|kube)$ ]]; then 
 echo "Usage: kafka-access-setup.sh <ocp or kube>"
 echo "Example: kafka-access-setup.sh ocp|kube"
 exit
fi

mkdir kafkacert
cd kafkacert

yum install java-1.8.0-openjdk -y

if [[ "$PLAFORM" == "ocp" ]]; then
 oc project $PROJECT
 oc extract secret/$KAFKACLUSTER-cluster-ca-cert -n $PROJECT --keys=ca.crt --to=- > $USER-$KAFKACLUSTER-ca.crt
 keytool -import -trustcacerts -alias $USER-$KAFKACLUSTER -file $USER-$KAFKACLUSTER-ca.crt -keystore $USER-$KAFKACLUSTER-truststore.jks -storepass $PASSWORD -noprompt
 rm -rf $USER-$KAFKACLUSTER-ca.crt
 KAFKAROUTE=$(oc get routes $KAFKACLUSTER-kafka-bootstrap-$PROJECT -n $PROJECT | grep -v HOST | awk '{ print $2 }')
else
 kubectl ns $PROJECT
 kubectl get secret $KAFKACLUSTER-cluster-ca-cert -n $PROJECT --keys=ca.crt --to=- > $USER-$KAFKACLUSTER-ca.crt
 keytool -import -trustcacerts -alias $USER-$KAFKACLUSTER -file $USER-$KAFKACLUSTER-ca.crt -keystore $USER-$KAFKACLUSTER-truststore.jks -storepass $PASSWORD -noprompt
 rm -rf $USER-$KAFKACLUSTER-ca.crt 
 KAFKAROUTE=$(kubectl get ing n $PROJECT | grep kafka-bootstrap | grep -v HOST | awk '{ print $1 }')
fi


echo bootstrap.servers=$KAFKAROUTE:443 >> $USER-$KAFKACLUSTER-$PLAFORM.properties
echo security.protocol=SSL >> $USER-$KAFKACLUSTER-$PLAFORM.properties
echo ssl.truststore.password=$PASSWORD >> $USER-$KAFKACLUSTER-$PLAFORM.properties
echo ssl.truststore.location=/root/kafka/$USER-$KAFKACLUSTER-truststore.jks >> $USER-$KAFKACLUSTER-$PLAFORM.properties

cp $USER-$KAFKACLUSTER-$PLAFORM.properties $USER-$KAFKACLUSTER-truststore.jks /home/centos/
chown centos:centos /home/centos/$USER-$KAFKACLUSTER*

