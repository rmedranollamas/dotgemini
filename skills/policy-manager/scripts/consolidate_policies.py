import os
import re
import sys

def parse_prefixes(content):
    match = re.search(r'commandPrefix\s*=\s*\[(.*?)\]', content, re.DOTALL)
    if not match: return []
    return re.findall(r'"(.*?)"', match.group(1))

def run():
    # Look for policies relative to the current working directory
    shell_path = 'policies/shell.toml'
    auto_path = 'policies/auto-saved.toml'
    
    if not os.path.exists(shell_path):
        print(f"Error: {shell_path} not found.")
        return

    with open(shell_path, 'r') as f: shell_content = f.read()
    
    prefixes = set(parse_prefixes(shell_content))
    
    if os.path.exists(auto_path):
        with open(auto_path, 'r') as f: auto_content = f.read()
        auto_prefixes_raw = re.findall(r'commandPrefix\s*=\s*\[(.*?)\]', auto_content, re.DOTALL)
        for ap in auto_prefixes_raw:
            prefixes.update(re.findall(r'"(.*?)"', ap))
    
    final_prefixes = set()
    for p in prefixes:
        final_prefixes.add(p)
        if '/' in p:
            final_prefixes.add(os.path.basename(p))
            
    sorted_prefixes = sorted(list(final_prefixes))
    prefix_lines = ',\n  '.join(['"{}"'.format(p) for p in sorted_prefixes])
    
    new_shell = f'[[rule]]\ntoolName = "run_shell_command"\ndecision = "allow"\npriority = 100\nallow_redirection = true\ncommandPrefix = [\n  {prefix_lines}\n]\n'
    new_auto = '[[rule]]\ntoolName = "enter_plan_mode"\ndecision = "allow"\npriority = 100\n'
    
    with open(shell_path, 'w') as f: f.write(new_shell)
    if os.path.exists(auto_path):
        with open(auto_path, 'w') as f: f.write(new_auto)
    
    print("SUCCESS: Policies consolidated and basenames added.")

if __name__ == "__main__":
    run()
