// Copies the web app (index.html and its files in the folder above) into native/www for Capacitor.
import { cpSync, mkdirSync, rmSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const out = join(here, '..', 'www');
rmSync(out, { recursive: true, force: true });
mkdirSync(out, { recursive: true });
const files = ['index.html', 'config.js', 'manifest.webmanifest', 'privacy.html', 'pip.png', 'balloon.png',
  'icon-192.png', 'icon-512.png', 'icon-maskable-512.png', 'apple-touch-icon.png', 'favicon-32.png'];
for (const f of files) if (existsSync(join(root, f))) cpSync(join(root, f), join(out, f));
if (existsSync(join(root, 'animals'))) cpSync(join(root, 'animals'), join(out, 'animals'), { recursive: true });
console.log('Web app copied to native/www');
