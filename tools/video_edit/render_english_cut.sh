#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/../.." && pwd)"
build_dir="$repo_dir/build/nikoneko_video"
clips_dir="$build_dir/clips"
captions_dir="$build_dir/captions"
python_bin="/Users/yvonne_f_fan/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"

source_a="/Users/yvonne_f_fan/Downloads/ScreenRecording_08-23-2026 16-04-43_1.MP4"
source_b="/Users/yvonne_f_fan/Downloads/ScreenRecording_08-23-2026 16-07-39_1.MP4"
source_d="/Users/yvonne_f_fan/Downloads/ScreenRecording_08-23-2026 16-09-19_1.MP4"

mkdir -p "$clips_dir" "$captions_dir"
"$python_bin" "$repo_dir/tools/video_edit/make_caption_cards.py"

render_clip() {
  local name="$1"
  local source="$2"
  local start="$3"
  local duration="$4"
  local speed="$5"
  local framing="$6"
  local caption="$7"
  local video_filter

  case "$framing" in
    phone)
      video_filter="[0:v]fps=30,split=2[bg][fg];[bg]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=30:5[blur];[fg]scale=-2:1840[phone];[blur][phone]overlay=(W-w)/2:(H-h)/2,setsar=1,setpts=PTS/${speed}[base]"
      ;;
    fill)
      video_filter="[0:v]fps=30,crop=1180:2098:0:210,scale=1080:1920,setsar=1,setpts=PTS/${speed}[base]"
      ;;
    detail)
      video_filter="[0:v]fps=30,crop=900:1600:140:470,scale=1080:1920,setsar=1,setpts=PTS/${speed}[base]"
      ;;
    character)
      video_filter="[0:v]fps=30,crop=620:1102:280:80,scale=1080:1920,setsar=1,setpts=PTS/${speed}[base]"
      ;;
    endcard)
      video_filter="[0:v]fps=30,crop=1180:2098:0:210,scale=1080:1920,setsar=1,trim=duration=0.1,tpad=stop_mode=clone:stop_duration=2.9[base]"
      ;;
    *)
      echo "Unknown framing: $framing" >&2
      exit 1
      ;;
  esac

  ffmpeg -y -v error -ss "$start" -t "$duration" -i "$source" \
    -loop 1 -framerate 30 -i "$captions_dir/$caption.png" \
    -filter_complex "$video_filter;[base][1:v]overlay=0:0:format=auto:shortest=1[v]" \
    -map "[v]" -an -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p \
    -movflags +faststart -shortest "$clips_dir/$name.mp4"
}

# Hook: product, character, report, and theme in three seconds.
render_clip 001 "$source_a" 31.5 1.0 1 phone hook
render_clip 002 "$source_d" 120.0 0.55 1 character hook
render_clip 003 "$source_d" 164.0 0.55 1 character hook
render_clip 004 "$source_a" 105.0 0.55 1 fill hook
render_clip 005 "$source_a" 137.0 0.55 1 fill hook

# Onboarding and pace setup.
render_clip 006 "$source_a" 0.0 1.2 1 phone onboarding
render_clip 007 "$source_a" 3.5 1.3 1 phone onboarding
render_clip 008 "$source_a" 7.5 1.3 1 phone onboarding
render_clip 009 "$source_a" 11.5 1.3 1 phone onboarding
render_clip 010 "$source_a" 16.0 5.5 1.6 detail pace
render_clip 011 "$source_a" 23.5 6.0 2.2 fill ready

# Live running data, with a closer crop for the changing metrics.
render_clip 012 "$source_a" 31.0 5.0 1.6 fill run
render_clip 013 "$source_a" 45.0 1.6 1 fill run
render_clip 014 "$source_a" 69.0 1.6 1 fill run
render_clip 015 "$source_a" 93.0 1.6 1 fill run
render_clip 016 "$source_a" 101.0 1.6 1 fill run

# Display and training controls.
render_clip 017 "$source_b" 14.0 4.0 1.4 detail settings
render_clip 018 "$source_b" 22.0 4.0 1.4 phone settings
render_clip 019 "$source_b" 28.0 6.5 1.8 detail settings

# Character montage: 18 quick, readable animation beats.
render_clip 020 "$source_d" 0.5 0.50 1 character characters
render_clip 021 "$source_d" 8.5 0.50 1 character characters
render_clip 022 "$source_d" 16.5 0.50 1 character characters
render_clip 023 "$source_d" 24.5 0.50 1 character characters
render_clip 024 "$source_d" 32.5 0.50 1 character characters
render_clip 025 "$source_d" 44.5 0.50 1 character characters
render_clip 026 "$source_d" 52.5 0.50 1 character characters
render_clip 027 "$source_d" 60.5 0.50 1 character characters
render_clip 028 "$source_d" 68.5 0.50 1 character characters
render_clip 029 "$source_d" 80.5 0.50 1 character characters
render_clip 030 "$source_d" 100.5 0.50 1 character characters
render_clip 031 "$source_d" 112.5 0.50 1 character characters
render_clip 032 "$source_d" 120.5 0.50 1 character characters
render_clip 033 "$source_d" 132.5 0.50 1 character characters
render_clip 034 "$source_d" 140.5 0.50 1 character characters
render_clip 035 "$source_d" 152.5 0.50 1 character characters
render_clip 036 "$source_d" 164.5 0.50 1 character characters
render_clip 037 "$source_d" 176.5 0.50 1 character characters

# Report, themes, and final lock-up.
render_clip 038 "$source_a" 104.0 4.0 1.25 fill report
render_clip 039 "$source_a" 108.0 13.0 3.2 detail report
render_clip 040 "$source_a" 132.0 18.0 4.0 fill theme
render_clip 041 "$source_a" 2.2 0.2 1 endcard end

concat_file="$build_dir/concat.txt"
: > "$concat_file"
for clip in "$clips_dir"/*.mp4; do
  printf "file '%s'\n" "$clip" >> "$concat_file"
done

silent_video="$build_dir/nikoneko_run_english_cut_silent.mp4"
final_video="$repo_dir/nikoneko_run_english_cut_v1.mp4"

ffmpeg -y -v error -f concat -safe 0 -i "$concat_file" -c copy "$silent_video"
ffmpeg -y -v error -i "$silent_video" -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 \
  -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart "$final_video"

printf '%s\n' "$final_video"
