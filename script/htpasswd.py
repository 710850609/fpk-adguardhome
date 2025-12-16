import bcrypt
import sys

def generate_htpasswd(password, rounds=10):
    # 将密码转换为字节
    password_bytes = password.encode('utf-8')
    # 使用 bcrypt 加密密码
    hashed_password = bcrypt.hashpw(password_bytes, bcrypt.gensalt(rounds=rounds))
    # 返回用户名和加密后的密码组合
    return f"{hashed_password.decode('utf-8')}"

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 htpasswd.py <PASSWORD>")
        sys.exit(1)
    
    password = sys.argv[1]
    result = generate_htpasswd(password)
    print(result)