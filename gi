#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
#          VIDEO RATIO TOOL
#     Không crop - Không upscale
#     Thêm nền đen - Giữ chất lượng cao
# ==========================================

INPUT_DIR="/sdcard/Download"
OUTPUT_DIR="/sdcard/Download/Video Ratio"

mkdir -p "$OUTPUT_DIR"

clear

echo "╔════════════════════════════════════╗"
echo "║         VIDEO RATIO TOOL           ║"
echo "╠════════════════════════════════════╣"
echo "║  Không crop                        ║"
echo "║  Không upscale                     ║"
echo "║  Không kéo giãn                    ║"
echo "║  Thêm nền đen                      ║"
echo "╚════════════════════════════════════╝"
echo

# ==========================================
# Kiểm tra FFmpeg
# ==========================================

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "❌ Chưa cài FFmpeg."
    echo
    echo "Chạy:"
    echo "pkg install ffmpeg -y"
    exit 1
fi

if ! command -v ffprobe >/dev/null 2>&1; then
    echo "❌ Không tìm thấy ffprobe."
    exit 1
fi

# ==========================================
# Tìm video
# ==========================================

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
    echo "❌ Không tìm thấy video trong:"
    echo "$INPUT_DIR"
    exit 1
fi

echo "📁 VIDEO TRONG DOWNLOAD"
echo "────────────────────────────────────"
echo

for i in "${!files[@]}"; do
    echo "$((i+1)). $(basename "${files[$i]}")"
done

echo
echo "────────────────────────────────────"

read -p "👉 Chọn video: " CHOICE

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
    echo "❌ Vui lòng nhập số."
    exit 1
fi

if [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#files[@]}" ]; then
    echo "❌ Lựa chọn không hợp lệ."
    exit 1
fi

INPUT="${files[$((CHOICE-1))]}"

BASENAME=$(basename "$INPUT")
NAME="${BASENAME%.*}"

echo
echo "🎬 Video:"
echo "$BASENAME"

# ==========================================
# Chọn tỷ lệ
# ==========================================

echo
echo "════════════════════════════════════"
echo "           CHỌN TỶ LỆ"
echo "════════════════════════════════════"
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

read -p "👉 Lựa chọn: " RATIO_CHOICE

case "$RATIO_CHOICE" in

    1)
        RATIO_W=16
        RATIO_H=9
        RATIO_NAME="16x9"
        ;;

    2)
        RATIO_W=9
        RATIO_H=16
        RATIO_NAME="9x16"
        ;;

    3)
        RATIO_W=4
        RATIO_H=3
        RATIO_NAME="4x3"
        ;;

    4)
        RATIO_W=3
        RATIO_H=4
        RATIO_NAME="3x4"
        ;;

    5)
        RATIO_W=1
        RATIO_H=1
        RATIO_NAME="1x1"
        ;;

    6)
        RATIO_W=2
        RATIO_H=3
        RATIO_NAME="2x3"
        ;;

    7)
        RATIO_W=3
        RATIO_H=2
        RATIO_NAME="3x2"
        ;;

    8)
        RATIO_W=5
        RATIO_H=7
        RATIO_NAME="5x7"
        ;;

    9)
        RATIO_W=7
        RATIO_H=5
        RATIO_NAME="7x5"
        ;;

    10)

        echo
        read -p "👉 Nhập tỷ lệ (ví dụ 2:3): " CUSTOM_RATIO

        if [[ ! "$CUSTOM_RATIO" =~ ^[0-9]+:[0-9]+$ ]]; then
            echo "❌ Tỷ lệ không hợp lệ."
            echo "Ví dụ đúng: 2:3"
            exit 1
        fi

        RATIO_W="${CUSTOM_RATIO%%:*}"
        RATIO_H="${CUSTOM_RATIO##*:}"

        RATIO_NAME="${RATIO_W}x${RATIO_H}"

        ;;

    *)

        echo "❌ Lựa chọn không hợp lệ."
        exit 1
        ;;

esac

# ==========================================
# Kiểm tra tỷ lệ
# ==========================================

if [ "$RATIO_W" -le 0 ] || [ "$RATIO_H" -le 0 ]; then
    echo "❌ Tỷ lệ không hợp lệ."
    exit 1
fi

# ==========================================
# Lấy kích thước video gốc
# ==========================================

WIDTH=$(ffprobe \
    -v error \
    -select_streams v:0 \
    -show_entries stream=width \
    -of default=noprint_wrappers=1:nokey=1 \
    "$INPUT")

HEIGHT=$(ffprobe \
    -v error \
    -select_streams v:0 \
    -show_entries stream=height \
    -of default=noprint_wrappers=1:nokey=1 \
    "$INPUT")

if ! [[ "$WIDTH" =~ ^[0-9]+$ ]] || ! [[ "$HEIGHT" =~ ^[0-9]+$ ]]; then
    echo "❌ Không đọc được kích thước video."
    exit 1
fi

if [ "$WIDTH" -le 0 ] || [ "$HEIGHT" -le 0 ]; then
    echo "❌ Kích thước video không hợp lệ."
    exit 1
fi

# ==========================================
# Tính canvas mới
#
# QUAN TRỌNG:
# Không thay đổi kích thước video gốc.
# Chỉ mở rộng canvas và thêm nền đen.
# ==========================================

LEFT=$((WIDTH * RATIO_H))
RIGHT=$((HEIGHT * RATIO_W))

if [ "$LEFT" -gt "$RIGHT" ]; then

    # Video rộng hơn tỷ lệ cần tạo
    # GIỮ NGUYÊN WIDTH
    # Tăng HEIGHT bằng nền đen

    TARGET_W="$WIDTH"

    TARGET_H=$((WIDTH * RATIO_H / RATIO_W))

else

    # Video cao hơn tỷ lệ cần tạo
    # GIỮ NGUYÊN HEIGHT
    # Tăng WIDTH bằng nền đen

    TARGET_H="$HEIGHT"

    TARGET_W=$((HEIGHT * RATIO_W / RATIO_H))

fi

# ==========================================
# Đảm bảo canvas là số chẵn
# ==========================================

if [ $((TARGET_W % 2)) -ne 0 ]; then
    TARGET_W=$((TARGET_W + 1))
fi

if [ $((TARGET_H % 2)) -ne 0 ]; then
    TARGET_H=$((TARGET_H + 1))
fi

# ==========================================
# Thông tin
# ==========================================

echo
echo "════════════════════════════════════"
echo "             THÔNG TIN"
echo "════════════════════════════════════"
echo

echo "📐 Video gốc:"
echo "   ${WIDTH}x${HEIGHT}"

echo
echo "🎞️ Tỷ lệ mới:"
echo "   ${RATIO_W}:${RATIO_H}"

echo
echo "🖼️ Canvas:"
echo "   ${TARGET_W}x${TARGET_H}"

echo
echo "🔒 Video gốc:"
echo "   GIỮ NGUYÊN KÍCH THƯỚC"

echo
echo "✂️ Crop:"
echo "   KHÔNG"

echo
echo "🔍 Upscale:"
echo "   KHÔNG"

echo
echo "⬛ Phần thừa:"
echo "   NỀN ĐEN"

echo

# ==========================================
# File output
# ==========================================

OUTPUT="$OUTPUT_DIR/${NAME}_${RATIO_NAME}.mp4"

echo "📂 File xuất:"
echo "$OUTPUT"

echo
echo "════════════════════════════════════"
echo "🚀 BẮT ĐẦU XỬ LÝ"
echo "════════════════════════════════════"
echo

# ==========================================
# FFmpeg
#
# pad:
# - Không resize video
# - Không crop
# - Không stretch
# - Chỉ thêm canvas màu đen
#
# CRF 18:
# Chất lượng rất cao
#
# veryfast:
# Ưu tiên tốc độ
# ==========================================

ffmpeg \
    -hide_banner \
    -i "$INPUT" \
    -map 0:v:0 \
    -map 0:a? \
    -vf "pad=${TARGET_W}:${TARGET_H}:(ow-iw)/2:(oh-ih)/2:black" \
    -c:v libx264 \
    -preset veryfast \
    -crf 18 \
    -pix_fmt yuv420p \
    -c:a aac \
    -b:a 192k \
    -movflags +faststart \
    -y \
    "$OUTPUT"

FFMPEG_STATUS=$?

echo

# ==========================================
# Kiểm tra kết quả
# ==========================================

if [ "$FFMPEG_STATUS" -eq 0 ] && [ -f "$OUTPUT" ]; then

    echo "╔════════════════════════════════════╗"
    echo "║          ✅ HOÀN THÀNH            ║"
    echo "╚════════════════════════════════════╝"
    echo

    echo "📁 File:"
    echo "$OUTPUT"

    echo
    echo "📐 Kích thước canvas:"
    echo "${TARGET_W}x${TARGET_H}"

    echo
    echo "🎞️ Tỷ lệ:"
    echo "${RATIO_W}:${RATIO_H}"

    echo
    echo "⬛ Video gốc không bị crop."
    echo "⬛ Không upscale video."

else

    echo "╔════════════════════════════════════╗"
    echo "║            ❌ THẤT BẠI            ║"
    echo "╚════════════════════════════════════╝"
    echo

    echo "FFmpeg đã trả về lỗi."
    echo "Mã lỗi: $FFMPEG_STATUS"

    exit 1

fi

echo
echo "📂 Thư mục:"
echo "/sdcard/Download/Video Ratio"
echo
