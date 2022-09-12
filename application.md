In this lab you will deploy a Travel application. Let's get familiar with the application.

## Travel application

This demo application will deploy several services grouped into three namespaces.

### Travel Portal namespace

The Travel Demo application simulates two business domains organized in different namespaces.

In a first namespace called *travel-portal* there will be deployed several travel shops, where users can search for and book flights, hotels, cars or insurance.

The shop applications can behave differently based on request characteristics like channel (web or mobile) or user (new or existing).

These workloads may generate different types of traffic to imitate different real scenarios.

All the portals consume a service called _travels_ deployed in the *travel-agency* namespace.

### Travel Agency namespace

A second namespace called *travel-agency* will host a set of services created to provide quotes for travel.

A main _travels_ service will be the business entry point for the travel agency. It receives a destination city and a user as parameters and it calculates all elements that compose a travel budget: airfare, lodging, car reservation and travel insurance.

Each service can provide an independent quote and the _travels_ service must then aggregate them into a single response.

Additionally, some users, like _registered_ users, can have access to special discounts, managed as well by an external service.

Service relations between namespaces can be described in the following diagram:

![Travel Demo Design](https://kiali.io/images/tutorial/02-02-travels-demo-design.png "Travel Demo Design")

#### Travel Portal and Travel Agency flow

A typical flow consists of the following steps:

- A portal queries the _travels_ service for available destinations.
- _Travels_ service queries the available hotels and returns to the portal shop.
- A user selects a destination and a type of travel, which may include a _flight_ and/or a _car_, _hotel_ and _insurance_.
- _Cars_, _Hotels_ and _Flights_ may have available discounts depending on user type.

### Travel Control namespace

The *travel-control* namespace runs a *business dashboard* with two key features:

* Allow setting changes for every travel shop simulator (traffic ratio, device, user and type of travel).
* Provide a *business* view of the total requests generated from the *travel-portal* namespace to the *travel-agency* services, organized by business criteria as grouped per shop, per type of traffic and per city.


## Next

Now that you understand the application, let's move on to setting up the cluster.
