#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bundle_dir="$project_dir/build/linux/x64/release/bundle"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
install_dir="$data_dir/vitta-fitness"
apps_dir="$data_dir/applications"
icons_dir="$data_dir/icons/hicolor/512x512/apps"

if [[ ! -x "$bundle_dir/fitness_app" ]]; then
  echo "Bundle não encontrado. Execute flutter build linux --release primeiro." >&2
  exit 1
fi

mkdir -p "$install_dir" "$apps_dir" "$icons_dir"
cp -a "$bundle_dir/." "$install_dir/"
cp "$project_dir/web/icons/Icon-512.png" "$icons_dir/br.gov.dgti.fitness_app.png"
sed "s|Exec=fitness_app|Exec=$install_dir/fitness_app|" \
  "$project_dir/linux/packaging/br.gov.dgti.fitness_app.desktop" \
  > "$apps_dir/br.gov.dgti.fitness_app.desktop"
chmod +x "$apps_dir/br.gov.dgti.fitness_app.desktop"
echo "Vitta Fitness instalado no menu de aplicativos."
