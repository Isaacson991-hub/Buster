import { createServer } from 'node:http'
import { readFile, stat } from 'node:fs/promises'
import { extname, join, resolve, sep } from 'node:path'
import { pathToFileURL } from 'node:url'

const root = resolve(process.argv[2] || '.')
const port = Number(process.env.PORT || 3000)
const mime = new Map([
  ['.html', 'text/html; charset=utf-8'], ['.js', 'text/javascript; charset=utf-8'],
  ['.mjs', 'text/javascript; charset=utf-8'], ['.css', 'text/css; charset=utf-8'],
  ['.json', 'application/json; charset=utf-8'], ['.svg', 'image/svg+xml'],
  ['.png', 'image/png'], ['.jpg', 'image/jpeg'], ['.jpeg', 'image/jpeg'],
  ['.webp', 'image/webp'], ['.glb', 'model/gltf-binary'], ['.wasm', 'application/wasm'],
])

const server = createServer(async (request, response) => {
  try {
    const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname)
    let target = resolve(root, `.${pathname}`)
    if (target !== root && !target.startsWith(root + sep)) {
      response.writeHead(403).end('Forbidden')
      return
    }
    let info
    try { info = await stat(target) } catch { info = null }
    if (info?.isDirectory()) target = join(target, 'index.html')
    try {
      const body = await readFile(target)
      response.writeHead(200, {
        'Content-Type': mime.get(extname(target).toLowerCase()) || 'application/octet-stream',
        'Cache-Control': 'no-cache',
        'X-Content-Type-Options': 'nosniff',
      })
      response.end(body)
    } catch {
      // Support client-side routes without hiding missing asset requests.
      if (!extname(pathname)) {
        const body = await readFile(join(root, 'index.html'))
        response.writeHead(200, { 'Content-Type': mime.get('.html'), 'Cache-Control': 'no-cache' })
        response.end(body)
      } else response.writeHead(404).end('Not found')
    }
  } catch (error) {
    console.error(error)
    response.writeHead(400).end('Bad request')
  }
})

server.listen(port, '0.0.0.0', () => console.log(`Serving ${root} on port ${port}`))
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => server.close(() => process.exit(0)))

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  // Keep the process in the foreground for the controller's tmux lifecycle.
}
