#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
#        🎬 VIDEO CUTTER - TERMUX
# ==========================================

clear

# Kiểm tra FFmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "❌ Chưa cài FFmpeg."
    echo
    echo "Đang cài FFmpeg..."
    pkg update -y
    pkg install ffmpeg -y

    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo "❌ Không thể cài FFmpeg."
        exit 1
    fi
fi

# Kiểm tra quyền bộ nhớ
if [ ! -d "$HOME/storage/shared" ]; then
    echo "📱 Termux chưa được cấp quyền bộ nhớ."
    echo
    echo "Chạy lệnh:"
    echo
    echo "termux-setup-storage"
    echo
    read -r -p "Nhấn Enter sau khi đã cấp quyền..."
fi

# Thư mục chứa video
VIDEO_DIR="${1:-$(pwd)}"

if [ ! -d "$VIDEO_DIR" ]; then
    echo "❌ Không tìm thấy thư mục:"
    echo "$VIDEO_DIR"
    exit 1
fi

cd "$VIDEO_DIR" || exit 1

# ==========================================
# TÌM VIDEO
# ==========================================

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
    echo "          🎬 VIDEO CUTTER TERMUX"
    echo "=========================================="
    echo
    echo "❌ Không tìm thấy video."
    echo
    echo "Thư mục hiện tại:"
    echo "$VIDEO_DIR"
    echo
    echo "Các định dạng hỗ trợ:"
    echo "MP4 / MKV / MOV / WEBM / AVI / M4V / FLV"
    echo

    exit 1
fi


# ==========================================
# MENU CHÍNH
# ==========================================

while true
do

    clear

    echo "=========================================="
    echo "          🎬 VIDEO CUTTER TERMUX"
    echo "=========================================="
    echo
    echo "📁 Thư mục:"
    echo "$VIDEO_DIR"
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
    if [[ "$CHOICE" == "0" ]]
    then

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


    # ======================================
    # VIDEO ĐƯỢC CHỌN
    # ======================================

    INPUT="${VIDEOS[$((CHOICE-1))]}"

    BASENAME="$(basename "$INPUT")"

    NAME="${BASENAME%.*}"

    EXT="${BASENAME##*.}"


    clear

    echo "=========================================="
    echo "             🎬 CẮT VIDEO"
    echo "=========================================="
    echo
    echo "🎞 Video:"
    echo "$BASENAME"
    echo

    echo "Nhập thời gian theo dạng:"
    echo
    echo "  00:30"
    echo "  01:25"
    echo "  01:25:30"
    echo
    echo "Ví dụ:"
    echo
    echo "  Từ 01:00 đến 03:25"
    echo


    # ======================================
    # NHẬP THỜI GIAN
    # ======================================

    read -r -p "⏱ Thời gian bắt đầu: " START

    read -r -p "⏱ Thời gian kết thúc:  " END


    # Không cho bỏ trống
    if [[ -z "$START" || -z "$END" ]]
    then

        echo
        echo "❌ Thời gian không được để trống."
        sleep 2
        continue

    fi


    # ======================================
    # TẠO TÊN FILE
    # ======================================

    START_SAFE="${START//:/-}"

    END_SAFE="${END//:/-}"

    OUTPUT="${NAME}_cut_${START_SAFE}_to_${END_SAFE}.${EXT}"


    # Nếu file đã tồn tại
    COUNT=1

    while [ -e "$OUTPUT" ]
    do

        OUTPUT="${NAME}_cut_${START_SAFE}_to_${END_SAFE}_${COUNT}.${EXT}"

        COUNT=$((COUNT+1))

    done


    # ======================================
    # BẮT ĐẦU CẮT
    # ======================================

    clear

    echo "=========================================="
    echo "             ✂️  ĐANG CẮT VIDEO"
    echo "=========================================="
    echo
    echo "🎞 File:"
    echo "$BASENAME"
    echo
    echo "▶️  Bắt đầu:"
    echo "$START"
    echo
    echo "⏹ Kết thúc:"
    echo "$END"
    echo
    echo "💾 File xuất:"
    echo "$OUTPUT"
    echo
    echo "=========================================="
    echo


    # ======================================
    # FFMPEG
    # ======================================

    ffmpeg \
        -hide_banner \
        -loglevel warning \
        -ss "$START" \
        -i "$INPUT" \
        -to "$END" \
        -c:v libx264 \
        -preset veryfast \
        -crf 18 \
        -c:a aac \
        -b:a 192k \
        -movflags +faststart \
        "$OUTPUT"


    STATUS=$?


    # ======================================
    # KẾT QUẢ
    # ======================================

    echo
    echo "=========================================="


    if [ "$STATUS" -eq 0 ] && [ -f "$OUTPUT" ]
    then

        echo "✅ CẮT VIDEO THÀNH CÔNG!"
        echo
        echo "📁 File kết quả:"
        echo "$OUTPUT"
        echo
        echo "📍 Vị trí:"
        pwd
        echo
        echo "🎞 Video gốc vẫn được giữ nguyên."

    else

        echo "❌ CẮT VIDEO THẤT BẠI."
        echo
        echo "Kiểm tra lại:"
        echo "- Thời gian bắt đầu"
        echo "- Thời gian kết thúc"
        echo "- File video"

        rm -f "$OUTPUT" 2>/dev/null

    fi


    echo "=========================================="
    echo

    read -r -p "Nhấn Enter để quay lại danh sách..."

done
