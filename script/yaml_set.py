#!/usr/bin/env python3
import yaml, sys, os

if len(sys.argv) != 4:
    print(f"Usage: {sys.argv[0]} 'key.path' 'value' file.yaml", file=sys.stderr)
    sys.exit(1)

path, value_str, yaml_file = sys.argv[1:]

# 1. 读
with open(yaml_file, 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f) or {}

# 2. 逐级导航
node = data
keys = path.split('.')
for k in keys[:-1]:
    if isinstance(node, list) and k.isdigit():
        idx = int(k)
        # 列表长度不够就自动扩容（填 None）
        while len(node) <= idx:
            node.append(None)
        if node[idx] is None:
            node[idx] = {}
        node = node[idx]
    elif isinstance(node, dict):
        node = node.setdefault(k, {})
    else:
        print(f"Cannot navigate into {k!r}", file=sys.stderr)
        sys.exit(1)

# 3. 赋值
value = yaml.safe_load(value_str)   # 自动转 bool/int/str
if isinstance(node, list) and keys[-1].isdigit():
    node[int(keys[-1])] = value
elif isinstance(node, dict):
    node[keys[-1]] = value
else:
    print(f"Cannot assign to {keys[-1]!r}", file=sys.stderr)
    sys.exit(1)

# 4. 写回
with open(yaml_file, 'w', encoding='utf-8') as f:
    yaml.safe_dump(data, f, sort_keys=False, allow_unicode=True)