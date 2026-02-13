#!/usr/bin/env python3

import sys
import os
from ruamel.yaml import YAML

    
def main():
    if len(sys.argv) != 3:
        print("用法: python3 yaml_get.py <路径> <文件>", file=sys.stderr)
        print("例如: python3 yaml_get.py 'dns.upstream_dns' config.yaml", file=sys.stderr)
        sys.exit(1)
    
    key=sys.argv[1]
    file=sys.argv[2]
    try:
        yaml = YAML()
        yaml.preserve_quotes = True  # 保留引号（可选）
        
        with open(os.path.expanduser(file)) as f:
            data = yaml.load(f)
        
        for seg in key.split('.'):
            data = data[seg]
        
        print(data)
    except Exception as e:
        print(e, file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()