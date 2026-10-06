#!/data/data/com.termux/files/usr/bin/bash

INPUT_DIR="/sdcard/Download"
OUTPUT_DIR="/sdcard/Download/Video Ratio"

mkdir -p "$OUTPUT_DIR"

clear

echo "╔════════════════════════════════╗"
echo "║        VIDEO RATIO TOOL        ║"
echo "╚════════════════════════════════╝"
echo

# Kiểm tra FFmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "❌ Chưa cài FFmpeg."
    echo "Hãy chạy: pkg install ffmpeg -y"
    exit 1
fi

# Liệt kê video
echo "📁 Video trong Download:"
echo

files=()

for file in "$INPUT_DIR"/*; do
    if [ -f "$file" ]; then
        case "${file,,}" in
            *.mp4|*.mkv|*.mov|*.avi|*.webm|*.m4v)
                files+=("$file")
                ;;
        esac
    fi
done

if [ ${#files[@]} -eq 0 ]; then
    echo "❌ Không tìm thấy video trong Download."
    exit 1
fi

for i in "${!files[@]}"; do
    echo "$((i+1)). $(basename "${files[$i]}")"
done

echo
read -p "👉 Chọn video: " choice

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#files[@]} ]; then
    echo "❌ Lựa chọn không hợp lệ."
    exit 1
fi

INPUT="${files[$((choice-1))]}"
BASENAME=$(basename "$INPUT")
NAME="${BASENAME%.*}"

echo
echo "════════════════════════════════"
echo "Chọn tỷ lệ video"
echo "════════════════════════════════"
echo
echo "1. 16:9"
echo "2. 9:16"
echo "3. 4:3"
echo "4. 3:4"
echo "5. 1:1"
echo "6. 2:3"
echo "7. 3:2"
echo "8. 5:7"
echo "9. 7:5"
echo "10. Tự nhập"
echo

read -p "👉 Lựa chọn: " ratio_choice

case "$ratio_choice" in
    1) RATIO="16:9" ;;
    2) RATIO="9:16" ;;
    3) RATIO="4:3" ;;
    4) RATIO="3:4" ;;
    5) RATIO="1:1" ;;
    6) RATIO="2:3" ;;
    7) RATIO="3:2" ;;
    8) RATIO="5:7" ;;
    9) RATIO="7:5" ;;
    10)
        echo
        read -p "👉 Nhập tỷ lệ, ví dụ 2:3: " RATIO
        ;;
    *)
        echo "❌ Lựa chọn không hợp lệ."
        exit 1
        ;;
esac

# Kiểm tra tỷ lệ
if ! [[ "$RATIO" =~ ^[0-9]+:[0-9]+$ ]]; then
    echo "❌ Tỷ lệ không hợp lệ."
    exit 1
fi

W_RATIO="${RATIO%%:*}"
H_RATIO="${RATIO##*:}"

if [ "$W_RATIO" -eq 0 ] || [ "$H_RATIO" -eq 0 ]; then
    echo "❌ Tỷ lệ không hợp lệ."
    exit 1
fi

echo
echo "════════════════════════════════"
echo "⚙️ Chế độ xử lý"
echo "════════════════════════════════"
echo
echo "Video sẽ được giữ nguyên toàn bộ."
echo "Phần thừa sẽ được thêm nền đen."
echo
echo "Không crop."
echo "Không kéo giãn."
echo

# Lấy kích thước video
WIDTH=$(ffprobe -v error \
    -select_streams v:0 \
    -show_entries stream=width \
    -of csv=p=0 "$INPUT")

HEIGHT=$(ffprobe -v error \
    -select_streams v:0 \
    -show_entries stream=height \
    -of csv=p=0 "$INPUT")

if [ -z "$WIDTH" ] || [ -z "$HEIGHT" ]; then
    echo "❌ Không đọc được kích thước video."
    exit 1
fi

echo "📐 Video gốc: ${WIDTH}x${HEIGHT}"
echo "🎞️ Tỷ lệ mới: $RATIO"
echo

# Tính canvas mới.
# Giữ video lớn nhất có thể nhưng không crop.
TARGET_W="$WIDTH"
TARGET_H="$HEIGHT"

# So sánh WIDTH/HEIGHT với W_RATIO/H_RATIO
# Dùng số nguyên để tránh cần bc.

LEFT=$((WIDTH * H_RATIO))
RIGHT=$((HEIGHT * W_RATIO))

if [ "$LEFT" -gt "$RIGHT" ]; then
    # Video rộng hơn tỷ lệ đích
    # Giữ chiều rộng, tăng chiều cao
    TARGET_H=$((WIDTH * H_RATIO / W_RATIO))
else
    # Video cao hơn tỷ lệ đích
    # Giữ chiều cao, tăng chiều rộng
    TARGET_W=$((HEIGHT * W_RATIO / H_RATIO))
fi

# Đảm bảo kích thước là số chẵn
TARGET_W=$((TARGET_W / 2 * 2))
TARGET_H=$((TARGET_H / 2 * 2))

echo "🖼️ Canvas mới: ${TARGET_W}x${TARGET_H}"
echo

OUTPUT="$OUTPUT_DIR/${NAME}_${W_RATIO}x${H_RATIO}.mp4"

echo "🚀 Đang xử lý..."
echo
echo "📂 File xuất:"
echo "$OUTPUT"
echo

ffmpeg \
-hide_banner \
-i "$INPUT" \
-map 0:v:0 \
-map 0:a? \
-vf "scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=decrease,pad=${TARGET_W}:${TARGET_H}:(ow-iw)/2:(oh-ih)/2:black" \
-c:v libx264 \
-preset veryfast \
-crf 23 \
-pix_fmt yuv420p \
-c:a aac \
-b:a 128k \
-movflags +faststart \
-progress pipe:1 \
-n "$OUTPUT" 2>/dev/null |
while IFS='=' read -r key value; do
    if [ "$key" = "out_time_ms" ]; then
        printf "\r⏳ Đang xuất: %s giây" "$((value / 1000000))"
    fi

    if [ "$key" = "progress" ] && [ "$value" = "end" ]; then
        echo
    fi
done

if [ $? -eq 0 ] && [ -f "$OUTPUT" ]; then
    echo
    echo "╔════════════════════════════════╗"
    echo "║        ✅ HOÀN THÀNH          ║"
    echo "╚════════════════════════════════╝"
    echo
    echo "📁 File nằm tại:"
    echo "$OUTPUT"
    echo
else
    echo
    echo "❌ Có lỗi khi xuất video."
    exit 1
fi
