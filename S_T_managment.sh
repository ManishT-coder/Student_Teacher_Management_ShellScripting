#!/bin/bash

# ================= THEME & COLOR CONFIGURATION =================
THEME="DARK"

set_theme() {
    if [ "$THEME" = "DARK" ]; then
        BG='\033[44;1;37m' # Blue Header BG
        B='\033[1;34m' C='\033[1;36m' G='\033[1;32m' 
        Y='\033[1;33m' R='\033[1;31m' W='\033[1;37m' NC='\033[0m'
    else
        BG='\033[42;1;30m' # Green Header BG
        B='\033[1;32m' C='\033[1;33m' G='\033[1;34m' 
        Y='\033[1;35m' R='\033[1;31m' W='\033[0;30m' NC='\033[0m'
    fi
}
set_theme

# ================= UI REUSABLE ELEMENTS =================
header() {
    clear
    echo -e "${B}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BG}║        STUDENT–TEACHER MANAGEMENT SYSTEM             ║${NC}"
    echo -e "${B}╚══════════════════════════════════════════════════════╝${NC}"
    echo -e "  ${C}📅 $(date +'%A, %d %B %Y') | ${Y}THEME: $THEME ${NC}"
    echo
}

draw_line() {
    echo -e "${B}────────────────────────────────────────────────────────────────────────${NC}"
}

toast() {
    echo -e "\n${Y} ❯❯ $1...${NC}"
    sleep 1.2
}

pause() {
    echo -e "\n${W}⏎ Press Enter to continue...${NC}"
    read
}

# ================= EXIT SYSTEM =================
exit_system() {
    header
    echo -e "${Y}🚀 Shutting down System...${NC}"
    sleep 0.5
    echo -e "✨ ${G}Thank you for using STUDENT–TEACHER MANAGEMENT SYSTEM!${NC}"
    echo
    echo -e "👋 ${W}Goodbye!${NC}"
    sleep 1.5
    clear
    exit
}

# ================= NOTIFICATION SYSTEM =================
check_notifs() {
    unread=$(grep "^$sid|.*|.*|.*|\(ACCEPTED\|DECLINED\)|.*|UNREAD" leaves.txt)
    if [ ! -z "$unread" ]; then
        echo -e "${R}🔔 NOTIFICATION: LEAVE STATUS UPDATED!${NC}"
        draw_line
        while IFS="|" read -r id name date reason status remark seen; do
            st_col=$G; [ "$status" == "DECLINED" ] && st_col=$R
            echo -e "  ${W}Date:${NC} $date | ${W}Status:${NC} ${st_col}$status${NC}"
            echo -e "  ${W}Remark:${NC} $remark"
            echo -e "  --------------------------------------------------"
        done <<< "$unread"
        sed -i "/^$sid|.*|.*|.*|\(ACCEPTED\|DECLINED\)|.*|UNREAD/s/UNREAD/READ/g" leaves.txt
        pause
    fi
}

# ================= STUDENT MODULE =================
student_login() {
    header; echo -e "${C}🔐 STUDENT LOGIN${NC}"
    read -p "  Student ID : " sid
    read -s -p "  Password   : " pass; echo
    spass=$(grep student passwords.txt | cut -d "|" -f2)
    if grep -q "^$sid|" students.txt && [ "$pass" = "$spass" ]; then
        toast "Identity Verified"; check_notifs; student_menu
    else
        echo -e "${R}  ❌ Access Denied${NC}"; pause
    fi
}

student_menu() {
    while true; do
        header; name=$(grep "^$sid|" students.txt | cut -d "|" -f2)
        echo -e "👩‍🎓 ${G}Welcome, $name${NC}"
        echo -e "${B}┌───────────────────────────────────────────┐${NC}"
        echo -e "  1) My Profile"
        echo -e "  2) Weekly Timetable"
        echo -e "  3) Exam Timetable 📅"
        echo -e "  4) View Result Card"
        echo -e "  5) Submit Leave Request ✉"
        echo -e "  6) Campus Announcements 📢"
        [ "$sid" == "S8" ] && echo -e "  M) Post Announcement (Monitor)"
        echo -e "  7) Change Theme"
        echo -e "  8) Logout"
        echo -e "${B}└───────────────────────────────────────────┘${NC}"
        read -p " Action: " ch
        case $ch in
            1) student_profile ;;
            2) view_timetable ;;
            3) view_exam_timetable ;;
            4) show_result ;;
            5) submit_leave ;;
            6) view_announcements ;;
            [Mm]) [ "$sid" == "S8" ] && post_monitor_news ;;
            7) theme_switch ;;
            8) break ;;
        esac
    done
}

# ================= TEACHER MODULE =================
teacher_login() {
    header; echo -e "${C}🔐 TEACHER LOGIN${NC}"
    read -p "  Teacher ID : " tid
    read -s -p "  Password   : " tpass_in; echo
    tpass=$(grep teacher passwords.txt | cut -d "|" -f2)
    if grep -q "^$tid|" teachers.txt && [ "$tpass_in" = "$tpass" ]; then
        toast "Identity Verified"; teacher_menu
    else
        echo -e "${R}  ❌ Access Denied${NC}"; pause
    fi
}

teacher_menu() {
    while true; do
        header; tname=$(grep "^$tid|" teachers.txt | cut -d "|" -f2)
        echo -e "👩‍🏫 ${G}Prof. $tname ${NC}"
        echo -e "${B}┌───────────────────────────────────────────┐${NC}"
        echo -e "  1) Mark Attendance"
        echo -e "  2) Manage Leaves Requests ✉"
        echo -e "  3) Post Announcement 📢"
        echo -e "  4) Personal Subject Notes 📌"
        echo -e "  5) Change Theme"
        echo -e "  6) Logout"
        echo -e "${B}└───────────────────────────────────────────┘${NC}"
        read -p " Action: " ch
        case $ch in
            1) add_attendance ;;
            2) manage_leaves ;;
            3) post_news ;;
            4) teacher_bookmarks ;;
            5) theme_switch ;;
            6) break ;;
        esac
    done
}

manage_leaves() {
    header; 
    echo -e "${C}✉  LEAVE MANAGEMENT${NC}"; 
    draw_line
    IFS=$'\n' 
    read -d '' -r -a pending_list < <(grep "|PENDING|" leaves.txt && printf '\0')
    if [ ${#pending_list[@]} -eq 0 ]; 
    then 
    echo "  No pending requests."; 
    draw_line; 
    pause; 
    return; 
    fi
    (echo "NO|ID|NAME|DATE|REASON|STATUS"; 
    for i in "${!pending_list[@]}"; 
    do 
    echo "$((i+1))|${pending_list[$i]}" | cut -d"|" -f1-6; done) | column -t -s "|" | sed 's/^/  /'
    draw_line; 
    read -p "  Select Number: " sel
    [ -z "$sel" ] && return
    target="${pending_list[$((sel-1))]}"
    t_id=$(echo "$target" | cut -d"|" -f1); 
    t_date=$(echo "$target" | cut -d"|" -f3)
    echo -e "  1) ACCEPT | 2) DECLINE"; 
    read -p "  Decision: " dec
    rem="Approved"
    if [ "$dec" == "1" ]; 
    then status="ACCEPTED"
    else status="DECLINED"; 
    read -p "  Enter Reason: " rem; 
    fi
    sed -i "s/^$t_id|\([^|]*\)|$t_date|\([^|]*\)|PENDING|[^|]*|[^|]*/$t_id|\1|$t_date|\2|$status|$rem|UNREAD/" leaves.txt
    toast "Update Saved Successfully"
}

teacher_bookmarks() {
    header; echo -e "  1) View Notes | 2) Add New Subject Note"
    read -p " Choice: " bch
    tfull=$(grep "^$tid|" teachers.txt | cut -d "|" -f2)
    if [ "$bch" == "2" ]; then
        read -p " Subject: " s; read -p " Note: " n; echo "$tid|$s|$(date +%F)|$n" >> bookmarks.txt; toast "Saved"
    else
        draw_line; echo -e "  ${Y}TEACHER | SUBJECT | DATE | NOTE${NC}"
        grep "^$tid|" bookmarks.txt | while IFS="|" read -r _ s d n; do echo "$tfull mam|$s|$d|$n"; done | column -t -s "|" | sed 's/^/  /'
        draw_line; pause
    fi
}

# (Data Helpers)
submit_leave() { 
header; 
sname=$(grep "^$sid|" students.txt | cut -d "|" -f2); 
read -p " Reason: " reason; 
echo "$sid|$sname|$(date +%F)|$reason|PENDING|None|UNREAD" >> leaves.txt; 
toast "Submitted"; 
}
check_leave_notifications() {
    # Scan for entries matching the student ID that are NOT Pending and are UNREAD
    unread_notif=$(grep "^$sid|.*|.*|.*|\(ACCEPTED\|DECLINED\)|.*|UNREAD" leaves.txt)

    if [ ! -z "$unread_notif" ]; then
        header
        echo -e "${R}🔔 NEW LEAVE STATUS NOTIFICATION${NC}"
        draw_line
        while IFS="|" read -r id name date reason status remark seen; do
            color_status=$G
            [ "$status" == "DECLINED" ] && color_status=$R
            
            echo -e "  ${W}Leave requested for Date:${NC} $date"
            echo -e "  ${W}Current Status:${NC} ${color_status}$status${NC}"
            echo -e "  ${W}Teacher Remark:${NC} $remark"
            echo -e "  --------------------------------------------------"
        done <<< "$unread_notif"
        
        # Mark as READ in the file so it won't show again next login
        # We target the specific student's ID and change UNREAD to READ
        sed -i "/^$sid|.*|.*|.*|\(ACCEPTED\|DECLINED\)|.*|UNREAD/s/UNREAD/READ/g" leaves.txt
        
        pause
    fi
}
post_news() { 
header; 
read -p " Message: " msg; 
tfull=$(grep "^$tid|" teachers.txt | cut -d "|" -f2); 
echo "$(date +%F)|Prof. $tfull |$msg" >> announcements.txt; 
toast "Broadcasted"; 
}
post_monitor_news() { 
header; 
read -p " Message: " msg;
mname=$(grep "^S8|" students.txt | cut -d "|" -f2);
echo "$(date +%F)|$mname (Monitor)|$msg" >> announcements.txt;
toast "Posted";
}
add_attendance() { 
header; 
echo "Enter 'q' to stop."; 
while true; do read -p " ID: " asid; 
[[ "$asid" == "q" || -z "$asid" ]] && break; 
read -p " 1-P/2-A: " ach; [ "$ach" == "1" ] && st="PRESENT" || st="ABSENT" echo "$asid|$(date +%F)|$st|$tid" >> attendance.txt; 
done; 
}
student_profile() {
    header; stu=$(grep "^$sid|" students.txt); echo -e "${C}🪪 STUDENT IDENTIFICATION${NC}"; draw_line
    printf "  ${Y}%-15s :${NC} %s\n" "ID" "$sid"
    printf "  ${Y}%-15s :${NC} %s\n" "NAME" "$(echo "$stu" | cut -d "|" -f2)"
    printf "  ${Y}%-15s :${NC} %s\n" "STREAM" "$(echo "$stu" | cut -d "|" -f3)"; draw_line; pause
}
view_timetable() { 
header; 
draw_line; 
column -t -s "|" timetable.txt | sed 's/^/  /'; 
draw_line; 
pause; 
}
view_exam_timetable() { 
header; 
draw_line; 
column -t -s "|" exam_timetable.txt | sed 's/^/  /'; 
draw_line; 
pause; }
show_result() { 
    header; stu=$(grep "^$sid|" students.txt); stream=$(echo "$stu" | cut -d "|" -f3); overall=$(grep "^$sid|$stream" result.txt)
    if [ -z "$overall" ]; then echo "No Result Found"; pause; return; fi
    echo -e "${C}📊 PERFORMANCE REPORT${NC}"; draw_line; IFS="|" read _ _ roll _ _ outof total res _ _ <<< "$overall"
    echo -e "  Roll: $roll | Marks: $total/$outof | Result: $res"
    awk -F"|" -v sid="$sid" '$1==sid {printf "  %-18s %-6s %-6s %-6s\n",$2,$3,$4,$5}' result1.txt; draw_line; pause
}
theme_switch() { 
header; 
echo "1) Dark Ocean | 2) Forest Light"; 
read -p " Select: " tch; 
[ "$tch" == "2" ] && THEME="LIGHT" || THEME="DARK"; 
set_theme; 
toast "Applied"; 
}
view_announcements() { 
header; 
while IFS="|" read -r d a m; do echo -e " [$d] $a: $m"; 
done < announcements.txt | tail -n 5; 
pause; 
}


# ================= MAIN LOOP =================
while true; do
    header
    echo -e "👩‍🎓 ${C}PORTAL GATEWAY${NC}"
    echo -e "${B}┌───────────────────────────────────────────┐${NC}"
    echo -e "  1) Student Portal"
    echo -e "  2) Teacher Portal"
    echo -e "  3) System Theme"
    echo -e "  4) Exit System"
    echo -e "${B}└───────────────────────────────────────────┘${NC}"
    read -p " Select: " main
    case $main in
        1) student_login ;;
        2) teacher_login ;;
        3) theme_switch ;;
        4) exit_system ;;
        *) echo -e "${R}Invalid selection${NC}"; sleep 1 ;;
    esac
done
