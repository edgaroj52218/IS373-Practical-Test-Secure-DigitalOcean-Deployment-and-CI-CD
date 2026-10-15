# IS373 Practical Test: Secure DigitalOcean Deployment and CI/CD

Author: Edgar Steven Ojeda

## Live Websites

- Production: https://edgarstevenojeda.site
- QA: https://qa.edgarstevenojeda.site

Both environments run separate Apache containers on my DigitalOcean Ubuntu Droplet at `167.172.128.166`. Traefik routes requests by hostname and provides HTTPS through Let's Encrypt. HTTP requests redirect to HTTPS.

## Repository Files

| File | Purpose |
| --- | --- |
| `index.html` | Website source and visible release version |
| `Dockerfile` | Packages the website using Apache httpd |
| `compose.yaml` | Application container and Traefik routing configuration |
| `.github/workflows/deploy.yml` | Validation, image build/push, and automatic deployment |
| `scripts/deploy.sh` | Server deployment script |

## QA-to-Production Promotion Rule

1. Commit and push changes to the `qa` branch.
2. GitHub Actions validates the website and Compose configuration.
3. The workflow builds a Docker image, pushes it to GitHub Container Registry (GHCR), and automatically deploys QA.
4. Verify the visible change at the QA HTTPS URL.
5. Open a pull request from `qa` into `main`.
6. Merge the verified change into `main`.
7. GitHub Actions automatically builds, pushes, and deploys production.
8. Verify the production HTTPS URL.

Normal releases follow this QA-to-main promotion process. The workflow also supports manual dispatch.

## Deployment Configuration

Docker images are tagged with the full Git commit SHA.

The server's deployment script is installed at:

```text
/usr/local/sbin/is373-deploy
```

The application Compose configuration is installed at:

```text
/opt/is373-practical/compose.yaml
```

Separate Compose projects isolate the environments:

- `is373-qa`
- `is373-prod`

Both environments connect to the external `hosting-web` Docker network.

Traefik routes:

- `qa.edgarstevenojeda.site` to QA
- `edgarstevenojeda.site` to production

The application containers listen on port 80 internally. Traefik handles public HTTP and HTTPS traffic.

### Required GitHub Actions Secrets

- `DEPLOY_HOST`
- `DEPLOY_USER`
- `DEPLOY_SSH_KEY`
- `DEPLOY_KNOWN_HOSTS`

GitHub Actions connects to the Droplet using SSH-key authentication and invokes:

```bash
sudo -n /usr/local/sbin/is373-deploy STAGE IMAGE
```

`STAGE` is `qa` or `prod`. `IMAGE` is the GHCR image reference tagged with the full commit SHA.

The deployment account has passwordless sudo permission for the deployment script. The script pulls the requested image and starts the selected environment.

The deployment script and Compose configuration are root-owned. They must be installed on the server before the workflow can deploy; the workflow does not copy these files automatically.

The old hosting service's `traefik.enable` label is set to `false` in `/root/373_hosting/runtime/compose.yaml`. This prevents it from competing for the production hostname.

## SSH Security

The configured non-root account is `edgarsteven`.

Recorded effective SSH settings:

```text
permitrootlogin no
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
```

Check configuration syntax and effective settings:

```bash
sudo /usr/sbin/sshd -t
sudo /usr/sbin/sshd -T |
  grep -E '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication) '
```

Demonstrate non-root SSH-key access from a separate client terminal:

```bash
ssh -o PreferredAuthentications=publickey \
    -o PasswordAuthentication=no \
    edgarsteven@167.172.128.166
```

After connecting:

```bash
whoami
id
hostname
```

Expected: `whoami` reports `edgarsteven`, and `id` reports a nonzero user ID.

The supporting evidence must include a successful client SSH-key login; a server console session alone does not demonstrate SSH-key access.

## CI/CD Validation

Before building and deploying, the workflow checks that:

- `index.html` exists and is nonempty.
- The page contains `IS373 Deployment Test`.
- The page contains a `Release:` marker.
- The Dockerfile exists.
- Docker Compose configuration validates successfully.

The workflow then builds and pushes the Docker image and deploys it to the selected environment.

These checks validate required content and configuration. Live HTTPS checks provide additional evidence that the deployed website is accessible.

## Demonstrated Release Promotion

### QA Deployment

Commit `d157801` changed the visible page text from:

```text
Release: Version 1
```

to:

```text
Release: Version 2
```

Successful QA validation, image build/push, and automatic deployment:

[QA workflow run 38786537257](https://github.com/edgaroj52218/IS373-Practical-Test-Secure-DigitalOcean-Deployment-and-CI-CD/actions/runs/38786537257)

Before promotion, live HTTPS checks showed:

```text
Checking https://qa.edgarstevenojeda.site
    <p>Release: Version 2</p>
Checking https://edgarstevenojeda.site
    <p>Release: Version 1</p>
```

### Production Promotion

The verified QA change was promoted through:

[Pull request #1: Promote Version 2 from QA to production](https://github.com/edgaroj52218/IS373-Practical-Test-Secure-DigitalOcean-Deployment-and-CI-CD/pull/1)

Merging the pull request triggered a successful production pipeline:

[Production workflow run 38788650247](https://github.com/edgaroj52218/IS373-Practical-Test-Secure-DigitalOcean-Deployment-and-CI-CD/actions/runs/38788650247)

After promotion, live HTTPS checks showed:

```text
Checking https://qa.edgarstevenojeda.site
    <p>Release: Version 2</p>
Checking https://edgarstevenojeda.site
    <p>Release: Version 2</p>
```

## Repeatable Verification Commands

### Running Containers

```bash
whoami
hostname
hostname -I
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
```

Expected containers include:

- `is373-qa-site-1`
- `is373-prod-site-1`
- `hosting373-traefik-1`

### HTTP Redirects and HTTPS Responses

```bash
curl -I --max-time 20 http://qa.edgarstevenojeda.site
curl -I --max-time 20 http://edgarstevenojeda.site
curl -I --max-time 20 https://qa.edgarstevenojeda.site
curl -I --max-time 20 https://edgarstevenojeda.site
```

Expected:

- HTTP requests redirect to the matching HTTPS hostname.
- HTTPS requests return status 200 without certificate errors.

### Visible Release Versions

```bash
for host in qa.edgarstevenojeda.site edgarstevenojeda.site; do
  echo "Checking https://$host"
  curl -fsS --max-time 20 "https://$host" | grep 'Release:'
done
```

After the demonstrated promotion, both sites should report `Release: Version 2`.

These checks do not disable TLS certificate verification.

### GitHub Actions Runs

```bash
REPO="edgaroj52218/IS373-Practical-Test-Secure-DigitalOcean-Deployment-and-CI-CD"
gh run list --repo "$REPO" --limit 10
```

## Rubric Evidence Checklist

Supporting submission screenshots should show:

1. **Own server:** DigitalOcean Droplet ownership, matching public IP, and running website containers.
2. **SSH security:** Successful SSH-key access through the non-root account and effective settings disabling root SSH login and password SSH login.
3. **GitHub repository:** Public repository accessible without signing in, required source/configuration files, and this README with live links and test evidence.
4. **CI/CD and image:** Successful validation, image build/push, automatic deployment, and the visible Version 2 change moving from QA through production.
5. **QA and production sites:** Separate HTTPS hostnames working correctly and following the documented promotion rule.

Capture both the before-promotion state and the after-promotion state. Include the merged pull request and successful workflow runs.

Never include private keys, tokens, or secret values in evidence.
