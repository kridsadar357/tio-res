import zipfile
import os
import datetime

def check_zip(path):
    try:
        with zipfile.ZipFile(path, 'r') as z:
            for info in z.infolist():
                # zipfile.ZipInfo.date_time is a tuple (year, month, day, hour, min, sec)
                # DOS dates start from 1980.
                if info.date_time[0] < 1980 and info.date_time[0] > 0: # 0 is often used for empty? 
                    # If year is 0, python zip structure might report something else, but let's check < 1980.
                    # Some use 1970, which is invalid for DOS.
                    print(f"FOUND INVALID TIMESTAMP: {path} -> {info.filename} : {info.date_time}")
                    return True
                if info.date_time[0] == 0: 
                     # Sometimes 0 means 1970?
                     pass
    except Exception as e:
        # print(f"Error reading {path}: {e}")
        pass
    return False

def scan_dir(root_dir):
    print(f"Scanning {root_dir}...")
    for root, dirs, files in os.walk(root_dir):
        for f in files:
            if f.endswith(".jar") or f.endswith(".aar"):
                path = os.path.join(root, f)
                if check_zip(path):
                    # print(f"Bad Jar: {path}")
                    pass

print("Starting scan...")
# Scan pub cache first as it's smaller and likely location of plugins
home = os.path.expanduser("~")
scan_dir(os.path.join(home, ".pub-cache"))
# scan_dir(os.path.join(home, ".gradle/caches")) # This might be Huge
