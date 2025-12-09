# R Pipeline Development Workshop (NZSA) with Kubernetes [2025/12/09]

## Authentication

- Workshop attendees will need to access [https://shiny.otago.ac.nz/NZSA/login](https://shiny.otago.ac.nz/NZSA/login)
- User credentials will be: username = **nzsa-XX** and password = **NZSA2025-XX**, where XX is an incrementing integer. E.g [01, 02, 03...]
- You should now be running an instance of RStudio Server.

## Working with Kubernetes

### S3 Credentials

- On the bottom right, you'll see the files window.
- You will need to access **~/pages/tidymodels_workshop/4_mlops_vetiver.qmd**
- You can run the code from lines 1 - 199 without issue.
- You will need to modify lines 199 - 207 like so:

```r
board <- board_s3(
  "data", 
  access_key = "NZSA", 
  secret_access_key = "NZSA", 
  region = "us-east-2", 
  endpoint = Sys.getenv("S3_ENDPOINT_URL") 
)
```

- You will be connected to a local S3 server. You can upload and download files to and from this server.
- The remaining code from lines 207 - 357 can remain unchanged.

### Kubernetes Manifest Files

#### HTTP Routing

- You will need to modify the Kubernetes manifest files depending on your user credentials.
- Open: **~/deployments/k8s/nzsa/r-models-http-route.yaml**
- This should look similar to the following:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: r-pipelines-models
spec:
  parentRefs:
    - name: rtis-k8s-charlie-gw
      namespace: gateways
  hostnames:
    - shiny.otago.ac.nz
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /NZSA-01-shiny
      backendRefs:
        - name: r-pipelines-models
          port: 3838
      filters:
        - type: URLRewrite
          urlRewrite:
            path:
              replacePrefixMatch: /
              type: ReplacePrefixMatch
    - matches:
        - path:
            type: PathPrefix
            value: /NZSA-01-plumber
      backendRefs:
        - name: r-pipelines-models
          port: 8089
      filters:
        - type: URLRewrite
          urlRewrite:
            path:
              replacePrefixMatch: /
              type: ReplacePrefixMatch
```

- You will need to modify the following two lines: 
  - **/NZSA-01-shiny**
  - **/NZSA-01-plumber**
- To:
  - **/NZSA-XX-shiny**
  -  **/NZSA-XX-plumber**
-  Depending on your username. E.g. **nzsa-02** would need to change these lines to:
   - **/NZSA-02-shiny**
   - **/NZSA-02-plumber**

#### Deployment

- You will also need to modify **~/deployments/k8s/nzsa/r-models-deployment.yaml**
- This should look similar to the following:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: r-pipelines-models
  labels:
    app: r-pipelines
spec:
  replicas: 1
  selector:
    matchLabels:
      app: r-pipelines
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: r-pipelines
    spec:
      containers:
        - image: ghcr.io/plant-food-research-open/shiny-rpipelines:0.1.0
          resources:
            requests:
              memory: "2Gi"
              cpu: "300m"
          imagePullPolicy: Always
          name: shiny-random-forest
          ports:
            - containerPort: 3838
              protocol: TCP
          args:
            - R
            - -e
            - shiny::runApp('/app', launch.browser = FALSE, host = '0.0.0.0', port = 3838)
          env:
            - name: AWS_ACCESS_KEY_ID
              value: NZSA
            - name: AWS_SECRET_ACCESS_KEY
              value: NZSA
            - name: MODEL_CHOICES
              value: random_forest
            - name: MODEL_ENDPOINTS
              value: https://shiny.otago.ac.nz/NZSA-01-plumber
        - image: ghcr.io/plant-food-research-open/shiny-rpipelines:0.1.0
          resources:
            requests:
              memory: "1Gi"
              cpu: "300m"
          imagePullPolicy: Always
          name: random-forest
          ports:
            - containerPort: 8089
              protocol: TCP
          args:
            - Rscript
            - api/vetiver_deploy.R
          env:
            - name: S3_BUCKET
              value: data
            - name: AWS_ACCESS_KEY_ID
              value: NZSA
            - name: AWS_SECRET_ACCESS_KEY
              value: NZSA
            - name: S3_ENDPOINT_URL
              value: http://nzsa-s3:8080
            - name: MODEL_NAME
              value: random_forest
            - name: MODEL_PORT
              value: "8089"
            - name: MODEL_CARD_NAME
              value: random_forest_card
      restartPolicy: Always
```

- You will need to modify line 42:
  - **value: https://shiny.otago.ac.nz/NZSA-01-plumber**
- To:
  - **value: https://shiny.otago.ac.nz/NZSA-XX-plumber**
-  Depending on your username. E.g. **nzsa-02** would need to change these lines to:
   - **value: https://shiny.otago.ac.nz/NZSA-02-plumber**

###  Deploying your services

- Return to **lines 357-363** in **~/pages/tidymodels_workshop/4_mlops_vetiver.qmd**
-  Run the code block.
-  To view the plumber backend, access: **https://shiny.otago.ac.nz/NZSA-XX-plumber/__docs__/**, where XX depends on your username.
   -  E.g. user **nzsa-01** would need to visit: **https://shiny.otago.ac.nz/NZSA-01-plumber/__docs__/** 
- To view the Shiny frontend, access: **https://shiny.otago.ac.nz/NZSA-XX-shiny/**, where XX depends on your username. 
   -  E.g. user **nzsa-01** would need to visit: **https://shiny.otago.ac.nz/NZSA-01-shiny/** 