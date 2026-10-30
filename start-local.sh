#!/usr/bin/env bash
# Levanta Chatwoot en local (entorno de desarrollo, con el Kanban).
set -euo pipefail

cd "$(dirname "$0")"

if ! docker info >/dev/null 2>&1; then
  echo "Docker no responde."
  echo "Abre Docker Desktop y activa: Settings > Resources > WSL integration > Ubuntu-24.04"
  exit 1
fi

# Cada imagen se construye solo si falta. vite y rails parten de la base.
docker image inspect chatwoot:development >/dev/null 2>&1 || {
  echo "==> Construyendo imagen base (tarda ~15-30 min la primera vez)"
  docker compose build base
}
docker image inspect chatwoot-rails:development >/dev/null 2>&1 || {
  echo "==> Construyendo imagen de rails"
  docker compose build rails
}
docker image inspect chatwoot-vite:development >/dev/null 2>&1 || {
  echo "==> Construyendo imagen de vite"
  docker compose build vite
}

# db:chatwoot_prepare no sirve aqui: carga schema.rb (que no incluye las tablas
# del Kanban) y luego siembra, y el seed aborta por migraciones pendientes.
echo "==> Preparando base de datos"
docker compose up -d postgres redis
if ! docker compose run --rm rails bundle exec rails runner 'ActiveRecord::Base.connection.table_exists?("accounts") || exit(1)' >/dev/null 2>&1; then
  docker compose run --rm rails bundle exec rails db:create db:schema:load
fi
docker compose run --rm rails bundle exec rails db:migrate
docker compose run --rm rails bundle exec rails db:seed

echo "==> Levantando servicios"
docker compose up -d

cat <<'MSG'

Listo. Espera 1-2 minutos a que compile el frontend y entra:

  Chatwoot        http://localhost:3001
  Kanban          http://localhost:3001  -> menu lateral "Kanban"
  Correo de prueba http://localhost:8025

  Usuario: john@acme.inc
  Clave:   Password1!

Comandos utiles:
  docker compose logs -f rails    # ver que pasa
  docker compose logs -f vite     # compilacion del frontend
  docker compose down             # apagar (conserva los datos)
MSG
