# Generate — Regenerate Dashboard Artifacts

Re-copies `templates/parser.js` and `templates/dashboard.html` to `.dashboard/` in the target project. Use this when the skill's templates have been updated.

## When to run

- After updating `templates/parser.js` or `templates/dashboard.html` in the skill
- When the user says "regenerate the dashboard" or "$dashboard. Regenerate."
- After pulling updates to the skill

## Steps

### 1. Verify .dashboard/ exists

```bash
if [[ ! -d ".dashboard" ]]; then
  echo ".dashboard/ not found. Run 00-bootstrap.md first."
  exit 1
fi
```

### 2. Backup current files (optional)

```bash
cp .dashboard/parser.js .dashboard/parser.js.bak 2>/dev/null || true
cp .dashboard/dashboard.html .dashboard/dashboard.html.bak 2>/dev/null || true
```

### 3. Copy updated templates

```bash
cp templates/parser.js .dashboard/parser.js
cp templates/dashboard.html .dashboard/dashboard.html
```

### 4. Verify the server starts

```bash
cd .dashboard && node -e "require('./parser.js')" &
sleep 1
curl -s http://localhost:4321/api/health > /dev/null && echo "OK" || echo "FAIL"
kill %1 2>/dev/null
```

### 5. Restart if running

If the dashboard server is already running, tell the user to restart it:

```bash
# Kill the old process and restart
pkill -f "node .*parser.js" 2>/dev/null || true
bash scripts/dashboard.sh &
```

## After generate

- Check the dashboard in browser to confirm the update applied
- If customizations were made to `.dashboard/` files, they will be overwritten. Advise user to edit `templates/` instead.
