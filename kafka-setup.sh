#!/bin/bash
# Install script for Strimzi KAFKA on OCP/KUBE

PLAFORM=$1
REPLICA=3
PROJECT=streaming
KAFKAVERSON=0.18.0
KAFKACLUSTER=prod-cluster
KAFKAPVC=2Gi
HIP=`ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1`
KAFKADNS=$HIP.nip.io
STORAGECLASS=kubenfs-storage

if [[ ! $PLAFORM =~ ^( |ocp|kube)$ ]]; then 
 echo "Usage: kafka-setup.sh <ocp or kube>"
 echo "Example: kafka-setup.sh ocp|kube"
 exit
fi

mkdir kafka
cd kafka

wget https://github.com/strimzi/strimzi-kafka-operator/releases/download/$KAFKAVERSON/strimzi-cluster-operator-$KAFKAVERSON.yaml
sed -i "s/myproject/$PROJECT/" strimzi-cluster-operator-$KAFKAVERSON.yaml 

if [[ "$REPLICA" == "3" ]]; then
 LOGVAL=2
else
 LOGVAL=1
fi

cat <<EOF > kafka.yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: $KAFKACLUSTER
spec:
  kafka:
    version: 2.5.0
    replicas: $REPLICA
    listeners:
      plain: {}
      tls: {}
      external:
        type: route
    config:
      offsets.topic.replication.factor: $REPLICA
      transaction.state.log.replication.factor: $REPLICA
      transaction.state.log.min.isr: $LOGVAL
      log.message.format.version: "2.5"
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        class: $STORAGECLASS
        size: $KAFKAPVC
        deleteClaim: false
  zookeeper:
    replicas: $REPLICA
    storage:
      type: persistent-claim
      class: $STORAGECLASS	  
      size: $KAFKAPVC
      deleteClaim: false
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOF

if [[ "$PLAFORM" == "ocp" ]]; then
 oc new-project $PROJECT
 oc apply -f strimzi-cluster-operator-$KAFKAVERSON.yaml -n $PROJECT
 
 echo "Waiting for Strimzi Cluster Operator POD ready .."
 SKAFPOD=$(oc get pod -n $PROJECT | grep strimzi-cluster-operator | awk '{print $1}')
 while [[ $(oc get pods $SKAFPOD -n $PROJECT -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do printf '.'; sleep 2; done

 oc apply -f kafka.yaml -n $PROJECT
else
 kubectl create ns $PROJECT
 kubectl apply -f strimzi-cluster-operator-$KAFKAVERSON.yaml -n $PROJECT
 
 echo "Waiting for Strimzi Cluster Operator POD ready .."
 SKAFPOD=$(kubectl get pod -n $PROJECT | grep strimzi-cluster-operator | awk '{print $1}')
 while [[ $(kubectl get pods $SKAFPOD -n $PROJECT -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do printf '.'; sleep 2; done
 
cat <<EOF > kube-kafka.yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: $KAFKACLUSTER
spec:
  kafka:
    version: 2.5.0
    replicas: $REPLICA
    listeners:
      plain: {}
      tls: {}	  
      external:
        type: ingress
        configuration:
          bootstrap:
            host: $KAFKACLUSTER-bootstrap-$PROJECT.$KAFKADNS
          brokers:
          - broker: 0
            host: $KAFKACLUSTER-broker-0-$PROJECT.$KAFKADNS
          - broker: 1
            host: $KAFKACLUSTER-broker-1-$PROJECT.$KAFKADNS
          - broker: 2
            host: $KAFKACLUSTER-broker-2-$PROJECT.$KAFKADNS			
    config:
      offsets.topic.replication.factor: $REPLICA
      transaction.state.log.replication.factor: $REPLICA
      transaction.state.log.min.isr: $LOGVAL
      log.message.format.version: "2.5"
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        class: $STORAGECLASS
        size: $KAFKAPVC
        deleteClaim: false
  zookeeper:
    replicas: $REPLICA
    storage:
      type: persistent-claim
      class: $STORAGECLASS	  
      size: $KAFKAPVC
      deleteClaim: false
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOF
 
 #sed -i "s/route/ingress/g" kafka.yaml
 #kubectl apply -f kafka.yaml -n $PROJECT
 if [[ "$REPLICA" == "1" ]]; then
 sed -i '/broker-0/,+3 d' kube-kafka.yaml; sed -i 's/broker-2/broker-0/' kube-kafka.yaml
 fi 
 kubectl apply -f kube-kafka.yaml -n $PROJECT
fi

echo "Waiting everything ready .."
sleep 30
kubectl get all -n $PROJECT

# Setup for Kafka Access
wget https://raw.githubusercontent.com/cloudcafetech/ocpsetup/master/kafka-access-setup.sh
chmod +x ./kafka-access-setup.sh
#./kafka-access-setup.sh
