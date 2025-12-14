# CASH App - Complete Flowchart

## 📱 Application Flow Diagram

```
                        ╔════════════════╗
                        ║   APP LAUNCH   ║
                        ╚═══════╤════════╝
                                │
                                ▼
                        ┌───────────────┐
                        │  Check Auth   │
                        │    Status     │
                        └───────┬───────┘
                                │
                                ▼
                            ╱       ╲
                          ╱   User   ╲        ◇ = Decision
                         ╱   Logged   ╲       □ = Process
                         ╲    In?     ╱       ⬭ = Input/Output
                          ╲         ╱        ╔╗ = Start/End
                            ╲     ╱
                              ╲ ╱
                               │
                  ┌────────────┼────────────┐
                  │ YES        │ NO         │
                  ▼            ▼            
          ┌──────────────┐  ┌──────────────┐
          │  DASHBOARD   │  │   LANDING    │
          │     PAGE     │  │     PAGE     │
          └──────────────┘  └──────┬───────┘
                                   │
                                   ▼
                          ⬭────────────────⬭
                          │ LOGIN SELECTION│
                          │  • Phone Login │
                          │  • Google OAuth│
                          ⬭────────┬───────⬭
                                   │
                                   ▼
                               ╱       ╲
                             ╱  Login   ╲
                            ╱   Method?  ╲
                            ╲           ╱
                             ╲         ╱
                               ╲     ╱
                                 ╲ ╱
                                  │
                    ┌─────────────┼─────────────┐
                    │ Phone       │ Google      │
                    ▼             ▼
          ┌──────────────────┐  ┌──────────────────┐
          │  REGISTRATION    │  │  Google OAuth    │
          │      PAGE        │  │  Authentication  │
          │ 1. Enter Name    │  └────────┬─────────┘
          │ 2. Enter Phone   │           │
          │ 3. Verify Phone  │           ▼
          │ 4. Set PIN       │       ╱       ╲
          │ 5. Setup Success │     ╱  OAuth   ╲
          └────────┬─────────┘    ╱  Success?  ╲
                   │              ╲           ╱
                   │               ╲         ╱
                   │                 ╲     ╱
                   │                   ╲ ╱
                   │                    │
                   │         ┌──────────┼──────────┐
                   │         │ YES      │ NO       │
                   │         │          │          │
                   │         │          └──► Show Error
                   │         │
                   └─────────┼────────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │   LOGIN PAGE     │
                    │  • Enter PIN     │
                    │  • Biometric     │
                    └────────┬─────────┘
                             │
                             ▼
                         ╱       ╲
                       ╱   Auth   ╲
                      ╱   Success?  ╲
                      ╲            ╱
                       ╲          ╱
                         ╲      ╱
                           ╲  ╱
                            │
                 ┌──────────┼──────────┐
                 │ YES      │ NO       │
                 ▼          ▼
        ┌──────────────┐  ┌──────────────┐
        │  Go to       │  │ Show Error & │
        │  Dashboard   │  │  Retry       │
        └──────────────┘  └──────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────────────┐
│                          DASHBOARD PAGE                               │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ HEADER                                                           ││
│  │ • User Avatar                                                    ││
│  │ • Welcome Message                                                ││
│  │ • Calendar Icon → Calendar View                                  ││
│  │ • Help Icon → User Guide                                         ││
│  │ • Logout Icon → Logout Dialog                                    ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ BALANCE CARD                                                     ││
│  │ • Total Balance Display                                          ││
│  │ • Show/Hide Balance Toggle                                       ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ QUICK ACTIONS                                                    ││
│  │ ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        ││
│  │ │   Scan   │  │   Add    │  │  History │  │ Reports  │        ││
│  │ │  Receipt │  │ Manual   │  │          │  │          │        ││
│  │ └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘        ││
│  │      │             │              │              │              ││
│  │      ▼             ▼              ▼              ▼              ││
│  │   [Scan]      [Manual]      [History]      [Reports]           ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ TRANSACTION SUMMARY                                              ││
│  │ • Cash In Count                                                  ││
│  │ • Cash Out Count                                                 ││
│  │ • Bar Chart (Last 7 Days)                                        ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ RECENT TRANSACTIONS (Last 5)                                     ││
│  │ • Transaction Type                                               ││
│  │ • Amount                                                         ││
│  │ • Date                                                           ││
│  │ • Tap → Transaction Details                                      ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ BOTTOM NAVIGATION                                                ││
│  │ [Home] [Transactions] [Scan] [AI Chat] [Settings]               ││
│  └─────────────────────────────────────────────────────────────────┘│
└───────────────────────────────────────────────────────────────────────┘
```

## 🔄 Transaction Flow

```
                    ╔════════════════════╗
                    ║ ADD TRANSACTION    ║
                    ╚═════════╤══════════╝
                              │
                              ▼
                          ╱       ╲
                        ╱  Entry   ╲
                       ╱   Method?  ╲
                       ╲           ╱
                        ╲         ╱
                          ╲     ╱
                            ╲ ╱
                             │
               ┌─────────────┼─────────────┐
               │ Scan        │ Manual      │
               ▼             ▼
       ⬭──────────────⬭  ┌──────────────┐
       │ SCAN OPTIONS │  │   MANUAL     │
       │ • Basic      │  │   ENTRY      │
       │ • Enhanced   │  │   FORM       │
       ⬭──────┬───────⬭  └──────┬───────┘
              │                  │
              ▼                  │
          ╱       ╲              │
        ╱  Scan    ╲             │
       ╱   Type?    ╲            │
       ╲           ╱             │
        ╲         ╱              │
          ╲     ╱                │
            ╲ ╱                  │
             │                   │
    ┌────────┼────────┐          │
    │ Basic  │Enhanced│          │
    ▼        ▼                   │
┌────────┐ ┌──────────┐          │
│ Basic  │ │Enhanced  │          │
│ Scan   │ │  Scan    │          │
└───┬────┘ └─────┬────┘          │
    │            │               │
    └────┬───────┘               │
         │                       │
         ▼                       │
    ┌──────────────┐             │
    │ OCR Service  │             │
    │ Extract Data │             │
    │ • Amount     │             │
    │ • Ref#       │             │
    │ • Name       │             │
    │ • Phone      │             │
    │ • Fee        │             │
    └──────┬───────┘             │
           │                     │
           └──────┬──────────────┘
                  │
                  ▼
         ⬭────────────────⬭
         │ RECEIPT PREVIEW│
         │  • Review Data │
         │  • Edit Fields │
         │  • View Image  │
         │  • Select Type │
         ⬭────────┬───────⬭
                  │
                  ▼
             ┌─────────┐
             │ Validate│
             │   Data  │
             └────┬────┘
                  │
                  ▼
              ╱       ╲
            ╱   Data   ╲
           ╱   Valid?   ╲
           ╲           ╱
            ╲         ╱
              ╲     ╱
                ╲ ╱
                 │
        ┌────────┼────────┐
        │ NO     │ YES    │
        ▼        ▼
  ┌──────────┐  ┌─────────┐
  │  Show    │  │  Check  │
  │  Error   │  │Duplicate│
  └────┬─────┘  └────┬────┘
       │             │
       │             ▼
       │         ╱       ╲
       │       ╱  Ref#    ╲
       │      ╱ Duplicate? ╲
       │      ╲           ╱
       │       ╲         ╱
       │         ╲     ╱
       │           ╲ ╱
       │            │
       │   ┌────────┼────────┐
       │   │ YES    │ NO     │
       │   ▼        ▼
       │ ┌───────┐ ┌────────┐
       │ │ Show  │ │  Save  │
       │ │Warning│ │ Trans. │
       │ └───────┘ └───┬────┘
       │               │
       │               ▼
       │         ╔═══════════╗
       │         ║  SUCCESS  ║
       │         ╚═════╤═════╝
       │               │
       └───────────────┼───────────
                       │
                       ▼
              ┌─────────────────┐
              │ Return to       │
              │   Dashboard     │
              └─────────────────┘
```

## 🤖 AI Assistant Flow

```
                    ╔════════════════╗
                    ║  AI CHAT PAGE  ║
                    ╚═══════╤════════╝
                            │
                            ▼
                   ⬭────────────────⬭
                   │ Chat Interface │
                   │  • Text Input  │
                   │  • Image Upload│
                   │  • Voice Input │
                   ⬭────────┬───────⬭
                            │
                            ▼
                        ╱       ╲
                      ╱  Input   ╲
                     ╱   Type?    ╲
                     ╲           ╱
                      ╲         ╱
                        ╲     ╱
                          ╲ ╱
                           │
              ┌────────────┼────────────┐
              │ Text       │ Image      │
              ▼            ▼
      ┌───────────────┐  ┌──────────────┐
      │  Gemini AI    │  │    Image     │
      │  Processing   │  │   Analysis   │
      │ • Parse Intent│  │ • OCR Extract│
      │ • Extract Info│  │ • Parse Data │
      └───────┬───────┘  └──────┬───────┘
              │                 │
              └────────┬────────┘
                       │
                       ▼
                   ╱       ╲
                 ╱  Intent  ╲
                ╱   Type?    ╲
                ╲           ╱
                 ╲         ╱
                   ╲     ╱
                     ╲ ╱
                      │
        ┌─────────────┼─────────────┐
        │Transaction  │ General     │
        ▼             ▼
⬭──────────────────⬭  ┌──────────────┐
│ Show Confirmation│  │   Provide    │
│  • Amount        │  │   Answer     │
│  • Recipient     │  │ • Balance    │
│  • Ref #         │  │ • Statistics │
│  • Fee           │  │ • Insights   │
│ [Confirm][Cancel]│  │ • Help       │
⬭────────┬─────────⬭  └──────────────┘
         │
         ▼
     ╱       ╲
   ╱  User    ╲
  ╱  Confirms? ╲
  ╲           ╱
   ╲         ╱
     ╲     ╱
       ╲ ╱
        │
   ┌────┼────┐
   │YES │NO  │
   ▼    ▼
┌────┐ ┌────┐
│Next│ │Back│
└─┬──┘ └────┘
  │
  ▼
┌─────────┐
│  Check  │
│Duplicate│
└────┬────┘
     │
     ▼
 ╱       ╲
╱  Ref#   ╲
╱Duplicate?╲
╲         ╱
 ╲       ╱
   ╲   ╱
     │
  ┌──┼──┐
  │YES│NO│
  ▼   ▼
┌────┐┌────┐
│Warn││Save│
└────┘└─┬──┘
        │
        ▼
  ╔═══════════╗
  ║  SUCCESS  ║
  ╚═══════════╝
```

## 📊 Transaction Management Flow

```
                 ╔══════════════════╗
                 ║ TRANSACTION LOGS ║
                 ╚════════╤═════════╝
                          │
                          ▼
                 ┌────────────────┐
                 │ Filter Panel   │
                 │ • Date Range   │
                 │ • Type         │
                 │ • Source       │
                 │ • Search       │
                 └────────┬───────┘
                          │
                          ▼
                 ⬭────────────────⬭
                 │ Transaction    │
                 │     List       │
                 ⬭────────┬───────⬭
                          │
                          ▼
                      ╱       ╲
                    ╱   User   ╲
                   ╱   Taps?    ╲
                   ╲           ╱
                    ╲         ╱
                      ╲     ╱
                        ╲ ╱
                         │
                    YES  │
                         ▼
                 ⬭────────────────⬭
                 │ Bottom Sheet   │
                 │  Details       │
                 │ • Amount       │
                 │ • Fee          │
                 │ • Total        │
                 │ • Ref #        │
                 │ • Source       │
                 │ • Date         │
                 │ [Delete Button]│
                 ⬭────────┬───────⬭
                          │
                          ▼
                      ╱       ╲
                    ╱  Delete  ╲
                   ╱  Clicked?  ╲
                   ╲           ╱
                    ╲         ╱
                      ╲     ╱
                        ╲ ╱
                         │
                    YES  │
                         ▼
                 ┌────────────────┐
                 │ Confirmation   │
                 │    Dialog      │
                 │[Cancel][Delete]│
                 └────────┬───────┘
                          │
                          ▼
                      ╱       ╲
                    ╱  Confirm ╲
                   ╱  Delete?   ╲
                   ╲           ╱
                    ╲         ╱
                      ╲     ╱
                        ╲ ╱
                         │
                ┌────────┼────────┐
                │ NO     │ YES    │
                ▼        ▼
           ┌────┐  ┌──────────┐
           │Back│  │  Delete  │
           └────┘  │from Fire-│
                   │  store   │
                   └─────┬────┘
                         │
                         ▼
                   ┌──────────┐
                   │ Update   │
                   │   UI     │
                   └──────────┘
```

## 📈 Reports Flow

```
                 ╔═══════════════╗
                 ║ REPORTS PAGE  ║
                 ╚═══════╤═══════╝
                         │
                         ▼
                     ╱       ╲
                   ╱  Report  ╲
                  ╱    Type?   ╲
                  ╲           ╱
                   ╲         ╱
                     ╲     ╱
                       ╲ ╱
                        │
         ┌──────────────┼──────────────┐
         │              │              │
         ▼              ▼              ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│   Daily     │ │  Monthly    │ │   Custom    │
│   Report    │ │  Report     │ │   Range     │
└──────┬──────┘ └──────┬──────┘ └──────┬──────┘
       │               │               │
       └───────────────┼───────────────┘
                       │
                       ▼
               ┌───────────────┐
               │   Calculate   │
               │ • Total In    │
               │ • Total Out   │
               │ • Net Balance │
               │ • Count       │
               │ • By Source   │
               │ • By Type     │
               └───────┬───────┘
                       │
                       ▼
               ⬭───────────────⬭
               │    Display    │
               │   Analytics   │
               │ • Charts      │
               │ • Graphs      │
               │ • Summaries   │
               │ • Export PDF  │
               ⬭───────────────⬭
```

## 📅 Calendar View Flow

```
                 ╔══════════════════╗
                 ║  CALENDAR VIEW   ║
                 ╚════════╤═════════╝
                          │
                          ▼
                 │ • Date Markers │
                 │ • Navigation   │
                 └────────┬───────┘
                          │
                          ▼
                      ╱       ╲
                    ╱   User   ╲
                   ╱  Selects   ╲
                   ╲   Date?   ╱
                    ╲         ╱
                      ╲     ╱
                        ╲ ╱
                         │
                    YES  │
                         ▼
                 ┌────────────────┐
                 │ Load Trans.    │
                 │ for Date       │
                 └────────┬───────┘
                          │
                          ▼
                 ⬭────────────────⬭
                 │ Display List   │
                 │ • Cash In      │
                 │ • Cash Out     │
                 │ • Daily Total  │
                 ⬭────────┬───────⬭
                          │
                          ▼
                      ╱       ╲
                    ╱   Tap    ╲
                   ╱Transaction?╲
                   ╲           ╱
                    ╲         ╱
                      ╲     ╱
                        ╲ ╱
                         │
                    YES  │
                         ▼
                 ┌────────────────┐
                 │ Transaction    │
                 │   Details      │
                 └────────────────┘
```

## ⚙️ Settings Flow

```
                 ╔═══════════════╗
                 ║ SETTINGS PAGE ║
                 ╚═══════╤═══════╝
                         │
                         ▼
                     ╱       ╲
                   ╱  Setting ╲
                  ╱  Selected? ╲
                  ╲           ╱
                   ╲         ╱
                     ╲     ╱
                       ╲ ╱
                        │
     ┌──────────────────┼──────────────────┬───────────┐
     │                  │                  │           │
     ▼                  ▼                  ▼           ▼
┌────────┐      ┌──────────┐      ┌───────────┐ ┌────────┐
│Profile │      │  Theme   │      │    Fee    │ │ Guide  │
│  Edit  │      │  Toggle  │      │  Settings │ └────────┘
└───┬────┘      └─────┬────┘      └─────┬─────┘
    │                 │                 │
    ▼                 ▼                 ▼
┌────────┐      ┌──────────┐      ┌───────────┐
│• Name  │      │ Switch   │      │  Adjust   │
│• Phone │      │Light/Dark│      │   Fees    │
│[Save]  │      └──────────┘      │Per Source │
└────────┘                        └───────────┘

     ┌────────────────────────┐
     │                        │
     ▼                        ▼
┌──────────┐         ┌─────────────┐
│Biometric │         │  Calendar   │
│  Toggle  │         │    View     │
└────┬─────┘         └─────────────┘
     │
     ▼
┌──────────────────┐
│Enable/Disable    │
│Face/Fingerprint  │
└──────────────────┘

     │
     ▼
 ╱       ╲
╱  Logout  ╲
╱  Clicked? ╲
╲          ╱
 ╲        ╱
   ╲    ╱
     ╲╱
      │
 YES  │
      ▼
┌──────────┐
│ Logout   │
│  Dialog  │
│[Cancel]  │
│[Logout]  │
└────┬─────┘
     │
     ▼
 ╱       ╲
╱  Confirm ╲
╱  Logout?  ╲
╲          ╱
 ╲        ╱
   ╲    ╱
     ╲╱
      │
 ┌────┼────┐
 │YES │NO  │
 ▼    ▼
┌──┐ ┌────┐
│Go│ │Back│
│to│ └────┘
│Lo-│
│gin│
└──┘
```

## 🔐 Authentication & Security Flow

```
                ╔═══════════════════╗
                ║ AUTHENTICATION    ║
                ║     SYSTEM        ║
                ╚═════════╤═════════╝
                          │
                          ▼
                      ╱       ╲
                    ╱   Auth   ╲
                   ╱   Method?  ╲
                   ╲           ╱
                    ╲         ╱
                      ╲     ╱
                        ╲ ╱
                         │
              ┌──────────┼──────────┐
              │Phone+PIN │ Google   │
              ▼          ▼
      ┌───────────┐  ┌──────────┐
      │   Phone   │  │  Google  │
      │ Verify    │  │ Sign-In  │
      │1.Enter Ph │  │1.Select  │
      │2.Verify   │  │2.Grant   │
      │3.Set PIN  │  │3.Create  │
      └─────┬─────┘  └────┬─────┘
            │             │
            └──────┬──────┘
                   │
                   ▼
             ┌──────────┐
             │  Create  │
             │   User   │
             │Firestore │
             │• User ID │
             │• Name    │
             │• Phone   │
             └────┬─────┘
                  │
                  ▼
             ┌──────────┐
             │  Store   │
             │ Session  │
             │(SharedPrf)│
             └────┬─────┘
                  │
                  ▼
            ╔═════════════╗
            ║  DASHBOARD  ║
            ╚═════════════╝

    ╔═══════════════════════╗
    ║    BIOMETRIC AUTH     ║
    ╚═══════════╤═══════════╝
                │
            ▼
        ┌──────────┐
        │  Check   │
        │ Device   │
        │Capability│
        └────┬─────┘
             │
             ▼
         ╱       ╲
       ╱ Device   ╲
      ╱ Supports?  ╲
      ╲           ╱
       ╲         ╱
         ╲     ╱
           ╲ ╱
            │
      ┌─────┼─────┐
      │YES  │NO   │
      ▼     ▼
   ┌────┐ ┌────┐
   │Show│ │Hide│
   │Opt │ └────┘
   └─┬──┘
     │
     ▼
 ╱       ╲
╱  User   ╲
╱ Enables? ╲
╲         ╱
 ╲       ╱
   ╲   ╱
     │
YES  │
     ▼
┌─────────┐
│  Store  │
│  Pref   │
└────┬────┘
     │
     ▼
 ╱       ╲
╱  Login  ╲
╱ Attempt? ╲
╲         ╱
 ╲       ╱
   ╲   ╱
     │
YES  │
     ▼
┌─────────┐
│  Show   │
│Biometric│
│ Prompt  │
└────┬────┘
     │
     ▼
 ╱       ╲
╱ Success? ╲
╲         ╱
 ╲       ╱
   ╲   ╱
    │
┌───┼───┐
│YES│NO │
▼   ▼
┌──┐┌───┐
│OK││PIN│
└──┘└───┘
```

## 💾 Data Flow

```
            ╔═══════════════════╗
            ║ DATA ARCHITECTURE ║
            ╚═════════╤═════════╝
                      │
                      ▼
              ┌───────────────┐
              │   App Layer   │
              │ (GetX State)  │
              └───────┬───────┘
                      │
                      ▼
                  ╱       ╲
                ╱ Storage  ╲
               ╱   Type?    ╲
               ╲           ╱
                ╲         ╱
                  ╲     ╱
                    ╲ ╱
                     │
          ┌──────────┼──────────┐
          │Local     │ Cloud    │
          ▼          ▼
    ┌──────────┐ ┌──────────┐
    │ SharedPrf│ │Firestore │
    │• Session │ │• Users   │
    │• PIN     │ │  -Data   │
    │• Bio Flag│ │• Trans.  │
    │• Theme   │ │  -userId │
    │• Settings│ │  -amount │
    └──────────┘ │  -fee    │
                 │  -refNo  │
                 │  -date   │
                 │  -type   │
                 │  -source │
                 │• Storage │
                 │  -Images │
                 └──────────┘

    ╔═══════════════════════╗
    ║ TRANSACTION LIFECYCLE ║
    ╚═══════════╤═══════════╝
                │
                ▼
          ╔═══════════╗
          ║  CREATE   ║
          ╚═════╤═════╝
                │
                ▼
          ┌──────────┐
          │ Validate │
          │• Required│
          │• Dup Chk │
          │• Format  │
          └────┬─────┘
               │
               ▼
           ╱       ╲
         ╱  Valid?  ╲
        ╱           ╲
        ╲           ╱
         ╲         ╱
           ╲     ╱
             ╲ ╱
              │
        ┌─────┼─────┐
        │YES  │NO   │
        ▼     ▼
    ┌────┐ ┌─────┐
    │Save│ │Error│
    │to  │ └─────┘
    │Fire│
    │stor│
    └─┬──┘
      │
      ▼
 ┌─────────┐
 │ Update  │
 │ State   │
 │ (GetX)  │
 └────┬────┘
      │
      ▼
 ┌─────────┐
 │Refresh  │
 │   UI    │
 └────┬────┘
      │
      ▼
  ╱       ╲
╱   User   ╲
╱  Action?  ╲
╲          ╱
 ╲        ╱
   ╲    ╱
     ╲╱
      │
  ┌───┼───┐
  │Edt│Del│
  ▼   ▼
┌───┐┌───┐
│Upd││Del│
│DB ││DB │
└───┘└───┘
```

## 🎯 Key Features Integration

```
            ╔═══════════════════╗
            ║ FEATURE ECOSYSTEM ║
            ╚═════════╤═════════╝
                      │
                      ▼
                  ╱       ╲
                ╱ Feature  ╲
               ╱   Type?    ╲
               ╲           ╱
                ╲         ╱
                  ╲     ╱
                    ╲ ╱
                     │
      ┌──────────────┼──────────────┐
      │              │              │
      ▼              ▼              ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│   OCR    │  │    AI    │  │Analytics │
│ System   │  │Assistant │  │          │
│• Extract │  │• Gemini  │  │• Charts  │
│• Process │  │• NLP     │  │• Reports │
│• Match   │  │• Voice   │  │• Export  │
└────┬─────┘  └────┬─────┘  └────┬─────┘
     │             │             │
     └─────────────┼─────────────┘
                   │
                   ▼
           ┌───────────────┐
           │ Transaction   │
           │   Service     │
           └───────┬───────┘
                   │
                   ▼
           ╔═══════════════╗
           ║   FIRESTORE   ║
           ╚═══════════════╝
```

## 🔄 State Management Flow

```
            ╔═══════════════════════╗
            ║  GetX STATE MGMT      ║
            ╚═════════╤═════════════╝
                      │
                      ▼
              ┌───────────────┐
              │ App Controller│
              │ • userName    │
              │ • phone       │
              │ • userId      │
              │ • pin         │
              └───────┬───────┘
                      │
                      ▼
                  ╱       ╲
                ╱Controller╲
               ╱   Type?    ╲
               ╲           ╱
                ╲         ╱
                  ╲     ╱
                    ╲ ╱
                     │
      ┌──────────────┼──────────────┐
      │              │              │
      ▼              ▼              ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│Dashboard │  │  Gemini  │  │  Theme   │
│• Balance │  │• Chat    │  │• isDark  │
│• Trans.  │  │• Messages│  │• toggle()│
│• Analytic│  │• Actions │  └──────────┘
└────┬─────┘  └────┬─────┘
     │             │
     └─────────────┘
                   │
                   ▼
           ┌───────────────┐
           │  Reactive UI  │
           │  (Obx/GetX)   │
           └───────────────┘
```

---

## 📋 Legend

**Flowchart Symbols:**
- `╔══╗` `╚══╝` - Start/End (Oval/Terminal)
- `┌──┐` `└──┘` - Process (Rectangle)
- `⬭──⬭` - Input/Output (Parallelogram)
- `╱ ╲` `╲ ╱` - Decision (Diamond)
- `▼` `│` - Flow Direction
- `├──` `┬` - Branch Points
- `YES/NO` - Decision Outcomes

---

## 🎨 Page Count Summary

**Total Pages: 20+**

1. Landing Page
2. Login Selection Page
3. Registration Page
4. Phone Verification Page
5. Set PIN Page
6. Success Setup Page
7. Login Page
8. Dashboard Page
9. Scan Page
10. Enhanced Scan Page
11. Receipt Preview Page
12. Transaction Page (Manual Entry)
13. Transaction Logs Page
14. History Page
15. Reports Page
16. Calendar View Page
17. AI Chat Page
18. Custom Image Analysis Page
19. Settings Page
20. Profile Edit Page
21. Fee Settings Page
22. User Guide Page
23. Verification Success Page

**Core Services: 7**
- Transaction Service
- OCR Service
- Biometric Auth Service
- Google Sign-In Service
- Gemini AI Service
- Firebase Service
- Storage Service

**State Controllers: 4**
- App Controller
- Dashboard Controller
- Gemini Controller
- Theme Controller

---

*This flowchart represents the complete application architecture and user journey through the CASH app.*
