# Set up the Agent Platform — zero to connected

You are a coding agent setting up the [Agno Agent Platform](https://github.com/agno-agi/agent-platform-railway) on this machine. Follow the steps in order. **Verify every step before moving to the next.** When a step needs the human (an API key, a Docker install), stop, tell them exactly what to do, and wait for their confirmation. Never print secrets.

When you are done, the human will have a running AgentOS — a backend of agents, teams, and workflows — callable from this coding agent over MCP, and connectable to Claude and ChatGPT as chat frontends.

## Step 1 — Clone the repo

```sh
git clone https://github.com/agno-agi/agent-platform-railway.git agent-platform
cd agent-platform
```

**Verify:** `ls` shows `compose.yaml`, `example.env`, and an `agents/` directory.

**If it fails:** `git` missing → ask the human to install it (macOS: `xcode-select --install`). Directory already exists → `cd agent-platform && git pull` and continue.

## Step 2 — Configure the API key (human required)

```sh
cp example.env .env
```

Open `.env` for the human — try `code .env`, then `open .env` (macOS) or `xdg-open .env` (Linux), and if no opener works, print the absolute path. Then **stop and ask**:

> Please set `OPENAI_API_KEY` in the `.env` file I just opened (an OpenAI key from platform.openai.com — it powers the agents and embeddings). Tell me when you've saved it.

**Wait for confirmation. Do not proceed without it.**

**Verify:** `grep -c '^OPENAI_API_KEY=sk-' .env` prints `1` **and** `grep -c '^OPENAI_API_KEY=sk-\*\*\*' .env` prints `0` (the placeholder is `sk-***`; it must have been replaced). Never echo the key itself.

**If it fails:** the key is missing or still the placeholder — ask the human again, pointing at the exact line to edit.

## Step 3 — Check Docker (human installs if missing)

```sh
docker info
```

**Verify:** the command succeeds (it proves both that Docker is installed and that the daemon is running).

**If it fails:** do **not** try to install Docker yourself — it needs admin rights. Tell the human:

> Docker isn't available. Please install Docker Desktop from https://www.docker.com/get-started/ , start it, and tell me when the whale icon says it's running.

Wait for confirmation, then re-run `docker info` until it succeeds.

## Step 4 — Start the platform

```sh
docker compose up -d --build
```

The first build takes a few minutes. Then poll until the API is live:

```sh
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/docs
```

**Verify:** the curl returns `200` (retry every few seconds for up to ~2 minutes after the build finishes).

**If it fails:**
- `docker compose logs agentos-api --tail 50` shows the cause.
- `Invalid API key` / auth errors → the `OPENAI_API_KEY` in `.env` is wrong; go back to Step 2.
- Port conflict on 8000 or 5432 → something else is using it; ask the human whether to stop that service or edit the port mapping in `compose.yaml`.
- Database not ready → the entrypoint waits for Postgres (`WAIT_FOR_DB=True`); give it another 30 seconds, then check `docker compose logs agentos-db`.

## Step 5 — Register the platform as an MCP server

The platform exposes an MCP endpoint at `http://localhost:8000/mcp` (no auth needed locally — JWT protects it only in production). Register it in whichever coding agents are on this machine — check for each and register the ones present:

**Claude Code** (`command -v claude`):

```sh
claude mcp add --transport http agent-platform http://localhost:8000/mcp
```

**Verify:** `claude mcp list` shows `agent-platform`.

**Cursor** (`~/.cursor` exists): add to `~/.cursor/mcp.json` (create the file if needed, merge if it exists):

```json
{
  "mcpServers": {
    "agent-platform": { "url": "http://localhost:8000/mcp" }
  }
}
```

**Other MCP-capable tools** (Codex, Windsurf, …): register an HTTP/streamable-HTTP MCP server with URL `http://localhost:8000/mcp`, following that tool's MCP documentation.

**If none are installed:** skip this step and say so in the final summary — the platform still works from the AgentOS UI and chat connectors.

## Step 6 — Verify end to end

Call an agent through the MCP endpoint and show the human the response. The repo ships a check that runs the client inside the container (the image already has the `mcp` package — nothing to install on the host):

```sh
./scripts/mcp_check.sh
```

**Verify:** prints `MCP OK` and an agent response naming `web-search`, `platform-manager`, and `agent-builder`. Show the human the response — this is their platform answering through MCP.

**If it fails:** an exception here usually means the API restarted mid-call (`docker compose logs agentos-api --tail 20`) or the model call failed (check the `OPENAI_API_KEY`). Re-run once before diagnosing.

## Step 7 — Tell the human what they have

Summarize, adapted to what actually happened:

> Your agent platform is running at `http://localhost:8000` (API docs at `/docs`, MCP at `/mcp`).
>
> - **From this coding agent:** the `agent-platform` MCP server is registered — in a new session I can call `run_agent`, `run_team`, and `run_workflow` directly. Try: "ask the web-search agent what happened in AI this week".
> - **From the AgentOS UI:** connect `http://localhost:8000` at [os.agno.com](https://os.agno.com) to chat with agents and build new ones with Agent Builder.
> - **From Claude or ChatGPT:** chat apps can't reach localhost. Deploy first (`./scripts/railway/up.sh`, see the README), then add the MCP URL as a connector — in claude.ai: **Settings → Connectors → Add custom connector → `https://<your-railway-domain>/mcp`** (production requires the JWT auth configured during deploy). ChatGPT: **Settings → Connectors** with the same URL.
>
> Agent Builder creates and edits components immediately and reports what it built; only deletes pause for your approval at os.agno.com.
