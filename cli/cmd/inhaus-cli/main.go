package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/inhauscorp/inhaus-cli/internal/agent"
	"github.com/inhauscorp/inhaus-cli/internal/auth"
	"github.com/inhauscorp/inhaus-cli/internal/mcp"
	"github.com/inhauscorp/inhaus-cli/internal/tools"
)

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	subcommand := os.Args[1]

	switch subcommand {
	case "auth":
		authCmd := flag.NewFlagSet("auth", flag.ExitOnError)
		email := authCmd.String("email", "", "Firebase login email")
		password := authCmd.String("password", "", "Firebase login password")
		authCmd.Parse(os.Args[2:])

		if *email == "" || *password == "" {
			fmt.Println("--email and --password flags required")
			os.Exit(1)
		}
		
		fmt.Printf("Authenticating as %s...\n", *email)
		err := auth.LoginWithPassword(*email, *password)
		if err != nil {
			fmt.Printf("Login Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("Successfully authenticated and saved token.")

	case "shell":
		shellCmd := flag.NewFlagSet("shell", flag.ExitOnError)
		cmd := shellCmd.String("c", "", "Command to execute")
		brainweave := shellCmd.Bool("brainweave", false, "Log action to BrainWeave graph (BW3.0)")
		shellCmd.Parse(os.Args[2:])
		if *cmd == "" {
			fmt.Println("-c flag required")
			os.Exit(1)
		}
		out, err := tools.ExecuteShell(*cmd)
		if err != nil {
			fmt.Printf("Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Println(out)
		if *brainweave {
			mcp.LogDeviceAction("shell", *cmd, out)
		}

	case "fs":
		fsCmd := flag.NewFlagSet("fs", flag.ExitOnError)
		read := fsCmd.String("read", "", "File to read")
		list := fsCmd.String("list", "", "Directory to list")
		fsCmd.Parse(os.Args[2:])

		if *read != "" {
			content, err := tools.ReadFile(*read)
			if err != nil {
				fmt.Printf("Error: %v\n", err)
				os.Exit(1)
			}
			fmt.Println(content)
		} else if *list != "" {
			opts, err := tools.ListDirectory(*list)
			if err != nil {
				fmt.Printf("Error: %v\n", err)
				os.Exit(1)
			}
			for _, o := range opts {
				fmt.Println(o)
			}
		} else {
			fmt.Println("Provide --read or --list")
		}

	case "capture":
		captureCmd := flag.NewFlagSet("capture", flag.ExitOnError)
		out := captureCmd.String("o", "screenshot.png", "Output file")
		brainweave := captureCmd.Bool("brainweave", false, "Log action to BrainWeave graph (BW3.0)")
		captureCmd.Parse(os.Args[2:])
		
		err := tools.CaptureScreen(*out)
		if err != nil {
			fmt.Printf("Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Screenshot saved to %s\n", *out)
		if *brainweave {
			mcp.LogDeviceAction("capture", *out, "screenshot captured")
		}

	case "mcp":
		mcpCmd := flag.NewFlagSet("mcp", flag.ExitOnError)
		query := mcpCmd.String("query", "", "Graph query to run")
		mcpCmd.Parse(os.Args[2:])
		
		if *query != "" {
			res, err := mcp.QueryGraph(*query)
			if err != nil {
				fmt.Printf("Error: %v\n", err)
				os.Exit(1)
			}
			fmt.Println(res)
		} else {
			fmt.Println("Provide --query")
		}

	case "annotate":
		annotateCmd := flag.NewFlagSet("annotate", flag.ExitOnError)
		nodeId := annotateCmd.String("node", "", "Node ID to annotate")
		text := annotateCmd.String("text", "", "Annotation text")
		annotateCmd.Parse(os.Args[2:])

		if *nodeId == "" || *text == "" {
			fmt.Println("--node and --text flags required")
			os.Exit(1)
		}
		res, err := mcp.Annotate(*nodeId, *text)
		if err != nil {
			fmt.Printf("Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Println(res)

	case "evolve":
		fmt.Println("Running BrainWeave evolve (cluster instincts → skills)...")
		res, err := mcp.Evolve()
		if err != nil {
			fmt.Printf("Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Println(res)

	case "graph-query":
		gqCmd := flag.NewFlagSet("graph-query", flag.ExitOnError)
		query := gqCmd.String("q", "", "Semantic search query")
		gqCmd.Parse(os.Args[2:])

		if *query == "" {
			fmt.Println("-q flag required")
			os.Exit(1)
		}
		res, err := mcp.QueryGraph(*query)
		if err != nil {
			fmt.Printf("Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Println(res)

	case "cron":
		fmt.Println("Cron daemon started. Looking for BrainWeave scheduled tasks...")
		// Simulated cron event loop
		select {}

	case "agent":
		agent.StartServer()

	default:
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println(`InhausBrain CLI (BrainWeave 3.0 Evolution Edition)

Usage:
  inhaus-cli <command> [arguments]

Commands:
  agent        Start the background agent daemon connected to BrainWeave
  shell        Execute a local OS command (-c "ls -la" [--brainweave])
  fs           Perform local filesystem operations (--read <path> | --list <dir>)
  capture      Capture a screenshot of the main display (-o out.png [--brainweave])
  cron         Run in scheduled task mode equivalent to PicoClaw cron
  mcp          Query BrainWeave MCP directly (--query "who is brian?")
  annotate     Annotate a BrainWeave node (--node <id> --text "annotation")
  evolve       Cluster instincts into skills via BrainWeave evolve
  graph-query  Semantic search across the knowledge graph (-q "query")`)
}

