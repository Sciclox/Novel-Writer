import subprocess
import re
import os

def run_analyze():
    print("Running flutter analyze...")
    result = subprocess.run(
        ["flutter", "analyze"],
        cwd=r"c:\Users\Lenovo\OneDrive\Documentos\Proyectos\Novel-Writer",
        capture_output=True,
        text=True,
        encoding="utf-8",
        shell=True
    )
    return result.stdout + "\n" + result.stderr

def main():
    workspace = r"c:\Users\Lenovo\OneDrive\Documentos\Proyectos\Novel-Writer"
    
    # Loop to run analyze and fix const / getter issues
    for iteration in range(5):
        output = run_analyze()
        lines = output.splitlines()
        
        fixes_count = 0
        
        for line in lines:
            # Match analyze errors:
            # error - Invalid constant value - lib\screens\exporter_view.dart:212:64 - invalid_constant
            match_const = re.search(r"error - (Invalid constant value|Const variables must be|Arguments of a constant|Arguments of a const|Methods can't be invoked).* - ([^\s]+):(\d+):\d+", line)
            if match_const:
                file_rel = match_const.group(2)
                line_num = int(match_const.group(3))
                filepath = os.path.join(workspace, file_rel)
                
                if os.path.exists(filepath):
                    with open(filepath, "r", encoding="utf-8") as f:
                        file_lines = f.readlines()
                    idx = line_num - 1
                    if 0 <= idx < len(file_lines):
                        # Search upwards up to 5 lines to find "const"
                        found = False
                        for search_idx in range(idx, max(-1, idx - 5), -1):
                            orig = file_lines[search_idx]
                            if "const " in orig:
                                fixed = orig.replace("const ", "")
                                file_lines[search_idx] = fixed
                                with open(filepath, "w", encoding="utf-8") as f:
                                    f.writelines(file_lines)
                                print(f"Fixed const on {file_rel}:{search_idx + 1}")
                                fixes_count += 1
                                found = True
                                break
                        if not found:
                            # Let's try to remove "const" from the line itself if it has const (e.g. const Divider)
                            orig = file_lines[idx]
                            fixed = orig.replace("const ", "")
                            if fixed != orig:
                                file_lines[idx] = fixed
                                with open(filepath, "w", encoding="utf-8") as f:
                                    f.writelines(file_lines)
                                print(f"Fixed const on {file_rel}:{line_num} directly")
                                fixes_count += 1
            
            # Match undefined getters like textPrimary12, textPrimary38
            match_getter = re.search(r"The getter 'textPrimary(\d+)' isn't defined.* - ([^\s]+):(\d+):\d+", line)
            if match_getter:
                digits = match_getter.group(1)
                file_rel = match_getter.group(2)
                line_num = int(match_getter.group(3))
                filepath = os.path.join(workspace, file_rel)
                
                if os.path.exists(filepath):
                    with open(filepath, "r", encoding="utf-8") as f:
                        file_lines = f.readlines()
                    idx = line_num - 1
                    if 0 <= idx < len(file_lines):
                        orig = file_lines[idx]
                        fixed = orig.replace(f"AppColors.textPrimary{digits}", f"AppColors.textPrimary.withValues(alpha: 0.{digits})")
                        if fixed != orig:
                            file_lines[idx] = fixed
                            with open(filepath, "w", encoding="utf-8") as f:
                                f.writelines(file_lines)
                            print(f"Fixed undefined getter textPrimary{digits} on {file_rel}:{line_num}")
                            fixes_count += 1
                            
        if fixes_count == 0:
            print("No more automatically fixable errors found.")
            break
        else:
            print(f"Iteration {iteration+1}: applied {fixes_count} fixes.")
            
    print("Fix script completed.")

if __name__ == "__main__":
    main()
