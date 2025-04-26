import argparse
import re
import os.path

def main():
    # Set up the argument parser for command-line parameters
    parser = argparse.ArgumentParser(
        description="Convert a specified delimited text file to a CSV file with optional custom delimiter."
    )
    parser.add_argument(
        'input_filename',
        type=str,
        default='E:\\source\\KSP\\KSP-KOS\\RP1-V2-PPE\\data\\ref\\unicodeCharacters.txt',
        help='Path to the input text file.'
    )
    parser.add_argument(
        'output_filename',
        type=str,
        default='E:\\source\\KSP\\KSP-KOS\\RP1-V2-PPE\\data\\ref\\charCodes.csv',
        help='Path for the output CSV file.'
    )
    parser.add_argument(
        'input_delimiter',
        type=str,
        default='\s',
        help='Delimiter to use between fields in the input file (e.g., " ").'
    )
    parser.add_argument(
        'input_delimiter_ignoreconsecutive',
        type=bool,
        default=True,
        help='True to treat consecutive delimiters as one.'
    )
    parser.add_argument(
        'output_delimiter',
        type=str,
        default=r',',
        help='Delimiter to use between fields in the output CSV file (any combination of up to 3 chars).'
    )
    args = parser.parse_args()

    checked_delimiter = args.input_delimiter
    if args.input_delimiter_ignoreconsecutive:
        checked_delimiter = checked_delimiter + '+'

    # Read from the input file and convert spaces to the custom delimiter
    with open(args.input_filename, 'r') as infile, open(args.output_filename, 'w', newline='') as outfile:
        for line in infile:
            # Remove leading/trailing whitespace and skip empty lines.
            stripped_line = line.strip()
            if not stripped_line:
                continue
            
            # Treat any number of consecutive spaces as one by splitting with a regex.
            fields = re.split(checked_delimiter, stripped_line)
            # Join the fields with the provided delimiter.
            csv_line = args.output_delimiter.join(fields)
            outfile.write(csv_line + '\n')

if __name__ == '__main__':
    main()