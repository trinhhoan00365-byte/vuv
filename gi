#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
#       🎬 FAST VIDEO CUTTER - TERMUX
#       KHÔNG ENCODE - CẮT SIÊU NHANH
# ==========================================

clear

# ------------------------------------------
# Kiểm tra FFmpeg
# ------------------------------------------

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "❌ Chưa tìm thấy FFmpeg."
    echo
    echo "Cài FFmpeg bằng:"
    echo
    echo "pkg install ffmpeg -y"
    echo
    exit 1
fi


# ------------------------------------------
# Kiểm tra bộ nhớ
# ------------------------------------------

if [ ! -d "$HOME/storage/shared" ]; then
    echo "📱 Termux chưa được cấp quyền bộ nhớ."
    echo
    echo "Chạy:"
    echo
    echo "termux-setup-storage"
    echo
    read -r -p "Nhấn Enter sau khi cấp quyền..."
fi


# ==========================================
# THƯ MỤC DOWNLOAD
# ==========================================

DOWNLOAD_DIR="$HOME/storage/downloads"


# Kiểm tra Download
if [ ! -d "$DOWNLOAD_DIR" ]; then

    echo "❌ Không tìm thấy thư mục Download:"
    echo "$DOWNLOAD_DIR"
    echo
    echo "Hãy chạy:"
    echo
    echo "termux-setup-storage"
    echo

    exit 1
fi


# ==========================================
# THƯ MỤC VIDEO CUT
# ==========================================

OUTPUT_DIR="$DOWNLOAD_DIR/video cut"


# Tự tạo thư mục nếu chưa có
mkdir -p "$OUTPUT_DIR"


# ==========================================
# TÌM VIDEO TRONG DOWNLOAD
# ==========================================

cd "$DOWNLOAD_DIR" || exit 1


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


# ------------------------------------------
# Không có video
# ------------------------------------------

if [ "${#VIDEOS[@]}" -eq 0 ]; then

    clear

    echo "=========================================="
    echo "       🎬 FAST VIDEO CUTTER"
    echo "=========================================="
    echo
    echo "❌ Không tìm thấy video trong Download."
    echo
    echo "📁 Đường dẫn:"
    echo "$DOWNLOAD_DIR"
    echo

    exit 1
fi


# ==========================================
# HÀM ĐỔI THỜI GIAN → GIÂY
# ==========================================

time_to_seconds() {

    local TIME="$1"


    # HH:MM:SS
    if [[ "$TIME" =~ ^([0-9]+):([0-9]{2}):([0-9]{2})$ ]]; then

        local H="${BASH_REMATCH[1]}"
        local M="${BASH_REMATCH[2]}"
        local S="${BASH_REMATCH[3]}"

        echo $((H * 3600 + M * 60 + S))

        return
    fi


    # MM:SS
    if [[ "$TIME" =~ ^([0-9]+):([0-9]{2})$ ]]; then

        local M="${BASH_REMATCH[1]}"
        local S="${BASH_REMATCH[2]}"

        echo $((M * 60 + S))

        return
    fi


    # Chỉ nhập số giây
    if [[ "$TIME" =~ ^[0-9]+$ ]]; then

        echo "$TIME"

        return
    fi


    echo "-1"
}


# ==========================================
# HÀM ĐỔI GIÂY → HH:MM:SS
# ==========================================

seconds_to_time() {

    local TOTAL="$1"

    local H=$((TOTAL / 3600))

    local M=$(((TOTAL % 3600) / 60))

    local S=$((TOTAL % 60))

    printf "%02d:%02d:%02d" "$H" "$M" "$S"
}


# ==========================================
# MENU CHÍNH
# ==========================================

while true
do

    clear

    echo "=========================================="
    echo "       🎬 FAST VIDEO CUTTER"
    echo "=========================================="
    echo
    echo "⚡ Chế độ: KHÔNG ENCODE"
    echo "⚡ Tốc độ: Rất nhanh"
    echo
    echo "📁 Video lấy từ:"
    echo "$DOWNLOAD_DIR"
    echo
    echo "💾 File cắt sẽ lưu vào:"
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


    # --------------------------------------
    # THOÁT
    # --------------------------------------

    if [[ "$CHOICE" == "0" ]]; then

        echo
        echo "👋 Đã thoát."

        exit 0

    fi


    # --------------------------------------
    # KIỂM TRA LỰA CHỌN
    # --------------------------------------

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] ||
       [ "$CHOICE" -lt 1 ] ||
       [ "$CHOICE" -gt "${#VIDEOS[@]}" ]
    then

        echo
        echo "❌ Lựa chọn không hợp lệ."

        sleep 2

        continue
    fi


    # --------------------------------------
    # VIDEO ĐƯỢC CHỌN
    # --------------------------------------

    INPUT="${VIDEOS[$((CHOICE-1))]}"

    BASENAME="$(basename "$INPUT")"

    NAME="${BASENAME%.*}"

    EXT="${BASENAME##*.}"


    clear

    echo "=========================================="
    echo "          ✂️  CẮT VIDEO SIÊU NHANH"
    echo "=========================================="
    echo
    echo "🎞 Video:"
    echo "$BASENAME"
    echo
    echo "⚡ Không encode lại."
    echo "⚠️ Có thể lệch vài giây do keyframe."
    echo
    echo "Ví dụ:"
    echo
    echo "  00:01"
    echo "  00:55"
    echo


    # --------------------------------------
    # NHẬP THỜI GIAN
    # --------------------------------------

    read -r -p "▶️  Thời gian bắt đầu: " START

    read -r -p "⏹ Thời gian kết thúc:  " END


    # --------------------------------------
    # CHUYỂN THỜI GIAN
    # --------------------------------------

    START_SEC=$(time_to_seconds "$START")

    END_SEC=$(time_to_seconds "$END")


    if [ "$START_SEC" -lt 0 ] ||
       [ "$END_SEC" -lt 0 ]
    then

        echo
        echo "❌ Định dạng thời gian không hợp lệ."

        sleep 3

        continue
    fi


    # --------------------------------------
    # KIỂM TRA
    # --------------------------------------

    if [ "$END_SEC" -le "$START_SEC" ]; then

        echo
        echo "❌ Thời gian kết thúc phải lớn hơn thời gian bắt đầu."

        sleep 3

        continue
    fi


    # --------------------------------------
    # TÍNH DURATION
    # --------------------------------------

    DURATION_SEC=$((END_SEC - START_SEC))

    DURATION=$(seconds_to_time "$DURATION_SEC")


    # --------------------------------------
    # TÊN FILE
    # --------------------------------------

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


    # ======================================
    # HIỂN THỊ
    # ======================================

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


    # ======================================
    # KẾT QUẢ
    # ======================================

    echo
    echo "=========================================="


    if [ "$STATUS" -eq 0 ] &&
       [ -f "$OUTPUT" ]
    then

        echo "✅ CẮT THÀNH CÔNG!"
        echo
        echo "📁 File đã được lưu tại:"
        echo
        echo "$OUTPUT"
        echo
        echo "⚡ Không encode video."
        echo "⚡ Video gốc vẫn còn nguyên."
        echo
        echo "📂 Mở thư mục:"
        echo "Download/video cut"

    else

        echo "❌ CẮT VIDEO THẤT BẠI."

        rm -f "$OUTPUT" 2>/dev/null

    fi


    echo "=========================================="
    echo

    read -r -p "Nhấn Enter để quay lại danh sách..."

done
