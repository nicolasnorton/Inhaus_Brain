import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ag_ui/ag_ui.dart' hide State;
import 'package:go_router/go_router.dart';
import '../../assistant/presentation/widgets/gen_ui/gen_ui_renderer.dart';
import '../../assistant/presentation/widgets/gen_ui/atomic_ui_renderer.dart';

class _ComponentDoc {
  final String name;
  final String category;
  final String description;
  final String usageJson;
  final Map<String, dynamic> previewPayload;
  final List<Map<String, String>> props;

  const _ComponentDoc({
    required this.name,
    required this.category,
    required this.description,
    required this.usageJson,
    required this.previewPayload,
    required this.props,
  });
}

class ComposerComponentsScreen extends StatefulWidget {
  const ComposerComponentsScreen({super.key});

  @override
  State<ComposerComponentsScreen> createState() => _ComposerComponentsScreenState();
}

class _ComposerComponentsScreenState extends State<ComposerComponentsScreen> {
  final List<_ComponentDoc> _docs = [
    _ComponentDoc(
      name: 'Row',
      category: 'Layout',
      description: 'Horizontal flex container that arranges children in a row with configurable alignment and distribution.',
      usageJson: '''{
  "id": "row-1",
  "component": {
    "Row": {
      "alignment": "center",
      "distribution": "spaceBetween",
      "children": {
        "explicitList": ["child-1", "child-2"]
      }
    }
  }
}''',
      previewPayload: {
        "id": "row-demo",
        "component": {
          "Row": {"distribution": "spaceEvenly", "alignment": "center", "gap": "medium"}
        },
        "children": [
          {"id": "r1", "component": {"FilledButton": {"label": "Action 1"}}},
          {"id": "r2", "component": {"OutlinedButton": {"label": "Action 2"}}},
          {"id": "r3", "component": {"TextButton": {"label": "Action 3"}}},
        ]
      },
      props: [
        {'Name': 'children', 'Description': 'Child components to render inside the row.', 'Type': 'ComponentArrayReference', 'Default': '-'},
        {'Name': 'alignment', 'Description': 'Vertical alignment ("start", "center", "end", "stretch").', 'Type': 'String', 'Default': 'stretch'},
        {'Name': 'distribution', 'Description': 'Horizontal distribution ("start", "center", "end", "spaceBetween", "spaceAround", "spaceEvenly").', 'Type': 'String', 'Default': 'start'},
      ],
    ),
    _ComponentDoc(
      name: 'Column',
      category: 'Layout',
      description: 'Vertical flex container that arranges children in a column.',
      usageJson: '''{
  "id": "col-1",
  "component": {
    "Column": {
      "alignment": "stretch",
      "distribution": "start",
      "gap": "medium",
      "children": {
        "explicitList": ["child-1", "child-2"]
      }
    }
  }
}''',
      previewPayload: {
        "id": "col-demo",
        "component": {
          "Column": {"gap": "medium", "alignment": "stretch"}
        },
        "children": [
          {"id": "c1", "component": {"Text": {"text": "First Item", "style": "titleMedium", "bold": true}}},
          {"id": "c2", "component": {"Divider": {}}},
          {"id": "c3", "component": {"Text": {"text": "Second Item", "style": "bodyMedium"}}},
          {"id": "c4", "component": {"Text": {"text": "Third Item", "style": "bodySmall", "color": "grey"}}},
        ]
      },
      props: [
        {'Name': 'children', 'Description': 'Child components inside the column.', 'Type': 'ComponentArrayReference', 'Default': '-'},
        {'Name': 'gap', 'Description': 'Spacing between children ("none", "small", "medium", "large").', 'Type': 'String', 'Default': 'none'},
      ],
    ),
    _ComponentDoc(
       name: 'Text',
       category: 'Content',
       description: 'Displays a string of stylized text.',
       usageJson: '''{
  "id": "text-1",
  "component": {
    "Text": {
      "text": { "value": "Hello World" },
      "style": "headline",
      "alignment": "center",
      "color": "primary"
    }
  }
}''',
       previewPayload: {
         "id": "text-demo",
         "component": {
           "Column": {"gap": "small"}
         },
         "children": [
           {"id": "t1", "component": {"Text": {"text": "Display Small", "style": "displaySmall"}}},
           {"id": "t2", "component": {"Text": {"text": "Headline Medium", "style": "headlineMedium"}}},
           {"id": "t3", "component": {"Text": {"text": "Title Large", "style": "titleLarge", "bold": true}}},
           {"id": "t4", "component": {"Text": {"text": "Body Medium — standard reading text.", "style": "bodyMedium"}}},
           {"id": "t5", "component": {"Text": {"text": "Label Small", "style": "labelSmall", "color": "grey"}}},
         ]
       },
       props: [
         {'Name': 'text', 'Description': 'The string to display.', 'Type': 'Resolvable<String>', 'Default': '-'},
         {'Name': 'style', 'Description': 'Typography style ("body", "headline", "subhead", "caption", "code").', 'Type': 'String', 'Default': 'body'},
         {'Name': 'color', 'Description': 'Text color intent ("primary", "secondary", "error", "success").', 'Type': 'String', 'Default': 'primary'},
       ],
    ),
    _ComponentDoc(
       name: 'Button',
       category: 'Navigation',
       description: 'A clickable button that can trigger actions or navigation.',
       usageJson: '''{
  "id": "btn-1",
  "component": {
    "Button": {
      "label": { "value": "Submit" },
      "style": "filled",
      "onTap": { "url": "https://example.com" }
    }
  }
}''',
       previewPayload: {
         "id": "btn-demo",
         "component": {
           "Wrap": {"spacing": 8, "runSpacing": 8}
         },
         "children": [
           {"id": "b1", "component": {"ElevatedButton": {"label": "Elevated"}}},
           {"id": "b2", "component": {"FilledButton": {"label": "Filled"}}},
           {"id": "b3", "component": {"FilledTonalButton": {"label": "Filled Tonal"}}},
           {"id": "b4", "component": {"OutlinedButton": {"label": "Outlined"}}},
           {"id": "b5", "component": {"TextButton": {"label": "Text"}}},
           {"id": "b6", "component": {"IconButton": {"icon": "favorite", "tooltip": "Like"}}},
         ]
       },
       props: [
         {'Name': 'label', 'Description': 'Text inside the button.', 'Type': 'Resolvable<String>', 'Default': '-'},
         {'Name': 'style', 'Description': 'Visual style ("filled", "outlined", "text").', 'Type': 'String', 'Default': 'filled'},
       ],
    ),
    _ComponentDoc(
       name: 'List',
       category: 'Layout',
       description: 'A vertical, scrollable list of components.',
       usageJson: '''{
  "id": "list-1",
  "component": {
    "List": {
      "children": {
        "explicitList": ["item-1", "item-2"]
      }
    }
  }
}''',
       previewPayload: {
         "id": "list-demo",
         "component": {"Column": {"gap": "small"}},
         "children": [
           {"id": "li1", "component": {"ListTile": {"title": "Inbox", "subtitle": "3 new messages", "leadingIcon": "email", "trailingIcon": "chevron_right"}}},
           {"id": "li2", "component": {"ListTile": {"title": "Settings", "subtitle": "Account, notifications", "leadingIcon": "settings", "trailingIcon": "chevron_right"}}},
           {"id": "li3", "component": {"ListTile": {"title": "Help", "leadingIcon": "help", "trailingIcon": "chevron_right"}}},
         ]
       },
       props: [
         {'Name': 'children', 'Description': 'Child components inside the list.', 'Type': 'ComponentArrayReference', 'Default': '-'},
       ],
    ),
    _ComponentDoc(
       name: 'Card',
       category: 'Layout',
       description: 'A container with a background, border radius, and typical elevation/shadow styling.',
       usageJson: '''{
  "id": "card-1",
  "component": {
    "Card": {
      "child": "content-id"
    }
  }
}''',
       previewPayload: {
         "id": "card-demo",
         "component": {"Card": {"elevation": 2, "borderRadius": 16}},
         "children": [
           {"id": "ct", "component": {"Padding": {"padding": 16}}, "children": [
             {"id": "ct1", "component": {"Text": {"text": "Material 3 Card", "style": "titleLarge", "bold": true}}},
             {"id": "ct2", "component": {"SizedBox": {"height": 8}}},
             {"id": "ct3", "component": {"Text": {"text": "Cards contain content and actions about a single subject.", "style": "bodyMedium", "color": "grey"}}},
             {"id": "ct4", "component": {"SizedBox": {"height": 12}}},
             {"id": "ct5", "component": {"Row": {"distribution": "end", "gap": "medium"}}, "children": [
               {"id": "ct6", "component": {"OutlinedButton": {"label": "Cancel"}}},
               {"id": "ct7", "component": {"FilledButton": {"label": "OK"}}},
             ]},
           ]},
         ]
       },
       props: [
         {'Name': 'child', 'Description': 'The content of the card.', 'Type': 'String', 'Default': '-'},
       ],
    ),
    _ComponentDoc(
       name: 'Image',
       category: 'Content',
       description: 'Displays an image from a URL or asset path.',
       usageJson: '''{
  "id": "img-1",
  "component": {
    "Image": {
      "url": "https://example.com/image.png",
      "fit": "cover"
    }
  }
}''',
       previewPayload: {
         "id": "img-demo",
         "component": {"Image": {"url": "https://picsum.photos/300/200", "fit": "cover", "borderRadius": 12, "width": 300, "height": 200}}
       },
       props: [
         {'Name': 'url', 'Description': 'The image source URL.', 'Type': 'String', 'Default': '-'},
         {'Name': 'fit', 'Description': 'How the image should be inscribed into the box ("cover", "contain", "fill").', 'Type': 'String', 'Default': 'cover'},
       ],
    ),
    _ComponentDoc(
       name: 'Icon',
       category: 'Content',
       description: 'Displays a standard Material icon.',
       usageJson: '''{
  "id": "icon-1",
  "component": {
    "Icon": {
      "icon": "settings",
      "color": "primary",
      "size": 24.0
    }
  }
}''',
       previewPayload: {
         "id": "icon-demo",
         "component": {"Wrap": {"spacing": 16, "runSpacing": 16}},
         "children": [
           {"id": "i1", "component": {"Icon": {"icon": "home", "size": 32, "color": "primary"}}},
           {"id": "i2", "component": {"Icon": {"icon": "settings", "size": 32, "color": "secondary"}}},
           {"id": "i3", "component": {"Icon": {"icon": "favorite", "size": 32, "color": "error"}}},
           {"id": "i4", "component": {"Icon": {"icon": "star", "size": 32, "color": "amber"}}},
           {"id": "i5", "component": {"Icon": {"icon": "bolt", "size": 32, "color": "teal"}}},
         ]
       },
       props: [
         {'Name': 'icon', 'Description': 'Material icon string identifier.', 'Type': 'String', 'Default': '-'},
         {'Name': 'color', 'Description': 'Color intent ("primary", "secondary", etc).', 'Type': 'String', 'Default': 'primary'},
         {'Name': 'size', 'Description': 'Icon size in logical pixels.', 'Type': 'Number', 'Default': '24.0'},
       ],
    ),
    _ComponentDoc(
       name: 'Video',
       category: 'Content',
       description: 'A video player component.',
       usageJson: '''{
  "id": "vid-1",
  "component": {
    "Video": {
      "url": "https://example.com/video.mp4",
      "autoPlay": false
    }
  }
}''',
       previewPayload: {
         "id": "vid-demo",
         "component": {"Text": {"text": "Video Player requires a URL. See the GenUI Video docs.", "style": "bodySmall", "color": "grey"}}
       },
       props: [
         {'Name': 'url', 'Description': 'The video source URL.', 'Type': 'String', 'Default': '-'},
         {'Name': 'autoPlay', 'Description': 'Whether to start playing automatically.', 'Type': 'Boolean', 'Default': 'false'},
       ],
    ),
    _ComponentDoc(
       name: 'AudioPlayer',
       category: 'Content',
       description: 'An audio player component with standard playback controls.',
       usageJson: '''{
  "id": "audio-1",
  "component": {
    "AudioPlayer": {
      "url": "https://example.com/audio.mp3"
    }
  }
}''',
       previewPayload: {
         "id": "audio-demo",
         "component": {"Text": {"text": "AudioPlayer requires a URL. See the GenUI Audio docs.", "style": "bodySmall", "color": "grey"}}
       },
       props: [
         {'Name': 'url', 'Description': 'The audio source URL.', 'Type': 'String', 'Default': '-'},
       ],
    ),
    _ComponentDoc(
       name: 'TextField',
       category: 'Input',
       description: 'A standard text input field for user text entry.',
       usageJson: '''{
  "id": "input-1",
  "component": {
    "TextField": {
      "label": "Email Address",
      "placeholder": "Enter your email",
      "type": "email"
    }
  }
}''',
       previewPayload: {
         "id": "tf-demo",
         "component": {"Column": {"gap": "medium"}},
         "children": [
           {"id": "tf1", "component": {"TextField": {"label": "Email Address", "placeholder": "Enter your email", "prefixIcon": "email"}}},
           {"id": "tf2", "component": {"TextField": {"label": "Password", "placeholder": "Enter your password", "prefixIcon": "lock", "suffixIcon": "visibility_off"}}},
         ]
       },
       props: [
         {'Name': 'label', 'Description': 'The field label.', 'Type': 'String', 'Default': '-'},
         {'Name': 'placeholder', 'Description': 'Hint text.', 'Type': 'String', 'Default': '-'},
         {'Name': 'type', 'Description': 'Input type ("text", "email", "password", "number").', 'Type': 'String', 'Default': 'text'},
       ],
    ),
    _ComponentDoc(
       name: 'CheckBox',
       category: 'Input',
       description: 'A multi-selection toggle.',
       usageJson: '''{
  "id": "check-1",
  "component": {
    "CheckBox": {
      "label": "I agree to the terms",
      "initialValue": false
    }
  }
}''',
       previewPayload: {
         "id": "cb-demo",
         "component": {"Column": {}},
         "children": [
           {"id": "cb1", "component": {"Checkbox": {"label": "I agree to the terms", "initialValue": false}}},
           {"id": "cb2", "component": {"Checkbox": {"label": "Subscribe to newsletter", "initialValue": true}}},
         ]
       },
       props: [
         {'Name': 'label', 'Description': 'The checkbox label.', 'Type': 'String', 'Default': '-'},
         {'Name': 'initialValue', 'Description': 'Starting state.', 'Type': 'Boolean', 'Default': 'false'},
       ],
    ),
    _ComponentDoc(
       name: 'Slider',
       category: 'Input',
       description: 'An input for selecting a value from a continuous or discrete range.',
       usageJson: '''{
  "id": "slider-1",
  "component": {
    "Slider": {
      "min": 0,
      "max": 100,
      "initialValue": 50
    }
  }
}''',
       previewPayload: {
         "id": "sl-demo",
         "component": {"Column": {}},
         "children": [
           {"id": "sl1", "component": {"Slider": {"min": 0, "max": 100, "initialValue": 50, "label": "Volume"}}},
           {"id": "sl2", "component": {"Slider": {"min": 0, "max": 10, "initialValue": 3, "label": "Rating"}}},
         ]
       },
       props: [
         {'Name': 'min', 'Description': 'Minimum value.', 'Type': 'Number', 'Default': '0'},
         {'Name': 'max', 'Description': 'Maximum value.', 'Type': 'Number', 'Default': '100'},
         {'Name': 'initialValue', 'Description': 'Starting value.', 'Type': 'Number', 'Default': '50'},
       ],
    ),
    _ComponentDoc(
       name: 'DateTimeInput',
       category: 'Input',
       description: 'A picker for dates and times.',
       usageJson: '''{
  "id": "date-1",
  "component": {
    "DateTimeInput": {
      "mode": "date",
      "label": "Select Start Date"
    }
  }
}''',
       previewPayload: {
         "id": "date-demo",
         "component": {"Text": {"text": "DateTimeInput requires native pickers. Use TextField with prefixIcon: calendar_today as a placeholder.", "style": "bodySmall", "color": "grey"}}
       },
       props: [
         {'Name': 'mode', 'Description': 'Picker mode ("date", "time", "datetime").', 'Type': 'String', 'Default': 'date'},
         {'Name': 'label', 'Description': 'The input label.', 'Type': 'String', 'Default': '-'},
       ],
    ),
    _ComponentDoc(
       name: 'MultipleChoice',
       category: 'Input',
       description: 'A radio button group or dropdown for single selection from multiple options.',
       usageJson: '''{
  "id": "mc-1",
  "component": {
    "MultipleChoice": {
      "options": ["Option A", "Option B", "Option C"],
      "style": "radio"
    }
  }
}''',
       previewPayload: {
         "id": "mc-demo",
         "component": {"Radio": {"options": ["Option A", "Option B", "Option C"], "label": "Select one:"}}
       },
       props: [
         {'Name': 'options', 'Description': 'List of choices.', 'Type': 'Array<String>', 'Default': '-'},
         {'Name': 'style', 'Description': 'Display style ("radio", "dropdown").', 'Type': 'String', 'Default': 'radio'},
       ],
    ),
    _ComponentDoc(
       name: 'Tabs',
       category: 'Navigation',
       description: 'Horizontal or vertical tabbed navigation.',
       usageJson: '''{
  "id": "tabs-1",
  "component": {
    "Tabs": {
      "tabs": ["Home", "Settings", "Profile"],
      "content": ["home-view", "settings-view", "profile-view"]
    }
  }
}''',
       previewPayload: {
         "id": "tabs-demo",
         "component": {"Tabs": {"tabs": ["Home", "Settings", "Profile"]}},
         "children": [
           {"id": "tab1", "component": {"Center": {}}, "children": [{"id": "t1c", "component": {"Text": {"text": "Home Tab Content"}}}]},
           {"id": "tab2", "component": {"Center": {}}, "children": [{"id": "t2c", "component": {"Text": {"text": "Settings Tab Content"}}}]},
           {"id": "tab3", "component": {"Center": {}}, "children": [{"id": "t3c", "component": {"Text": {"text": "Profile Tab Content"}}}]},
         ]
       },
       props: [
         {'Name': 'tabs', 'Description': 'List of tab labels.', 'Type': 'Array<String>', 'Default': '-'},
         {'Name': 'content', 'Description': 'List of component IDs corresponding to the tabs.', 'Type': 'Array<String>', 'Default': '-'},
       ],
    ),
    _ComponentDoc(
       name: 'Modal',
       category: 'Navigation',
       description: 'A dialog box/popup window.',
       usageJson: '''{
  "id": "modal-1",
  "component": {
    "Modal": {
      "title": "Confirmation",
      "child": "modal-content-id",
      "actions": ["cancel-btn", "confirm-btn"]
    }
  }
}''',
       previewPayload: {
         "id": "modal-demo",
         "component": {"Card": {"elevation": 6, "borderRadius": 16}},
         "children": [
           {"id": "md", "component": {"Padding": {"padding": 24}}, "children": [
             {"id": "md1", "component": {"Text": {"text": "Confirm Action", "style": "titleLarge", "bold": true}}},
             {"id": "md2", "component": {"SizedBox": {"height": 12}}},
             {"id": "md3", "component": {"Text": {"text": "Are you sure you want to proceed? This action cannot be undone.", "style": "bodyMedium", "color": "grey"}}},
             {"id": "md4", "component": {"SizedBox": {"height": 20}}},
             {"id": "md5", "component": {"Row": {"distribution": "end", "gap": "medium"}}, "children": [
               {"id": "md6", "component": {"TextButton": {"label": "Cancel"}}},
               {"id": "md7", "component": {"FilledButton": {"label": "Confirm", "backgroundColor": "error"}}},
             ]},
           ]},
         ]
       },
       props: [
         {'Name': 'title', 'Description': 'The modal title.', 'Type': 'String', 'Default': '-'},
         {'Name': 'child', 'Description': 'The main content component ID.', 'Type': 'String', 'Default': '-'},
         {'Name': 'actions', 'Description': 'List of action component IDs (usually Buttons).', 'Type': 'Array<String>', 'Default': '-'},
       ],
    ),
    _ComponentDoc(
       name: 'Divider',
       category: 'Decoration',
       description: 'A thin line that groups content in lists and layouts.',
       usageJson: '''{
  "id": "div-1",
  "component": {
    "Divider": {
      "thickness": 1.0,
      "color": "outline"
    }
  }
}''',
       previewPayload: {
         "id": "div-demo",
         "component": {"Column": {"gap": "small"}},
         "children": [
           {"id": "d1", "component": {"Text": {"text": "Above the divider", "style": "bodyMedium"}}},
           {"id": "d2", "component": {"Divider": {"thickness": 1}}},
           {"id": "d3", "component": {"Text": {"text": "Below the divider", "style": "bodyMedium"}}},
         ]
       },
       props: [
         {'Name': 'thickness', 'Description': 'Line thickness.', 'Type': 'Number', 'Default': '1.0'},
         {'Name': 'color', 'Description': 'Color intent.', 'Type': 'String', 'Default': 'outline'},
       ],
    ),
  ];

  _ComponentDoc? _selectedDoc;

  @override
  void initState() {
    super.initState();
    if (_docs.isNotEmpty) {
      _selectedDoc = _docs.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group docs by category
    final Map<String, List<_ComponentDoc>> grouped = {};
    for (var doc in _docs) {
      grouped.putIfAbsent(doc.category, () => []).add(doc);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          // Left Sidebar (Components List)
          Container(
            width: 250,
            color: Colors.white,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'COMPONENTS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.2),
                  ),
                ),
                ...grouped.entries.map((entry) {
                  return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Padding(
                         padding: const EdgeInsets.only(left: 24, top: 16, bottom: 8),
                         child: Text(
                           entry.key,
                           style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                         ),
                       ),
                       ...entry.value.map((doc) {
                         final isSelected = _selectedDoc?.name == doc.name;
                         return InkWell(
                           onTap: () {
                             setState(() {
                               _selectedDoc = doc;
                             });
                           },
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                             color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.transparent,
                             child: Row(
                               children: [
                                 Text(
                                   doc.name,
                                   style: TextStyle(
                                     fontSize: 14,
                                     fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                     color: isSelected ? Colors.blue[700] : Colors.black87,
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         );
                       }),
                     ],
                  );
                }),
              ],
            ),
          ),
          
          // Right Pane (Details)
          Expanded(
            child: _selectedDoc == null
                ? const Center(child: Text('Select a component'))
                : _buildDetailsPane(context, _selectedDoc!),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPane(BuildContext context, _ComponentDoc doc) {
    return ListView(
      padding: const EdgeInsets.all(40.0),
      children: [
        // Title & Description
        Text(
          doc.name,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          doc.description,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.black54,
                height: 1.5,
              ),
        ),
        
        // Live Preview
        if (doc.previewPayload.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Text(
            'Live Preview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: AtomicUIRenderer(node: Map<String, dynamic>.from(doc.previewPayload)),
          ),
        ],
        
        const SizedBox(height: 48),
        
        // Usage Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Usage',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: doc.usageJson));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied usage JSON to clipboard'), duration: Duration(seconds: 2)),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy JSON'),
            )
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF282C34),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            doc.usageJson,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Color(0xFFABB2BF), // Atom syntax highlighting vibe
              height: 1.5,
            ),
          ),
        ),
        
        const SizedBox(height: 48),
        
        // Props Section
        const Text(
          'Props',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              dataTextStyle: const TextStyle(color: Colors.black87),
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Default')),
              ],
              rows: doc.props.map((prop) {
                return DataRow(
                  cells: [
                    DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(prop['Name']!, style: TextStyle(color: Colors.green[700], fontFamily: 'monospace', fontSize: 13)),
                    )),
                    DataCell(Text(prop['Description']!)),
                    DataCell(Text(prop['Type']!, style: const TextStyle(color: Colors.black54, fontSize: 13))),
                    DataCell(Text(prop['Default']!, style: const TextStyle(color: Colors.black54, fontSize: 13))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 64),
      ],
    );
  }
}
