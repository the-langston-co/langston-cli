#!/bin/zsh
source "$(dirname $0)/env.sh" "${1:-prod}"
lock_target

echo "Attempting to stop auth-proxy for ${ENV}"

STATUS_CODE=$(proxy_http "$ADMIN_PORT" quitquitquit)
echo "  POST to http://localhost:${ADMIN_PORT}/quitquitquit returned status \"${STATUS_CODE}\""

# A wedged proxy may not answer quitquitquit, or may linger after it. Give it a
# few seconds to exit, then kill it by its health port so the ports free up.
for i in {1..10}; do
  [[ -z "$(proxy_pids)" ]] && break
  sleep 0.5
done
PIDS=($(proxy_pids))
if [[ ${#PIDS} -gt 0 ]]; then
  echo "  proxy still running (pid ${PIDS[*]}); sending SIGKILL"
  kill -9 "${PIDS[@]}" 2>/dev/null
  STATUS_CODE=200
fi

echo
if [ "$STATUS_CODE" -eq 200 ]; then
  echo "✅  cloud-sql-proxy stopped"
else
  echo "⃠  cloud-sql-proxy is not running"
fi
