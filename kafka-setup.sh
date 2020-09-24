#!/bin/bash
# Install script for Strimzi KAFKA on OCP/KUBE

PLAFORM=$1
REPLICA=3
PROJECT=streaming
KAFKAVERSON=0.18.0
KAFKACLUSTER=prod-cluster
KAFKAPVC=2Gi
KAFKADNS=10.128.0.46.nip.io
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
 LOGVAL=3
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
 while [[ $(oc get pods jaeger-operator-0 -n $PROJECT -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do printf '.'; sleep 2; done

 oc apply -f kafka.yaml -n $PROJECT
else
 kubectl create ns $PROJECT
 kubectl apply -f strimzi-cluster-operator-$KAFKAVERSON.yaml -n $PROJECT
 
 echo "Waiting for Strimzi Cluster Operator POD ready .."
 SKAFPOD=$(kubectl get pod -n $PROJECT | grep strimzi-cluster-operator | awk '{print $1}')
 while [[ $(kubectl get pods jaeger-operator-0 -n $PROJECT -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do printf '.'; sleep 2; done
 
 kubectl apply -f kafka.yaml -n $PROJECT
fi

echo "Waiting everything ready .."
sleep 30
kubectl get all -n $PROJECT


