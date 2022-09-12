A Kubernetes cluster was provisioned on your behalf. 

The following are already deployed to the cluster:
- Istio 1.15.0 
- Istio addons (Kiali 1.5.5, Prometheus, Grafana, Jaeger, Zipkin)

You can interact with the cluster using `kubectl` (or its configured alias, `k`).

## Inspect the `istio-system` namespace

Run the following to list the resources deployed to the `istio-system` namespace:

```
k get pod -n istio-system
```{{exec}}

Notice that service of type _LoadBalancer_ was created for the ingress gateway.
In this lab environment, the _LoadBalancer_ service does not have a corresponding public IP address.

As a workaround, in this lab we will use the `kubectl port-forward` command to expose the ingress gateway service via a port on the host machine.

## Expose the ingress gateway

```
k port-forward -n istio-system --address 0.0.0.0 service/istio-ingressgateway 50080:80
```{{exec}}

Attempt to [access the gateway via port 50080]({{TRAFFIC_HOST1_50080}}/).  It should return a 404 (not found) response.

### Note

The `kubectl port-forward` command blocks. It may be simplest to leave it running, and open a separate terminal in your cloud shell environment.

## Expose Kiali UI

Throughout this scenario we will use Kiali as a user interface to manage our mesh.
 
Expose the Kiali dashboard with the following command:

```
istioctl dashboard --address=0.0.0.0 kiali
```{{exec}}

[Access kiali via port 20001]({{TRAFFIC_HOST1_20001}}/).

### Note

The `istioctl dashboard` command also blocks. Here too, open a separate terminal in your cloud shell environment to continue to the next lab.

## Next

With the environment set up, we are ready to proceed to deploy the Travel application.
