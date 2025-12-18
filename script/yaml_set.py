#!/usr/bin/env python3
"""
简单版YAML操作脚本 - 专门处理清空数组
"""
import sys
import re
from ruamel.yaml import YAML

def set_yaml_value(file_path: str, path: str, value_str: str) -> bool:
    """设置YAML值，支持清空数组"""
    yaml = YAML()
    yaml.indent(mapping=2, sequence=4, offset=2)
    yaml.preserve_quotes = True
    
    # 加载数据
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = yaml.load(f) or {}
    except FileNotFoundError:
        data = {}
    except Exception as e:
        print(f"加载文件失败: {e}", file=sys.stderr)
        return False
    
    # 解析值
    parser = YAML(typ='safe')
    value = parser.load(value_str)
    
    # 解析路径
    if path.startswith('$.'):
        path = path[2:]
    elif path.startswith('$'):
        path = path[1:]
    
    # 处理清空数组的特殊情况
    if value_str == '[]':
        # 如果值是空数组，直接设置为空数组
        if not path:
            data = []
            result = True
        else:
            result = _set_value_to_path(data, path, [])
    else:
        result = _set_value_to_path(data, path, value)
    
    if not result:
        return False
    
    # 保存文件
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            yaml.dump(data, f)
        return True
    except Exception as e:
        print(f"保存文件失败: {e}", file=sys.stderr)
        return False

def _set_value_to_path(data, path: str, value) -> bool:
    """将值设置到路径"""
    # 解析路径部分
    parts = []
    i = 0
    while i < len(path):
        if path[i] == '[':
            match = re.match(r'\[(\d+)\]', path[i:])
            if match:
                parts.append(int(match.group(1)))
                i += len(match.group(0))
            else:
                return False
        elif path[i] == '.':
            i += 1
            j = i
            while j < len(path) and path[j] not in ['[', '.']:
                j += 1
            key = path[i:j]
            parts.append(int(key) if key.isdigit() else key)
            i = j
        else:
            j = i
            while j < len(path) and path[j] not in ['[', '.']:
                j += 1
            key = path[i:j]
            parts.append(int(key) if key.isdigit() else key)
            i = j
    
    # 导航到父节点
    node = data
    for i, part in enumerate(parts[:-1]):
        next_part = parts[i+1] if i+1 < len(parts) else None
        node = _ensure_node(node, part, next_part)
        if node is None:
            return False
    
    # 设置最终值
    if not parts:
        # 根路径
        data = value
        return True
    
    last_part = parts[-1]
    if isinstance(node, list) and isinstance(last_part, int):
        while len(node) <= last_part:
            node.append(None)
        node[last_part] = value
    elif isinstance(node, dict):
        node[last_part] = value
    else:
        return False
    
    return True

def _ensure_node(node, part, next_part=None):
    """确保节点存在"""
    if isinstance(part, int):
        if not isinstance(node, list):
            # 不能将非列表转换为列表
            return None
        
        while len(node) <= part:
            node.append(None)
        
        if node[part] is None:
            if next_part is not None and isinstance(next_part, int):
                node[part] = []
            else:
                node[part] = {}
        
        return node[part]
    else:
        if not isinstance(node, dict):
            # 不能将非字典转换为字典
            return None
        
        if part not in node:
            if next_part is not None and isinstance(next_part, int):
                node[part] = []
            else:
                node[part] = {}
        
        return node[part]

def main():
    if len(sys.argv) != 4:
        print("用法: python3 yaml_set.py <路径> <值> <文件>", file=sys.stderr)
        print("清空数组示例: python3 yaml_set.py 'dns.upstream_dns' '[]' config.yaml", file=sys.stderr)
        sys.exit(1)
    
    path = sys.argv[1]
    value = sys.argv[2]
    file_path = sys.argv[3]
    
    if set_yaml_value(file_path, path, value):
        print(f"成功更新 {file_path}")
    else:
        print(f"操作失败", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()