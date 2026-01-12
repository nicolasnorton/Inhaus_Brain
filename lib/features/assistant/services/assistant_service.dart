import 'dart:async';
import 'package:flutter/material.dart';
import 'assistant_tools.dart';

class AssistantMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isToolOutput;

  AssistantMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isToolOutput = false,
  });
}

class AssistantService {
  final List<AssistantMessage> _history = [];
  AssistantTools? _tools;

  List<AssistantMessage> get history => List.unmodifiable(_history);

  void setContext(BuildContext context) {
    _tools = AssistantTools(context);
  }

  Future<AssistantMessage> sendMessage(String text) async {
    // Add user message
    _history.add(AssistantMessage(
      id: DateTime.now().toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // Simulate AI processing & Tool calling
    await Future.delayed(const Duration(seconds: 1));

    String responseText = "I'm not sure how to help with that yet.";
    
    // Simple naive intent parsing for demo purposes
    // IN REALITY: This would call an LLM API which returns function calls
    if (text.toLowerCase().contains('navigate') || text.toLowerCase().contains('go to')) {
      if (text.toLowerCase().contains('settings')) {
        _tools?.tools['navigate']?.call({'route': '/settings'});
        responseText = "Navigating to Settings...";
      } else if (text.toLowerCase().contains('monitor')) {
        _tools?.tools['navigate']?.call({'route': '/monitor'});
        responseText = "Opening Monitor Dashboard...";
      } else if (text.toLowerCase().contains('campaigns')) {
        _tools?.tools['navigate']?.call({'route': '/campaigns'});
        responseText = "Taking you to Campaigns.";
      }
    } else if (text.toLowerCase().contains('create campaign')) {
       _tools?.tools['create_campaign']?.call({'title': 'New Campaign from Chat'});
       responseText = "Starting new campaign creation flow.";
    } else if (text.toLowerCase().contains('celebrate')) {
       _tools?.tools['confetti']?.call({});
       responseText = "Woohoo! 🎉";
    } else if (text.toLowerCase().contains('customer service')) {
       _tools?.tools['create_app_from_template']?.call({'template_id': 'customer_service_bot'});
       responseText = "I'm setting up a Customer Service Bot for you.";
    } else if (text.toLowerCase().contains('twitter')) {
       _tools?.tools['create_app_from_template']?.call({'template_id': 'twitter_chatflow'});
       responseText = "Creating a Twitter Chatflow app.";
    } else if (text.toLowerCase().contains('image generation')) {
       _tools?.tools['create_app_from_template']?.call({'template_id': 'ai_image_gen'});
       responseText = "Spinning up an AI Image Generation app template.";
    } else if (text.toLowerCase().contains('chatbot')) {
       _tools?.tools['create_app_from_template']?.call({'template_id': 'simple_chatbot'});
       responseText = "Creating a Simple Chatbot app.";
    } else {
      responseText = "I can help you create apps like 'Customer Service Bot', 'Twitter Flow', or navigate the app.";
    }

    final message = AssistantMessage(
      id: DateTime.now().toString(),
      text: responseText,
      isUser: false,
      timestamp: DateTime.now(),
      isToolOutput: false, // In a real system, we might show the tool output separately
    );

    _history.add(message);
    return message;
  }
  
  void clearHistory() {
    _history.clear();
  }
}
