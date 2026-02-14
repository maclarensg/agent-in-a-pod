# agent-in-a-pod

Containerized web terminal with [Claude Code](https://docs.anthropic.com/en/docs/claude-code), accessible from any browser via [ttyd](https://github.com/tsl0922/ttyd). Designed to sit behind an nginx reverse proxy with mTLS for zero-password authentication.

Sessions persist via tmux — close your browser, come back later, pick up where you left off.

## What's inside

| Tool | Version | Purpose |
|------|---------|---------|
| ttyd | 1.7.7 | Web terminal over WebSocket |
| tmux | latest | Persistent sessions |
| Claude Code | latest | AI coding agent (works with Max subscription) |
| Python | 3.12 | Runtime + pip + venv |
| Node.js | 22 | Runtime + npm |
| git | latest | Version control |
| ssh | latest | Client + agent (keys mounted from host) |
| ripgrep, fd, jq, vim, nano | latest | Dev utilities |

## Quick start

```bash
# Clone
git clone https://github.com/maclarensg/agent-in-a-pod.git
cd agent-in-a-pod

# Setup
cp .env.example .env    # edit with your values
task init               # build, start, and go

# Or without Task runner
docker compose up -d
```

Open your browser to the ttyd endpoint (default `http://localhost:7681`, or via your nginx proxy).

First time only:
```bash
task login    # authenticate Claude with your Max subscription
```

## Tasks

Requires [Task](https://taskfile.dev) runner.

| Command | Description |
|---------|-------------|
| `task init` | First-time setup — copy env, build, start |
| `task build` | Build the container image |
| `task up` | Start the pod |
| `task down` | Stop the pod |
| `task restart` | Restart (preserves tmux session) |
| `task shell` | Drop into container bash |
| `task attach` | Attach to tmux session |
| `task claude` | Launch Claude Code directly |
| `task login` | OAuth login for Claude |
| `task status` | Show container status |
| `task logs` | Tail container logs |
| `task info` | Show installed tool versions |
| `task destroy` | Remove everything including volumes |

## Architecture

```
Browser (client cert)
  │
  │  mTLS
  ▼
nginx (reverse proxy)
  │
  │  WebSocket → localhost:7681
  ▼
ttyd (web terminal)
  │
  ▼
tmux session
  │
  ▼
bash / claude
```

## Volumes

| Volume | Persists |
|--------|----------|
| `claude-data` | Claude login credentials + settings |
| `shell-history` | Bash history |
| Bind: `~/.ssh` | SSH keys (read-only from host) |
| Bind: `~/.gitconfig` | Git config (read-only from host) |
| Bind: `$WORKSPACE` | Your project files |

## nginx config

Add to your existing mTLS server block:

```nginx
location /shell {
    proxy_pass http://127.0.0.1:7681;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 86400s;
}
```

## CI/CD

| Trigger | Pipeline |
|---------|----------|
| Pull request | Build image + Trivy vulnerability scan |
| Release published | Build + scan + push to Docker Hub as `maclarensg/agent-in-a-pod:<tag>` |

## License

MIT
