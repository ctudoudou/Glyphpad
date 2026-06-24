# Decisions

## 1. Cache Metadata, Not Raw Icons

SQLite stores application metadata and paths. Icons are loaded from app bundles and cached in memory because serializing icon images is unnecessary for the first performance pass.

## 2. Cached First, Refresh Second

The launcher should display cached applications immediately when available, then refresh the list from disk in the background.

## 3. Avoid Main-Thread Scanning

Filesystem enumeration should not happen synchronously on the main actor. UI publishing still happens on the main actor.
