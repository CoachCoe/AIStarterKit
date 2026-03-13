// ---------------------------------------------------------------------------
// Host Detection & Connection Utilities
// ---------------------------------------------------------------------------
//
// Detects whether the app is running inside a Triangle host (Polkadot Desktop,
// dot.li, Polkadot App) and provides utilities for connecting to the host.
//
// Usage:
//   import { isInHost, detectHostEnvironment, connectToHost, checkHostAlive } from './lib/host.js'
//
//   if (isInHost()) {
//     const extension = await connectToHost()
//     if (extension) { /* use host-provided accounts */ }
//   }
// ---------------------------------------------------------------------------

import {
  injectSpektrExtension,
  SpektrExtensionName,
  createAccountsProvider,
  sandboxTransport,
} from "@novasamatech/product-sdk";
import { connectInjectedExtension } from "@polkadot-api/pjs-signer";

const HOST_PING_TIMEOUT_MS = 5_000;

let _hostDetected = null;

/**
 * Detect which host environment we're running in.
 *
 * @returns {'desktop-webview' | 'web-iframe' | 'standalone'}
 *   - 'desktop-webview': Running in Polkadot Desktop (Electron webview)
 *   - 'web-iframe': Running in a web-based host (dot.li, Polkadot.com)
 *   - 'standalone': Running directly in browser (no host)
 */
export function detectHostEnvironment() {
  // Polkadot Desktop sets this marker on the window object
  if (window.__HOST_WEBVIEW_MARK__) return "desktop-webview";
  // Web hosts load the product in an iframe
  if (window.parent !== window) return "web-iframe";
  return "standalone";
}

/**
 * Quick check: are we running inside any host environment?
 *
 * @returns {boolean} True if in a host (desktop or web iframe)
 */
export function isInHost() {
  return detectHostEnvironment() !== "standalone";
}

/**
 * Whether host was successfully detected and connected.
 *
 * @returns {boolean | null} True if connected, false if failed, null if not yet checked
 */
export function hostDetected() {
  return _hostDetected;
}

/**
 * Inject the Spektr extension shim and connect to the host.
 *
 * This enables the host to provide accounts and signing services to the app.
 * Returns the connected extension or null if connection fails.
 *
 * @returns {Promise<object | null>} The injected extension, or null on failure
 */
export async function connectToHost() {
  try {
    const success = await injectSpektrExtension();
    if (!success) {
      _hostDetected = false;
      return null;
    }
    _hostDetected = true;
    return await connectInjectedExtension(SpektrExtensionName);
  } catch (e) {
    console.warn("[host] Failed to connect to host:", e);
    _hostDetected = false;
    return null;
  }
}

/**
 * Check if the host connection is still alive.
 *
 * Useful for detecting stale connections (e.g., after the app has been
 * backgrounded for a while). Makes a lightweight request through the
 * same transport that signing uses.
 *
 * @returns {Promise<boolean>} True if the host responded within timeout
 */
export async function checkHostAlive() {
  if (!isInHost()) return true; // not in host, nothing to check

  try {
    const accountsProvider = createAccountsProvider(sandboxTransport);
    const ping = new Promise((resolve) => {
      accountsProvider.getNonProductAccounts().then(
        () => resolve(true),
        () => resolve(false),
      );
    });
    const timeout = new Promise((resolve) =>
      setTimeout(() => resolve(false), HOST_PING_TIMEOUT_MS),
    );
    const result = await Promise.race([ping, timeout]);

    console.log(`[host] connection check: ${result ? "alive" : "stale"}`);
    return result;
  } catch (e) {
    console.warn("[host] connection check failed:", e);
    return false;
  }
}

export { SpektrExtensionName };
