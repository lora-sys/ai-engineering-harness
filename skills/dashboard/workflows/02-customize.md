# Customize — Theme, Title, Branding

Modify the dashboard's appearance and behavior. Edit the source templates, not the `.dashboard/` copies.

## Customization options

### 1. Change project title

Edit `templates/parser.js` — change the `PROJECT_NAME` constant:

```javascript
// At the top of parser.js, after the requires:
const PROJECT_NAME = 'My Project';  // Change this
```

The title appears in the dashboard header and browser tab.

### 2. Change the port

Edit `scripts/dashboard.sh` — change the `PORT` variable:

```bash
PORT=4321 node .dashboard/parser.js
```

Or set the environment variable:

```bash
DASHBOARD_PORT=8080 bash scripts/dashboard.sh
```

### 3. Customize the color theme

Edit `templates/dashboard.html` — the `:root` CSS custom properties:

```css
:root {
  --bg-base: #0a0e17;      /* near-black blue */
  --bg-surface: #111827;   /* card */
  --bg-elevated: #1a2332;  /* hover */
  --text-primary: #e2e8f0;
  --text-secondary: #94a3b8;
  --green: #22c55e;        /* PASS, Approved, Healthy */
  --yellow: #eab308;       /* Warning, Non-blocking */
  --red: #ef4444;          /* FAIL, Blocking, Critical */
  --accent: #3b82f6;       /* primary actions */
}
```

### 4. Change auto-refresh interval

Edit `templates/dashboard.html` — find the `REFRESH_INTERVAL` constant:

```javascript
const REFRESH_INTERVAL = 30000;  // 30 seconds, in milliseconds
```

### 5. Add a logo or favicon

Edit `templates/dashboard.html` — add to the `<head>`:

```html
<link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>📊</text></svg>">
```

### 6. Customize which views show

Edit `templates/dashboard.html` — the nav items:

```javascript
const VIEWS = [
  { id: 'dashboard', label: 'Dashboard', icon: '📊' },
  { id: 'evidence', label: 'Evidence', icon: '📁' },
  { id: 'kanban', label: 'Kanban', icon: '📋' },
  { id: 'takeover', label: 'Audit', icon: '🔍' },
];
```

Remove entries to hide views. Change labels and icons to rebrand.

### 7. Apply changes

After editing templates, regenerate:

```bash
$dashboard. Regenerate dashboard.
bash scripts/dashboard.sh  # restart server
```

## Theme presets

### Light theme

```css
:root {
  --bg-base: #f8fafc;
  --bg-surface: #ffffff;
  --bg-elevated: #f1f5f9;
  --text-primary: #1e293b;
  --text-secondary: #64748b;
  --green: #16a34a;
  --yellow: #ca8a04;
  --red: #dc2626;
  --accent: #2563eb;
}
```

### Cyberpunk (high contrast)

```css
:root {
  --bg-base: #050510;
  --bg-surface: #0a0a1a;
  --bg-elevated: #12122a;
  --text-primary: #e0e0ff;
  --text-secondary: #8888aa;
  --green: #00ff88;
  --yellow: #ffcc00;
  --red: #ff0066;
  --accent: #00ccff;
}
```

### Dracula

```css
:root {
  --bg-base: #282a36;
  --bg-surface: #44475a;
  --bg-elevated: #6272a4;
  --text-primary: #f8f8f2;
  --text-secondary: #bd93f9;
  --green: #50fa7b;
  --yellow: #f1fa8c;
  --red: #ff5555;
  --accent: #8be9fd;
}
```
