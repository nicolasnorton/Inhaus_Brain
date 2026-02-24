import 'package:flutter/material.dart';

class GalleryTemplate {
  final String name;
  final String description;
  final IconData icon;
  final String jsonSchema;

  const GalleryTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.jsonSchema,
  });
}

const List<GalleryTemplate> composerGalleryTemplates = [
  GalleryTemplate(
    name: 'Flight Status',
    description: 'A minimal card displaying departure and arrival times for a flight.',
    icon: Icons.flight_takeoff,
    jsonSchema: '''{
  "id": "root",
  "component": {
    "Card": {}
  },
  "children": [
    {
      "id": "main-col",
      "component": {
        "Column": {
          "gap": "medium"
        }
      },
      "children": [
        {
          "id": "header-row",
          "component": {
            "Row": {
              "distribution": "spaceBetween",
              "alignment": "center"
            }
          },
          "children": [
            {
              "id": "flight-id-row",
              "component": {
                "Row": {
                  "gap": "small",
                  "alignment": "center"
                }
              },
              "children": [
                {
                  "id": "plane-icon",
                  "component": {
                    "Icon": {
                      "icon": "flight_takeoff",
                      "size": 24,
                      "color": "primary"
                    }
                  }
                },
                {
                  "id": "flight-number",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "OS 87"
                      },
                      "style": "headlineMedium"
                    }
                  }
                }
              ]
            },
            {
              "id": "date-text",
              "component": {
                "Text": {
                  "text": {
                    "value": "Mon, Dec 15"
                  },
                  "style": "bodyMedium",
                  "color": "secondary"
                }
              }
            }
          ]
        },
        {
          "id": "cities-row",
          "component": {
            "Row": {
              "distribution": "spaceBetween",
              "alignment": "center"
            }
          },
          "children": [
            {
              "id": "city-dep",
              "component": {
                "Text": {
                  "text": {
                    "value": "Vienna"
                  },
                  "style": "titleLarge"
                }
              }
            },
            {
              "id": "arrow-icon",
              "component": {
                "Icon": {
                  "icon": "arrow_forward",
                  "size": 20,
                  "color": "secondary"
                }
              }
            },
            {
              "id": "city-arr",
              "component": {
                "Text": {
                  "text": {
                    "value": "New York"
                  },
                  "style": "titleLarge"
                }
              }
            }
          ]
        },
        {
          "id": "details-row",
          "component": {
            "Row": {
              "distribution": "spaceBetween"
            }
          },
          "children": [
            {
              "id": "dep-info",
              "component": {
                "Column": {
                  "gap": "small"
                }
              },
              "children": [
                {
                  "id": "dep-label",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "Departs"
                      },
                      "style": "labelMedium",
                      "color": "secondary"
                    }
                  }
                },
                {
                  "id": "dep-time",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "10:15 AM"
                      },
                      "style": "titleLarge"
                    }
                  }
                }
              ]
            },
            {
              "id": "status-info",
              "component": {
                "Column": {
                  "gap": "small"
                }
              },
              "children": [
                {
                  "id": "status-label",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "Status"
                      },
                      "style": "labelMedium",
                      "color": "secondary"
                    }
                  }
                },
                {
                  "id": "status-val",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "On Time"
                      },
                      "style": "bodyMedium",
                      "color": "primary"
                    }
                  }
                }
              ]
            },
            {
              "id": "arr-info",
              "component": {
                "Column": {
                  "gap": "small"
                }
              },
              "children": [
                {
                  "id": "arr-label",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "Arrives"
                      },
                      "style": "labelMedium",
                      "color": "secondary"
                    }
                  }
                },
                {
                  "id": "arr-time",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "2:30 PM"
                      },
                      "style": "titleLarge"
                    }
                  }
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}''',
  ),
  GalleryTemplate(
    name: 'User Profile',
    description: 'A standard social media profile card with avatar, bio, and stat blocks.',
    icon: Icons.person,
    jsonSchema: '''{
  "id": "root",
  "component": {
    "Card": {}
  },
  "children": [
    {
      "id": "main-col",
      "component": {
        "Column": {
          "alignment": "center",
          "gap": "medium"
        }
      },
      "children": [
        {
          "id": "avatar",
          "component": {
            "Image": {
              "url": "https://i.pravatar.cc/150?u=a042581f4e29026704d",
              "width": 100,
              "height": 100,
              "borderRadius": 50,
              "fit": "cover"
            }
          }
        },
        {
          "id": "name",
          "component": {
            "Text": {
              "text": {
                "value": "Sarah Chen"
              },
              "style": "headlineSmall"
            }
          }
        },
        {
          "id": "handle",
          "component": {
            "Text": {
              "text": {
                "value": "@sarahchen"
              },
              "style": "bodyMedium",
              "color": "secondary"
            }
          }
        },
        {
          "id": "bio",
          "component": {
            "Text": {
              "text": {
                "value": "Product Designer at Tech Co. Creating delightful experiences."
              },
              "style": "bodyMedium",
              "textAlign": "center"
            }
          }
        },
        {
          "id": "stats-row",
          "component": {
            "Row": {
              "distribution": "spaceEvenly"
            }
          },
          "children": [
            {
              "id": "stat-1",
              "component": {
                "Column": {
                  "alignment": "center",
                  "gap": "small"
                }
              },
              "children": [
                {
                  "id": "v1",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "12.4K"
                      },
                      "style": "titleMedium"
                    }
                  }
                },
                {
                  "id": "l1",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "Followers"
                      },
                      "style": "labelMedium",
                      "color": "secondary"
                    }
                  }
                }
              ]
            },
            {
              "id": "stat-2",
              "component": {
                "Column": {
                  "alignment": "center",
                  "gap": "small"
                }
              },
              "children": [
                {
                  "id": "v2",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "892"
                      },
                      "style": "titleMedium"
                    }
                  }
                },
                {
                  "id": "l2",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "Following"
                      },
                      "style": "labelMedium",
                      "color": "secondary"
                    }
                  }
                }
              ]
            },
            {
              "id": "stat-3",
              "component": {
                "Column": {
                  "alignment": "center",
                  "gap": "small"
                }
              },
              "children": [
                {
                  "id": "v3",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "347"
                      },
                      "style": "titleMedium"
                    }
                  }
                },
                {
                  "id": "l3",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "Posts"
                      },
                      "style": "labelMedium",
                      "color": "secondary"
                    }
                  }
                }
              ]
            }
          ]
        },
        {
          "id": "follow-btn",
          "component": {
            "Button": {
              "label": {
                "value": "Follow"
              },
              "style": "filled"
            }
          }
        }
      ]
    }
  ]
}''',
  ),
  GalleryTemplate(
    name: 'Account Balance',
    description: 'Banking widget showing primary balance and quick actions.',
    icon: Icons.account_balance_wallet,
    jsonSchema: '''{
  "id": "root",
  "component": {
    "Card": {
      "child": "main-col"
    }
  },
  "children": [
    {
      "id": "main-col",
      "component": {
        "Column": {
          "gap": "large",
          "children": { "explicitList": ["header", "balance", "updated", "divider", "actions"] }
        }
      }
    },
    {
      "id": "header",
      "component": {
        "Row": {
          "gap": "small",
          "alignment": "center",
          "children": { "explicitList": ["bank-icon", "title"] }
        }
      }
    },
    {
      "id": "bank-icon",
      "component": { "Icon": { "icon": "account_balance", "size": 24, "color": "primary" } }
    },
    {
      "id": "title",
      "component": { "Text": { "text": {"value": "Primary Checking"}, "style": "titleMedium" } }
    },
    {
      "id": "balance",
      "component": { "Text": { "text": {"value": "\$12,458.32"}, "style": "headlineLarge" } }
    },
    {
      "id": "updated",
      "component": { "Text": { "text": {"value": "Updated just now"}, "style": "bodySmall", "color": "secondary" } }
    },
    {
      "id": "divider",
      "component": { "Divider": {} }
    },
    {
      "id": "actions",
      "component": {
        "Row": {
          "gap": "medium",
          "children": { "explicitList": ["transfer-btn", "pay-btn"] }
        }
      }
    },
    {
      "id": "transfer-btn",
      "component": {
        "Button": { "label": {"value": "Transfer"}, "style": "filled" }
      }
    },
    {
      "id": "pay-btn",
      "component": {
        "Button": { "label": {"value": "Pay Bill"}, "style": "outlined" }
      }
    }
  ]
}''',
  ),
  GalleryTemplate(
    name: 'Step Counter',
    description: 'Fitness widget showing daily steps and a progress indicator.',
    icon: Icons.directions_walk,
    jsonSchema: '''{
  "id": "root",
  "component": {
    "Card": {}
  },
  "children": [
    {
      "id": "main-col",
      "component": {
        "Column": {
          "alignment": "center",
          "gap": "medium"
        }
      },
      "children": [
        {
          "id": "header",
          "component": {
            "Row": {
              "gap": "small",
              "alignment": "center"
            }
          },
          "children": [
            {
              "id": "walk-icon",
              "component": {
                "Icon": {
                  "icon": "directions_walk",
                  "size": 24,
                  "color": "primary"
                }
              }
            },
            {
              "id": "title",
              "component": {
                "Text": {
                  "text": {
                    "value": "Today's Steps"
                  },
                  "style": "titleMedium"
                }
              }
            }
          ]
        },
        {
          "id": "steps",
          "component": {
            "Text": {
              "text": {
                "value": "8,432"
              },
              "style": "headlineLarge"
            }
          }
        },
        {
          "id": "goal",
          "component": {
            "Text": {
              "text": {
                "value": "84% of 10,000 goal"
              },
              "style": "bodyMedium",
              "color": "secondary"
            }
          }
        },
        {
          "id": "stats",
          "component": {
            "Row": {
              "distribution": "spaceEvenly"
            }
          },
          "children": [
            {
              "id": "dist",
              "component": {
                "Column": {
                  "alignment": "center"
                }
              },
              "children": [
                {
                  "id": "dist-v",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "3.8 mi"
                      },
                      "style": "titleMedium"
                    }
                  }
                },
                {
                  "id": "dist-l",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "Distance"
                      },
                      "style": "bodySmall",
                      "color": "secondary"
                    }
                  }
                }
              ]
            },
            {
              "id": "cal",
              "component": {
                "Column": {
                  "alignment": "center"
                }
              },
              "children": [
                {
                  "id": "cal-v",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "312"
                      },
                      "style": "titleMedium"
                    }
                  }
                },
                {
                  "id": "cal-l",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "Calories"
                      },
                      "style": "bodySmall",
                      "color": "secondary"
                    }
                  }
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}''',
  ),
  GalleryTemplate(
    name: 'Login Form',
    description: 'Standard authentication form with email and password fields.',
    icon: Icons.login,
    jsonSchema: '''{
  "id": "root",
  "component": {
    "Card": {}
  },
  "children": [
    {
      "id": "main-col",
      "component": {
        "Column": {
          "gap": "medium"
        }
      },
      "children": [
        {
          "id": "title",
          "component": {
            "Text": {
              "text": {
                "value": "Welcome back"
              },
              "style": "headlineSmall",
              "textAlign": "center"
            }
          }
        },
        {
          "id": "subtitle",
          "component": {
            "Text": {
              "text": {
                "value": "Sign in to your account"
              },
              "style": "bodyMedium",
              "color": "secondary",
              "textAlign": "center"
            }
          }
        },
        {
          "id": "email-field",
          "component": {
            "TextField": {
              "label": "Email",
              "placeholder": "Please enter a value",
              "type": "email"
            }
          }
        },
        {
          "id": "pass-field",
          "component": {
            "TextField": {
              "label": "Password",
              "placeholder": "Please enter a value",
              "type": "password"
            }
          }
        },
        {
          "id": "login-btn",
          "component": {
            "Button": {
              "label": {
                "value": "Sign in"
              },
              "style": "filled"
            }
          }
        },
        {
          "id": "signup-cto",
          "component": {
            "Row": {
              "alignment": "center",
              "distribution": "spaceBetween"
            }
          },
          "children": [
            {
              "id": "no-account",
              "component": {
                "Text": {
                  "text": {
                    "value": "Don't have an account?"
                  },
                  "style": "bodyMedium"
                }
              }
            },
            {
              "id": "signup-btn",
              "component": {
                "Button": {
                  "label": {
                    "value": "Sign up"
                  },
                  "style": "outlined"
                }
              }
            }
          ]
        }
      ]
    }
  ]
}''',
  ),
  GalleryTemplate(
    name: 'Recipe Card',
    description: 'A beautiful card displaying a food recipe with image, title, and prep time.',
    icon: Icons.restaurant,
    jsonSchema: '''{
  "id": "root",
  "component": {
    "Card": {
      "padding": "none"
    }
  },
  "children": [
    {
      "id": "main-col",
      "component": {
        "Column": {
          "gap": "medium"
        }
      },
      "children": [
        {
          "id": "hero-img",
          "component": {
            "Image": {
              "url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
              "height": 180,
              "fit": "cover"
            }
          }
        },
        {
          "id": "content",
          "component": {
            "Column": {
              "gap": "medium",
              "padding": "medium"
            }
          },
          "children": [
            {
              "id": "title",
              "component": {
                "Text": {
                  "text": {
                    "value": "Mediterranean Quinoa Bowl"
                  },
                  "style": "titleLarge",
                  "maxLines": 2
                }
              }
            },
            {
              "id": "rating-row",
              "component": {
                "Row": {
                  "gap": "small",
                  "alignment": "center"
                }
              },
              "children": [
                {
                  "id": "star",
                  "component": {
                    "Icon": {
                      "icon": "star",
                      "size": 16,
                      "color": "primary"
                    }
                  }
                },
                {
                  "id": "score",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "4.9"
                      },
                      "style": "bodyMedium"
                    }
                  }
                },
                {
                  "id": "reviews",
                  "component": {
                    "Text": {
                      "text": {
                        "value": "(1,247 reviews)"
                      },
                      "style": "bodySmall",
                      "color": "secondary"
                    }
                  }
                }
              ]
            },
            {
              "id": "time-row",
              "component": {
                "Row": {
                  "gap": "medium",
                  "alignment": "center"
                }
              },
              "children": [
                {
                  "id": "prep",
                  "component": {
                    "Row": {
                      "gap": "small",
                      "alignment": "center"
                    }
                  },
                  "children": [
                    {
                      "id": "prep-icon",
                      "component": {
                        "Icon": {
                          "icon": "schedule",
                          "size": 16,
                          "color": "secondary"
                        }
                      }
                    },
                    {
                      "id": "prep-txt",
                      "component": {
                        "Text": {
                          "text": {
                            "value": "15 min prep"
                          },
                          "style": "bodySmall",
                          "color": "secondary"
                        }
                      }
                    }
                  ]
                },
                {
                  "id": "cook",
                  "component": {
                    "Row": {
                      "gap": "small",
                      "alignment": "center"
                    }
                  },
                  "children": [
                    {
                      "id": "cook-icon",
                      "component": {
                        "Icon": {
                          "icon": "local_fire_department",
                          "size": 16,
                          "color": "secondary"
                        }
                      }
                    },
                    {
                      "id": "cook-txt",
                      "component": {
                        "Text": {
                          "text": {
                            "value": "20 min cook"
                          },
                          "style": "bodySmall",
                          "color": "secondary"
                        }
                      }
                    }
                  ]
                }
              ]
            },
            {
              "id": "serves",
              "component": {
                "Text": {
                  "text": {
                    "value": "Serves 4"
                  },
                  "style": "bodySmall"
                }
              }
            }
          ]
        }
      ]
    }
  ]
}''',
  ),
  GalleryTemplate(
    name: 'Music Player',
    description: 'A beautiful music player with rotating album art and audio controls.',
    icon: Icons.music_note,
    jsonSchema: '''{
  "id": "root",
  "component": {
    "Card": {}
  },
  "children": [
    {
      "id": "main-col",
      "component": {
        "Column": {
          "gap": "large"
        }
      },
      "children": [
        {
          "id": "album-art",
          "component": {
            "Image": {
              "url": "https://images.unsplash.com/photo-1614680376593-902f74cf0d41?auto=format&fit=crop&q=80&w=800",
              "height": 200,
              "width": 300,
              "fit": "cover",
              "borderRadius": 12
            }
          }
        },
        {
          "id": "song-info",
          "component": {
            "Column": {
              "gap": "small",
              "alignment": "center"
            }
          },
          "children": [
            {
              "id": "title",
              "component": {
                "Text": {
                  "text": {
                    "value": "Midnight City Lights"
                  },
                  "style": "titleLarge"
                }
              }
            },
            {
              "id": "artist",
              "component": {
                "Text": {
                  "text": {
                    "value": "Neon Synthwave"
                  },
                  "style": "bodyMedium",
                  "color": "secondary"
                }
              }
            }
          ]
        },
        {
          "id": "audio-player",
          "component": {
            "AudioPlayer": {
              "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
            }
          }
        }
      ]
    }
  ]
}''',
  ),
  GalleryTemplate(
    name: 'Cinematic Player',
    description: 'A sleek cinematic video player container for showcasing generated video content.',
    icon: Icons.movie_creation,
    jsonSchema: '''{
  "id": "root",
  "component": {
    "Card": {
      "padding": "none"
    }
  },
  "children": [
    {
      "id": "main-col",
      "component": {
        "Column": {}
      },
      "children": [
        {
          "id": "video-player",
          "component": {
            "Video": {
              "url": "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
              "title": "Epic Sci-Fi Trailer",
              "caption": "A stunning visual journey through a futuristic neon city generated by Google Veo.",
              "autoplay": true
            }
          }
        },
        {
          "id": "video-details",
          "component": {
            "Padding": {
              "padding": 16
            }
          },
          "children": [
            {
              "id": "details-row",
              "component": {
                "Row": {
                  "distribution": "spaceBetween",
                  "alignment": "center"
                }
              },
              "children": [
                {
                  "id": "author-info",
                  "component": {
                    "Row": {
                      "gap": "small",
                      "alignment": "center"
                    }
                  },
                  "children": [
                    {
                      "id": "pro-badge",
                      "component": {
                        "Icon": {
                          "icon": "auto_awesome",
                          "size": 18,
                          "color": "primary"
                        }
                      }
                    },
                    {
                      "id": "author-text",
                      "component": {
                        "Text": {
                          "text": {
                            "value": "Generated with Veo 3.1"
                          },
                          "style": "labelMedium",
                          "color": "secondary"
                        }
                      }
                    }
                  ]
                },
                {
                  "id": "actions",
                  "component": {
                    "Row": {
                      "gap": "small"
                    }
                  },
                  "children": [
                    {
                      "id": "like-btn",
                      "component": {
                        "IconButton": {
                          "icon": "favorite_border",
                          "size": 20
                        }
                      }
                    },
                    {
                      "id": "share-btn",
                      "component": {
                        "IconButton": {
                          "icon": "share",
                          "size": 20
                        }
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}''',
  )
];
