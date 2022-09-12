The *control* workload has an Istio sidecar proxy injected, but this application is not accessible from the outside.

In this step we are going to expose the *control* service using an Istio Ingress Gateway which will map a path to a route at the edge of the mesh.

Use the Request Routing Wizard on the *control* service to generate a traffic rule:

![Request Routing Wizard](https://kiali.io/images/tutorial/03-03-service-actions.png "Request Routing Wizard")

Use "Add Route Rule" button to add a default rule where any request will be routed to the *control* workload.

Use the Advanced Options and add a gateway and create the Istio config.

Verify the Istio configuration generated:

![Istio Config](https://kiali.io/images/tutorial/03-03-istio-config.png "Istio Config")


Finally, [open the control service Web UI]({{TRAFFIC_HOST1_50080}}/).

## Understanding what happened

- External traffic enters into the cluster through a Gateway
- Traffic is routed to the *control* service through a VirtualService

The configuration we used routes all ingress to the *control* service.
In a real deployment more fine-grained routing is used, e.g., by domain or request parameters.

## Next
