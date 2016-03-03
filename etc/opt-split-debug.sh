#! /bin/bash
# Usage: opt-split-debug.sh <elf-file> <debug-file-dir>

set -eu

source $OPT_ROOT/etc/opt/opt-config.sh

usage() {
    echo "Usage: opt-split-debug.sh <stage-root> <elf-file> <debug-file-stage-root>"
    echo "<elf-file> must be relative to <stage-root>"
}

error() {
    echo "$@" >&2
    exit 1
}

if [ $# -ne 3 ]
then
    usage >&2
    exit 1
fi

declare -r stage_root="$1"
declare -r elf_file="$2"
declare -r debug_file_stage_root="$3"

declare -r full_elf_file="$stage_root/$elf_file"
declare -r full_debug_file="$debug_file_stage_root/${elf_file}.debug"

if [ ! -d "$stage_root" ]
then
    echo "Not a directory: $stage_root" >&2
    exit 1
fi

if [ ! -f "$full_elf_file" ]
then
    echo "Not a file: $full_elf_file" >&2
    exit 1
fi

if [ ! -d "$debug_file_stage_root" ]
then
    echo "Not a directory: $debug_file_stage_root" >&2
    exit 1
fi

case "$(file $full_elf_file)" in
    *ELF*) ;;
    *) error "Not an ELF file: $full_elf_file" ;;
esac

set -x

mkdir -m 0755 -p $(dirname $full_debug_file)

# Some files get installed without user write permissions.
# It doesn't buy us anything so keep it simple.
chmod u+w "$full_elf_file"

${OPT_HOST_SYSTEM}-objcopy --only-keep-debug "$full_elf_file" "$full_debug_file"
${OPT_HOST_SYSTEM}-objcopy --add-gnu-debuglink="$full_debug_file" "$full_elf_file"
