#!/usr/bin/env python3
"""
轻量级YAML操作脚本
用法: python3 yaml_tool.py set 'dns.upstream_dns[0]' '8.8.8.8' config.yaml
"""
import sys
import re
from ruamel.yaml import YAML

class YamlEditor:
    """轻量级YAML编辑器"""
    
    def __init__(self, file_path: str):
        self.file_path = file_path
        self.yaml = YAML()
        self.yaml.indent(mapping=2, sequence=4, offset=2)
        self.yaml.preserve_quotes = True
        
        # 加载数据
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                self.data = self.yaml.load(f) or {}
        except FileNotFoundError:
            self.data = {}
        except Exception as e:
            print(f"加载文件失败: {e}", file=sys.stderr)
            self.data = {}
    
    def set_value(self, path: str, value_str: str) -> bool:
        """设置值"""
        try:
            # 解析值
            parser = YAML(typ='safe')
            import io
            value = parser.load(value_str)
            
            # 解析路径
            parts = self._parse_path(path)
            
            # 导航并设置
            node = self.data
            for i, part in enumerate(parts[:-1]):
                next_part = parts[i+1] if i+1 < len(parts) else None
                node = self._ensure_node(node, part, next_part)
            
            # 设置最终值
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
        except Exception as e:
            print(f"设置值失败: {e}", file=sys.stderr)
            return False
    
    def save(self) -> bool:
        """保存到文件"""
        try:
            with open(self.file_path, 'w', encoding='utf-8') as f:
                self.yaml.dump(self.data, f)
            return True
        except Exception as e:
            print(f"保存文件失败: {e}", file=sys.stderr)
            return False
    
    def _parse_path(self, path: str) -> list:
        """解析路径"""
        # 清理路径
        if path.startswith('$.'):
            path = path[2:]
        elif path.startswith('$'):
            path = path[1:]
        
        parts = []
        i = 0
        while i < len(path):
            if path[i] == '[':
                match = re.match(r'\[(\d+)\]', path[i:])
                if match:
                    parts.append(int(match.group(1)))
                    i += len(match.group(0))
                else:
                    raise ValueError(f"无效的数组索引: {path}")
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
        
        return parts
    
    def _ensure_node(self, node, part, next_part=None):
        """确保节点存在"""
        if isinstance(part, int):
            if not isinstance(node, list):
                node = []
            
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
                node = {}
            
            if part not in node:
                if next_part is not None and isinstance(next_part, int):
                    node[part] = []
                else:
                    node[part] = {}
            
            return node[part]


def main():
    """主函数"""
    if len(sys.argv) != 4:
        print("用法: python3 yaml_set.py <路径> <值> <文件>", file=sys.stderr)
        print("示例: python3 yaml_set.py 'dns.upstream_dns[0]' '8.8.8.8' config.yaml", file=sys.stderr)
        sys.exit(1)
    
    path = sys.argv[1]
    value = sys.argv[2]
    file_path = sys.argv[3]
    
    editor = YamlEditor(file_path)
    if editor.set_value(path, value):
        if editor.save():
            print(f"成功更新 {file_path}")
        else:
            print(f"保存失败", file=sys.stderr)
            sys.exit(1)
    else:
        print(f"设置值失败", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()