import '../../../core/adk/models/pipeline_models.dart';
import '../../chat/models/chat_models.dart';
import '../models/app_models.dart';
import '../models/app_template.dart';

class AppTemplatesData {
  static List<AppTemplate> templates = [
    AppTemplate(
      id: 'simple_chatbot',
      name: 'Simple Chatbot',
      description: 'A basic conversational bot suitable for general inquiries.',
      icon: '🤖',
      appType: AppType.chatbot,
      defaultConfig: {},
      pipelineSteps: [
        PipelineStep(
          id: 'start',
          nodeType: WorkflowNodeType.trigger,
          instruction: 'Start',
          uiPosition: {'x': 100, 'y': 300},
        ),
        PipelineStep(
          id: 'llm_analyze',
          nodeType: WorkflowNodeType.llm,
          instruction: 'Analyze Query',
          uiPosition: {'x': 350, 'y': 300},
          dependencies: ['start'],
          config: {
            'model': 'gpt-4o',
            'prompt': 'Analyze the user query: {{start.output}}',
            'structured_output': true, // Simulated
          },
        ),
        PipelineStep(
          id: 'code_fun_fact',
          nodeType: WorkflowNodeType.code,
          instruction: 'Get Fun Fact',
          uiPosition: {'x': 600, 'y': 300},
          dependencies: ['llm_analyze'],
          config: {
            'code': 'def main(country):\n  return {"fun_fact": "Simulated fun fact for " + country}',
          },
        ),
        PipelineStep(
          id: 'answer',
          nodeType: WorkflowNodeType.answer,
          instruction: 'Final Answer',
          uiPosition: {'x': 850, 'y': 300},
          dependencies: ['code_fun_fact'],
          config: {
            'answer_template': 'Here is the answer based on {{llm_analyze.output}} and fun fact: {{code_fun_fact.output}}',
          },
        ),
      ],
    ),
    AppTemplate(
      id: 'twitter_chatflow',
      name: 'Twitter Chatflow',
      description: 'Automate tweet processing and engagement.',
      icon: '🐦',
      appType: AppType.chatflow,
      defaultConfig: {},
      pipelineSteps: [
        PipelineStep(
          id: 'start',
          nodeType: WorkflowNodeType.userInput,
          instruction: 'User ID Input',
          uiPosition: {'x': 100, 'y': 300},
          config: {'variables': [{'name': 'id', 'type': 'string'}]},
        ),
        PipelineStep(
          id: 'code_url',
          nodeType: WorkflowNodeType.code,
          instruction: 'Format URL',
          uiPosition: {'x': 350, 'y': 300},
          dependencies: ['start'],
          config: {'code': 'def main(id):\n return {"url": "https://twitter.com/"+id}'},
        ),
        PipelineStep(
          id: 'http_crawl',
          nodeType: WorkflowNodeType.httpRequest,
          instruction: 'Crawl Profile',
          uiPosition: {'x': 600, 'y': 300},
          dependencies: ['code_url'],
          config: {
             'method': 'GET', 
             'url': '{{code_url.url}}',
             'headers': {'Authorization': 'Bearer <hidden>'}
          },
        ),
        PipelineStep(
          id: 'llm_analyze',
          nodeType: WorkflowNodeType.llm,
          instruction: 'Analyze Profile',
          uiPosition: {'x': 850, 'y': 300},
          dependencies: ['http_crawl'],
          config: {'prompt': 'Analyze this profile data: {{http_crawl.body}}'},
        ),
      ],
    ),
    AppTemplate(
      id: 'customer_service_bot',
      name: 'Customer Service Bot',
      description: 'Specialized agent for handling support tickets and FAQs.',
      icon: '🎧',
      appType: AppType.agent,
      defaultConfig: {},
      pipelineSteps: [
        PipelineStep(
          id: 'start',
          nodeType: WorkflowNodeType.trigger,
          instruction: 'Incoming Message',
          uiPosition: {'x': 100, 'y': 300},
        ),
        PipelineStep(
          id: 'classifier',
          nodeType: WorkflowNodeType.questionClassifier,
          instruction: 'Classify Intent',
          uiPosition: {'x': 350, 'y': 300},
          dependencies: ['start'],
          config: {'categories': ['Support', 'Sales', 'General']},
        ),
        PipelineStep(
          id: 'kb_retrieval',
          nodeType: WorkflowNodeType.knowledgeRetrieval,
          instruction: 'Search Docs',
          uiPosition: {'x': 600, 'y': 150},
          dependencies: ['classifier'], // Only if Support
          config: {'query': '{{start.output}}'},
        ),
        PipelineStep(
          id: 'llm_answer',
          nodeType: WorkflowNodeType.llm,
          instruction: 'Generate Reply',
          uiPosition: {'x': 850, 'y': 150},
          dependencies: ['kb_retrieval'],
          config: {'context': '{{kb_retrieval.results}}'},
        ),
        PipelineStep(
          id: 'direct_reply',
          nodeType: WorkflowNodeType.answer,
          instruction: 'Direct Reply',
          uiPosition: {'x': 600, 'y': 450},
          dependencies: ['classifier'], // If General
          config: {'text': 'Please clarify your request.'},
        ),
      ],
    ),
    AppTemplate(
      id: 'ai_image_gen',
      name: 'AI Image Generation App',
      description: 'Generate images from text descriptions using DALL-E or Stable Diffusion.',
      icon: '🎨',
      appType: AppType.textGenerator,
      defaultConfig: {},
      pipelineSteps: [
         PipelineStep(
          id: 'start',
          nodeType: WorkflowNodeType.userInput,
          instruction: 'Image Prompt',
          uiPosition: {'x': 100, 'y': 300},
        ),
         PipelineStep(
          id: 'agent_draw',
          nodeType: WorkflowNodeType.agent, // Or Tool Node
          agentType: MessageSender.creativeAgent,
          instruction: 'Generate Image',
          uiPosition: {'x': 400, 'y': 300},
          dependencies: ['start'],
          config: {'tool': 'stability_text2image', 'prompt': '{{start.input}}'},
        ),
        PipelineStep(
          id: 'output',
          nodeType: WorkflowNodeType.answer, // Display Image
          instruction: 'Show Image',
          uiPosition: {'x': 700, 'y': 300},
          dependencies: ['agent_draw'],
        ),
      ],
    ),
  ];

  static AppTemplate? getById(String id) {
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
