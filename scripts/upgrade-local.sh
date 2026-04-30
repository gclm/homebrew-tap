#!/usr/bin/env bash
# Pull latest tap formulas and upgrade installed services.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
formula_dir="$script_dir/../Formula"

# 扫描 Formula/ 目录，提取 formula 名称
scan_formulas() {
  local formulas=()
  for f in "$formula_dir"/*.rb; do
    [[ -f "$f" ]] || continue
    basename "$f" .rb
  done
}

# 同步本地 tap
sync_local_tap() {
  local tap_dir
  tap_dir=$(brew --repository gclm/tap 2>/dev/null) || return 0

  local tap_origin
  tap_origin=$(git -C "$tap_dir" remote get-url origin 2>/dev/null) || return 0

  if [[ -d "$tap_origin" && ! "$tap_origin" =~ ^https?:// && ! "$tap_origin" =~ ^git@ ]]; then
    echo "==> Syncing local tap from $tap_origin..."
    git -C "$tap_dir" fetch origin --quiet 2>/dev/null || true
    git -C "$tap_dir" reset --hard origin/main --quiet 2>/dev/null || \
      git -C "$tap_dir" reset --hard origin/master --quiet 2>/dev/null || true
  fi
}

# 升级单个 formula
upgrade_formula() {
  local formula="$1"
  local full_name="gclm/tap/$formula"

  local versions
  versions="$(formula_versions "$formula")"
  if [[ -z "$versions" ]]; then
    echo "  $formula — 未安装，跳过"
    return
  fi

  local local_ver="${versions%% *}"
  local latest_ver="${versions##* }"
  if [[ "$local_ver" == "$latest_ver" ]]; then
    echo "  $formula — 已是最新"
    return
  fi

  echo "  升级 $formula (v$local_ver -> v$latest_ver)..."
  brew upgrade "$full_name"
  if brew services list 2>/dev/null | grep -q "^$formula"; then
    echo "  重启 $formula 服务..."
    brew services restart "$full_name"
  fi
}

# 通过 brew info JSON 获取版本信息
# 输出: "installed_version latest_version" 或为空（未安装）
formula_versions() {
  local full_name="gclm/tap/$1"
  local json
  json="$(brew info --json=v2 "$full_name" 2>/dev/null || true)"
  [[ -z "$json" ]] && return
  local installed latest
  installed="$(echo "$json" | jq -r '.formulae[0].installed[0].version // empty' 2>/dev/null || true)"
  latest="$(echo "$json" | jq -r '.formulae[0].versions.stable // empty' 2>/dev/null || true)"
  [[ -z "$installed" || -z "$latest" ]] && return
  # 统一去掉版本前缀用于比较
  installed="${installed#[vV]}"
  latest="${latest#[vV]}"
  echo "$installed $latest"
}

echo "==> Updating tap..."
sync_local_tap
brew update

formulas=()
while IFS= read -r f; do
  formulas+=("$f")
done < <(scan_formulas)

if [[ ${#formulas[@]} -eq 0 ]]; then
  echo "未找到任何 formula"
  exit 0
fi

# 传入参数时直接升级指定 formula
if [[ $# -gt 0 ]]; then
  for target in "$@"; do
    upgrade_formula "$target"
  done
  echo "==> Done"
  exit 0
fi

# 交互模式
echo ""
upgradable=()
for formula in "${formulas[@]}"; do
  full_name="gclm/tap/$formula"
  versions="$(formula_versions "$formula")"

  if [[ -z "$versions" ]]; then
    printf "  %-20s 未安装\n" "$formula"
  else
    local_ver="${versions%% *}"
    latest_ver="${versions##* }"
    if [[ "$local_ver" == "$latest_ver" ]]; then
      printf "  %-20s (暂无更新)\n" "$formula"
    else
      printf "  %-20s (v%s -> v%s)\n" "$formula" "$local_ver" "$latest_ver"
      upgradable+=("$formula")
    fi
  fi
done

if [[ ${#upgradable[@]} -eq 0 ]]; then
  echo ""
  echo "所有 formula 均为最新版本"
  exit 0
fi

echo ""
PS3=$'\n请选择要升级的 formula（a=全部，q=退出）：'
select formula in "${upgradable[@]}" "[升级全部]" "[退出]"; do
  case "$REPLY" in
    q|[Q]|$(( ${#upgradable[@]} + 2 )) )
      echo "退出"
      exit 0
      ;;
    a|A|$(( ${#upgradable[@]} + 1 )) )
      echo ""
      for f in "${upgradable[@]}"; do
        upgrade_formula "$f"
      done
      echo "==> Done"
      exit 0
      ;;
    *[!0-9]*)
      echo "无效选择"
      ;;
    *)
      if [[ "$REPLY" -ge 1 && "$REPLY" -le "${#upgradable[@]}" ]]; then
        echo ""
        upgrade_formula "${upgradable[$((REPLY-1))]}"
        echo "==> Done"
        exit 0
      else
        echo "无效选择"
      fi
      ;;
  esac
done
