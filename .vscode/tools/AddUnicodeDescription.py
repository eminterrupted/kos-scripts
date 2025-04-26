import argparse
import csv
import sys
import unicodedata

csv.field_size_limit(sys.maxsize)

def main(input_file, output_file):
    with open(input_file, newline='', encoding='utf-8') as csv_in:
        reader = csv.DictReader(csv_in, quotechar="'", quoting=5)
        # If your CSV already has headers, we add the new one.
        fieldnames = reader.fieldnames + ['Desc']
        rows = []
        for row in reader:
            char = row.get('Char', '')
            # char = char.strip()  # Remove any unintended whitespace
            if len(char) == 1:
                try:
                    description = unicodedata.name(char)
                except ValueError:
                    description = "No description available"
            else:
                description = "Invalid input: not a single Unicode character"
            row['Desc'] = description
            rows.append(row)

    with open(output_file, 'w', newline='', encoding='utf-8') as csv_out:
        writer = csv.DictWriter(csv_out, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)

    print(f"Processed file has been saved as {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Process a CSV file containing Unicode characters and add a description column."
    )
    parser.add_argument(
        "input_file",
        help="Path to the input CSV file with columns 'Code' and 'Char'."
    )
    parser.add_argument(
        "output_file",
        help="Path for the output CSV file which will include the additional 'Desc' column."
    )
    args = parser.parse_args()
    main(args.input_file, args.output_file)