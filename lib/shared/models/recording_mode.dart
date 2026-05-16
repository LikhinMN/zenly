import 'package:flutter/material.dart';

enum RecordingMode {
  email,
  chat,
  notes,
  code,
  essay,
  todo,
}

extension RecordingModeExtension on RecordingMode {
  String get label {
    switch (this) {
      case RecordingMode.email: return 'Email';
      case RecordingMode.chat: return 'Chat';
      case RecordingMode.notes: return 'Notes';
      case RecordingMode.code: return 'Code';
      case RecordingMode.essay: return 'Essay';
      case RecordingMode.todo: return 'Todo';
    }
  }

  String get emoji {
    switch (this) {
      case RecordingMode.email:
        return '📧';
      case RecordingMode.chat:
        return '💬';
      case RecordingMode.notes:
        return '📝';
      case RecordingMode.code:
        return '💻';
      case RecordingMode.essay:
        return '📄';
      case RecordingMode.todo:
        return '✅';
    }
  }

  IconData get icon {
    switch (this) {
      case RecordingMode.email:
        return Icons.email_outlined;
      case RecordingMode.chat:
        return Icons.chat_bubble_outline;
      case RecordingMode.notes:
        return Icons.notes;
      case RecordingMode.code:
        return Icons.code;
      case RecordingMode.essay:
        return Icons.article_outlined;
      case RecordingMode.todo:
        return Icons.check_box_outlined;
    }
  }

  String get description {
    switch (this) {
      case RecordingMode.email: return 'Formal, with subject & sign-off';
      case RecordingMode.chat: return 'Casual, short & conversational';
      case RecordingMode.notes: return 'Bullet points, structured';
      case RecordingMode.code: return 'Technical, camelCase formatted';
      case RecordingMode.essay: return 'Flowing prose, paragraphs';
      case RecordingMode.todo: return 'Extracted action items';
    }
  }

  String get prompt {
    switch (this) {
      case RecordingMode.email:
        return '''Transform this raw voice transcript into a clean, professional email.
- Add a suitable subject line
- Use formal greeting and sign-off
- Fix grammar and remove filler words (um, uh, like, you know)
- Format into proper paragraphs
- Keep the original intent and content

Raw transcript:''';

      case RecordingMode.chat:
        return '''Transform this raw voice transcript into a casual chat message.
- Keep it short and conversational
- Remove filler words and stammers
- Fix obvious errors but keep the casual tone
- No formal greetings or sign-offs
- Sound natural, like a text message

Raw transcript:''';

      case RecordingMode.notes:
        return '''Transform this raw voice transcript into clean structured notes.
- Use bullet points
- Group related ideas together
- Remove filler words and repetition
- Use clear, concise language
- Add a brief title at the top

Raw transcript:''';

      case RecordingMode.code:
        return '''Transform this raw voice transcript into technical documentation or code comments.
- Use technical language
- Format variable names in camelCase
- Structure as code comments or technical notes
- Remove all filler words
- Be precise and unambiguous

Raw transcript:''';

      case RecordingMode.essay:
        return '''Transform this raw voice transcript into polished essay-style prose.
- Write in flowing, connected paragraphs
- Remove all filler words and repetition
- Improve sentence structure and flow
- Keep the original ideas and arguments
- Use sophisticated vocabulary where appropriate

Raw transcript:''';

      case RecordingMode.todo:
        return '''Extract all action items and tasks from this raw voice transcript.
- List each task as a checkbox item (- [ ] task)
- Start each with an action verb
- Remove any non-actionable content
- Order by priority if clear from context
- Be specific and concrete

Raw transcript:''';
    }
  }
}