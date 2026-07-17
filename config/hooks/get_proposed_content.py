import sys
import json
import os

def main():
    if len(sys.argv) < 2:
        sys.exit(1)
    
    temp_path = sys.argv[1]
    
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(1)
        
    tool_call = payload.get("toolCall")
    if not tool_call:
        sys.exit(1)
        
    name = tool_call.get("name")
    args = tool_call.get("args", {})
    
    target_file = args.get("TargetFile")
    if not target_file:
        sys.exit(1)
        
    proposed_content = ""
    
    if name == "write_to_file":
        proposed_content = args.get("CodeContent", "")
    elif name == "replace_file_content":
        if not os.path.exists(target_file):
            sys.exit(1)
        with open(target_file, "r", encoding="utf-8") as f:
            content = f.read()
        target_content = args.get("TargetContent", "")
        replacement_content = args.get("ReplacementContent", "")
        if target_content in content:
            proposed_content = content.replace(target_content, replacement_content, 1)
        else:
            proposed_content = content
    elif name == "multi_replace_file_content":
        if not os.path.exists(target_file):
            sys.exit(1)
        with open(target_file, "r", encoding="utf-8") as f:
            content = f.read()
        
        chunks = args.get("ReplacementChunks", [])
        # Apply replacements
        proposed_content = content
        for chunk in chunks:
            target_chunk = chunk.get("TargetContent", "")
            replacement_chunk = chunk.get("ReplacementContent", "")
            if target_chunk in proposed_content:
                proposed_content = proposed_content.replace(target_chunk, replacement_chunk, 1)
    else:
        sys.exit(1)
        
    with open(temp_path, "w", encoding="utf-8") as f:
        f.write(proposed_content)
        
    print(target_file)

if __name__ == "__main__":
    main()
