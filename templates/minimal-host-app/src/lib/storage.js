// ---------------------------------------------------------------------------
// Adaptive Storage
// ---------------------------------------------------------------------------
//
// Dual-mode storage adapter that routes through hostLocalStorage when running
// inside a Triangle host, and falls back to browser localStorage when standalone.
//
// Benefits:
//   - Same API regardless of environment
//   - Host storage is encrypted and isolated per-product
//   - Standalone mode works for local development
//   - Zero migration overhead when moving between environments
//
// Usage:
//   import { storageReadJSON, storageWriteJSON, storageClear } from './lib/storage.js'
//
//   await storageWriteJSON('settings', { theme: 'dark' })
//   const settings = await storageReadJSON('settings')
//   await storageClear('settings')
// ---------------------------------------------------------------------------

import { hostLocalStorage } from "@novasamatech/product-sdk";
import { isInHost } from "./host.js";

// --- Host mode (Triangle hosts: Polkadot Desktop, dot.li, etc.) ---

async function hostReadJSON(key) {
  try {
    const value = await hostLocalStorage.readJSON(key);
    return value ?? null;
  } catch {
    // readJSON throws when key doesn't exist (JSON.parse on empty bytes)
    return null;
  }
}

async function hostWriteJSON(key, value) {
  await hostLocalStorage.writeJSON(key, value);
}

async function hostClear(key) {
  await hostLocalStorage.clear(key);
}

async function hostReadString(key) {
  try {
    const value = await hostLocalStorage.readString(key);
    return value || null;
  } catch {
    return null;
  }
}

async function hostWriteString(key, value) {
  await hostLocalStorage.writeString(key, value);
}

// --- Standalone mode (browser localStorage) ---

async function browserReadJSON(key) {
  const raw = localStorage.getItem(key);
  if (raw === null) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

async function browserWriteJSON(key, value) {
  localStorage.setItem(key, JSON.stringify(value));
}

async function browserClear(key) {
  localStorage.removeItem(key);
}

async function browserReadString(key) {
  return localStorage.getItem(key);
}

async function browserWriteString(key, value) {
  localStorage.setItem(key, value);
}

// --- Public API ---

/**
 * Read a JSON value from storage.
 *
 * @param {string} key - The storage key
 * @returns {Promise<T | null>} The parsed value, or null if not found
 */
export async function storageReadJSON(key) {
  return isInHost() ? hostReadJSON(key) : browserReadJSON(key);
}

/**
 * Write a JSON value to storage.
 *
 * @param {string} key - The storage key
 * @param {any} value - The value to store (must be JSON-serializable)
 */
export async function storageWriteJSON(key, value) {
  return isInHost() ? hostWriteJSON(key, value) : browserWriteJSON(key, value);
}

/**
 * Delete a key from storage.
 *
 * @param {string} key - The storage key to remove
 */
export async function storageClear(key) {
  return isInHost() ? hostClear(key) : browserClear(key);
}

/**
 * Read a raw string from storage.
 *
 * @param {string} key - The storage key
 * @returns {Promise<string | null>} The string value, or null if not found
 */
export async function storageReadString(key) {
  return isInHost() ? hostReadString(key) : browserReadString(key);
}

/**
 * Write a raw string to storage.
 *
 * @param {string} key - The storage key
 * @param {string} value - The string to store
 */
export async function storageWriteString(key, value) {
  return isInHost() ? hostWriteString(key, value) : browserWriteString(key, value);
}
