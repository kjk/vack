#!/usr/bin/python
import sys
import os
import re

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))

exclude_dirs = ["ThirdParty", "build", "English.lproj", "VisualAck.xcodeproj"]
exclude_files = []
include_files = [".*\.h", ".*\.m"]

def valid_file_name(filename):
    for regex in exclude_files:
        if re.match(regex, filename):
            return False
    for regex in include_files:
        if re.match(regex, filename):
            return True
    return False

def path_relative_to_script_dir(path):
    assert path.startswith(SCRIPT_DIR)
    return path[len(SCRIPT_DIR)+1:]

def is_empty_line(l): return 0 == len(l.strip())

def is_python_comment(l):
    if re.match("\s*#", l):
        return True
    return False

def is_c_comment(l):
    if re.match("\s*//", l):
        return True
    return False

class DefaultCommentDetector(object):
    def __int__(self): pass
    def is_comment_line(self, l): return False
    def starts_comment_block(self, l): return False
    def ends_comment_block(self, l): return False

class PythonCommentDetector(DefaultCommentDetector):
    def __init__(self): pass
    def is_comment_line(self, l): return is_python_comment(l)

class CCommentDetector(DefaultCommentDetector):
    def __init__(self): pass
    def is_comment_line(self, l): return is_c_comment(l)

def comment_detector_from_filepath(filepath):
    parts = filepath.split(".")
    if 1 == len(parts):
        return DefaultCommentDetector()
    ext = parts[-1]
    if ext == "py":
        return PythonCommentDetector()
    if ext in ["c", "h", "m", "mm", "cpp", "cc"]:
        return CCommentDetector()
    return DefaultCommentDetector()

def loc_helper(fo, comment_detector):
    lines = 0
    empty = 0
    comment = 0
    in_comment = False
    for l in fo:
        lines += 1
        if is_empty_line(l):
            empty += 1
            continue
        if comment_detector.is_comment_line(l):
            comment += 1
            continue
        if in_comment:
            comment += 1
            if comment_detector.ends_comment_block(l):
                in_comment = False
        else:
            if comment_detector.starts_comment_block(l):
                in_comment = True
    return (lines,empty,comment)

# Return tuple (total number of lines, empty lines, comment lines)
def loc(filepath):
    fo = open(filepath, "r")
    comment_detector = comment_detector_from_filepath(filepath)
    res = loc_helper(fo, comment_detector)
    fo.close()
    return res

def main():
    skipped_dirs = []
    skipped_files = []
    results = []
    for dirname, dirnames, filenames in os.walk(SCRIPT_DIR):
        dirs_to_remove = [d for d in dirnames if d in exclude_dirs]
        for d in dirs_to_remove:
            path = path_relative_to_script_dir(os.path.join(dirname, d))
            skipped_dirs.append(path)
            dirnames.remove(d)
        for filename in filenames:
            path = os.path.join(dirname, filename)
            relative_path = path_relative_to_script_dir(path)
            if valid_file_name(path):
                locs = loc(path)
                print("%s|%d|%d|%d" % (relative_path, locs[0], locs[1], locs[2]))
                results.append((relative_path, locs[0], locs[1], locs[2]))
            else:
                skipped_files.append(relative_path)
    print(skipped_dirs)
    print(skipped_files)
    print(results)

def tests():
    assert comment_detector_from_filepath("foo.py").__class__.__name__ == "PythonCommentDetector"
    assert comment_detector_from_filepath("foo.c").__class__.__name__ == "CCommentDetector"
    assert comment_detector_from_filepath("foo").__class__.__name__ == "DefaultCommentDetector"
    assert comment_detector_from_filepath("foo.o").__class__.__name__ == "DefaultCommentDetector"
    assert is_empty_line("")
    assert is_empty_line("   ")
    assert is_empty_line("  \t   ")
    assert is_python_comment("# this is a comment")
    assert is_python_comment("   # this is also a comment")
    assert not is_python_comment("   print(foo) # this is not a all-comment line")
    assert is_c_comment("// this is a c comment")
    assert is_c_comment("  // this is a c comment too")


if __name__ == "__main__":
    if "-test" in sys.argv:
        tests()
        sys.exit(1)
    main()
