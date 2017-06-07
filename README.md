
# NGINX S2I builder for Openshift v3

## Generate builder
```
$ git clone https://github.com/victornc83/s2i-nginx.git
$ docker build -t nginx-centos7 .
```

New image builder could be used in Openshift v3 to build a web server with static web content.

## Deploying in Openshift
```
apiVersion: "v1"
kind: "BuildConfig"
metadata:
  name: "app-build"
spec:
  output:
    to:
      kind: "ImageStreamTag"
      name: "app-image:latest"
  source:
    git:
      uri: "https://github.com/user/app.git"
    sourceSecret:
      name: "basicsecret"
  strategy:
    sourceStrategy:
      kind: DockerImage
      name: 'victornc83/nginx-centos7:latest'
```
New app-image is ready to be deployed
```
- kind: DeploymentConfig
  apiVersion: v1
  metadata:
    labels:
      app: "app"
    name: "app"
  spec:
    replicas: 1
    selector:
      app: "app"
    strategy:
      rollingParams:
        intervalSeconds: 1
        maxSurge: 25%
        maxUnavailable: 25%
        timeoutSeconds: 600
        updatePeriodSeconds: 1
      type: Rolling
    template:
      metadata:
        labels:
          app: "app"
          deploymentconfig: "app-deploy"
      spec:
        containers:
        - image: app-image:latest
          imagePullPolicy: Always
          name: "app"
          env: []
          ports:
          - containerPort: 8080
            protocol: TCP
          resources:
            limits:
              memory: "512Mi"
          terminationMessagePath: /dev/termination-log
          livenessProbe:
            httpGet:
              path: /
              port: 8080
              scheme: HTTP
            initialDelaySeconds: 90
            timeoutSeconds: 2
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /
              port: 8080
              scheme: HTTP
            initialDelaySeconds: 90
            timeoutSeconds: 2
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 3
        dnsPolicy: ClusterFirst
        restartPolicy: Always
        securityContext: {}
        terminationGracePeriodSeconds: 90
    test: false
    triggers:
    - type: ConfigChange
    - imageChangeParams:
        automatic: true
        containerNames:
        - app
        from:
          kind: ImageStreamTag
          name: app-image:latest
      type: ImageChange
  status: {}
```

## Logging
```
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log
```
These two entries in the Dockerfile help us to get logs in Openshift console.

## Testing S2I
 ```
 $ s2i build example/ nginx-centos7:latest image-test --loglevel=5
 $ docker run -ti -p 8080:8080 image-test /usr/libexec/s2i/run
 ```
You could use s2i tool published [here](https://github.com/openshift/source-to-image) by Openshift community.
