#!/usr/bin/python3

import tempfile
import subprocess
import os


def batch_scan(tmpdirname):
    cmd = [
        'scanimage',
        '--format=png',
        '--batch=' + tmpdirname + '/p%04d.png',
        '-x', '210',
        '-y', '297',
        '--resolution=300',
        '--source=ADF',
        '--device=hpaio:/net/hp_laserjet_pro_mfp_m521dw?ip=192.168.178.42&queue=false',
    ]
    print(str.join(" ", cmd))
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    _, stderr = process.communicate()
    if stderr:
        print(stderr)


def de_skew(file_name):
    cmd = [
        'mogrify',
        file_name,
        '-alpha', 'Off',
        '-deskew', '40%',
        '+repage',
        '-gravity', 'south'
    ]
    print(str.join(" ", cmd))
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    _, stderr = process.communicate()
    if stderr:
        print(stderr)


def merge(tmp_dir_name, file_name):
    cmd = ['convert', os.path.join(tmp_dir_name, '*.png'), file_name]
    print(str.join(" ", cmd))
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    _, stderr = process.communicate()
    if stderr:
        print(stderr)


def main():
    pdf_file_name = "/tmp/scan.pdf"
    with tempfile.TemporaryDirectory() as tmp_dir_name:
        batch_scan(tmp_dir_name)
        _, _, file_names = next(os.walk(tmp_dir_name))
        for file_name in file_names:
            de_skew(os.path.join(tmp_dir_name, file_name))
        merge(tmp_dir_name, pdf_file_name)


main()
