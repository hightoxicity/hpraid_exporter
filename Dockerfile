FROM centos:7 as exp-builder
WORKDIR /root
RUN curl -o /etc/yum.repos.d/vbatts-bazel-epel-7.repo \
    https://copr.fedorainfracloud.org/coprs/vbatts/bazel/repo/epel-7/vbatts-bazel-epel-7.repo && \
    echo '5e54bc5dbf82856c021908e30fba3299c464a755ff09b9b195de859e91585e78  /etc/yum.repos.d/vbatts-bazel-epel-7.repo' | sha256sum -c
RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y --setopt=tsflags=nodocs install bazel
RUN yum -y --setopt=tsflags=nodocs groupinstall 'Development Tools'
RUN mkdir -p /root/gocode/bin /root/gocode/src \
    /root/gocode/src/github.com/ProdriveTechnologies/hpraid_exporter
WORKDIR /root/gocode/src/github.com/ProdriveTechnologies/hpraid_exporter
COPY ./ /root/gocode/src/github.com/ProdriveTechnologies/hpraid_exporter/
RUN bazel build //...

FROM centos:7
WORKDIR /tmp
RUN curl -o ssacli.rpm https://downloads.hpe.com/pub/softlib2/software1/pubsw-linux/p1857046646/v123474/ssacli-2.60-19.0.x86_64.rpm
RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y install epel-release && \
    yum localinstall -y --setopt=tsflags=nodocs ssacli.rpm && \
    yum -y --enablerepo=epel install tidy && \
    yum clean all
RUN rm -rf ssacli.rpm 

COPY --from=exp-builder /root/gocode/src/github.com/ProdriveTechnologies/hpraid_exporter/bazel-bin/linux_amd64_pure_stripped/hpraid_exporter /sbin/hpraid_exporter

ENTRYPOINT ["/sbin/hpraid_exporter"]
