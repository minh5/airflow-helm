# airflow-helm

[Airflow](https://airflow.incubator.apache.org/) is a workflow management system built by Airbnb.  Airflow is used to run and monitor daily tasks as well as providing easy scaling when workloads become too large. This is a Helm chart for Kuberentes deployment, greatly inspired by the work of [Stibbons](https://github.com/Stibbons/kube-airflow/tree/helm_chart/airflow) and [Mumoshu](https://github.com/mumoshu/kube-airflow). This project was built out of trying to integrate the previous two Airflow Kubernetese deployment and tailoring it to my needs. Subtle differences include:
  * a separate charts for the Nginx Ingress and RabbitMQ
  * a probe to the Scheduler since there are bugs with broken pipes
  * using [Invoke](http://www.pyinvoke.org/) for task execution
  * optional Postgres deployment for Airflow metadb
  

## Installation

Before beginning, please make sure you install [pip](https://pip.pypa.io/en/stable/installing/) and the necessary libraries in `requirements.txt`. After install pip, just run:

```
pip install -r requirements.txt
```

Rather than using `MakeFile` we used [Invoke](http://www.pyinvoke.org/) to call commands, you can see the available Invoke commands by typing in `invoke -l` 


## Configuration

### Adding DAGs
Workflows are abstracted as DAGs in Airflow. After creating your DAGs, you can integrate them in two ways:
  * building the DAG directly into the image
  * using [Invoke](http://www.pyinvoke.org/) to copy local DAGs into the pods

For the first method, I have left a template of a `Dockerfile`, where all you have to do is put your DAGs in the `dags/` directory before building your image and adjusting line 2 in `airflow-helm/charts/airflow/values.yaml` to reflect the correct image repository. The drawback of this method is that you will have to build out your image every time a DAG change, so it is best for development and testing. For the second method, you move your DAGs into `dags/` and run:

```
invoke copy-dags --all
```

Note that if you decide not to put your dags in a dag folder, you can specify which folder to copy by running

```
invoke copy-dags --path your/path/to/dags
```

Or to only certain pods (by default, it sends to worker, scheduler, and airflow server pods). Note that you don't need to necessarily need to type in the full pod name, just enough for a regex match (e.g. `sche` for scheduler)

```
invoke copy-dags --pod pod_regex_here
```

A third viable option is the use of `git-sync` which is explained thoroughly [here](https://github.com/Stibbons/kube-airflow)


### Additional Python libraries
If your DAGs requires additional libraries, feel free to add them to `airflow-helm/charts/airflow/artifacts/requirements.txt` and they will be installed upon every pod start up.

Scaling can be done by adjusting `airflow-helm/charts/airflow/artifacts/airflow.cfg` line 47, this `dag_concurrency` variable will dictate how many tasks the Scheduler will allow Celery workers to execute tasks. I found this to be more helpful than increasing the number of replicas of worker pods (it still an option if you so choose to scale this way).

## Deployment

After configuration, all you need to do is run

```
invoke install all
```

To delete Helm charts, run

```
invoke delete all
```

You have the option of deleting a Helm chart and reinstalling it to allow changes to take place

```
invoke reinstall all
```

Charts can also be deployed, deleted, or reinstalled separately by replacing "all", for example:

```
invoke install rabbitmq
invoke reinstall airflow
invoke delete nginx-ingress
```


## To Dos

* Consider using [Horizontal Pod Auto Scalers](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) for worker pods instead of StatefulSets
* A more elegant way of probing the Scheduler
* Allow realtime syncing of the DAGs directly using NFS

Currently this is in testing and QA, so there will be more down the road.

Feel free to fork, make PRs, or file issues!
