This lab explores one of the main strengths of Istio: observability.

The services in our mesh are automatically observable, without adding any burden on developers.

## Kiali

[Access kiali via port 20001]({{TRAFFIC_HOST1_20001}}/).

Customize the view as follows:

1. Select the _Graph_ section from the sidebar.
1. Under _Select Namespaces_ (at the top of the page), select the `travel-*` namespaces, the location where the application's pods are running.
1. From the third "pulldown" menu, select _App graph_.
1. From the _Display_ "pulldown", toggle on _Traffic Animation_ and _Security_.
1. From the footer, toggle the legend so that it is visible.  Take a moment to familiarize yourself with the legend.

Observe the visualization and note the following:

- We can see traffic coming in through the ingress gateway routing all the way to the different travel services
- The lines connecting the services are green, indicating healthy requests
- The small lock icon on each edge in the graph indicates that the traffic is secured with mutual TLS

Such visualizations are helpful with understanding the flow of requests in the mesh, and with diagnosis.

Feel free to spend more time exploring Kiali.

We will revisit Kiali in a later lab to visualize traffic shifting such as when performing a blue-green or canary deployment.

## Jaeger

1. Install Jaeger

    ```
    kubectl apply -f istio-1.15.0/samples/addons/jaeger.yaml
    kubectl rollout status deployment/jaeger -n istio-system
    ```{{exec}}

1. Launch the Jaeger dashboard:

    ```
    istioctl dashboard --address 0.0.0.0 jaeger
    ```{{exec}}

1. [Access Jaeger via port 16686]({{TRAFFIC_HOST1_16686}}/).

The Jaeger dashboard displays.

- Select the service named `travels.travel-agency` and click on the _Find Traces_ button at the bottom.
- Click one of the traces (circles at the top right) and view the end-to-end breakdown of the trace

The resulting view shows spans that are part of the trace, and more importantly how much time was spent within each span.  Such information can help diagnose slow requests and pin-point where the latency lies.

Distributed tracing also helps us make sense of the flow of requests in a microservice architecture.

### Jaeger Cleanup

Close the Jaeger dashboard.  Interrupt the `istioctl dashboard` command with _Ctrl+C_.

Then uninstall it:

```
kubectl delete -f istio-1.15.0/samples/addons/jaeger.yaml
```{{exec}}

## Prometheus

Prometheus works by periodically calling a metrics endpoint against each running service (this endpoint is termed the "scrape" endpoint).  Developers normally have to instrument their applications to expose such an endpoint and return metrics information in the format the Prometheus expects.

With Istio, this is done automatically by the Envoy sidecar.

### Access the dashboard

1. Start the prometheus dashboard

    ```
    istioctl dashboard --address 0.0.0.0 prometheus
    ```{{exec}}

    [Access Prometheus via port 9090]({{TRAFFIC_HOST1_9090}}/).

1. In the search field enter the metric named `istio_requests_total`, and click the _Execute_ button (on the right).

1. Select the tab named _Graph_ to obtain a graphical representation of this metric over time.

    Note that you are looking at requests across the entire mesh.

1. As an example of Prometheus' dimensional metrics capability, we can ask for total requests having a response code of 200:

    ```
    istio_requests_total{response_code="200"}
    ```

1. With respect to requests, it's more interesting to look at the rate of incoming requests over a time window.  Try:

    ```
    rate(istio_requests_total[5m])
    ```

There's much more to the Prometheus query language ([this](https://prometheus.io/docs/prometheus/latest/querying/basics/) may be a good place to start).

Grafana consumes these metrics to produce graphs on our behalf.

- Close the Prometheus dashboard and terminate the corresponding `istioctl dashboard` command.

## Grafana

1. Install Grafana

    ```
    kubectl apply -f istio-1.15.0/samples/addons/grafana.yaml
    kubectl rollout status deployment/grafana -n istio-system
    ```{{exec}}


1. Launch the Grafana dashboard

    ```
    istioctl dashboard --address 0.0.0.0 grafana
    ```{{exec}}

    [Access Grafana via port 3000]({{TRAFFIC_HOST1_3000}}/).

1. From the sidebar, select _Dashboards_ --> _Browse_
1. Click on the folder named _Istio_ to reveal pre-designed Istio-specific Grafana dashboards
1. Explore the Istio Mesh Dashboard.  Note the Global Request Volume and Global Success Rate.
1. Navigate back to _Dashboards_ and explore the Istio Service Dashboard. 
1. Navigate back to _Dashboards_ and explore the Istio Workload Dashboard.
1. Feel free to further explore these dashboards.
1. Close the Grafana dashboard and terminate the corresponding `istioctl dashboard` command.
1. Uninstall grafane:
    ```
    kubectl delete -f istio-1.15.0/samples/addons/grafana.yaml
    ```{{exec}}

## Next

We turn our attention next to security features of a service mesh.
