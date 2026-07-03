CVE Assessment: cyberdojo/docker-base (FROM docker:29.5.3-dind-alpine3.24) for cyber-dojo
Generated: 2026-06-15

Each vulnerability has its own file in this directory named after its CVE or Snyk ID.

== Why these live here ==

docker-base is not deployed directly. It is the base image that the downstream
cyber-dojo service images are built FROM. The two downstream consumers are:
  - runner    (assessed in detail; this analysis mirrors the runner repo)
  - commander (a second consumer, assessed separately)

Every vulnerability below is a Go CVE in the docker/dind toolchain binaries
(dockerd, docker-compose, docker-buildx) shipped inside the base image, not in
any cyber-dojo application code. A vulnerability in docker-base is therefore only
"genuine" if it is exploitable in a deployed downstream image. The assessment
below is the runner consumer's threat model; commander is tracked separately.

The matching .snyk ignore entries expire 30 days after creation (not "forever"),
so each assessment is forced to be re-reviewed rather than silently ignored.

== Runner security posture (the consumer this assessment is based on) ==

User code runs as UID 41966:51966 (non-root, non-privileged)
--net=none on every sandbox container -- no network access whatsoever
--security-opt=no-new-privileges -- blocks setuid escalation
No --privileged flag
--pids-limit=128, memory capped, ulimits set
Runner reaches Docker via mounted socket (/var/run/docker.sock), not from inside the sandbox

== Summary table ==

CVE / ID               Package                 Score  Exploitable?  Reason
------------------------------------------------------------------------------
CVE-2026-39821         golang.org/x/net/idna    9.3   No   runner resolves only trusted endpoints; no user-controlled IDNA input
CVE-2026-33186         gRPC-Go                  9.1   No   --net=none; no gRPC exposure
CVE-2026-29181         OTel baggage+family      8.7   No   --net=none; can't send baggage headers
CVE-2026-33814         golang.org/x/net/http2   8.7   No   --net=none; can't send SETTINGS frames
CVE-2026-46597         x/crypto/ssh             8.7   No   --net=none; no SSH server exposed
CVE-2026-39835         x/crypto/ssh             8.7   No   --net=none; no SSH server exposed
CVE-2026-46598         x/crypto/ssh/agent       8.7   No   --net=none; no SSH agent exposed
CVE-2026-53488         containerd v2 client/lbl 8.7   No   no CRI plugin in use; users cannot supply images; only trusted pre-built images run
CVE-2026-48702         sigstore/rekor pkg/types 8.7   No   no Rekor server run; server-side unmarshal path never reached; DoS only
CVE-2026-39831         x/crypto/ssh             8.6   No   --net=none; client-side; no outbound SSH
CloudWatch-16316406    aws-sdk-go-v2 CloudWatch 8.2   No   --net=none; DoS only; requires MITM of TLS
CVE-2026-24051         OTel SDK resource        7.3   No   macOS-only (ioreg)
CVE-2026-39827         x/crypto/ssh             7.1   No   --net=none; no SSH server exposed
CVE-2026-41178         OTel baggage/propagation 6.9   No   Docker toolchain only; dockerd Unix socket; CLI tools, no inbound HTTP
CVE-2026-39829         x/crypto/ssh             6.9   No   --net=none; no SSH server exposed
CVE-2026-39834         x/crypto/ssh             6.9   No   --net=none; no SSH server exposed
CVE-2026-39830         x/crypto/ssh             6.9   No   --net=none; no SSH server exposed
CVE-2026-39828         x/crypto/ssh             5.3   No   --net=none; no SSH server exposed
CVE-2026-46595         x/crypto/ssh             5.3   No   --net=none; no SSH server exposed
CVE-2026-39832         x/crypto/ssh/agent       5.3   No   --net=none; no SSH agent exposed
CVE-2026-39833         x/crypto/ssh/agent       5.3   No   --net=none; no SSH agent exposed
CVE-2026-42506         golang.org/x/net/html    5.3   No   only docker-buildx links html pkg; build-time CLI; no untrusted HTML rendered
CVE-2026-27136         golang.org/x/net/html    5.3   No   only docker-buildx links html pkg; build-time CLI; no untrusted HTML rendered
CVE-2026-42502         golang.org/x/net/html    5.3   No   only docker-buildx links html pkg; build-time CLI; no untrusted HTML rendered
CVE-2026-25681         golang.org/x/net/html    5.3   No   only docker-buildx links html pkg; build-time CLI; no untrusted HTML rendered
CVE-2026-25680         golang.org/x/net/html    5.3   No   only docker-buildx links html pkg; build-time CLI; no untrusted HTML parsed

== Key caveat ==

None of these are container escape vulnerabilities (runc escapes, kernel exploits).
Those are what would matter most for cyber-dojo's threat model. The CVEs listed are
mostly: network-service auth bugs (irrelevant with --net=none), Docker auth-plugin
bypass (irrelevant without plugins), BuildKit build-time flaws (irrelevant as
cyber-dojo doesn't build images from user content), and DoS issues. The runner's
defence-in-depth -- non-root user, no network, no-new-privileges, pid limits, tmpfs
isolation -- specifically neutralises the attack vectors these CVEs require.

The higher-value scan to run would target runc and containerd CVEs specifically,
since those are the components that actually mediate the boundary between user code
and the host.
