DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..

VERSION=`cat version.txt`

IPYTHON_OPTS=notebook \
PYSPARK_DRIVER_PYTHON=ipython \
$DIR/lib/spark-1.6.0-bin-hadoop2.6/bin/pyspark \
	--conf spark.cassandra.connection.host="localhost" \
	--driver-memory 2g \
	--master local[*] \
	--jars $DIR/target/scala-2.10/pyspark-cassandra-assembly-$VERSION.jar \
	--py-files $DIR/target/scala-2.10/pyspark-cassandra-assembly-$VERSION.jar \
	$@

