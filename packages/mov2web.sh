usage() {
    cat <<EOF
Usage: $(basename "$0") [-o output] [-c crf] [-r fps] [-w max_width] [-q] [-h] input

Convert MOV screen recordings to web-optimized MP4.

Options:
  -o output      Output file path (default: input with .mp4 extension)
  -c crf         Quality level, 0-51 (default: 23, lower = better quality)
  -r fps         Max framerate (default: source framerate)
  -w max_width   Max width in pixels (default: source width)
  -q             Quiet mode, suppress ffmpeg output
  -h             Show this help message

Examples:
  $(basename "$0") recording.mov
  $(basename "$0") -o demo.mp4 recording.mov
  $(basename "$0") -c 28 -r 30 -w 1920 recording.mov
EOF
    exit "${1:-0}"
}

# Defaults
output=""
crf=23
fps=""
max_width=""
quiet=0

while getopts ":o:c:r:w:qh" opt; do
    case $opt in
        o) output="$OPTARG" ;;
        c) crf="$OPTARG" ;;
        r) fps="$OPTARG" ;;
        w) max_width="$OPTARG" ;;
        q) quiet=1 ;;
        h) usage 0 ;;
        :) echo "Error: -$OPTARG requires an argument" >&2; usage 1 ;;
        *) echo "Error: unknown option -$OPTARG" >&2; usage 1 ;;
    esac
done
shift $((OPTIND - 1))

if [[ $# -lt 1 ]]; then
    echo "Error: no input file specified" >&2
    usage 1
fi

input="$1"

if [[ ! -f "$input" ]]; then
    echo "Error: input file '$input' not found" >&2
    exit 1
fi

if [[ -z "$output" ]]; then
    output="${input%.*}.mp4"
fi

# Build video filter chain
vf="scale=trunc(iw/2)*2:trunc(ih/2)*2"
if [[ -n "$max_width" ]]; then
    vf="scale='min(${max_width},iw)':-2"
fi

# Build ffmpeg args
args=(
    -i "$input"
    -c:v libx264
    -preset slow
    -crf "$crf"
    -fps_mode cfr
    -video_track_timescale 90000
    -c:a aac
    -b:a 128k
    -movflags +faststart
    -vf "$vf"
    -pix_fmt yuv420p
)

if [[ -n "$fps" ]]; then
    args+=(-r "$fps")
fi

if [[ $quiet -eq 1 ]]; then
    args+=(-loglevel error)
fi

args+=(-y "$output")

echo "Converting: $input -> $output"
ffmpeg "${args[@]}"
echo "Done: $output ($(du -h "$output" | cut -f1))"
