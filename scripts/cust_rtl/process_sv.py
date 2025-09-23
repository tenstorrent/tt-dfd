#!/usr/bin/env python3
# SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
# SPDX-License-Identifier: Apache-2.0

import argparse
import re
import sys
from pathlib import Path

def parse_arguments():
    parser = argparse.ArgumentParser(description='Process SystemVerilog files with conditional blocks')
    parser.add_argument('input_file', help='Input SystemVerilog file')
    parser.add_argument('output_file', help='Output SystemVerilog file')
    
    args, unknown = parser.parse_known_args()
    enabled_blocks = {arg.lstrip('-').upper() for arg in unknown}
    return args, enabled_blocks

def tokenize_condition(expr):
    """Convert expression to list of tokens, preserving parentheses."""
    expr = expr.replace('||', '|')
    expr = expr.replace('&&', '&')
    expr = expr.replace('~', '!')
    
    # Add spaces around operators and parentheses
    expr = re.sub(r'([&\|\(\)])', r' \1 ', expr)
    
    # Handle ! specially to keep it attached to what follows
    tokens = []
    parts = [p for p in expr.split() if p]
    i = 0
    while i < len(parts):
        if parts[i] == '!' and i + 1 < len(parts):
            if parts[i+1] == '(':
                # Keep ! separate from ( for proper parsing
                tokens.extend(['!', '('])
            else:
                # Combine ! with the following token
                tokens.append('!' + parts[i+1])
            i += 2
        else:
            tokens.append(parts[i])
            i += 1
            
    return tokens

def parse_condition(tokens, pos=0):
    """Recursively parse tokens into an AST."""
    if pos >= len(tokens):
        return None, pos
    
    # Handle unary operators
    if tokens[pos] == '!':
        if pos + 1 < len(tokens) and tokens[pos + 1] == '(':
            # Handle negation of parenthesized expression
            sub_expr, new_pos = parse_condition(tokens, pos + 2)
            if new_pos < len(tokens) and tokens[new_pos] == ')':
                expr = ('!', sub_expr)
                new_pos += 1
                # Check if this is followed by an operator
                if new_pos < len(tokens) and tokens[new_pos] in ['&', '|']:
                    right_expr, final_pos = parse_condition(tokens, new_pos + 1)
                    return ((tokens[new_pos], expr, right_expr), final_pos)
                return expr, new_pos
        else:
            # Handle negation of single token or other expressions
            sub_expr, new_pos = parse_condition(tokens, pos + 1)
            return ('!', sub_expr), new_pos
    
    # Handle parentheses
    if tokens[pos] == '(':
        sub_expr, new_pos = parse_condition(tokens, pos + 1)
        if new_pos < len(tokens) and tokens[new_pos] == ')':
            new_pos += 1
            # Check if this is followed by an operator
            if new_pos < len(tokens) and tokens[new_pos] in ['&', '|']:
                right_expr, final_pos = parse_condition(tokens, new_pos + 1)
                return ((tokens[new_pos], sub_expr, right_expr), final_pos)
            return sub_expr, new_pos
        raise ValueError("Mismatched parentheses")
    
    # Handle tokens that start with !
    if tokens[pos].startswith('!'):
        token = tokens[pos][1:]
        expr = ('!', token)
        if pos + 1 < len(tokens) and tokens[pos + 1] in ['&', '|']:
            right_expr, new_pos = parse_condition(tokens, pos + 2)
            return ((tokens[pos + 1], expr, right_expr), new_pos)
        return expr, pos + 1
    
    # Handle binary operators
    if pos + 1 < len(tokens) and tokens[pos + 1] in ['&', '|']:
        right_expr, new_pos = parse_condition(tokens, pos + 2)
        return ((tokens[pos + 1], tokens[pos], right_expr), new_pos)
    
    # Base case: single token
    return tokens[pos], pos + 1

def evaluate_ast(ast, enabled_blocks):
    """Evaluate AST against enabled blocks."""
    if isinstance(ast, tuple):
        if ast[0] == '!':
            return not evaluate_ast(ast[1], enabled_blocks)
        if ast[0] in ['&', '|']:
            left = evaluate_ast(ast[1], enabled_blocks)
            right = evaluate_ast(ast[2], enabled_blocks)
            return left & right if ast[0] == '&' else left | right
    return ast.upper() in enabled_blocks

def evaluate_condition(condition_str, enabled_blocks):
    """Evaluate a boolean condition string against enabled blocks."""
    try:
        condition_str = ''.join(condition_str.split()).upper()
        tokens = tokenize_condition(condition_str)
        ast, _ = parse_condition(tokens)
        return evaluate_ast(ast, enabled_blocks)
    except Exception as e:
        print(f"Error evaluating condition '{condition_str}': {e}", file=sys.stderr)
        return False

def process_file(input_file, output_file, enabled_blocks):
    # Read the input file
    with open(input_file, 'r') as f:
        content = f.readlines()

    result = []
    i = 0
    while i < len(content):
        line = content[i].rstrip()
        
        # Check for LINE conditional
        line_match = re.search(r'^(.*?)/\* @@ KEEP - \((.*)\) (\{(.*?)\} )?@@ \*/', line)
        if line_match:
            content_before_comment = line_match.group(1).rstrip()
            condition = line_match.group(2)
            if evaluate_condition(condition, enabled_blocks):
                if content_before_comment:  # Only add if there's content
                    result.append(content_before_comment)
                else:
                    result.append("\n")
            else:
                try:
                    if line_match.group(3) is not None:
                        result.append(line_match.group(4))
                except IndexError:
                    pass
            i += 1
            continue

        # Look for UNC block
        unc_match = re.search(r'/\* @@ START_UNC - \((.*)\) @@ \*/', line)
        if unc_match:
            block_name = unc_match.group(1)
            start_line = i + 1
            block_content_before_else = []
            block_content_after_else = []
            current_list = block_content_before_else
            
            i += 1
            while i < len(content):
                line = content[i].rstrip()
                end_match = re.search(r'/\* @@ END_UNC - \((.*)\) @@ \*/', line)
                else_match = re.search(r'/\* @@ ELSE @@ \*/', line)
                
                if end_match:
                    end_block_name = ''.join(end_match.group(1).split())
                    clean_block_name = ''.join(block_name.split())
                    if end_block_name != clean_block_name:
                        print(f"Error: Found END_UNC with condition '{end_match.group(1)}' but expected '{block_name}' at line {i + 1}")
                        print(f"Line content: {line}")
                        sys.exit(1)
                    break
                elif else_match:
                    current_list = block_content_after_else
                else:
                    if '//' in line:
                        line = "".join(line.split('//', 1))

                    if line:  # Only add non-empty lines
                        current_list.append(line)
                    
                i += 1
                
            if i >= len(content):
                print(f"Error: No matching END_UNC found for START_UNC block with condition '{block_name}'")
                print(f"START_UNC block begins at line {start_line}")
                sys.exit(1)
                
            i += 1
            
            if evaluate_condition(block_name, enabled_blocks):
                result.extend(block_content_before_else)
            elif block_content_after_else:
                result.extend(block_content_after_else)
            continue

        # Look for start marker
        start_match = re.search(r'/\* @@ START - \((.*)\) @@ \*/', line)
        if start_match:
            block_name = start_match.group(1)
            start_line = i + 1  # Save start line for error reporting
            block_content_before_else = []
            block_content_after_else = []
            current_list = block_content_before_else
            
            # Skip the START line
            i += 1
            
            # Process until we find the matching END marker
            while i < len(content):
                line = content[i].rstrip()
                end_match = re.search(r'/\* @@ END - \((.*)\) @@ \*/', line)
                else_match = re.search(r'/\* @@ ELSE @@ \*/', line)
                
                if end_match:
                    end_block_name = end_match.group(1)
                    if end_block_name != block_name:
                        # Found END but with mismatched condition
                        print(f"Error: Found END with condition '{end_block_name}' but expected '{block_name}' at line {i + 1}")
                        print(f"Line content: {line}")
                        sys.exit(1)
                    break
                elif else_match:
                    current_list = block_content_after_else
                else:
                    current_list.append(line)
                i += 1
                
            # Skip the END line
            if i < len(content):
                i += 1
                
            # Add the appropriate content based on condition
            if evaluate_condition(block_name, enabled_blocks):
                result.extend(block_content_before_else)
            elif block_content_after_else:
                result.extend(block_content_after_else)
        else:
            result.append(line)
            i += 1
    
    # Clean up blank lines - only keep single blank lines
    cleaned_result = []
    prev_blank = False
    for line in result:
        is_blank = not line.strip()
        if not (is_blank and prev_blank):
            cleaned_result.append(line)
        prev_blank = is_blank
    
    # Write output with proper newlines
    with open(output_file, 'w') as f:
        for line in cleaned_result:
            f.write(bytes(line + '\n', 'utf-8').decode('unicode_escape'))

def main():
    args, enabled_blocks = parse_arguments()
    
    # Verify input file exists
    if not Path(args.input_file).is_file():
        print(f"Error: Input file '{args.input_file}' does not exist", file=sys.stderr)
        sys.exit(1)
    
    # Process the file
    try:
        process_file(args.input_file, args.output_file, enabled_blocks)
        print(f"Successfully processed {args.input_file} -> {args.output_file}")
        print("Enabled blocks:", ", ".join(sorted(enabled_blocks)) if enabled_blocks else "None")
    except Exception as e:
        print(f"Error processing file: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()