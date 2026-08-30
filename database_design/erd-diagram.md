# ERD Diagram - رحلتي مع الإسلام

هذا رسم مبدئي لعلاقات قاعدة البيانات بصيغة Mermaid.

```mermaid
erDiagram
    USERS ||--|| PROFILES : has
    USERS }o--o{ ROLES : has
    ROLES }o--o{ PERMISSIONS : has

    PROFILES }o--|| LEVELS : current_level
    USERS ||--o{ USER_BADGES : earns
    BADGES ||--o{ USER_BADGES : assigned

    LEARNING_PATHS ||--o{ COURSES : contains
    COURSES ||--o{ COURSE_SECTIONS : contains
    COURSES ||--o{ LESSONS : contains
    COURSE_SECTIONS ||--o{ LESSONS : contains

    USERS ||--o{ COURSE_ENROLLMENTS : enrolls
    COURSES ||--o{ COURSE_ENROLLMENTS : has

    USERS ||--o{ LESSON_COMPLETIONS : completes
    LESSONS ||--o{ LESSON_COMPLETIONS : completed_by
    COURSES ||--o{ LESSON_COMPLETIONS : tracks

    LESSONS ||--o{ QUIZZES : has
    QUIZZES ||--o{ QUIZ_QUESTIONS : contains
    QUIZ_QUESTIONS ||--o{ QUIZ_ANSWERS : has
    USERS ||--o{ QUIZ_ATTEMPTS : attempts
    QUIZZES ||--o{ QUIZ_ATTEMPTS : attempted

    USERS ||--o{ USER_TASKS : assigned
    TASKS ||--o{ USER_TASKS : has

    USERS ||--|| MENTORS : may_be
    MENTORS ||--o{ MENTOR_STUDENTS : supervises
    USERS ||--o{ MENTOR_STUDENTS : student

    CONVERSATIONS ||--o{ CONVERSATION_PARTICIPANTS : has
    USERS ||--o{ CONVERSATION_PARTICIPANTS : joins
    CONVERSATIONS ||--o{ MESSAGES : contains
    USERS ||--o{ MESSAGES : sends

    LIBRARY_CATEGORIES ||--o{ LIBRARY_ITEMS : contains
    USERS ||--o{ CART_ITEMS : owns
    LIBRARY_ITEMS ||--o{ CART_ITEMS : added

    USERS ||--o{ ORDERS : places
    ORDERS ||--o{ ORDER_ITEMS : contains
    LIBRARY_ITEMS ||--o{ ORDER_ITEMS : purchased
    ORDERS ||--o{ PAYMENTS : paid_by

    USERS ||--o{ COMMISSIONS : earns
    ORDERS ||--o{ COMMISSIONS : generates
    USERS ||--o{ WITHDRAWAL_REQUESTS : requests

    COMMUNITY_GROUPS ||--o{ COMMUNITY_GROUP_MEMBERS : includes
    USERS ||--o{ COMMUNITY_GROUP_MEMBERS : member
    COMMUNITY_GROUPS ||--o{ COMMUNITY_POSTS : has
    USERS ||--o{ COMMUNITY_POSTS : writes
    COMMUNITY_POSTS ||--o{ COMMUNITY_COMMENTS : has
    USERS ||--o{ COMMUNITY_COMMENTS : comments
    COMMUNITY_POSTS ||--o{ COMMUNITY_LIKES : receives
    USERS ||--o{ COMMUNITY_LIKES : likes

    USERS ||--o{ NOTIFICATIONS : receives
    USERS ||--o{ SUPPORT_TICKETS : opens
    USERS ||--o{ AI_CHAT_LOGS : asks