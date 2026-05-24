# project/guild-master/tools/audit_wiki_pivot.py
import os
import sys

TARGET_DIR = "wiki/"
ILLEGAL_METRICS = ["player.sanity", "player.san", "time_units"]

def audit():
    errors = 0
    print("----- STARTING WIKI PIVOT COMPLIANCE AUDIT -----")
    for root, dirs, files in os.walk(TARGET_DIR):
        for file in files:
            if file.endswith(".md"):
                path = os.path.join(root, file)
                # Normalize path separators for consistent output
                path = path.replace("\\", "/")
                with open(path, "r", encoding="utf-8") as f:
                    content = f.read()
                
                # Skip officially archived files
                if "[ARCHIVED/LEGACY]" in content or "아카이빙된 레거시" in content:
                    continue
                
                for metric in ILLEGAL_METRICS:
                    if metric in content:
                        # Split into lines and check for active violations
                        lines = content.splitlines()
                        for i, line in enumerate(lines):
                            if metric in line:
                                # Ignore if marked as legacy, archive, or deprecated
                                lower_line = line.lower()
                                if any(x in lower_line for x in ["레거시", "legacy", "폐기", "아카이브", "동결", "archived", "착수", "이력", "history", "log"]):
                                    continue
                                print(f"ERROR: Legacy metric '{metric}' found in active line {i+1} of file: {path}")
                                print(f"  Line: {line.strip()}")
                                errors += 1
                        
    if errors > 0:
        print(f"\nAUDIT FAILED: Found {errors} occurrences of legacy metrics in active wiki files!")
        sys.exit(1)
    else:
        print("\nAUDIT SUCCESS: All active wiki files are perfectly sanitized and pivoted!")
        sys.exit(0)

if __name__ == "__main__":
    audit()
