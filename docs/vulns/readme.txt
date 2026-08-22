CVE Assessment: cyberdojo/docker-base (FROM docker:29.7.2-dind-alpine3.24) for cyber-dojo
Generated: 2026-08-22

Each vulnerability has its own file in this directory named after its CVE or Snyk ID.
This file lists only what the current scan detects. When a scan stops reporting a
vulnerability, its row and its file are removed; git holds the earlier assessments.

== Why these live here ==

docker-base is not deployed directly. It is the base image that the downstream
cyber-dojo service images are built FROM. The two downstream consumers are:
  - runner    (assessed in detail; this analysis mirrors the runner repo)
  - commander (a second consumer, assessed separately)

Every vulnerability below is a Go CVE in the docker/dind toolchain binaries
shipped inside the base image, not in any cyber-dojo application code. A
vulnerability in docker-base is therefore only "genuine" if it is exploitable in
a deployed downstream image. The assessment below is the runner consumer's threat
model; commander is tracked separately.

The matching .snyk ignore entries expire 30 days after creation (not "forever"),
so each assessment is forced to be re-reviewed rather than silently ignored.

== Runner security posture (the consumer this assessment is based on) ==

User code runs as UID 41966:51966 (non-root, non-privileged)
--net=none on every sandbox container, so no network access whatsoever
--security-opt=no-new-privileges blocks setuid escalation
No --privileged flag
--pids-limit=128, memory capped, ulimits set
Runner reaches Docker via mounted socket (/var/run/docker.sock), not from inside the sandbox

== Summary table ==

CVE / ID               Package                 Score  Exploitable?  Reason
------------------------------------------------------------------------------
grpc-18172578          grpc internal/transport  8.8   No   vulnerable v1.80.0 only in containerd/shim/ctr; local Unix sockets; no xDS RBAC in use
CloudWatch-16316406    aws-sdk-go-v2 CloudWatch 8.2   No   --net=none; DoS only; requires MITM of TLS
CVE-2026-17106         moby/go-archive          7.1   No   vulnerable v0.2.1 only in docker-buildx; dockerd and compose patched; buildx never invoked
CVE-2026-41178         OTel baggage/propagation 6.9   No   only containerd/ctr still on otel v1.43.0; containerd API is a local Unix socket; ctr is a CLI
CVE-2026-10722         cilium/ebpf/btf          4.8   No   BTF loaded from host kernel and compiled-in programs; user code cannot load eBPF; local DoS only

== Key caveat ==

None of the assessed vulnerabilities is a container escape (runc escapes, kernel
exploits). Those are what would matter most for cyber-dojo's threat model. What
remains falls into three groups: denial of service reachable only from a
position user code does not hold (CloudWatch needs MITM of a TLS connection, the
BTF overflow needs the ability to load eBPF), control-plane surfaces exposed only
on local Unix sockets (grpc and OTel baggage in containerd), and a flaw in a
build-time CLI plugin that runner never invokes (go-archive in buildx). The
runner's defence-in-depth (non-root user, no network, no-new-privileges, pid
limits, tmpfs isolation) specifically neutralises the attack vectors these
require.

The higher-value scan to run would target runc and containerd CVEs specifically,
since those are the components that actually mediate the boundary between user code
and the host.
