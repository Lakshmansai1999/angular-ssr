#!/bin/sh
set -e

echo "Building Angular app..."
npm run build

echo "Starting Angular SSR server..."
node dist/angular-demo/server/server.mjs

