> Note: the images in this lab are different from what you will observe since they include a v3 of the travels service whereas this lab only deploys v1 and v2

The Travel Demo application has several portals deployed on the *travel-portal* namespace consuming the *travels* service deployed on the *travel-agency* namespace.

The *travels* service is backed by a single workload called *travels-v1* that receives requests from all portal workloads.

At a moment of the lifecycle the business needs of the portals may differ and new versions of the *travels* service may be necessary.

This step will show how to route requests dynamically to multiple versions of the *travels* service.



## 1. Deploy *travels-v2* workload

To deploy the new version of the *travels* service execute the following commands:

```
kubectl apply -f travels-v2.yaml -n travel-agency
```{{exec}}

As there is no specific routing defined, when there are multiple workloads for *travels* service the requests are uniformly distributed.

## 2. Traffic routing

### 2.1. Investigate the http headers used by the Travel Demo application

The [Traffic Management](https://istio.io/latest/docs/concepts/traffic-management/#routing-rules) features of Istio allow you to define [Matching Conditions](https://istio.io/latest/docs/concepts/traffic-management/#match-condition) for dynamic request routing.

In our scenario we would like to perform the following routing logic:

- All traffic from *viaggi.it* routed to *travels-v1*
- All traffic from *voyages.fr* routed to *travels-v2*

Portal workloads use HTTP/1.1 protocols to call the *travels* service, so one strategy could be to use the HTTP headers to define the matching condition.

But, where to find the HTTP headers ? That information typically belongs to the application domain and we should examine the code, documentation or dynamically trace a request to understand which headers are being used in this context.

There are multiple possibilities. The Travel Demo application uses an [Istio Annotation](https://istio.io/latest/docs/reference/config/annotations/) feature to add an annotation into the Deployment descriptor, which adds additional Istio configuration into the proxy.

![Istio Config annotations](https://kiali.io/images/tutorial/05-01-deployment-istio-config.png "Istio Config annotations")

In our example the [HTTP Headers](https://github.com/kiali/demos/blob/master/travels/travels-v2.yaml#L15) are added as part of the trace context.

Then tracing will populate custom tags with the *portal*, *device*, *user* and *travel* used.

### 2.2. Use the Request Routing Wizard on *travels* service to generate a traffic rule

![Travels Service Request Routing](https://kiali.io/images/tutorial/05-01-travels-request-routing.png "Travels Service Request Routing")

We will define three "Request Matching" rules as part of this request routing. Define both rules before clicking the Create button.

In the first rule, we will add a request match for when the *portal* header has the value of *viaggi.it*.

Define the exact match, like below, and click the "Add Match" button to update the "Matching selected" for this rule.

![Add Request Matching](https://kiali.io/images/tutorial/05-01-add-match.png "Add Request Matching")

Move to "Route To" tab and update the destination for this "Request Matching" rule.  Then use the "Add Route Rule" to create the first rule.

![Route To](https://kiali.io/images/tutorial/05-01-route-to.png "Route To")

Add similar rules to route traffic from *voyages.fr* to *travels-v2* workload.

When the rules defined you can use "Create" button to generate all Istio configurations needed for this scenario. Note
that the rule ordering does not matter in this scenario.

![Rules Defined](https://kiali.io/images/tutorial/05-01-rules-defined.png "Rules Defined")

The Istio config for a given service is found on the "Istio Config" card, on the Service Details page.

![Service Istio Config](https://kiali.io/images/tutorial/05-01-service-istio-config.png "Service Istio Config")

### 2.3. Verify that the Request Routing is working from the *travels-portal* Graph

Once the Request Routing is working we can verify that outbound traffic from every portal goes to the single *travels* workload.  To
see this clearly use a "Workload Graph" for the "travel-portal" namespace, enable "Traffic Distribution" edge labels and disable the
"Service Nodes" Display option:

![Travel Portal Namespace Graph](https://kiali.io/images/tutorial/05-01-request-routing-graph.png "Travel Portal Namespace Graph")

Note that no distribution label on an edge implies 100% of traffic.

Examining the "Inbound Traffic" for any of the *travels* workloads will show a similar pattern in the telemetry.

![Travels v1 Inbound Traffic](https://kiali.io/images/tutorial/05-01-travels-v1-inbound-traffic.png "Travels v1 Inbound Traffic")

Using a custom time range to select a large interval, we can see how the workload initially received traffic from all portals but then only a single portal after the Request Routing scenarios were defined.

### 2.4. Update or delete Istio Configuration

Kiali Wizards allow you to define high level Service Mesh scenarios and will generate the Istio Configuration needed for its implementation (VirtualServices, DestinationRules, Gateways and PeerRequests).
These scenarios can be updated or deleted from the "Actions" menu of a given service.

To experiment further you can navigate to the *travels* service and update your configuration by selecting "Request Routing", as shown below.  When you have
finished experimenting with Routing Request scenarios then use the "Actions" menu to delete the generated Istio config.

![Update or Delete](https://kiali.io/images/tutorial/05-01-update-or-delete.png "Update or Delete")

## 3. Fault Injection

The Observe step has spotted that the *hotels* service has additional traffic compared with other services deployed in the *travel-agency* namespace.

Also, this service becomes critical in the main business logic. It is responsible for querying all available destinations, presenting them to the user, and getting a quote for the selected destination.

This also means that the *hotels* service may be one of the weakest points of the Travel Demo application.

This step will show how to test the resilience of the Travel Demo application by injecting faults into the *hotels* service and then observing how the application reacts to this scenario.

### 3.1. Use the Fault Injection Wizard on *hotels* service to inject a delay

![Fault Injection Action](https://kiali.io/images/tutorial/05-02-fault-injection-action.png "Fault Injection Action")

Select an HTTP Delay and specify the "Delay percentage" and "Fixed Delay" values. The default values will introduce a 5 seconds delay into 100% of received requests.

![HTTP Delay](https://kiali.io/images/tutorial/05-02-http-delay.png "HTTP Delay")

### 3.2. Understanding *source* and *destination* metrics

Telemetry is collected from proxies and it is labeled with information about the *source* and *destination* workloads.

In our example, let's say that *travels* service ("Service A" in the Istio diagram below) invokes the *hotels* service ("Service B" in the diagram). *Travels* is the "source" workload and *hotels* is the "destination" workload. The *travels* proxy will report telemetry from the source perspective and *hotels* proxy will report telemetry from the destination perspective. Let's look at the latency reporting from both perspectives.

![Istio Architecture](https://kiali.io/images/tutorial/05-02-istio-architecture.png "Istio Architecture")

The *travels* workload proxy has the Fault Injection configuration so it will perform the call to the *hotels* service and will apply the delay on the *travels* workload side (this is reported as *source* telemetry).

We can see in the *hotels* telemetry reported by the *source* (the *travels* proxy) that there is a visible gap showing 5 second delay in the request duration.

![Source Metrics](https://kiali.io/images/tutorial/05-02-source-metrics.png "Source Metrics")

But as the Fault Injection delay is applied on the source proxy (*travels*), the destination proxy (*hotels*) is unaffected and its destination telemetry show no delay.

![Destination Metrics](https://kiali.io/images/tutorial/05-02-destination-metrics.png "Destination Metrics")

### 3.3. Study the impact of the *travels* service delay

The injected delay is propagated from the *travels* service to the downstream services deployed on *travel-portal* namespace, degrading the overall response time. But the downstream services are unaware, operate normally, and show a green status.

![Degraded Response Time](https://kiali.io/images/tutorial/05-02-degraded-response-time.png "Degraded Response Time")

### 3.4. Update or delete Istio Configuration

As part of this step you can update the Fault Injection scenario to test different delays. When finished, you can delete the generated Istio config for the *hotels* service.

## 4. Traffic Shifting

In the previous [Request Routing](#request-routing) step we have deployed a new version of the *travels* service using the *travels-v2* workload.

That scenario showed how Istio can route specific requests to specific workloads. It was configured such that each portal deployed in the *travel-portal* namespace (*viaggi.it* and *voyages.fr*) were routed to a specific *travels* workload (*travels-v1* and *travels-v2*).

This Traffic Shifting step will simulate a new scenario: the new *travels-v2* workload will represent new improvements for the *travels* service that will be used by all requests.

These new improvements implemented in *travels-v2* represent an alternative way to address a specific problem. Our goal is to test the behavior of the new version.

At the beginning we will send 80% of the traffic into the original *travels-v1* workload, and 20% of the traffic to *travels-v2*.

### 4.1. Use the Traffic Shifting Wizard on *travels* service

![Traffic Shifting Action](https://kiali.io/images/tutorial/05-03-traffic-shifting-action.png "Traffic Shifting Action")

Create a scenario with 80% of the traffic distributed to *travels-v1* workload and 20% of the traffic distributed to *travels-v2*.

![Split Traffic](https://kiali.io/images/tutorial/05-03-split-traffic.png "Split Traffic")

### 4.2. Examine Traffic Shifting distribution from the *travels-agency* Graph

![Travels Graph](https://kiali.io/images/tutorial/05-03-travels-graph.png "Travels Graph")

### 4.3. Compare *travels* workload and assess new changes proposed in *travels-v2*

Istio Telemetry is grouped per logical application. That has the advantage of easily comparing different but related workloads, for one or more services.

In our example, we can use the "Inbound Metrics" and "Outbound Metrics" tabs in the *travels* application details, group by "Local version" and compare how *travels-v1* and *travels-v2* are working.

![Compare Travels Workloads](https://kiali.io/images/tutorial/05-03-compare-local-travels-version.png "Compare Travels Workloads")
![Compare Travels Workloads](https://kiali.io/images/tutorial/05-03-compare-local-travels-version-2.png "Compare Travels Workloads")

### 4.4. Update or delete Istio Configuration

As part of this step you can update the Traffic Shifting scenario to test different distributions. When finished, you can delete the generated Istio config for the *travels* service.

## 5. TCP Traffic Shifting

The Travel Demo application has a database service used by several services deployed in the *travel-agency* namespace.

At some point in the lifecycle of the application the telemetry shows that the database service degrades and starts to increase the average response time.

This is a common situation. In this case, a database specialist suggests an update of the original indexes due to the data growth.

Our database specialist is suggesting two approaches and proposes to prepare two versions of the database service to test which may work better.

This step will show how the "Traffic Shifting" strategy can be applied to TCP services to test which new database indexing strategy works better.

### 5.1. Deploy *mysqldb-v2* 

To deploy the new versions of the *mysqldb* service execute the commands:

```
kubectl apply -f mysql-v2.yaml -n travel-agency
```{{exec}}

```
kubectl apply -f mysql-v3.yaml -n travel-agency
```{{exec}}

### 5.2. Use the TCP Traffic Shifting Wizard on *mysqldb* service

![TCP Traffic Shifting Action](https://kiali.io/images/tutorial/05-04-tcp-traffic-shifting-action.png "TCP Traffic Shifting Action")

Create a scenario with 80% of the traffic distributed to *mysqldb-v1* workload and 10% of the traffic distributed each to *mysqldb-v2* and *mysqldb-v3*.

![TCP Split Traffic](https://kiali.io/images/tutorial/05-04-tcp-split-traffic.png "TCP Split Traffic")

### 5.3. Examine Traffic Shifting distribution from the *travels-agency* Graph

![MysqlDB Graph](https://kiali.io/images/tutorial/05-04-tcp-graph.png "MysqlDB Graph")

Note that TCP telemetry has different types of metrics, as "Traffic Distribution" is only available for HTTP/gRPC services, for this service we need to use "Traffic Rate" to evaluate the distribution of data (bytes-per-second) between *mysqldb* workloads.

### 5.4. Compare *mysqldb* workload and study new indexes proposed in *mysqldb-v2* and *mysqldb-v3*

TCP services have different telemetry but it's still grouped by versions, allowing the user to compare and study pattern differences for *mysqldb-v2* and *mysqldb-v3*.

![Compare MysqlDB Workloads](https://kiali.io/images/tutorial/05-04-tcp-compare-versions.png "Compare MysqlDB Workloads")

The charts show more peaks in *mysqldb-v2* compared to *mysqldb-v3* but overall a similar behavior, so it's probably safe to choose either strategy to shift all traffic.

### 5.5. Update or delete Istio Configuration

As part of this step you can update the TCP Traffic Shifting scenario to test a different distribution. When finished, you can delete the generated Istio config for the *mysqldb* service.

## 6. Request Timeouts

In the [Fault Injection](#fault-injection) step we showed how we could introduce a delay in the critical *hotels* service and test the resilience of the application.

The delay was propagated across services and Kiali showed how services accepted the delay without creating errors on the system.

But in real scenarios delays may have important consequences. Services may prefer to fail sooner, and recover, rather than propagating a delay across services.

This step will show how to add a request timeout for one of the portals deployed in *travel-portal* namespace. The *travel.uk* and *viaggi.it* portals will accept delays but *voyages.fr* will timeout and fail.

### 6.1 Use the Fault Injection Wizard on *hotels* service to inject a delay

Repeat the [Fault Injection](#fault-injection) step to add delay on *hotels* service.

### 6.2 Use the Request Routing Wizard on *travels* service to add a route rule with delay for *voyages.fr*

Add a rule to add a request timeout only on requests coming from *voyages.fr* portal:

- Use the Request Matching tab to add a matching condition for the *portal* header with *voyages.fr* value.
- Use the Request Timeouts tab to add an HTTP Timeout for this rule.
- Add the rule to the scenario.

![Request Timeout Rule](https://kiali.io/images/tutorial/05-05-request-timeout-rule.png "Request Timeout Rule")

A first rule should be added to the list like:

![Voyages Portal Rule](https://kiali.io/images/tutorial/05-05-voyages-rule.png "Voyages Portal Rule")

Add a second rule to match any request and create the scenario. With this configuration, requests coming from *voyages.fr* will match the first rule and all others will match the second rule.

![Any Request Rule](https://kiali.io/images/tutorial/05-05-generic-rule.png "Any Request Rule")

### 6.3. Review the impact of the request timeout in the *travels* service

Create the rule. The Graph will show how requests coming from *voyages.fr* start to fail, due to the request timeout introduced.

Requests coming from other portals work without failures but are degraded by the *hotels* delay.

![Travels Graph](https://kiali.io/images/tutorial/05-05-travels-graph-voyages-error.png "Travels Graph")

This scenario can be visualized in detail if we examine the "Inbound Metrics" and we group by "Remote app" and "Response code".

![Travels Inbound Metrics](https://kiali.io/images/tutorial/05-05-voyages-rule-metrics.png "Travels Inbound Metrics")
![Travels Inbound Metrics](https://kiali.io/images/tutorial/05-05-voyages-rule-metrics-2.png "Travels Inbound Metrics")

As expected, the requests coming from *voyages.fr* don't propagate the delay and they fail in the 2 seconds range, meanwhile requests from other portals don't fail but they propagate the delay introduced in the *hotels* service.

### 6.4. Update or delete Istio Configuration

As part of this step you can update the scenarios defined around *hotels* and *travels* services to experiment with more conditions, or you can delete the generated Istio config in both services.

## 7. Circuit Breaking

Distributed systems will benefit from failing quickly and applying back pressure, as opposed to propagating delays and errors through the system.

Circuit breaking is an important technique used to limit the impact of failures, latency spikes, and other types of network problems.

This step will show how to apply a Circuit Breaker into the *travels* service in order to limit the number of concurrent requests and connections.

## 7.1. Deploy a new *loadtester* portal in the *travel-portal* namespace

In this example we are going to deploy a new workload that will simulate an important increase in the load of the system.

```
kubectl apply -f travel_loadtester.yaml -n travel-portal
```{{exec}}

The *loadtester* workload will try to create 50 concurrent connections to the *travels* service, adding considerable pressure to the *travels-agency* namespace.

![Loadtester Graph](https://kiali.io/images/tutorial/05-06-loadtester-graph.png "Loadtester Graph")

The Travel Demo application is capable of handling this load and in a first look it doesn't show unhealthy status.

![Loadtester Details](https://kiali.io/images/tutorial/05-06-loadtester-details.png "Loadtester Details")

But in a real scenario an unexpected increase in the load of a service like this may have a significant impact in the overall system status.

## 7.2. Use the Traffic Shifting Wizard on *travels* service to generate a traffic rule

Use the "Traffic Shifting" Wizard to distribute traffic (evenly) to the *travels* workloads and use the "Advanced Options" to add a "Circuit Breaker" to the scenario.

![Traffic Shifting with Circuit Breaker](https://kiali.io/images/tutorial/05-06-traffic-shifting-circuit-breaker.png "Traffic Shifting with Circuit Breaker")

The "Connection Pool" settings will indicate that the proxy sidecar will reject requests when the number of concurrent connections and requests exceeds more than one.

The "Outlier Detection" will eject a host from the connection pool if there is more than one consecutive error.

## 7.3. Study the behavior of the Circuit Breaker in the *travels* service

In the *loadtester* versioned-app Graph we can see that the *travels* service's Circuit Breaker accepts some, but fails most, connections.

Remember, that these connections are stopped by the proxy on the *loadtester* side. That "fail sooner" pattern prevents overloading the network.

Using the Graph we can select the failed edge, check the Flags tab, and see that those requests are closed by the Circuit breaker.

![Loadtester Flags Graph](https://kiali.io/images/tutorial/05-06-loadtester-flags-graph.png "Loadtester Flags Graph")

If we examine the "Request volume" metric from the "Outbound Metrics" tab we can see the evolution of the requests, and how the introduction of the Circuit Breaker made the proxy reduce the request volume.

![Loadtester Outbound Metrics](https://kiali.io/images/tutorial/05-06-loadtester-flags-details.png "Loadtester Outbound Metrics")

## 7.4. Update or delete Istio Configuration

As part of this step you can update the scenarios defined around the *travels* service to experiment with more Circuit Breaker settings, or you can delete the generated Istio config in the service.

Understanding what happened:

[(i) Circuit Breaking](https://istio.io/latest/docs/tasks/traffic-management/circuit-breaking/)

[(ii) Outlier Detection](https://istio.io/latest/docs/reference/config/networking/destination-rule)

[(iii) Connection Pool Settings](https://istio.io/latest/docs/reference/config/networking/destination-rule)

[(iv) Envoy's Circuit breaking Architecture](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/circuit_breaking)

## 8. Mirroring

This tutorial has shown several scenarios where Istio can route traffic to different versions in order to compare versions and evaluate which one works best.

The [Traffic Shifting](#traffic-shifting) step was focused on *travels* service adding a new *travels-v2* and *travels-v3* workloads
and the [TCP Traffic Shifting](#tcp-traffic-shifting) showed how this scenario can be used on TCP services like *mysqldb* service.

Mirroring (or shadowing) is a particular case of the Traffic Shifting scenario where the proxy sends a copy of live traffic to a mirrored service.

The mirrored traffic happens out of band of the primary request path. It allows for testing of alternate services, in production environments, with minimal risk.

Istio mirrored traffic is only supported for HTTP/gRPC protocols.

This step will show how to apply mirrored traffic into the *travels* service.

### 8.1. Use the Traffic Shifting Wizard on *travels* service

We will simulate the following:

- *travels-v1* is the original traffic and it will keep 100% of the traffic
- *travels-v2* will be considered as a new, experimental version for testing outside of the regular request path. It will be defined as a mirrored workload on 50% of the original requests.

![Mirrored Traffic](https://kiali.io/images/tutorial/05-07-mirrored-traffic.png "Mirrored Traffic")

### 8.2. Examine Traffic Shifting distribution from the *travels-agency* Graph

Note that Istio does not report mirrored traffic telemetry from the source proxy. It is reported from the destination proxy, 
although it is not flagged as mirrored, and therefore an edge from *travels* to the *travels-v2* workload will appear in the graph.

![Mirrored Graph](https://kiali.io/images/tutorial/05-07-mirrored-graph.png "Mirrored Graph")

This can be examined better using the "Source" and "Destination" metrics from the "Inbound Metrics" tab.

The "Source" proxy, in this case the proxies injected into the workloads of *travel-portal* namespace, won't report telemetry for *travels-v2* mirrored workload.

![Mirrored Source Metrics](https://kiali.io/images/tutorial/05-07-mirrored-source-metrics.png "Mirrored Source Metrics")

But the "Destination" proxy, in this case the proxy injected in the *travels-v2* workload, will collect the telemetry from the mirrored traffic.

![Mirrored Destination Metrics](https://kiali.io/images/tutorial/05-07-mirrored-destination-metrics.png "Mirrored Destination Metrics")

### 8.3. Update or delete Istio Configuration

As part of this step you can update the Mirroring scenario to test different mirrored distributions.

When finished you can delete the generated Istio config for the *travels* service.

## Next

In the next lab you will experiment with some of Istio's security features
