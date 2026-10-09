cd upload || exit 1
# Stop when install fails (e.g. engine-strict rejects this Node version) so the
# upload never runs on stale dependencies.
npm install || exit 1
npm run upload
