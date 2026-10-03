#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
#       FAST VIDEO CUTTER - TERMUX
#       KHÔNG ENCODE - CẮT SIÊU NHANH
# ==========================================

clear

# Kiểm tra FFmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "❌ Chưa tìm thấy FFmpeg."
    echo
    echo "Cài FFmpeg bằng:"
    echo
    echo "pkg install ffmpeg -y"
    echo
    exit 1
fi

# Kiểm tra bộ nhớ
if [ ! -d "$HOME/storage/shared" ]; then
    echo "📱 Termux chưa được cấp quyền bộ nhớ."
    echo
    echo "Chạy:"
    echo "termux-setup-storage"
    echo
    read -r -p "Nhấn Enter sau khi cấp quyền..."
fi

# Thư mục Download
DOWNLOAD_DIR="$HOME/storage/downloads"

if [ ! -d "$DOWNLOAD_DIR" ]; then
    echo "❌ Không tìm thấy thư mục Download."
    echo
    echo "Hãy chạy:"
    echo "termux-setup-storage"
    exit 1
fi

# Thư mục chứa video đã cắt
OUTPUT_DIR="$DOWNLOAD_DIR/video cut"

# Tự tạo thư mục
mkdir -p "$OUTPUT_DIR"

# Đi vào Download
cd "$DOWNLOAD_DIR" || exit 1

# Tìm video trực tiếp trong Download
mapfile -d '' VIDEOS < <(
    find . -maxdepth 1 -type f \
    \( \
        -iname "*.mp4" \
        -o -iname "*.mkv" \
        -o -iname "*.mov" \
        -o -iname "*.webm" \
        -o -iname "*.avi" \
        -o -iname "*.m4v" \
        -o -iname "*.flv" \
    \) \
    -print0 | sort -z
)

if [ "${#VIDEOS[@]}" -eq 0 ]; then
    clear
    echo "=========================================="
    echo "       🎬 FAST VIDEO CUTTER"
    echo "=========================================="
    echo
    echo "❌ Không tìm thấy video trong Download."
    echo
    exit 1
fi


# ==========================================
# CHUYỂN THỜI GIAN → GIÂY
# Đã sửa lỗi 08, 09 bị Bash hiểu là OCTAL
# ==========================================

time_to_seconds() {

    local TIME="$1"

    # HH:MM:SS
    if [[ "$TIME" =~ ^([0-9]+):([0-9]{2}):([0-9]{2})$ ]]; then

        local H="${BASH_REMATCH[1]}"
        local M="${BASH_REMATCH[2]}"
        local S="${BASH_REMATCH[3]}"

        echo $((10#$H * 3600 + 10#$M * 60 + 10#$S))

        return
    fi

    # MM:SS
    if [[ "$TIME" =~ ^([0-9]+):([0-9]{2})$ ]]; then

        local M="${BASH_REMATCH[1]}"
        local S="${BASH_REMATCH[2]}"

        echo $((10#$M * 60 + 10#$S))

        return
    fi

    # Chỉ nhập số giây
    if [[ "$TIME" =~ ^[0-9]+$ ]]; then

        echo $((10#$TIME))

        return
    fi

    echo "-1"
}


# ==========================================
# GIÂY → HH:MM:SS
# ==========================================

seconds_to_time() {

    local TOTAL="$1"

    local H=$((TOTAL / 3600))
    local M=$(((TOTAL % 3600) / 60))
    local S=$((TOTAL % 60))

    printf "%02d:%02d:%02d" "$H" "$M" "$S"
}


# ==========================================
# MENU
# ==========================================

while true
do

    clear

    echo "=========================================="
    echo "       🎬 FAST VIDEO CUTTER"
    echo "=========================================="
    echo
    echo "⚡ KHÔNG ENCODE"
    echo "⚡ CẮT RẤT NHANH"
    echo
    echo "📁 Video:"
    echo "$DOWNLOAD_DIR"
    echo
    echo "💾 File cắt:"
    echo "$OUTPUT_DIR"
    echo
    echo "🎞 DANH SÁCH VIDEO"
    echo "------------------------------------------"

    for i in "${!VIDEOS[@]}"
    do

        filename="${VIDEOS[$i]#./}"

        printf "  %2d. %s\n" \
            "$((i+1))" \
            "$filename"

    done

    echo "------------------------------------------"
    echo "   0. Thoát"
    echo

    read -r -p "👉 Chọn video: " CHOICE

    # Thoát
    if [[ "$CHOICE" == "0" ]]; then
        echo
        echo "👋 Đã thoát."
        exit 0
    fi

    # Kiểm tra lựa chọn
    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#VIDEOS[@]}" ]
    then

        echo
        echo "❌ Lựa chọn không hợp lệ."
        sleep 2
        continue
    fi

    # Video được chọn
    INPUT="${VIDEOS[$((CHOICE-1))]}"

    BASENAME="$(basename "$INPUT")"
    NAME="${BASENAME%.*}"
    EXT="${BASENAME##*.}"

    clear

    echo "=========================================="
    echo "          ⚡ CẮT SIÊU NHANH"
    echo "=========================================="
    echo
    echo "🎞 Video:"
    echo "$BASENAME"
    echo
    echo "⚠️ Không encode."
    echo "⚠️ Có thể lệch vài giây do keyframe."
    echo
    echo "Ví dụ:"
    echo "05:00"
    echo "08:30"
    echo

    # Nhập thời gian
    read -r -p "▶️  Thời gian bắt đầu: " START

    read -r -p "⏹ Thời gian kết thúc:  " END

    # Chuyển sang giây
    START_SEC=$(time_to_seconds "$START")
    END_SEC=$(time_to_seconds "$END")

    # Kiểm tra
    if [ "$START_SEC" -lt 0 ] ||
       [ "$END_SEC" -lt 0 ]
    then

        echo
        echo "❌ Định dạng thời gian không hợp lệ."
        sleep 3
        continue
    fi

    # Kiểm tra thứ tự
    if [ "$END_SEC" -le "$START_SEC" ]; then

        echo
        echo "❌ Thời gian kết thúc phải lớn hơn thời gian bắt đầu."
        sleep 3
        continue
    fi

    # Tính thời lượng
    DURATION_SEC=$((END_SEC - START_SEC))

    DURATION=$(seconds_to_time "$DURATION_SEC")

    # Tên file
    START_SAFE="${START//:/-}"
    END_SAFE="${END//:/-}"

    OUTPUT="$OUTPUT_DIR/${NAME}_cut_${START_SAFE}_to_${END_SAFE}.${EXT}"

    # Nếu file đã tồn tại
    COUNT=1

    while [ -e "$OUTPUT" ]
    do

        OUTPUT="$OUTPUT_DIR/${NAME}_cut_${START_SAFE}_to_${END_SAFE}_${COUNT}.${EXT}"

        COUNT=$((COUNT+1))

    done

    # Hiển thị
    clear

    echo "=========================================="
    echo "          ⚡ CẮT SIÊU NHANH"
    echo "=========================================="
    echo
    echo "🎞 Video:"
    echo "$BASENAME"
    echo
    echo "▶️  Bắt đầu:"
    echo "$START"
    echo
    echo "⏹ Kết thúc:"
    echo "$END"
    echo
    echo "⏱ Thời lượng:"
    echo "$DURATION"
    echo
    echo "💾 File xuất:"
    echo "$(basename "$OUTPUT")"
    echo
    echo "📁 Thư mục:"
    echo "$OUTPUT_DIR"
    echo
    echo "=========================================="
    echo "⚡ ĐANG CẮT..."
    echo "=========================================="
    echo

    # ======================================
    # CẮT KHÔNG ENCODE
    # ======================================

    ffmpeg \
        -hide_banner \
        -loglevel warning \
        -ss "$START" \
        -i "$INPUT" \
        -t "$DURATION" \
        -map 0 \
        -c copy \
        -avoid_negative_ts make_zero \
        "$OUTPUT"

    STATUS=$?

    echo
    echo "=========================================="

    if [ "$STATUS" -eq 0 ] &&
       [ -f "$OUTPUT" ]
    then

        echo "✅ CẮT THÀNH CÔNG!"
        echo
        echo "📁 File đã lưu:"
        echo "$OUTPUT"
        echo
        echo "⚡ Không encode."
        echo "⚡ Video gốc vẫn nguyên."
        echo
        echo "📂 Download/video cut"

    else

        echo "❌ CẮT VIDEO THẤT BẠI."

        rm -f "$OUTPUT" 2>/dev/null

    fi

    echo "=========================================="
    echo

    read -r -p "Nhấn Enter để quay lại danh sách..."

done
