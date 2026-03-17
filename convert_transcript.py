#!/usr/bin/env python3
"""
Convert Claude Code JSONL conversation transcript to readable Markdown format.

Usage:
    python convert_transcript.py [input.jsonl] [output.md]

Default:
    python convert_transcript.py
    (reads conversation_transcript.jsonl, writes conversation_transcript.md)
"""

import json
import sys
from datetime import datetime
from pathlib import Path


def format_content(content):
    """Format content, handling different types."""
    if isinstance(content, str):
        return content
    elif isinstance(content, list):
        # Handle content blocks (text, tool_use, tool_result, etc.)
        result = []
        for item in content:
            if isinstance(item, dict):
                item_type = item.get('type', '')

                if item_type == 'text':
                    text = item.get('text', '')
                    if text.strip():
                        result.append(text)

                elif item_type == 'tool_use':
                    tool_name = item.get('name', 'unknown')
                    params = item.get('input', {})
                    result.append(f"\n**[Tool Use: {tool_name}]**\n")
                    if params:
                        result.append(f"```json\n{json.dumps(params, indent=2, ensure_ascii=False)}\n```\n")

                elif item_type == 'tool_result':
                    content_text = item.get('content', '')
                    is_error = item.get('is_error', False)
                    if is_error:
                        result.append(f"\n**[Tool Result: ERROR]**\n```\n{content_text}\n```\n")
                    else:
                        result.append(f"\n**[Tool Result]**\n```\n{content_text}\n```\n")

            else:
                result.append(str(item))
        return '\n'.join(result)
    else:
        return str(content)


def convert_jsonl_to_markdown(input_file, output_file, verbose=False):
    """Convert JSONL conversation to Markdown."""

    if not Path(input_file).exists():
        print(f"[ERROR] Input file '{input_file}' not found!")
        return False

    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        user_count = 0
        assistant_count = 0

        with open(output_file, 'w', encoding='utf-8') as out:
            # Write header
            out.write("# RISC-V RV32I Processor Development Conversation\n\n")
            out.write(f"**Export Time**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            out.write(f"**Total Messages**: {len(lines)}\n\n")
            out.write("**Repository**: https://github.com/dianweili/RISCV-Gen\n\n")
            out.write("---\n\n")
            out.write("## Table of Contents\n\n")
            out.write("This conversation documents the complete development process of a RISC-V RV32I 5-stage pipeline processor, including:\n\n")
            out.write("- RTL design (15 SystemVerilog modules)\n")
            out.write("- Testbench development\n")
            out.write("- Synthesis and PnR configuration\n")
            out.write("- Documentation\n")
            out.write("- Git repository setup\n\n")
            out.write("---\n\n")

            # Process each message
            for i, line in enumerate(lines, 1):
                try:
                    msg = json.loads(line.strip())

                    # Extract message info
                    msg_type = msg.get('type', 'unknown')
                    timestamp = msg.get('timestamp', '')
                    message_obj = msg.get('message', {})
                    role = message_obj.get('role', msg_type)
                    content = message_obj.get('content', '')

                    # Skip empty messages
                    if not content:
                        continue

                    # Format role header
                    if role == 'user':
                        user_count += 1
                        out.write(f"## Message {i} - USER\n\n")
                        if timestamp:
                            out.write(f"*Time: {timestamp}*\n\n")
                    elif role == 'assistant':
                        assistant_count += 1
                        out.write(f"## Message {i} - ASSISTANT\n\n")
                        if timestamp:
                            out.write(f"*Time: {timestamp}*\n\n")
                    else:
                        out.write(f"## Message {i} - SYSTEM ({msg_type})\n\n")

                    # Write content
                    formatted_content = format_content(content)
                    if formatted_content.strip():
                        out.write(f"{formatted_content}\n\n")

                    # Add separator
                    out.write("---\n\n")

                    if verbose and i % 50 == 0:
                        print(f"   Processed {i}/{len(lines)} messages...")

                except json.JSONDecodeError as e:
                    out.write(f"## Message {i} - PARSE ERROR\n\n")
                    out.write(f"```\n{line[:200]}...\n```\n\n")
                    out.write(f"Error: {e}\n\n")
                    out.write("---\n\n")
                except Exception as e:
                    out.write(f"## Message {i} - PROCESSING ERROR\n\n")
                    out.write(f"Error: {e}\n\n")
                    out.write("---\n\n")

            # Write footer
            out.write("---\n\n")
            out.write("## Summary\n\n")
            out.write(f"- Total messages: {len(lines)}\n")
            out.write(f"- User messages: {user_count}\n")
            out.write(f"- Assistant messages: {assistant_count}\n")
            out.write(f"- Export time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            out.write("**Project**: RISC-V RV32I 5-Stage Pipeline Processor\n\n")
            out.write("**GitHub**: https://github.com/dianweili/RISCV-Gen\n")

        print(f"[OK] Conversion complete!")
        print(f"   Input:  {input_file} ({len(lines)} total messages)")
        print(f"   Output: {output_file}")
        print(f"   User messages: {user_count}")
        print(f"   Assistant messages: {assistant_count}")
        return True

    except Exception as e:
        print(f"[FAIL] Conversion failed: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Main entry point."""
    # Set UTF-8 encoding for Windows console
    if sys.platform == 'win32':
        import io
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

    # Parse arguments
    verbose = '--verbose' in sys.argv or '-v' in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith('-')]

    if len(args) > 1:
        input_file = args[0]
        output_file = args[1]
    elif len(args) > 0:
        input_file = args[0]
        output_file = Path(input_file).stem + '.md'
    else:
        input_file = 'conversation_transcript.jsonl'
        output_file = 'conversation_transcript.md'

    print(f"[JSONL to Markdown Converter]")
    print(f"   Input:  {input_file}")
    print(f"   Output: {output_file}")
    print()

    success = convert_jsonl_to_markdown(input_file, output_file, verbose)

    if success:
        # Print file size
        output_size = Path(output_file).stat().st_size
        if output_size > 1024 * 1024:
            size_str = f"{output_size / (1024 * 1024):.2f} MB"
        elif output_size > 1024:
            size_str = f"{output_size / 1024:.2f} KB"
        else:
            size_str = f"{output_size} bytes"

        print(f"   File size: {size_str}")
        print()
        print(f"[TIP] Open {output_file} with a Markdown viewer")
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == '__main__':
    main()
