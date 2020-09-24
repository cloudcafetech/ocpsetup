## Some KAFKA testing notes

### Download KAFKA tools

```
wget http://mirror.cc.columbia.edu/pub/software/apache/kafka/2.4.1/kafka_2.11-2.4.1.tgz
tar -zxvf kafka_2.11-2.4.1.tgz
rm -rf kafka_2.11-2.4.1.tgz
```

### On terminal, start producer

```
KAFKA_HOME=/root/kafka/kafka_2.11-2.4.1
KAFKAROUTE=prod-kafka-cluster-kafka-bootstrap-streaming.10.128.0.46.nip.io:443
TOPIC=my-topic
PROPFILE=prod-kafka-cluster-ocp.properties
$KAFKA_HOME/bin/kafka-console-producer.sh --broker-list $KAFKAROUTE --topic $TOPIC --producer.config ./$PROPFILE
```

### On another terminal, start consumer

```
KAFKA_HOME=/root/kafka/kafka_2.11-2.4.1
KAFKAROUTE=prod-kafka-cluster-kafka-bootstrap-streaming.10.128.0.46.nip.io:443
TOPIC=my-topic
PROPFILE=prod-kafka-cluster-ocp.properties
$KAFKA_HOME/bin/kafka-console-consumer.sh  --bootstrap-server $KAFKAROUTE --topic $TOPIC --consumer.config ./$PROPFILE --from-beginning
```

### To list topic

```
KAFKA_HOME=/root/kafka/kafka_2.11-2.4.1
KAFKAROUTE=prod-kafka-cluster-kafka-bootstrap-streaming.10.128.0.46.nip.io:443
PROPFILE=prod-kafka-cluster-ocp.properties
$KAFKA_HOME/bin/kafka-topics.sh --bootstrap-server $KAFKAROUTE --list --command-config ./$PROPFILE
```

### Docker tool

- Create a folder

```
mkdir /root/kafka
cd /root/kafka
```

- Copy truststore.jks file from Kafka server

```scp -i <PEM-FILE> <USER>@<SERVER>:/home/<USER>/truststore.jks . ```

- Create file

```
KAFKAROUTE=prod-kafka-cluster-kafka-bootstrap-streaming.10.128.0.46.nip.io:443
TRUSTFILE=truststore.jks
PASSWORD=admin2675

cat <<EOF > application.yml
akhq:
  connections:
    kube-kafka-server:
      properties:
        bootstrap.servers: $KAFKAROUTE
        security.protocol: SSL
        ssl.truststore.location: /tmp/$TRUSTFILE
        ssl.truststore.password: $PASSWORD
EOF
```

- Run Docker 

```
docker run -d --name kdmin --restart=always \
-v /root/kafka/application.yml:/app/application.yml \
-v /root/kafka:/tmp \
-p 8081:8080 tchiotludo/akhq
```
