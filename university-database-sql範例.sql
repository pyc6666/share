-- =====================================================
-- 大學教務系統資料庫建立腳本 (MariaDB版本)
-- =====================================================

-- 刪除已存在的資料庫並重新建立

DROP DATABASE IF EXISTS university_db;
CREATE DATABASE university_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE university_db;




-- =====================================================
-- 表格結構定義
-- =====================================================
USE university_db;
-- 系所表
CREATE TABLE DEPARTMENT (
    Department_ID CHAR(5) PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Location VARCHAR(50),
    Phone VARCHAR(15),
    Established_Year INT,
    Chair_ID CHAR(6),
    College VARCHAR(30)
);

-- 教師表
CREATE TABLE TEACHER (
    Teacher_ID CHAR(6) PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Title VARCHAR(20) CHECK (Title IN ('教授', '副教授', '助理教授', '講師')),
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(15),
    Office_Location VARCHAR(50),
    Hire_Date DATE,
    Department_ID CHAR(5),
    FOREIGN KEY (Department_ID) REFERENCES DEPARTMENT(Department_ID)
);

-- 更新系所表的外鍵約束(系主任)
ALTER TABLE DEPARTMENT 
ADD CONSTRAINT fk_department_chair 
FOREIGN KEY (Chair_ID) REFERENCES TEACHER(Teacher_ID);

-- 學生表
CREATE TABLE STUDENT (
    Student_ID CHAR(9) PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Birth_Date DATE,
    Gender CHAR(1) CHECK (Gender IN ('M', 'F')),
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(15),
    Address VARCHAR(200),
    Admission_Year INT,
    Status VARCHAR(10) CHECK (Status IN ('在學', '休學', '畢業', '退學')),
    Department_ID CHAR(5),
    FOREIGN KEY (Department_ID) REFERENCES DEPARTMENT(Department_ID)
);

-- 學生聯絡人表 (弱實體)
CREATE TABLE STUDENT_CONTACT (
    Student_ID CHAR(9),
    Contact_Name VARCHAR(50),
    Relationship VARCHAR(20),
    Phone VARCHAR(15) NOT NULL,
    Email VARCHAR(100),
    Address VARCHAR(200),
    Is_Emergency BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (Student_ID, Contact_Name),
    FOREIGN KEY (Student_ID) REFERENCES STUDENT(Student_ID) ON DELETE CASCADE
);

-- 教室表
CREATE TABLE CLASSROOM (
    Room_ID CHAR(6) PRIMARY KEY,
    Building VARCHAR(30) NOT NULL,
    Room_Number VARCHAR(10) NOT NULL,
    Capacity INT CHECK (Capacity > 0),
    Type VARCHAR(20) CHECK (Type IN ('一般教室', '電腦教室', '實驗室', '演講廳')),
    Has_Projector BOOLEAN DEFAULT FALSE,
    Has_Computer BOOLEAN DEFAULT FALSE
);

-- 學期表
CREATE TABLE SEMESTER (
    Semester_ID CHAR(6) PRIMARY KEY,
    Year INT NOT NULL,
    Term VARCHAR(10) NOT NULL CHECK (Term IN ('第一學期', '第二學期', '暑期')),
    Start_Date DATE NOT NULL,
    End_Date DATE NOT NULL,
    Registration_Start DATE,
    Registration_End DATE,
    CHECK (Start_Date < End_Date),
    CHECK (Registration_Start < Registration_End),
    UNIQUE (Year, Term)
);

-- 課程表
CREATE TABLE COURSE (
    Course_ID CHAR(8) PRIMARY KEY,
    Title VARCHAR(100) NOT NULL,
    Description TEXT,
    Credits INT CHECK (Credits > 0),
    Level VARCHAR(10) CHECK (Level IN ('大學部', '研究所')),
    Hours_Per_Week INT,
    Department_ID CHAR(5),
    FOREIGN KEY (Department_ID) REFERENCES DEPARTMENT(Department_ID)
);

-- 課程先修課程表 (多值屬性)
CREATE TABLE COURSE_PREREQUISITE (
    Course_ID CHAR(8),
    Prerequisite_ID CHAR(8),
    PRIMARY KEY (Course_ID, Prerequisite_ID),
    FOREIGN KEY (Course_ID) REFERENCES COURSE(Course_ID) ON DELETE CASCADE,
    FOREIGN KEY (Prerequisite_ID) REFERENCES COURSE(Course_ID) ON DELETE CASCADE,
    CHECK (Course_ID <> Prerequisite_ID)
);

-- 教師專長表 (多值屬性)
CREATE TABLE TEACHER_EXPERTISE (
    Teacher_ID CHAR(6),
    Expertise VARCHAR(50),
    PRIMARY KEY (Teacher_ID, Expertise),
    FOREIGN KEY (Teacher_ID) REFERENCES TEACHER(Teacher_ID) ON DELETE CASCADE
);

-- 選課表 (學生-課程 多對多關係)
CREATE TABLE ENROLLMENT (
    Student_ID CHAR(9),
    Course_ID CHAR(8),
    Semester_ID CHAR(6),
    Enrollment_Date DATE NOT NULL,
    Grade DECIMAL(4,1) CHECK (Grade IS NULL OR (Grade >= 0 AND Grade <= 100)),
    Status VARCHAR(10) DEFAULT '修課中' CHECK (Status IN ('修課中', '通過', '不通過', '退選')),
    PRIMARY KEY (Student_ID, Course_ID, Semester_ID),
    FOREIGN KEY (Student_ID) REFERENCES STUDENT(Student_ID),
    FOREIGN KEY (Course_ID) REFERENCES COURSE(Course_ID),
    FOREIGN KEY (Semester_ID) REFERENCES SEMESTER(Semester_ID)
);

-- 教授表 (教師-課程 多對多關係)
CREATE TABLE TEACHING (
    Teacher_ID CHAR(6),
    Course_ID CHAR(8),
    Semester_ID CHAR(6),
    PRIMARY KEY (Teacher_ID, Course_ID, Semester_ID),
    FOREIGN KEY (Teacher_ID) REFERENCES TEACHER(Teacher_ID),
    FOREIGN KEY (Course_ID) REFERENCES COURSE(Course_ID),
    FOREIGN KEY (Semester_ID) REFERENCES SEMESTER(Semester_ID)
);

-- 課程安排表 (課程-教室 多對一關係，包括排課時間)
CREATE TABLE SCHEDULE (
    Course_ID CHAR(8),
    Semester_ID CHAR(6),
    Room_ID CHAR(6),
    Day_Of_Week INT CHECK (Day_Of_Week BETWEEN 1 AND 7),
    Start_Time TIME,
    End_Time TIME,
    PRIMARY KEY (Course_ID, Semester_ID, Room_ID, Day_Of_Week, Start_Time),
    FOREIGN KEY (Course_ID) REFERENCES COURSE(Course_ID),
    FOREIGN KEY (Semester_ID) REFERENCES SEMESTER(Semester_ID),
    FOREIGN KEY (Room_ID) REFERENCES CLASSROOM(Room_ID),
    CHECK (Start_Time < End_Time)
);

-- 社團表
CREATE TABLE CLUB (
    Club_ID CHAR(5) PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Type VARCHAR(20) CHECK (Type IN ('學術性', '康樂性', '服務性', '體育性', '其他')),
    Established_Date DATE,
    Description TEXT,
    Advisor_ID CHAR(6),
    FOREIGN KEY (Advisor_ID) REFERENCES TEACHER(Teacher_ID)
);

-- 學生社團參與表 (多對多關係)
CREATE TABLE CLUB_MEMBERSHIP (
    Student_ID CHAR(9),
    Club_ID CHAR(5),
    Join_Date DATE NOT NULL,
    Position VARCHAR(20) DEFAULT '社員',
    Status VARCHAR(10) CHECK (Status IN ('活躍', '非活躍', '退出')),
    PRIMARY KEY (Student_ID, Club_ID),
    FOREIGN KEY (Student_ID) REFERENCES STUDENT(Student_ID),
    FOREIGN KEY (Club_ID) REFERENCES CLUB(Club_ID)
);

-- 社團活動表
CREATE TABLE CLUB_ACTIVITY (
    Activity_ID CHAR(8) PRIMARY KEY,
    Club_ID CHAR(5),
    Name VARCHAR(100) NOT NULL,
    Description TEXT,
    Start_Date DATE NOT NULL,
    End_Date DATE,
    Location VARCHAR(100),
    Budget DECIMAL(10,2),
    Status VARCHAR(20) CHECK (Status IN ('計劃中', '審核中', '已核准', '進行中', '已完成', '已取消')),
    FOREIGN KEY (Club_ID) REFERENCES CLUB(Club_ID),
    CHECK (Start_Date <= End_Date)
);

-- 學生活動參與表
CREATE TABLE ACTIVITY_PARTICIPATION (
    Student_ID CHAR(9),
    Activity_ID CHAR(8),
    Registration_Date DATE NOT NULL,
    Role VARCHAR(30),
    Attendance BOOLEAN DEFAULT NULL,
    PRIMARY KEY (Student_ID, Activity_ID),
    FOREIGN KEY (Student_ID) REFERENCES STUDENT(Student_ID),
    FOREIGN KEY (Activity_ID) REFERENCES CLUB_ACTIVITY(Activity_ID)
);

-- =====================================================
-- 視圖定義
-- =====================================================

-- 學生選課總覽視圖
CREATE VIEW STUDENT_ENROLLMENT_SUMMARY AS
SELECT 
    s.Student_ID, 
    s.Name AS Student_Name,
    d.Name AS Department_Name,
    COUNT(e.Course_ID) AS Total_Courses,
    SUM(c.Credits) AS Total_Credits,
    ROUND(AVG(e.Grade), 2) AS Average_Grade
FROM 
    STUDENT s
    JOIN DEPARTMENT d ON s.Department_ID = d.Department_ID
    LEFT JOIN ENROLLMENT e ON s.Student_ID = e.Student_ID
    LEFT JOIN COURSE c ON e.Course_ID = c.Course_ID
WHERE 
    e.Status = '通過' OR e.Status IS NULL
GROUP BY 
    s.Student_ID, s.Name, d.Name;

-- 教師教學總覽視圖
CREATE VIEW TEACHER_TEACHING_SUMMARY AS
SELECT 
    t.Teacher_ID,
    t.Name AS Teacher_Name,
    t.Title,
    d.Name AS Department_Name,
    sem.Year,
    sem.Term,
    COUNT(DISTINCT teach.Course_ID) AS Courses_Count,
    COUNT(DISTINCT e.Student_ID) AS Students_Count
FROM 
    TEACHER t
    JOIN DEPARTMENT d ON t.Department_ID = d.Department_ID
    JOIN TEACHING teach ON t.Teacher_ID = teach.Teacher_ID
    JOIN SEMESTER sem ON teach.Semester_ID = sem.Semester_ID
    LEFT JOIN ENROLLMENT e ON teach.Course_ID = e.Course_ID AND teach.Semester_ID = e.Semester_ID
GROUP BY 
    t.Teacher_ID, t.Name, t.Title, d.Name, sem.Year, sem.Term;

-- 系所課程統計視圖
CREATE VIEW DEPARTMENT_COURSE_STATS AS
SELECT 
    d.Department_ID,
    d.Name AS Department_Name,
    COUNT(c.Course_ID) AS Total_Courses,
    SUM(CASE WHEN c.Level = '大學部' THEN 1 ELSE 0 END) AS Undergraduate_Courses,
    SUM(CASE WHEN c.Level = '研究所' THEN 1 ELSE 0 END) AS Graduate_Courses,
    AVG(c.Credits) AS Avg_Credits
FROM 
    DEPARTMENT d
    LEFT JOIN COURSE c ON d.Department_ID = c.Department_ID
GROUP BY 
    d.Department_ID, d.Name;

-- =====================================================
-- 觸發器定義
-- =====================================================

-- 更新系所主管時的檢查觸發器
DELIMITER //
CREATE TRIGGER check_department_chair
BEFORE UPDATE ON DEPARTMENT
FOR EACH ROW
BEGIN
    DECLARE teacher_exists INT;
    
    -- 檢查是否為該系所的教師
    IF NEW.Chair_ID IS NOT NULL THEN
        SELECT COUNT(*) INTO teacher_exists
        FROM TEACHER
        WHERE Teacher_ID = NEW.Chair_ID AND Department_ID = NEW.Department_ID;
        
        IF teacher_exists = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '系所主管必須是該系所的教師';
        END IF;
    END IF;
END//
DELIMITER ;

-- 防止衝堂的觸發器
DELIMITER //
CREATE TRIGGER prevent_schedule_conflict
BEFORE INSERT ON SCHEDULE
FOR EACH ROW
BEGIN
    DECLARE conflict_count INT;
    
    -- 檢查是否有教室衝突
    SELECT COUNT(*) INTO conflict_count
    FROM SCHEDULE
    WHERE Room_ID = NEW.Room_ID 
        AND Semester_ID = NEW.Semester_ID
        AND Day_Of_Week = NEW.Day_Of_Week
        AND ((Start_Time <= NEW.Start_Time AND End_Time > NEW.Start_Time)
            OR (Start_Time < NEW.End_Time AND End_Time >= NEW.End_Time)
            OR (Start_Time >= NEW.Start_Time AND End_Time <= NEW.End_Time));
    
    IF conflict_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '教室排課時段衝突';
    END IF;
END//
DELIMITER ;

-- 成績登錄後更新選課狀態的觸發器
DELIMITER //
CREATE TRIGGER update_enrollment_status
AFTER UPDATE ON ENROLLMENT
FOR EACH ROW
BEGIN
    IF NEW.Grade IS NOT NULL AND OLD.Grade IS NULL THEN
        IF NEW.Grade >= 60 THEN
            UPDATE ENROLLMENT SET Status = '通過' 
            WHERE Student_ID = NEW.Student_ID AND Course_ID = NEW.Course_ID AND Semester_ID = NEW.Semester_ID;
        ELSE
            UPDATE ENROLLMENT SET Status = '不通過' 
            WHERE Student_ID = NEW.Student_ID AND Course_ID = NEW.Course_ID AND Semester_ID = NEW.Semester_ID;
        END IF;
    END IF;
END//
DELIMITER ;

-- =====================================================
-- 插入範例資料
-- =====================================================

-- 系所資料
INSERT INTO DEPARTMENT (Department_ID, Name, Location, Phone, Established_Year, College) VALUES
('CS001', '資訊工程學系', '工程大樓A區', '02-2736-1661', 1980, '工學院'),
('EE001', '電機工程學系', '工程大樓B區', '02-2736-1662', 1975, '工學院'),
('ME001', '機械工程學系', '工程大樓C區', '02-2736-1663', 1970, '工學院'),
('BA001', '企業管理學系', '管理大樓A區', '02-2736-1664', 1985, '管理學院'),
('FN001', '財務金融學系', '管理大樓B區', '02-2736-1665', 1990, '管理學院'),
('LS001', '生命科學系', '理學院大樓A區', '02-2736-1666', 1982, '理學院'),
('CH001', '化學系', '理學院大樓B區', '02-2736-1667', 1965, '理學院'),
('MA001', '數學系', '理學院大樓C區', '02-2736-1668', 1960, '理學院');

-- 教師資料
INSERT INTO TEACHER (Teacher_ID, Name, Title, Email, Phone, Office_Location, Hire_Date, Department_ID) VALUES
('T00001', '張大為', '教授', 'chang@ntu.edu.tw', '02-3366-1001', '工程大樓A501', '1995-08-01', 'CS001'),
('T00002', '李明哲', '副教授', 'lee@ntu.edu.tw', '02-3366-1002', '工程大樓A502', '2000-02-01', 'CS001'),
('T00003', '王小華', '助理教授', 'wang@ntu.edu.tw', '02-3366-1003', '工程大樓A503', '2015-08-01', 'CS001'),
('T00004', '林志明', '教授', 'lin@ntu.edu.tw', '02-3366-1004', '工程大樓B501', '1998-08-01', 'EE001'),
('T00005', '陳大明', '教授', 'chen@ntu.edu.tw', '02-3366-1005', '工程大樓B502', '1990-08-01', 'EE001'),
('T00006', '吳小英', '副教授', 'wu@ntu.edu.tw', '02-3366-1006', '工程大樓C501', '2005-08-01', 'ME001'),
('T00007', '趙子龍', '教授', 'chao@ntu.edu.tw', '02-3366-1007', '管理大樓A501', '1997-08-01', 'BA001'),
('T00008', '楊美麗', '助理教授', 'yang@ntu.edu.tw', '02-3366-1008', '管理大樓B501', '2016-08-01', 'FN001'),
('T00009', '周文彬', '教授', 'chou@ntu.edu.tw', '02-3366-1009', '理學院大樓A501', '1993-08-01', 'LS001'),
('T00010', '許建民', '副教授', 'hsu@ntu.edu.tw', '02-3366-1010', '理學院大樓B501', '2002-08-01', 'CH001'),
('T00011', '洪世昌', '教授', 'hung@ntu.edu.tw', '02-3366-1011', '理學院大樓C501', '1991-08-01', 'MA001');

-- 更新系所主席
UPDATE DEPARTMENT SET Chair_ID = 'T00001' WHERE Department_ID = 'CS001';
UPDATE DEPARTMENT SET Chair_ID = 'T00004' WHERE Department_ID = 'EE001';
UPDATE DEPARTMENT SET Chair_ID = 'T00006' WHERE Department_ID = 'ME001';
UPDATE DEPARTMENT SET Chair_ID = 'T00007' WHERE Department_ID = 'BA001';
UPDATE DEPARTMENT SET Chair_ID = 'T00008' WHERE Department_ID = 'FN001';
UPDATE DEPARTMENT SET Chair_ID = 'T00009' WHERE Department_ID = 'LS001';
UPDATE DEPARTMENT SET Chair_ID = 'T00010' WHERE Department_ID = 'CH001';
UPDATE DEPARTMENT SET Chair_ID = 'T00011' WHERE Department_ID = 'MA001';

-- 教師專長
INSERT INTO TEACHER_EXPERTISE (Teacher_ID, Expertise) VALUES
('T00001', '資料庫系統'),
('T00001', '資料探勘'),
('T00001', '人工智慧'),
('T00002', '計算機網路'),
('T00002', '網路安全'),
('T00003', '軟體工程'),
('T00003', '物件導向設計'),
('T00004', '電路設計'),
('T00004', '半導體技術'),
('T00005', '通訊系統'),
('T00006', '機器學習'),
('T00006', '熱力學'),
('T00007', '企業策略'),
('T00007', '組織行為'),
('T00008', '財務分析'),
('T00008', '投資學'),
('T00009', '分子生物學'),
('T00010', '有機化學'),
('T00011', '微積分'),
('T00011', '線性代數');

-- 學生資料
INSERT INTO STUDENT (Student_ID, Name, Birth_Date, Gender, Email, Phone, Address, Admission_Year, Status, Department_ID) VALUES
('S10811001', '王小明', '2000-05-15', 'M', 's10811001@std.ntu.edu.tw', '0912-345-678', '台北市信義區信義路五段1號', 2019, '在學', 'CS001'),
('S10811002', '李佳琪', '2000-08-20', 'F', 's10811002@std.ntu.edu.tw', '0923-456-789', '台北市大安區和平東路一段2號', 2019, '在學', 'CS001'),
('S10811003', '陳小華', '2000-03-10', 'M', 's10811003@std.ntu.edu.tw', '0934-567-890', '台北市中正區重慶南路3號', 2019, '在學', 'CS001'),
('S10811004', '張美麗', '2001-12-05', 'F', 's10811004@std.ntu.edu.tw', '0945-678-901', '台北市大安區信義路4段4號', 2019, '在學', 'CS001'),
('S10811005', '林志明', '1999-11-25', 'M', 's10811005@std.ntu.edu.tw', '0956-789-012', '新北市板橋區文化路一段5號', 2019, '在學', 'CS001'),
('S10721001', '劉大偉', '1999-02-12', 'M', 's10721001@std.ntu.edu.tw', '0967-890-123', '台北市松山區民生東路6號', 2018, '在學', 'EE001'),
('S10721002', '趙小美', '1999-07-30', 'F', 's10721002@std.ntu.edu.tw', '0978-901-234', '台北市大安區復興南路7號', 2018, '在學', 'EE001'),
('S10731001', '黃建志', '1998-09-15', 'M', 's10731001@std.ntu.edu.tw', '0989-012-345', '台北市信義區松仁路8號', 2018, '在學', 'ME001'),
('S10741001', '吳美玲', '1999-01-20', 'F', 's10741001@std.ntu.edu.tw', '0990-123-456', '新北市板橋區民生路9號', 2018, '在學', 'BA001'),
('S10751001', '鄭志成', '1998-12-10', 'M', 's10751001@std.ntu.edu.tw', '0901-234-567', '台北市中山區中山北路10號', 2018, '在學', 'FN001'),
('S10761001', '許小婷', '2000-06-25', 'F', 's10761001@std.ntu.edu.tw', '0912-345-678', '台北市信義區永吉路11號', 2019, '在學', 'LS001'),
('S10771001', '蔡明翰', '1999-05-20', 'M', 's10771001@std.ntu.edu.tw', '0923-456-789', '新北市永和區永和路12號', 2019, '在學', 'CH001'),
('S10781001', '楊雅文', '2000-10-15', 'F', 's10781001@std.ntu.edu.tw', '0934-567-890', '台北市萬華區西園路13號', 2019, '在學', 'MA001'),
('S10911001', '郭小弘', '2001-04-05', 'M', 's10911001@std.ntu.edu.tw', '0945-678-901', '台北市北投區石牌路14號', 2020, '在學', 'CS001'),
('S10911002', '施美君', '2001-09-12', 'F', 's10911002@std.ntu.edu.tw', '0956-789-012', '新北市三重區重新路15號', 2020, '在學', 'CS001');

-- 學生聯絡人資料
INSERT INTO STUDENT_CONTACT (Student_ID, Contact_Name, Relationship, Phone, Email, Address, Is_Emergency) VALUES
('S10811001', '王大勇', '父親', '0922-333-444', 'wang_father@gmail.com', '台北市信義區信義路五段1號', TRUE),
('S10811001', '李小芬', '母親', '0933-444-555', 'lee_mother@gmail.com', '台北市信義區信義路五段1號', FALSE),
('S10811002', '李志明', '父親', '0944-555-666', 'lee_father@gmail.com', '台北市大安區和平東路一段2號', TRUE),
('S10811003', '陳大華', '父親', '0955-666-777', 'chen_father@gmail.com', '台北市中正區重慶南路3號', TRUE),
('S10811004', '張志偉', '父親', '0966-777-888', 'chang_father@gmail.com', '台北市大安區信義路4段4號', TRUE),
('S10811005', '林大明', '父親', '0977-888-999', 'lin_father@gmail.com', '新北市板橋區文化路一段5號', TRUE);

-- 教室資料
INSERT INTO CLASSROOM (Room_ID, Building, Room_Number, Capacity, Type, Has_Projector, Has_Computer) VALUES
('ENG101', '工程大樓', '101', 60, '一般教室', TRUE, TRUE),
('ENG102', '工程大樓', '102', 80, '一般教室', TRUE, TRUE),
('ENG201', '工程大樓', '201', 40, '電腦教室', TRUE, TRUE),
('ENG202', '工程大樓', '202', 60, '電腦教室', TRUE, TRUE),
('ENG301', '工程大樓', '301', 30, '實驗室', TRUE, TRUE),
('ENG302', '工程大樓', '302', 30, '實驗室', TRUE, TRUE),
('MNG101', '管理大樓', '101', 100, '演講廳', TRUE, TRUE),
('MNG102', '管理大樓', '102', 80, '一般教室', TRUE, TRUE),
('MNG201', '管理大樓', '201', 30, '一般教室', TRUE, FALSE),
('SCI101', '理學院大樓', '101', 120, '演講廳', TRUE, TRUE),
('SCI102', '理學院大樓', '102', 60, '一般教室', TRUE, TRUE),
('SCI201', '理學院大樓', '201', 40, '實驗室', TRUE, TRUE);

-- 學期資料
INSERT INTO SEMESTER (Semester_ID, Year, Term, Start_Date, End_Date, Registration_Start, Registration_End) VALUES
('112-1', 2023, '第一學期', '2023-09-11', '2024-01-19', '2023-08-21', '2023-09-01'),
('112-2', 2024, '第二學期', '2024-02-19', '2024-06-21', '2024-01-29', '2024-02-09'),
('112-3', 2024, '暑期', '2024-07-01', '2024-08-30', '2024-06-17', '2024-06-28'),
('111-1', 2022, '第一學期', '2022-09-12', '2023-01-20', '2022-08-22', '2022-09-02'),
('111-2', 2023, '第二學期', '2023-02-20', '2023-06-23', '2023-01-30', '2023-02-10'),
('111-3', 2023, '暑期', '2023-07-01', '2023-08-31', '2023-06-19', '2023-06-30');

-- 課程資料
INSERT INTO COURSE (Course_ID, Title, Description, Credits, Level, Hours_Per_Week, Department_ID) VALUES
('CS101001', '計算機概論', '本課程介紹計算機科學的基本概念，包括硬體、軟體、網路等。', 3, '大學部', 3, 'CS001'),
('CS201001', '資料結構', '本課程介紹基礎資料結構與演算法，包括陣列、鏈結串列、堆疊、佇列、樹狀結構及圖形等。', 3, '大學部', 3, 'CS001'),
('CS303001', '資料庫系統', '本課程介紹資料庫系統的設計與實作，包括關聯式資料庫理論、SQL語言及資料庫管理系統等。', 3, '大學部', 3, 'CS001'),
('CS305001', '計算機網路', '本課程介紹電腦網路相關概念和技術，包括TCP/IP協定、網路應用程式設計等。', 3, '大學部', 3, 'CS001'),
('CS406001', '軟體工程', '本課程介紹軟體開發生命週期、需求分析、系統設計、測試與軟體專案管理等。', 3, '大學部', 3, 'CS001'),
('CS505001', '機器學習', '本課程介紹機器學習理論與實作，包括監督式學習、非監督式學習及強化學習等。', 3, '研究所', 3, 'CS001'),
('EE201001', '電路學', '本課程介紹基本電路理論與分析方法，包括電阻、電容、電感等。', 3, '大學部', 3, 'EE001'),
('EE301001', '電子學', '本課程介紹半導體元件及其應用，包括二極體、電晶體等。', 3, '大學部', 3, 'EE001'),
('ME201001', '工程力學', '本課程介紹基本力學原理與工程應用，包括靜力學與動力學。', 3, '大學部', 3, 'ME001'),
('BA201001', '管理學', '本課程介紹組織管理的基本概念與理論，包括規劃、組織、領導與控制等。', 3, '大學部', 3, 'BA001'),
('FN201001', '財務管理', '本課程介紹企業財務決策理論與方法，包括資金成本、投資決策等。', 3, '大學部', 3, 'FN001'),
('LS201001', '細胞生物學', '本課程介紹細胞的結構、功能與生命週期，包括細胞分裂、代謝等。', 3, '大學部', 3, 'LS001'),
('CH201001', '有機化學', '本課程介紹有機化合物的結構、性質與反應，包括烷烴、醇類等。', 3, '大學部', 3, 'CH001'),
('MA201001', '微積分', '本課程介紹微積分的基本概念與應用，包括極限、微分與積分。', 3, '大學部', 3, 'MA001'),
('MA301001', '線性代數', '本課程介紹線性代數的基本概念與應用，包括向量空間、矩陣等。', 3, '大學部', 3, 'MA001'),
('CS501001', '演算法設計與分析', '本課程介紹各種演算法設計技巧與分析方法，包括分治法、動態規劃等。', 3, '研究所', 3, 'CS001'),
('CS502001', '人工智慧', '本課程介紹人工智慧的基本概念與技術，包括搜尋策略、知識表示等。', 3, '研究所', 3, 'CS001');

-- 課程先修關係
INSERT INTO COURSE_PREREQUISITE (Course_ID, Prerequisite_ID) VALUES
('CS201001', 'CS101001'),  -- 資料結構的先修為計算機概論
('CS303001', 'CS201001'),  -- 資料庫系統的先修為資料結構
('CS305001', 'CS201001'),  -- 計算機網路的先修為資料結構
('CS406001', 'CS303001'),  -- 軟體工程的先修為資料庫系統
('CS505001', 'CS201001'),  -- 機器學習的先修為資料結構
('CS501001', 'CS201001'),  -- 演算法設計與分析的先修為資料結構
('CS502001', 'CS201001'),  -- 人工智慧的先修為資料結構
('EE301001', 'EE201001'),  -- 電子學的先修為電路學
('MA301001', 'MA201001');  -- 線性代數的先修為微積分

-- 教授課程關係
INSERT INTO TEACHING (Teacher_ID, Course_ID, Semester_ID) VALUES
('T00001', 'CS303001', '112-1'),  -- 張大為教授資料庫系統(112-1)
('T00001', 'CS501001', '112-1'),  -- 張大為教授演算法設計與分析(112-1)
('T00002', 'CS305001', '112-1'),  -- 李明哲教授計算機網路(112-1)
('T00003', 'CS406001', '112-1'),  -- 王小華教授軟體工程(112-1)
('T00003', 'CS101001', '112-1'),  -- 王小華教授計算機概論(112-1)
('T00004', 'EE201001', '112-1'),  -- 林志明教授電路學(112-1)
('T00005', 'EE301001', '112-1'),  -- 陳大明教授電子學(112-1)
('T00006', 'ME201001', '112-1'),  -- 吳小英教授工程力學(112-1)
('T00007', 'BA201001', '112-1'),  -- 趙子龍教授管理學(112-1)
('T00008', 'FN201001', '112-1'),  -- 楊美麗教授財務管理(112-1)
('T00009', 'LS201001', '112-1'),  -- 周文彬教授細胞生物學(112-1)
('T00010', 'CH201001', '112-1'),  -- 許建民教授有機化學(112-1)
('T00011', 'MA201001', '112-1'),  -- 洪世昌教授微積分(112-1)
('T00011', 'MA301001', '112-1'),  -- 洪世昌教授線性代數(112-1)
('T00006', 'CS505001', '112-1'),  -- 吳小英教授機器學習(112-1)
('T00001', 'CS502001', '112-1'),  -- 張大為教授人工智慧(112-1)
('T00002', 'CS201001', '112-1');  -- 李明哲教授資料結構(112-1)

-- 課程安排
INSERT INTO SCHEDULE (Course_ID, Semester_ID, Room_ID, Day_Of_Week, Start_Time, End_Time) VALUES
('CS101001', '112-1', 'ENG101', 1, '09:00:00', '12:00:00'),  -- 計算機概論：週一上午9-12
('CS201001', '112-1', 'ENG102', 2, '13:00:00', '16:00:00'),  -- 資料結構：週二下午1-4
('CS303001', '112-1', 'ENG201', 3, '09:00:00', '12:00:00'),  -- 資料庫系統：週三上午9-12
('CS305001', '112-1', 'ENG202', 4, '13:00:00', '16:00:00'),  -- 計算機網路：週四下午1-4
('CS406001', '112-1', 'ENG101', 5, '09:00:00', '12:00:00'),  -- 軟體工程：週五上午9-12
('CS505001', '112-1', 'ENG102', 1, '13:00:00', '16:00:00'),  -- 機器學習：週一下午1-4
('EE201001', '112-1', 'ENG301', 2, '09:00:00', '12:00:00'),  -- 電路學：週二上午9-12
('EE301001', '112-1', 'ENG302', 3, '13:00:00', '16:00:00'),  -- 電子學：週三下午1-4
('ME201001', '112-1', 'ENG101', 2, '18:30:00', '21:30:00'),  -- 工程力學：週二晚上6:30-9:30
('BA201001', '112-1', 'MNG101', 1, '09:00:00', '12:00:00'),  -- 管理學：週一上午9-12
('FN201001', '112-1', 'MNG102', 3, '13:00:00', '16:00:00'),  -- 財務管理：週三下午1-4
('LS201001', '112-1', 'SCI101', 2, '13:00:00', '16:00:00'),  -- 細胞生物學：週二下午1-4
('CH201001', '112-1', 'SCI201', 4, '09:00:00', '12:00:00'),  -- 有機化學：週四上午9-12
('MA201001', '112-1', 'SCI102', 5, '13:00:00', '16:00:00'),  -- 微積分：週五下午1-4
('MA301001', '112-1', 'SCI102', 3, '09:00:00', '12:00:00'),  -- 線性代數：週三上午9-12
('CS501001', '112-1', 'ENG201', 1, '18:30:00', '21:30:00'),  -- 演算法設計與分析：週一晚上6:30-9:30
('CS502001', '112-1', 'ENG202', 4, '18:30:00', '21:30:00');  -- 人工智慧：週四晚上6:30-9:30

-- 學生選課資料
INSERT INTO ENROLLMENT (Student_ID, Course_ID, Semester_ID, Enrollment_Date, Grade, Status) VALUES
-- 資訊系王小明選課
('S10811001', 'CS101001', '112-1', '2023-08-25', NULL, '修課中'),
('S10811001', 'CS201001', '112-1', '2023-08-25', NULL, '修課中'),
('S10811001', 'CS303001', '112-1', '2023-08-25', NULL, '修課中'),
('S10811001', 'CS305001', '112-1', '2023-08-25', NULL, '修課中'),

-- 資訊系李佳琪選課
('S10811002', 'CS101001', '112-1', '2023-08-26', NULL, '修課中'),
('S10811002', 'CS201001', '112-1', '2023-08-26', NULL, '修課中'),
('S10811002', 'CS303001', '112-1', '2023-08-26', NULL, '修課中'),
('S10811002', 'MA201001', '112-1', '2023-08-26', NULL, '修課中'),

-- 資訊系陳小華選課
('S10811003', 'CS101001', '112-1', '2023-08-26', NULL, '修課中'),
('S10811003', 'CS201001', '112-1', '2023-08-26', NULL, '修課中'),
('S10811003', 'CS305001', '112-1', '2023-08-26', NULL, '修課中'),
('S10811003', 'MA201001', '112-1', '2023-08-26', NULL, '修課中'),

-- 資訊系張美麗選課
('S10811004', 'CS101001', '112-1', '2023-08-27', NULL, '修課中'),
('S10811004', 'CS201001', '112-1', '2023-08-27', NULL, '修課中'),
('S10811004', 'CS406001', '112-1', '2023-08-27', NULL, '修課中'),
('S10811004', 'MA201001', '112-1', '2023-08-27', NULL, '修課中'),

-- 資訊系林志明選課
('S10811005', 'CS101001', '112-1', '2023-08-27', NULL, '修課中'),
('S10811005', 'CS201001', '112-1', '2023-08-27', NULL, '修課中'),
('S10811005', 'CS303001', '112-1', '2023-08-27', NULL, '修課中'),
('S10811005', 'CS305001', '112-1', '2023-08-27', NULL, '修課中'),

-- 電機系劉大偉選課
('S10721001', 'EE201001', '112-1', '2023-08-25', NULL, '修課中'),
('S10721001', 'EE301001', '112-1', '2023-08-25', NULL, '修課中'),
('S10721001', 'CS101001', '112-1', '2023-08-25', NULL, '修課中'),
('S10721001', 'MA201001', '112-1', '2023-08-25', NULL, '修課中'),

-- 電機系趙小美選課
('S10721002', 'EE201001', '112-1', '2023-08-25', NULL, '修課中'),
('S10721002', 'EE301001', '112-1', '2023-08-25', NULL, '修課中'),
('S10721002', 'CS201001', '112-1', '2023-08-25', NULL, '修課中'),
('S10721002', 'MA301001', '112-1', '2023-08-25', NULL, '修課中'),

-- 機械系黃建志選課
('S10731001', 'ME201001', '112-1', '2023-08-28', NULL, '修課中'),
('S10731001', 'CS101001', '112-1', '2023-08-28', NULL, '修課中'),
('S10731001', 'MA201001', '112-1', '2023-08-28', NULL, '修課中'),

-- 企管系吳美玲選課
('S10741001', 'BA201001', '112-1', '2023-08-28', NULL, '修課中'),
('S10741001', 'FN201001', '112-1', '2023-08-28', NULL, '修課中'),
('S10741001', 'CS101001', '112-1', '2023-08-28', NULL, '修課中'),

-- 財金系鄭志成選課
('S10751001', 'FN201001', '112-1', '2023-08-29', NULL, '修課中'),
('S10751001', 'BA201001', '112-1', '2023-08-29', NULL, '修課中'),
('S10751001', 'MA201001', '112-1', '2023-08-29', NULL, '修課中'),

-- 生科系許小婷選課
('S10761001', 'LS201001', '112-1', '2023-08-29', NULL, '修課中'),
('S10761001', 'CH201001', '112-1', '2023-08-29', NULL, '修課中'),
('S10761001', 'MA201001', '112-1', '2023-08-29', NULL, '修課中'),

-- 化學系蔡明翰選課
('S10771001', 'CH201001', '112-1', '2023-08-30', NULL, '修課中'),
('S10771001', 'LS201001', '112-1', '2023-08-30', NULL, '修課中'),
('S10771001', 'MA201001', '112-1', '2023-08-30', NULL, '修課中'),

-- 數學系楊雅文選課
('S10781001', 'MA201001', '112-1', '2023-08-30', NULL, '修課中'),
('S10781001', 'MA301001', '112-1', '2023-08-30', NULL, '修課中'),
('S10781001', 'CS101001', '112-1', '2023-08-30', NULL, '修課中'),

-- 資訊系郭小弘選課
('S10911001', 'CS101001', '112-1', '2023-08-31', NULL, '修課中'),
('S10911001', 'MA201001', '112-1', '2023-08-31', NULL, '修課中'),

-- 資訊系施美君選課
('S10911002', 'CS101001', '112-1', '2023-08-31', NULL, '修課中'),
('S10911002', 'MA201001', '112-1', '2023-08-31', NULL, '修課中');

-- 社團資料
INSERT INTO CLUB (Club_ID, Name, Type, Established_Date, Description, Advisor_ID) VALUES
('C0001', '程式設計社', '學術性', '2010-09-01', '致力於推廣程式設計與軟體開發的社團，定期舉辦工作坊與競賽。', 'T00003'),
('C0002', '資訊安全研究社', '學術性', '2015-03-01', '研究資訊安全與駭客技術的社團，舉辦資安講座與CTF競賽。', 'T00002'),
('C0003', '機器人研究社', '學術性', '2012-09-01', '專注於機器人設計與人工智慧的社團，參與各類機器人競賽。', 'T00001'),
('C0004', '攝影社', '康樂性', '2008-09-01', '培養攝影興趣與技巧的社團，定期舉辦攝影展與外拍活動。', 'T00007'),
('C0005', '吉他社', '康樂性', '2005-09-01', '學習吉他演奏與音樂欣賞的社團，定期舉辦音樂會與講座。', 'T00008'),
('C0006', '籃球社', '體育性', '2007-09-01', '推廣籃球運動的社團，舉辦校內比賽與訓練課程。', 'T00006'),
('C0007', '志工服務社', '服務性', '2009-09-01', '組織各種志工服務活動，如社區服務、環保淨灘等。', 'T00009'),
('C0008', '創新創業社', '其他', '2018-09-01', '培養創業精神與創新思維的社團，舉辦創業競賽與講座。', 'T00007');

-- 社團成員資料
INSERT INTO CLUB_MEMBERSHIP (Student_ID, Club_ID, Join_Date, Position, Status) VALUES
('S10811001', 'C0001', '2019-09-15', '社長', '活躍'),
('S10811002', 'C0001', '2019-09-20', '副社長', '活躍'),
('S10811003', 'C0001', '2019-10-05', '社員', '活躍'),
('S10811004', 'C0001', '2019-10-10', '社員', '活躍'),
('S10811005', 'C0002', '2019-09-18', '社長', '活躍'),
('S10721001', 'C0002', '2018-10-01', '副社長', '活躍'),
('S10721002', 'C0002', '2018-10-05', '社員', '活躍'),
('S10731001', 'C0003', '2018-09-25', '社長', '活躍'),
('S10741001', 'C0004', '2018-10-15', '社員', '活躍'),
('S10751001', 'C0005', '2018-09-28', '社員', '活躍'),
('S10761001', 'C0006', '2019-09-22', '社員', '活躍'),
('S10771001', 'C0007', '2019-10-01', '社員', '活躍'),
('S10781001', 'C0008', '2019-09-30', '社長', '活躍'),
('S10911001', 'C0001', '2020-09-18', '社員', '活躍'),
('S10911002', 'C0001', '2020-09-20', '社員', '活躍'),
('S10811001', 'C0003', '2019-11-05', '社員', '活躍'),
('S10811002', 'C0004', '2019-10-25', '社員', '活躍'),
('S10811003', 'C0005', '2019-11-10', '社員', '活躍'),
('S10811004', 'C0007', '2019-12-01', '社員', '活躍');

-- 社團活動資料
INSERT INTO CLUB_ACTIVITY (Activity_ID, Club_ID, Name, Description, Start_Date, End_Date, Location, Budget, Status) VALUES
('A0000001', 'C0001', '程式設計新手工作坊', '為新加入社員舉辦的基礎程式設計工作坊，內容包括Python入門。', '2023-10-15', '2023-10-15', '工程大樓201教室', 5000.00, '已核准'),
('A0000002', 'C0001', '黑客松競賽', '24小時不間斷的程式開發競賽，鼓勵創新與團隊合作。', '2023-11-25', '2023-11-26', '工程大樓一樓大廳', 20000.00, '計劃中'),
('A0000003', 'C0002', '資安講座：網路威脅與防禦', '邀請業界專家分享最新的網路威脅趨勢與防禦策略。', '2023-10-20', '2023-10-20', '管理大樓101教室', 8000.00, '已核准'),
('A0000004', 'C0003', '機器人設計大賽', '校內機器人設計比賽，考驗參賽者的創意與技術。', '2023-12-05', '2023-12-05', '工程大樓一樓大廳', 15000.00, '審核中'),
('A0000005', 'C0004', '校園之美攝影展', '展示社員拍攝的校園風景與生活照片。', '2023-11-10', '2023-11-15', '圖書館藝廊', 10000.00, '已核准'),
('A0000006', 'C0005', '期末音樂會', '吉他社期末成果發表會，展示社員學習成果。', '2024-01-10', '2024-01-10', '學生活動中心禮堂', 12000.00, '計劃中'),
('A0000007', 'C0006', '系際籃球賽', '邀請各系組隊參加的籃球比賽，促進系際交流。', '2023-11-01', '2023-11-30', '體育館', 8000.00, '已核准'),
('A0000008', 'C0007', '冬季送暖活動', '到社區關懷獨居老人，送上禦寒物品與關懷。', '2023-12-20', '2023-12-22', '台北市信義區', 15000.00, '已核准'),
('A0000009', 'C0008', '創業講座：從零到一', '邀請成功創業家分享創業經驗與挑戰。', '2023-10-25', '2023-10-25', '管理大樓101教室', 6000.00, '已核准');

-- 學生活動參與資料
INSERT INTO ACTIVITY_PARTICIPATION (Student_ID, Activity_ID, Registration_Date, Role, Attendance) VALUES
('S10811001', 'A0000001', '2023-10-01', '主辦人', NULL),
('S10811002', 'A0000001', '2023-10-01', '講師', NULL),
('S10811003', 'A0000001', '2023-10-02', '參與者', NULL),
('S10811004', 'A0000001', '2023-10-03', '參與者', NULL),
('S10811005', 'A0000001', '2023-10-03', '參與者', NULL),
('S10811001', 'A0000002', '2023-11-01', '主辦人', NULL),
('S10811002', 'A0000002', '2023-11-01', '參與者', NULL),
('S10811003', 'A0000002', '2023-11-02', '參與者', NULL),
('S10811005', 'A0000003', '2023-10-05', '主辦人', NULL),
('S10721001', 'A0000003', '2023-10-06', '協辦人', NULL),
('S10721002', 'A0000003', '2023-10-07', '參與者', NULL),
('S10731001', 'A0000004', '2023-11-20', '主辦人', NULL),
('S10811001', 'A0000004', '2023-11-21', '參與者', NULL),
('S10741001', 'A0000005', '2023-10-25', '展出者', NULL),
('S10811002', 'A0000005', '2023-10-26', '展出者', NULL),
('S10751001', 'A0000006', '2023-12-15', '表演者', NULL),
('S10811003', 'A0000006', '2023-12-16', '表演者', NULL),
('S10761001', 'A0000007', '2023-10-20', '參賽者', NULL),
('S10771001', 'A0000008', '2023-12-01', '志工', NULL),
('S10811004', 'A0000008', '2023-12-02', '志工', NULL),
('S10781001', 'A0000009', '2023-10-10', '主辦人', NULL),
('S10751001', 'A0000009', '2023-10-11', '參與者', NULL);

-- 新增歷史學期的成績資料
INSERT INTO ENROLLMENT (Student_ID, Course_ID, Semester_ID, Enrollment_Date, Grade, Status) VALUES
-- 王小明的歷史成績
('S10811001', 'CS101001', '111-1', '2022-08-25', 85.5, '通過'),
('S10811001', 'MA201001', '111-1', '2022-08-25', 78.0, '通過'),
('S10811001', 'CS201001', '111-2', '2023-02-20', 90.5, '通過'),
('S10811001', 'MA301001', '111-2', '2023-02-20', 82.5, '通過'),

-- 李佳琪的歷史成績
('S10811002', 'CS101001', '111-1', '2022-08-26', 92.0, '通過'),
('S10811002', 'MA201001', '111-1', '2022-08-26', 88.5, '通過'),
('S10811002', 'CS201001', '111-2', '2023-02-21', 95.0, '通過'),
('S10811002', 'MA301001', '111-2', '2023-02-21', 89.5, '通過'),

-- 陳小華的歷史成績
('S10811003', 'CS101001', '111-1', '2022-08-26', 75.5, '通過'),
('S10811003', 'MA201001', '111-1', '2022-08-26', 68.0, '通過'),
('S10811003', 'CS201001', '111-2', '2023-02-22', 80.0, '通過'),
('S10811003', 'MA301001', '111-2', '2023-02-22', 72.5, '通過'),

-- 張美麗的歷史成績
('S10811004', 'CS101001', '111-1', '2022-08-27', 88.0, '通過'),
('S10811004', 'MA201001', '111-1', '2022-08-27', 91.5, '通過'),
('S10811004', 'CS201001', '111-2', '2023-02-23', 86.5, '通過'),
('S10811004', 'MA301001', '111-2', '2023-02-23', 93.0, '通過'),

-- 林志明的歷史成績
('S10811005', 'CS101001', '111-1', '2022-08-27', 79.5, '通過'),
('S10811005', 'MA201001', '111-1', '2022-08-27', 72.0, '通過'),
('S10811005', 'CS201001', '111-2', '2023-02-24', 81.0, '通過'),
('S10811005', 'MA301001', '111-2', '2023-02-24', 76.5, '通過'),

-- 劉大偉的歷史成績
('S10721001', 'CS101001', '111-1', '2022-08-25', 83.0, '通過'),
('S10721001', 'MA201001', '111-1', '2022-08-25', 77.5, '通過'),
('S10721001', 'EE201001', '111-2', '2023-02-20', 86.0, '通過'),
('S10721001', 'MA301001', '111-2', '2023-02-20', 80.5, '通過'),

-- 趙小美的歷史成績
('S10721002', 'CS101001', '111-1', '2022-08-25', 90.0, '通過'),
('S10721002', 'MA201001', '111-1', '2022-08-25', 85.5, '通過'),
('S10721002', 'EE201001', '111-2', '2023-02-21', 92.5, '通過'),
('S10721002', 'MA301001', '111-2', '2023-02-21', 88.0, '通過');

'