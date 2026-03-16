# Eventify 📅

**Eventify** is an intelligent iOS calendar assistant designed to bridge the gap between unstructured text and your organized life. It leverages a hybrid parsing engine to transform complex university timetables and casual natural language into system events with just one click.

---

## 🌟 Features

- **Hybrid Parsing Engine**: 
  - **Local Layer**: High-resiliency regex patterns for university timetables and structured single-line events. Works offline, respects privacy, and saves AI tokens.
  - **AI Layer**: OpenAI-compatible API integration for parsing unstructured natural language or spoken schedule descriptions.
- **One-Click Integration**: Seamlessly saves identified events directly to your local Apple Calendar.
- **Privacy First**: Localized parsing ensures your data never leaves the device unless AI assistance is explicitly requested.
- **Developer Friendly**: Built with SwiftUI, highly modular, and easily customizable.

---

## 🚀 Usage & Formats

Eventify supports various formats for maximum efficiency. For best results (and to save tokens), use the structured local formats.

### 1. Simple Single-Line (Local)
Perfect for quick meetings or reminders.
- **Format**: `Title [Space] Date [Space] StartTime-EndTime`
- **Example**: `Meeting with The42nd 3.18 2:00PM-4:00PM`

### 2. University Timetable (Local)
Handles semester-long blocks with automated recurring dates.
- **Example**:
  ```text
  COMP 1234 - Programming Java
  Monday 10:15AM-12:05PM
  Building 101 Room 202
  01/03/2026 - 15/06/2026
  ```

### 3. Natural Language (AI)
Just describe your plans as you would to a friend.
- **Example**: "Hey, I have a dentist appointment tomorrow from 9 to 11 am at City Hospital."

---

## 🔧 Customization

You can tailor Eventify to your specific needs by modifying these files:

- **Connect Your AI**: Add your API key and base URL in `OpenAICompatibleClient.swift` to enable full natural language parsing.
- **Personalize Formats**: Adjust the regex logic in `LocalTextParser.swift` to match your school or company's specific timetable style for zero-latency local recognition.

---

## 🛡 License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**.

- **Copyright © 2026 The42nd Foundation.**
- You are free to use, modify, and distribute this software, provided that any derivative works are also open-sourced under the same GPL-3.0 license.
- See the [LICENSE](LICENSE) file for the full text.

---

Built with ❤️ for efficiency by **The42nd Foundation**.
