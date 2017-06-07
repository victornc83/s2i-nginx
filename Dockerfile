# We are basing our builder image on openshift base-centos7 image
FROM openshift/base-centos7

# Inform users who's the maintainer of this builder image
MAINTAINER Victor Nieto <victornc83@gmail.com>

# Inform about software versions being used inside the builder
ENV NGINX_VERSION=1.10.2

# Set labels used in OpenShift to describe the builder images
LABEL io.k8s.description="Platform for serving static HTML files" \
      io.k8s.display-name="Nginx wer server v1.10" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,html,nginx"

# Enable epel repository for nginx
RUN yum install -y epel-release

# Install the required software, namely Lighttpd and
RUN yum install -y --setopt=tsflags=nodocs nginx && \
    yum clean all -y

# Copy the S2I scripts to /usr/libexec/s2i which is the location set for scripts
# in openshift/base-centos7 as io.openshift.s2i.scripts-url label
COPY ./s2i/bin/ /usr/libexec/s2i

# Copy the lighttpd configuration file
COPY ./etc/ /opt/app-root/etc

# Drop the root user and make the content of /opt/openshift owned by user 1001
RUN chown -R 1001:0 /opt/app-root && chown -R 1001:0 /var/log/nginx && \
    chown -R 1001:0 /var/lib/nginx && chown -R 1001:0 /usr/share/nginx && \
    chown -R 1001:0 /etc/nginx && chmod 644 /opt/app-root/etc/nginx.conf && \
    chmod 775 /var/log/nginx && chmod -R 777 /var/lib/nginx
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# Set the default user for the image, the user itself was created in the base image
USER 1001

# Specify the ports the final image will expose
EXPOSE 8080

# Set the default CMD to print the usage of the image, if somebody does docker run
CMD ["/usr/libexec/s2i/usage"]
