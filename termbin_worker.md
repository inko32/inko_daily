# Cloudflare Worker Termbin

A lightweight, self-hosted `termbin`-like paste service powered by Cloudflare Workers and KV.

## Features

- **Zero Infrastructure**: Run entirely on Cloudflare's serverless edge network.
- **CLI Friendly**: Easily pipe text or files directly via `curl`.
- **Auto-Expiration**: Pastes automatically expire after 7 days (configurable).

## Deployment

### 1. Create a Worker
1. Go to the [Cloudflare Dashboard](https://dash.cloudflare.com/).
2. Navigate to **Workers & Pages** and click **Create application** -> **Create Worker**.
3. Give it a name (e.g., `my-termbin`) and click **Deploy**.

### 2. Create a KV Namespace
1. In the Cloudflare Dashboard, navigate to **Workers & Pages** -> **KV**.
2. Click **Create a namespace** and name it something like `PASTE_KV`.

### 3. Bind KV to your Worker
1. Go back to your Worker -> **Settings** -> **Variables** -> **KV Namespace Bindings**.
2. Click **Add binding**:
   - **Variable name**: `MY_KV`
   - **KV namespace**: Select the `PASTE_KV` you created in Step 2.
3. Save and deploy the changes.

### 4. Deploy the Worker Code
1. Go to your Worker's **Code** tab (or **Edit code**).
2. Replace the default code with the script below (you can change `/mypaste` to any path you like):

```javascript
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const id = url.pathname.slice(1);

    if (request.method === "GET" && id) {
      const data = await env.MY_KV.get(id);
      if (!data) return new Response("Not Found", { status: 404 });
      return new Response(data, {
        headers: { "Content-Type": "text/plain; charset=utf-8" },
      });
    }

    // You can change "/mypaste" to any custom path you prefer
    if (request.method === "POST" && url.pathname === "/mypaste") {
      const newId = Math.random().toString(36).substring(2, 8); 
      const body = await request.text();
      
      if (!body) {
        return new Response("Empty body", { status: 400 });
      }

      await env.MY_KV.put(newId, body, { expirationTtl: 604800 });

      return new Response(`https://${url.host}/${newId}\\n`, {
        headers: { "Content-Type": "text/plain; charset=utf-8" },
      });
    }

    return new Response("Not Found", { status: 404 });
  }
};
```

## Usage

### 1. Setup Shell Alias
Add the following alias to your `~/.bashrc` or `~/.zshrc` (make sure to match your custom path like `/mypaste`):

alias tb='curl -s --data-binary @- https://<your-worker-domain>/mypaste'

### 2. Upload Content
Pipe any text or file into the `tb` command:

echo "Hello, World!" | tb
# Returns: https://<your-worker-domain>/abc123

### 3. Retrieve Content
View your uploaded paste using a browser or `curl`:

curl https://<your-worker-domain>/abc123
