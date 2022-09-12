
First, create the namespaces for the application:

```
kubectl create namespace travel-agency
kubectl create namespace travel-portal
kubectl create namespace travel-control
```{{exec}}

Before deploying the application, you must enable sidecar injection.

## Enable automatic sidecar injection

There are two options for [sidecar injection](https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/): automatic and manual.

In this lab we will use automatic injection, which involves labeling the namespace where the pods are to reside.

1.  Label the namespaces for automatic injection

    ```
    kubectl label namespace travel-agency istio-injection=enabled
    kubectl label namespace travel-portal istio-injection=enabled
    kubectl label namespace travel-control istio-injection=enabled
    ```{{exec}}

1. Verify that the labels has been applied:

    ```
    kubectl get ns -Listio-injection
    ```{{exec}}

## Deploy the application

1. Study the Kubernetes yaml files: `travel_agency.yaml`, `travel_portal.yaml` and `travel_control.yaml`.

      ```
      cat travel_agency.yaml
      ```{{exec}}

      ```
      cat travel_portal.yaml
      ```{{exec}}

      ```
      cat travel_control.yaml
      ```{{exec}}

    Each file defines its corresponding deployments and ClusterIP services.
    The initial deployment uses the default service account for all deployments. We will later adjust that in the security section.

1. Apply the YAML files to your Kubernetes cluster.

    ```
    kubectl apply -f travel_agency.yaml -n travel-agency
    ```{{exec}}

    ```
    kubectl apply -f travel_portal.yaml -n travel-portal
    ```{{exec}}

    ```
    kubectl apply -f travel_control.yaml -n travel-control
    ```{{exec}}

Check that all deployments rolled out as expected:

```
kubectl get deployments -n travel-control
kubectl get deployments -n travel-portal
kubectl get deployments -n travel-agency
```{{exec}}

The expected output should look like the following:

```
controlplane $ kubectl get deployments -n travel-control
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
control   1/1     1            1           92s
controlplane $ kubectl get deployments -n travel-portal
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
travels   1/1     1            1           94s
viaggi    1/1     1            1           94s
voyages   1/1     1            1           94s
controlplane $ kubectl get deployments -n travel-agency
NAME            READY   UP-TO-DATE   AVAILABLE   AGE
cars-v1         1/1     1            1           96s
discounts-v1    1/1     1            1           96s
flights-v1      1/1     1            1           96s
hotels-v1       1/1     1            1           96s
insurances-v1   1/1     1            1           96s
mysqldb-v1      1/1     1            1           96s
travels-v1      1/1     1            1           96s
```

## Next

In the next lab, we expose the `control` service using an Istio Ingress Gateway which will map a path to a route at the edge of the mesh.
