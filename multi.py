import os
import subprocess
import sys
import tempfile
import shutil
import glob
from multiprocessing import Pool


def de_skew(file_name):
    cmd = ['mogrify', file_name, '-alpha', 'Off', '-deskew', '40%', '+repage', '-gravity', 'south']
    print(str.join(" ", cmd))
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    _, stderr = process.communicate()
    return {"file": file_name, "code": process.returncode, "stderr": stderr}


def ocr(file_name):
    file_name_wo_ext = os.path.splitext(file_name)[0]
    cmd = ['tesseract', file_name, file_name_wo_ext, '-l', 'deu', 'pdf']
    print(str.join(" ", cmd))
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    _, stderr = process.communicate()
    return {"file": file_name, "pdf_file": "%s.pdf" % file_name_wo_ext, "code": process.returncode, "stderr": stderr}


def process_page(file_name):
    # result = de_skew(file_name)
    # if result["code"] != 0:
    #     return result
    return ocr(file_name)


def pdf_merge(pdf_files):
    merged_file = tempfile.NamedTemporaryFile(prefix="scanAndOcr-", suffix=".pdf", delete=False)
    merged_file_name = merged_file.name
    merged_file.close()
    cmd = ['gs', '-sDEVICE=pdfwrite', '-dCompatibilityLevel=1.4', #'-dPDFSETTINGS=/ebook',
           '-dNOPAUSE', '-dQUIET', '-dBATCH', '-sOutputFile=%s' % merged_file_name]
    cmd.extend(pdf_files)
    print(str.join(" ", cmd))
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    _, stderr = process.communicate()
    return {"code": process.returncode, "stderr": stderr, "pdf_file": merged_file_name}


def scan(tmp_dir_name):
    for filename in glob.glob(os.path.join("/home/sebastian.bogan/blub/private-repos/ScanningAndOcr/data", '*.*')):
        shutil.copy(filename, tmp_dir_name)

    _, _, file_names = next(os.walk(tmp_dir_name))
    file_paths = map(lambda x: os.path.join(tmp_dir_name, x), file_names)
    return file_paths


def doit():
    tmp_dir_name = tempfile.mkdtemp()
    files = scan(tmp_dir_name)
    with Pool(4) as p:
        processed = p.map(process_page, files)
        errors = list(filter(lambda x: x["code"] != 0, processed))
        if errors:
            for e in errors:
                print("failed to process %s: %s" % (e["file"], e["stderr"]))
            sys.exit(1)
        pdf_files = map(lambda x: x["pdf_file"], processed)
        result = pdf_merge(pdf_files)
        if result["code"] != 0:
            print("failed to merge: %s" % result["stderr"])
            sys.exit(1)
        print(result["pdf_file"])


if __name__ == '__main__':
    doit()
