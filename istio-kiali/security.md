In this lab we explore some of the security features of the Istio service mesh.

## 1. Mutual TLS

By default, Istio is configured such that when a service is deployed onto the mesh, it will take advantage of mutual TLS:

- the service is given an identity as a function of its associated service account and namespace
- an x.509 certificate is issued to the workload (and regularly rotated) and used to identify the workload in calls to other services

In the observability lab, we looked at the Kiali dashboard and noted the lock icons indicating that traffic was secured with mTLS.

### Can a workload receive plain-text requests?

Yes. By default Istio is configured to allow plain-text request.

This is called _permissive mode_ and is specifically designed to allow services that have not yet fully onboarded onto the mesh to participate.

### Enable strict mode

Istio provides the `PeerAuthentication` custom resource to define peer authentication policy.

You are going to apply the following `PeerAuthentication` resource to enable strict mTLS globally by setting the namespace to the name of the Istio root namespace, which by default is `istio-system`. A `PeerAuthentication` can also be restricted to specific namespaces or even specific workloads.

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
```

Apply the resource:

```
k apply -f mtls-strict.yaml
```{{exec}}


## 2. Authorization Policies and Sidecars

The Istio [Security High Level Architecture](https://istio.io/latest/docs/concepts/security/#high-level-architecture) provides a comprehensive solution to design and implement multiple security scenarios.

In this tutorial we will show how Kiali can use telemetry information to create security policies for the workloads deployed in a given namespace.

Istio telemetry aggregates the ServiceAccount information used in the workloads communication. This information can be used to define authorization policies that deny and allow actions on future live traffic communication status.

Additionally, Istio sidecars can be created to limit the hosts with which a given workload can communicate. This improves traffic control, and also reduces the [memory footprint](https://istio.io/latest/docs/ops/deployment/performance-and-scalability/#cpu-and-memory) of the proxies.

This step will show how we can define authorization policies for the *travel-agency* namespace, in the Travel Demo application, for all existing traffic in a given time period.

Once authorization policies are defined, a new workload will be rejected if it doesn't match the security rules defined.

### 2.1. Undeploy the *loadtester* workload from *travel-portal* namespace

In this example we will use the *loadtester* workload as the "intruder" in our security rules.

If we have followed the previous tutorial steps, we need to undeploy it from the system.

```
kubectl delete -f travel_loadtester.yaml -n travel-portal
```{{exec}}

We should validate that telemetry has updated the *travel-portal* namespace and "Security" can be enabled in the Graph Display options.

![Travel Portal Graph](https://kiali.io/images/tutorial/06-01-travel-portal-graph.png "Travel Portal Graph")

### 2.2. Create Authorization Policies, and Istio Sidecars, for current traffic for *travel-agency* namespace

Every workload in the cluster uses a [Service Account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/).

*travels.uk*, *viaggi.it* and *voyages.fr* workloads use the default *cluster.local/ns/travel-portal/sa/default* ServiceAccount defined automatically per namespace.

This information is propagated into the Istio Telemetry and Kiali can use it to define a set of AuthorizationPolicy rules, and Istio Sidecars.

The Sidecars restrict the list of hosts with which each workload can communicate, based on the current traffic.

The "Create Traffic Policies" action, located in the Overview page, will create these definitions.

![Create Traffic Policies](https://kiali.io/images/tutorial/06-01-create-traffic-policies.png "Create Traffic Policies")

This will generate a main DENY ALL rule to protect the whole namespace, and an individual ALLOW rule per workload identified in the telemetry.

![Travel Agency Authorization Policies](https://kiali.io/images/tutorial/06-01-travel-agency-authorization-policies.png "Travel Agency Authorization Policies")

It will create also an individual Sidecar per workload, each of them containing the set of hosts.

![Travel Agency Sidecars](https://kiali.io/images/tutorial/06-01-travel-agency-sidecars.png "Travel Agency Sidecars")

As an example, we can see that for the *travels-v1* workload, the following list of hosts are added to the sidecar.

![Travels V1 Sidecar](https://kiali.io/images/tutorial/06-01-travels-v1-sidecars.png "Travels V1 Sidecar")

### 2.3. Deploy the *loadtester* portal in the *travel-portal* namespace

If the *loadtester* workload uses a different ServiceAccount then, when it's deployed, it won't comply with the AuthorizationPolicy rules defined in the previous step.

```
kubectl apply -f travel_loadtester.yaml -n travel-portal
```{{exec}}

Now, *travels* workload will reject requests made by *loadtester* workload and that situation will be reflected in Graph:

![Loadtester Denied](https://kiali.io/images/tutorial/06-01-loadtester-denied.png "Loadtester Denied")

This can also be verified in the details page using the Outbound Metrics tab grouped by response code (only the 403 line is present).

![Loadtester Denied Metrics](https://kiali.io/images/tutorial/06-01-loadtester-denied-metrics.png "Loadtester Denied Metrics")

Inspecting the Logs tab confirms that *loadtester* workload is getting a HTTP 403 Forbidden response from *travels* workloads, as expected.

![Loadtester Logs](https://kiali.io/images/tutorial/06-01-loadtester-logs.png "Loadtester Logs")

### 2.4. Update *travels-v1* AuthorizationPolicy to allow *loadtester* ServiceAccount

AuthorizationPolicy resources are defined per workload using matching selectors.

As part of the example, we can show how a ServiceAccount can be added into an existing rule to allow traffic from *loadtester* workload into the *travels-v1* workload only.

![AuthorizationPolicy Edit](https://kiali.io/images/tutorial/06-01-authorizationpolicy-edit.png "AuthorizationPolicy Edit")

As expected, now we can see that *travels-v1* workload accepts requests from all *travel-portal* namespace workloads, but *travels-v2* and *travels-v3* continue rejecting requests from *loadtester* source.

![Travels v1 AuthorizationPolicy](https://kiali.io/images/tutorial/06-01-travels-v1-authorizationpolicy.png "Travels v1 AuthorizationPolicy")

Using "Outbound Metrics" tab from the *loadtester* workload we can group per "Remote version" and "Response code" to get a detailed view of this AuthorizationPolicy change.

![Travels v1 AuthorizationPolicy](https://kiali.io/images/tutorial/06-01-loadtester-authorized-metrics.png "Travels v1 AuthorizationPolicy")

### 2.5. Verify the proxies clusters list is limited by the Sidecars

According to [Istio Sidecar](https://istio.io/latest/docs/reference/config/networking/sidecar/) documentation, Istio configures all mesh sidecar proxies to reach every mesh workload. After the sidecars are created, the list of hosts is reduced according to the current traffic. To verify this, we can look for the clusters configured in each proxy.

As an example, looking into the *cars-v1* workload, we can see that there is a reduced number of clusters with which the proxy can communicate.

![Cars v1 clusters](https://kiali.io/images/tutorial/06-01-cars-v1-clusters.png "Cars v1 clusters")

### 2.6. Update or delete Istio Configuration

As part of this step, you can update the AuthorizationPolicies and Istio Sidecars generated for the *travel-agency* namespace, and experiment with more security rules. Or, you can delete the generated Istio config for the namespace.
