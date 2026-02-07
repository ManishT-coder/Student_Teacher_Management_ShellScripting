#!/bin/bash

header() {
    clear
    echo "======================================================"
    echo "        STUDENT–TEACHER MANAGEMENT SYSTEM             "
    echo "======================================================"
    echo "  $(date +'%A, %d %B %Y')"
    echo
}

draw_line() {
    echo "--------------------------------------------------------------"
}


toast() {
    echo -e "\n>> $1..."
    sleep 1.2
}

pause() {
    echo -e "\nPress Enter to continue..."
    read
}

# ================= STUDENT MODULE =================

student_login() {
    header
    echo "STUDENT LOGIN"
    read -p "Student ID : " sid
    read -s -p "Password   : " pass; echo
    spass=$(grep student passwords.txt | cut -d "|" -f2)

    if grep -q "^$sid|" students.txt && [ "$pass" = "$spass" ]; then
        toast "Identity Verified"
        check_notifs
        student_menu
    else
        echo "Access Denied"
        pause
    fi
}

student_menu() {
    while true; do
        header
        name=$(grep "^$sid|" students.txt | cut -d "|" -f2)
        echo "Welcome, $name"
        echo "-----------------------------------"
        echo "1) My Profile"
        echo "2) Weekly Timetable"
        echo "3) Exam Timetable"
        echo "4) View Result Card"
        echo "5) Submit Leave Request"
        echo "6) Campus Announcements"
        [ "$sid" == "S5" ] && echo "M) Post Announcement (Monitor)"
        echo "7) Logout"
        echo "-----------------------------------"
        read -p "Action: " ch

        case $ch in
            1) student_profile ;;
            2) view_timetable ;;
            3) view_exam_timetable ;;
            4) show_result ;;
            5) submit_leave ;;
            6) view_announcements ;;
            [Mm]) [ "$sid" == "S8" ] && post_monitor_news ;;
            7) break ;;
        esac
    done
}

student_profile() {
    header
    stu=$(grep "^$sid|" students.txt)
    echo "STUDENT PROFILE"
    draw_line
    echo "ID     : $sid"
    echo "Name   : $(echo "$stu" | cut -d "|" -f2)"
    echo "Stream : $(echo "$stu" | cut -d "|" -f3)"
    draw_line
    pause
}

show_result() {
# awk is a text processing command used to filter and format data from files.
# -F "|" tells awk to use '|' as the column separator instead of default space.
# After splitting:
#   $1 = first column
#   $2 = second column
#   $3 = third column
    header   # Clear screen and show system header
    # Step 1: Get full student record using student ID
    stu=$(grep "^$sid|" students.txt)
    # Step 2: Extract stream (3rd column) from student record
    # Using '|' as delimiter
    stream=$(echo "$stu" | cut -d "|" -f3)
    # Step 3: Find overall result for that student
    # It matches both student ID and stream
    overall=$(grep "^$sid|$stream" result.txt)
    # Step 4: Check if result exists
    if [ -z "$overall" ]; then
        echo "No Result Found"
        pause
        return
    fi

    echo "PERFORMANCE REPORT"
    draw_line
    # Step 5: Split the overall result line using '|'
    # IFS="|" tells shell to use pipe as separator
    # We ignore unwanted columns using '_'
    IFS="|" read _ _ roll _ _ outof total res _ _ <<< "$overall"

    # --------------------------------------------------
    # Step 6: Display summary result
    echo "Roll: $roll | Marks: $total/$outof | Result: $res"

    # --------------------------------------------------
    # Step 7: Show subject-wise marks from result1.txt
    # -F "|" sets field separator
    # -v sid="$sid" passes shell variable into awk
    # printf formats output nicely in columns
    awk -F"|" -v sid="$sid"
    '$1==sid {printf "%-18s %-6s %-6s %-6s\n",$2,$3,$4,$5}' result1.txt
    draw_line
    pause
}

submit_leave() {
    header
    sname=$(grep "^$sid|" students.txt | cut -d "|" -f2)
    read -p "Reason: " reason
    echo "$sid|$sname|$(date +%F)|$reason|PENDING|None|UNREAD" >> leaves.txt
    toast "Submitted"
}

check_notifs() {
    unread=$(grep "^$sid|.*|.*|.*|\(ACCEPTED\|DECLINED\)|.*|UNREAD" leaves.txt)

    if [ ! -z "$unread" ]; then
        echo "NOTIFICATION: LEAVE STATUS UPDATED!"
        draw_line

        while IFS="|" read -r id name date reason status remark seen; do
            echo "Date: $date | Status: $status"
            echo "Remark: $remark"
            echo "----------------------------------"
        done <<< "$unread"

        sed -i "/^$sid|.*|.*|.*|\(ACCEPTED\|DECLINED\)|.*|UNREAD/s/UNREAD/READ/g" leaves.txt
        pause
    fi
}

# ================= TEACHER MODULE =================

teacher_login() {
    header
    echo "TEACHER LOGIN"
    read -p "Teacher ID : " tid
    read -s -p "Password   : " tpass_in; echo
    tpass=$(grep teacher passwords.txt | cut -d "|" -f2)

    if grep -q "^$tid|" teachers.txt && [ "$tpass_in" = "$tpass" ]; then
        toast "Identity Verified"
        teacher_menu
    else
        echo "Access Denied"
        pause
    fi
}

teacher_menu() {
    while true; do
        header
        tname=$(grep "^$tid|" teachers.txt | cut -d "|" -f2)
        echo "Prof. $tname"
        echo "-----------------------------------"
        echo "1) Mark Attendance"
        echo "2) Manage Leave Requests"
        echo "3) Post Announcement"
        echo "4) Personal Subject Notes"
        echo "5) Logout"
        echo "-----------------------------------"
        read -p "Action: " ch

        case $ch in
            1) add_attendance ;;
            2) manage_leaves ;;
            3) post_news ;;
            4) teacher_bookmarks ;;
            5) break ;;
        esac
    done
}

# ================= CORE SYSTEM =================

view_timetable() {
    header
    column -t -s "|" timetable.txt
    pause
}

view_exam_timetable() {
    header
    column -t -s "|" exam_timetable.txt
    pause
}

view_announcements() {
    header
    while IFS="|" read -r d a m; do
        echo "[$d] $a: $m"
    done < announcements.txt | tail -n 5
    pause
}

post_news() {
    header
    read -p "Message: " msg
    tfull=$(grep "^$tid|" teachers.txt | cut -d "|" -f2)
    echo "$(date +%F)|Prof. $tfull|$msg" >> announcements.txt
    toast "Broadcasted"
}

post_monitor_news() {
    header
    read -p "Message: " msg
    mname=$(grep "^S5|" students.txt | cut -d "|" -f2)
    echo "$(date +%F)|$mname (Monitor)|$msg" >> announcements.txt
    toast "Posted"
}

exit_system() {
    header
    echo "Shutting down System..."
    echo "Thank you for using the System!"
    echo "Goodbye!"
    exit
}

# ================= MAIN LOOP =================

while true; do
    header
    echo "PORTAL GATEWAY"
    echo "-----------------------------------"
    echo "1) Student Portal"
    echo "2) Teacher Portal"
    echo "3) Exit"
    echo "-----------------------------------"
    read -p "Select: " main

    case $main in
        1) student_login ;;
        2) teacher_login ;;
        3) exit_system ;;
        *) echo "Invalid selection"; sleep 1 ;;
    esac
done
