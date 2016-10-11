PySpark Cassandra
=================

PySpark Cassandra is no longer maintained. Development effort has moved away from Spark to pure Python environment.

---

[![Build Status](https://travis-ci.org/TargetHolding/pyspark-cassandra.svg)](https://travis-ci.org/TargetHolding/pyspark-cassandra)
[![Codacy Badge](https://api.codacy.com/project/badge/grade/1fb73418b06b4db18e3a4103a0ce056c)](https://www.codacy.com/app/frensjan/pyspark-cassandra)

PySpark Cassandra brings back the fun in working with Cassandra data in PySpark.

This module provides python support for Apache Spark's Resillient Distributed Datasets from Apache Cassandra CQL rows using [Cassandra Spark Connector](https://github.com/datastax/spark-cassandra-connector) within PySpark, both in the interactive shell and in python programmes submitted with spark-submit.

This project was initially forked from https://github.com/Parsely/pyspark-cassandra, but in order to submit it to http://spark-packages.org/, a plain old repository was created. 

**Contents:**
* [Compatibility](#compatibility)
* [Using with PySpark](#using-with-pyspark)
* [Using with PySpark shell](#using-with-pyspark-shell)
* [Building](#building)
* [API](#api)
* [Examples](#examples)
* [Problems / ideas?](#problems--ideas)
* [Contributing](#contributing)



Compatibility
-------------
Feedback on (in-)compatibility is much appreciated.

### Spark
The current version of PySpark Cassandra is succesfully used with Spark version 1.5 and 1.6. Use older versions for Spark 1.2, 1.3 or 1.4.

### Cassandra
PySpark Cassandra is compatible with Cassandra:
* 2.1.5 and higher
* 2.2
* 3

### Python
PySpark Cassandra is used with python 2.7, python 3.3 and 3.4.

### Scala
PySpark Cassandra is currently only packaged for Scala 2.10



Using with PySpark
------------------

### With Spark Packages
Pyspark Cassandra is published at [Spark Packages](http://spark-packages.org/package/TargetHolding/pyspark-cassandra). This allows easy usage with Spark through:
```bash
spark-submit \
	--packages TargetHolding/pyspark-cassandra:<version> \
	--conf spark.cassandra.connection.host=your,cassandra,node,names
```


### Without Spark Packages

```bash
spark-submit \
	--jars /path/to/pyspark-cassandra-assembly-<version>.jar \
	--driver-class-path /path/to/pyspark-cassandra-assembly-<version>.jar \
	--py-files /path/to/pyspark-cassandra-assembly-<version>.jar \
	--conf spark.cassandra.connection.host=your,cassandra,node,names \
	--master spark://spark-master:7077 \
	yourscript.py
```
(note that the the --driver-class-path due to [SPARK-5185](https://issues.apache.org/jira/browse/SPARK-5185))
(also not that the assembly will include the python source files, quite similar to a python source distribution)


Using with PySpark shell
------------------------

Replace `spark-submit` with `pyspark` to start the interactive shell and don't provide a script as argument and then import PySpark Cassandra. Note that when performing this import the `sc` variable in pyspark is augmented with the `cassandraTable(...)` method.

```python
import pyspark_cassandra
```



Building
--------

### For [Spark Packages](http://spark-packages.org/package/TargetHolding/pyspark-cassandra) Pyspark Cassandra can be published using:
```bash
sbt compile
```
The package can be published locally with:
```bash
sbt spPublishLocal
```
The package can be published to Spark Packages with (requires authentication and authorization):
```bash
make publish
```

### For local testing / without Spark Packages
A Java / JVM library as well as a python library is required to use PySpark Cassandra. They can be built with:

```bash
make dist
```

This creates a fat jar with the Spark Cassandra Connector and additional classes for bridging Spark and PySpark for Cassandra data and the .py source files at: `target/scala-2.10/pyspark-cassandra-assembly-<version>.jar`



API
---

The PySpark Cassandra API aims to stay close to the Cassandra Spark Connector API. Reading its [documentation](https://github.com/datastax/spark-cassandra-connector/#documentation) is a good place to start.


### pyspark_cassandra.RowFormat

The primary representation of CQL rows in PySpark Cassandra is the ROW format. However `sc.cassandraTable(...)` supports the `row_format` argument which can be any of the constants from `RowFormat`:
* `DICT`: The default layout, a CQL row is represented as a python dict with the CQL row columns as keys.
* `TUPLE`: A CQL row is represented as a python tuple with the values in CQL table column order / the order of the selected columns.
* `ROW`: A pyspark_cassandra.Row object representing a CQL row.

Column values are related between CQL and python as follows:

|  **CQL**  |       **python**      |
|:---------:|:---------------------:|
|   ascii   |    unicode string     |
|   bigint  |         long          |
|    blob   |       bytearray       |
|  boolean  |        boolean        |
|  counter  |       int, long       |
|  decimal  |        decimal        |
|   double  |         float         |
|   float   |         float         |
|    inet   |          str          |
|    int    |          int          |
|    map    |         dict          |
|    set    |          set          |
|    list   |         list          |
|    text   |    unicode string     |
| timestamp |   datetime.datetime   |
|  timeuuid |       uuid.UUID       |
|  varchar  |    unicode string     |
|   varint  |         long          |
|    uuid   |       uuid.UUID       |
|   _UDT_   | pyspark_cassandra.UDT |


### pyspark_cassandra.Row

This is the default type to which CQL rows are mapped. It is directly compatible with `pyspark.sql.Row` but is (correctly) mutable and provides some other improvements.


### pyspark_cassandra.UDT

This type is structurally identical to pyspark_cassandra.Row but serves user defined types. Mapping to custom python types (e.g. via CQLEngine) is not yet supported.
 

### pyspark_cassandra.CassandraSparkContext

A `CassandraSparkContext` is very similar to a regular `SparkContext`. It is created in the same way, can be used to read files, parallelize local data, broadcast a variable, etc. See the [Spark Programming Guide](https://spark.apache.org/docs/1.2.0/programming-guide.html) for more details. *But* it exposes one additional method:

* ``cassandraTable(keyspace, table, ...)``:	Returns a CassandraRDD for the given keyspace and table. Additional arguments which can be provided:

  * `row_format` can be set to any of the `pyspark_cassandra.RowFormat` values (defaults to `ROW`)
  * `split_size` sets the size in the number of CQL rows in each partition (defaults to `100000`)
  * `fetch_size` sets the number of rows to fetch per request from Cassandra (defaults to `1000`)
  * `consistency_level` sets with which consistency level to read the data (defaults to `LOCAL_ONE`)


### pyspark.RDD

PySpark Cassandra supports saving arbitrary RDD's to Cassandra using:

* ``rdd.saveToCassandra(keyspace, table, ...)``: Saves an RDD to Cassandra. The RDD is expected to contain dicts with keys mapping to CQL columns. Additional arguments which can be supplied are:

  * ``columns(iterable)``: The columns to save, i.e. which keys to take from the dicts in the RDD.
  * ``batch_size(int)``: The size in bytes to batch up in an unlogged batch of CQL inserts.
  * ``batch_buffer_size(int)``: The maximum number of batches which are 'pending'.
  * ``batch_grouping_key(string)``: The way batches are formed (defaults to "partition"):
     * ``all``: any row can be added to any batch
     * ``replicaset``: rows are batched for replica sets 
     * ``partition``: rows are batched by their partition key
  * ``consistency_level(cassandra.ConsistencyLevel)``: The consistency level used in writing to Cassandra.
  * ``parallelism_level(int)``: The maximum number of batches written in parallel.
  * ``throughput_mibps``: Maximum write throughput allowed per single core in MB/s.
  * ``ttl(int or timedelta)``: The time to live as milliseconds or timedelta to use for the values.
  * ``timestamp(int, date or datetime)``: The timestamp in milliseconds, date or datetime to use for the values.
  * ``metrics_enabled(bool)``: Whether to enable task metrics updates.


### pyspark_cassandra.CassandraRDD

A `CassandraRDD` is very similar to a regular `RDD` in pyspark. It is extended with the following methods: 

* ``select(*columns)``: Creates a CassandraRDD with the select clause applied.
* ``where(clause, *args)``: Creates a CassandraRDD with a CQL where clause applied. The clause can contain ? markers with the arguments supplied as *args.
* ``limit(num)``: Creates a CassandraRDD with the limit clause applied.
* ``take(num)``: Takes at most ``num`` records from the Cassandra table. Note that if ``limit()`` was invoked before ``take()`` a normal pyspark ``take()`` is performed. Otherwise, first limit is set and _then_ a ``take()`` is performed.
* ``cassandraCount()``: Lets Cassandra perform a count, instead of loading the data to Spark first.
* ``saveToCassandra(...)``: As above, but the keyspace and/or table __may__ be omitted to save to the same keyspace and/or table. 
* ``spanBy(*columns)``: Groups rows by the given columns without shuffling. 
* ``joinWithCassandraTable(keyspace, table)``: Join an RDD with a Cassandra table on the partition key. Use .on(...) to specifiy other columns to join on. .select(...), .where(...) and .limit(...) can be used as well.


### pyspark_cassandra.streaming

When importing ```pyspark_cassandra.streaming``` the method ``saveToCassandra(...)``` is made available on DStreams. Also support for joining with a Cassandra table is added:
* ``joinWithCassandraTable(keyspace, table, selected_columns, join_columns)``: 


Examples
--------

Creating a SparkContext with Cassandra support

```python
import pyspark_cassandra

conf = SparkConf() \
	.setAppName("PySpark Cassandra Test") \
	.setMaster("spark://spark-master:7077") \
	.set("spark.cassandra.connection.host", "cas-1")

sc = CassandraSparkContext(conf=conf)
```

Using select and where to narrow the data in an RDD and then filter, map, reduce and collect it::

```python	
sc \
	.cassandraTable("keyspace", "table") \
	.select("col-a", "col-b") \
	.where("key=?", "x") \
	.filter(lambda r: r["col-b"].contains("foo")) \
	.map(lambda r: (r["col-a"], 1)
	.reduceByKey(lambda a, b: a + b)
	.collect()
```

Storing data in Cassandra::

```python
rdd = sc.parallelize([{
	"key": k,
	"stamp": datetime.now(),
	"val": random() * 10,
	"tags": ["a", "b", "c"],
	"options": {
		"foo": "bar",
		"baz": "qux",
	}
} for k in ["x", "y", "z"]])

rdd.saveToCassandra(
	"keyspace",
	"table",
	ttl=timedelta(hours=1),
)
```

Create a streaming context, convert every line to a generater of words which are saved to cassandra. Through this example all unique words are stored in Cassandra.

The words are wrapped as a tuple so that they are in a format which can be stored. A dict or a pyspark_cassandra.Row object would have worked as well.

```python
from pyspark.streaming import StreamingContext
from pyspark_cassandra import streaming

ssc = StreamingContext(sc, 2)

ssc \
    .socketTextStream("localhost", 9999) \
    .flatMap(lambda l: ((w,) for w in (l,))) \
    .saveToCassandra('keyspace', 'words')

ssc.start()
```

Joining with Cassandra:

```python
joined = rdd \
    .joinWithCassandraTable('keyspace', 'accounts') \
    .on('id') \
    .select('e-mail', 'followers')

for left, right in joined:
    ...
```

Or with a DStream:

```python
joined = dstream.joinWithCassandraTable(self.keyspace, self.table, ['e-mail', 'followers'], ['id'])
```


Problems / ideas?
-----------------
Feel free to use the issue tracker propose new functionality and / or report bugs. In case of bugs please provides some code to reproduce the issue or at least some context information such as software used, CQL schema, etc.



Contributing
------------

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request
