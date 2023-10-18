#!/usr/bin/env python3
#
# Copyright (c) 2023 Microsoft Corporation
# Licensed under the MIT License

import os
import sys
import multiprocessing as mp
import subprocess
from argparse import ArgumentParser, Namespace
from typing import Dict, List


kernel_path = ''
builtin_list = ''
nworkers = 1

def parse_arguments(cli_args: List[str] = None) -> Namespace:
    parser = ArgumentParser(description='Get minimal kernel configuration expressions for each object file')
    parser.add_argument('-k', '--kernel-path', action='store', required=True,
                        help='kernel source path')
    parser.add_argument('-b', '--builtin-list', action='store', required=True,
                        help='builtin object list')
    parser.add_argument('-n', '--num-workers', action='store',
                        help='the number of worker threads')
    return parser.parse_args(args=cli_args)

def load_configs(args: Namespace) -> Dict:
    try:
        global kernel_path
        kernel_path=os.path.realpath(args.kernel_path)
        if not os.path.exists(kernel_path):
            print(kernel_path, "does not exist", file=sys.stderr)
            return False

        global builtin_list
        builtin_list = os.path.realpath(args.builtin_list)
        if not os.path.exists(builtin_list):
            print(builtin_list, "does not exist", file=sys.stderr)
            return False

        global nworkers
        if args.num_workers != None:
            nworkers = int(args.num_workers)

    except Exception as err:
        print(err)
        if err == "Really Bad":
            raise err

    return True

def extract_bc_cmd(ko):
    os.system('extract-bc {0} -o {0}.hacksaw.bc'.format(ko))

def main(args: Namespace = parse_arguments()) -> int:
    try:
        if not load_configs(args):
            return 1

        p = subprocess.run(['find', kernel_path, '-name', '*.ko'], capture_output=True, text=True)
        kos = p.stdout.split()

        objs = []
        with open(builtin_list) as file:
            for line in file:
                objs.append(line.rstrip())

        pool = mp.Pool(nworkers)
        pool.map(extract_bc_cmd, kos + objs)
        pool.close()
        pool.join()

    except KeyboardInterrupt:
        print("Keyboard interrupt", file=sys.stderr)
        return 1

    except Exception as err:
        print("Exception:", err, file=sys.stderr)
        return 1

    return 0

if __name__ == '__main__':
    sys.exit(main(parse_arguments()))
