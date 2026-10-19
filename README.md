# Text Viewport with Scroll and Search (x86 Assembly)

A 16-bit real-mode x86 assembly program that draws a bordered text viewport directly into VGA text memory, prints a title and a paragraph inside it, scrolls the contents up, then searches for a word and highlights every match. A status line at the bottom shows how many matches were found.

## Features

- Clears the screen by writing directly to video memory
- Draws a double-line box (viewport) using box-drawing characters
- Prints a title inside the top of the viewport
- Prints a paragraph with newline handling and automatic wrapping at 60 characters
- Scrolls a rectangular region of the screen up by `n` rows
- Searches the viewport for a word and highlights each match with a new color attribute
- Prints a status line with the total match count

## Requirements

- [NASM](https://www.nasm.us/)
- [DOSBox](https://www.dosbox.com/) (or any DOS or 16-bit real-mode environment)

## Build and Run

The program is written as a `.COM` file (`[org 0x0100]`), so assemble it as a flat binary:

```
nasm -f bin main.asm -o main.com
```

Then run it in DOSBox:

```
mount c path\to\your\folder
c:
main.com
```

## How It Works

The program writes straight to text-mode video memory at segment `0xB800`. Each screen cell is two bytes: the character and its color attribute. The screen is 80 columns by 25 rows, so the offset of a cell is `(row * 80 + col) * 2`.

### Layout

| Element | Position |
|---|---|
| Viewport top border | Row 3, columns 8 to 71 |
| Viewport bottom border | Row 21, columns 8 to 71 |
| Left and right borders | Rows 4 to 20, columns 8 and 71 |
| Title | Row 4, starting at column 36 |
| Paragraph | Starting at row 6, column 10 |
| Status line | Bottom of the screen (offset 3680) |

### Functions

| Function | Description |
|---|---|
| `ClearScreen` | Fills all 2000 cells with a space and the default attribute `0x07`. |
| `DrawViewport` | Draws the top and bottom borders with `0xCD` and the left and right borders with `0xBA`. |
| `PrintTitle` | Prints the 8-character title string with attribute `0x1E`. |
| `PrintParagraph` | Prints a null-terminated string line by line. Breaks on a newline (`10`) or after 60 characters, and stops at row 21. Takes the string offset and the attribute as stack parameters. |
| `ScrollUp` | Scrolls a rectangular region up by `n` rows and blanks the freed rows at the bottom. Takes `top, left, bottom, right, n` as stack parameters. |
| `HighlightMatches` | Scans rows 4 to 20 for the search word, increments `MatchCount` on each hit, and rewrites the attribute of the matched cells. Takes the search string and the new attribute as stack parameters. |
| `PrintNumber` | Converts a number to decimal digits and writes them to a given video offset. Returns the offset after the last digit in `AX`. |
| `PrintStatus` | Prints `Total Matches Found: [N] | Viewport Status: ACTIVE` using `MatchCount`. |

### Calling convention

Parameters are pushed onto the stack by the caller and cleaned up by the callee with `ret n`. Every function saves and restores the registers it uses.

## Configuration

These values are defined at the top of the file and can be edited:

| Label | Purpose |
|---|---|
| `TitleText` | Title shown in the viewport (must be 8 characters, or change the count in `PrintTitle`) |
| `ParagraphText` | Text to display. Use `10` for line breaks and end with `0` |
| `SearchWord` | Word to search for and highlight (null-terminated) |

The scroll region and amount are set in `Main` before the call to `ScrollUp`, and the highlight color is the second value pushed before `HighlightMatches` (`0xCE`).

## Notes

- The default `SearchWord` is `Kabootar`, which does not appear in the default paragraph, so the match count will show `0`. Change it to a word that is in the text (for example `Ammar`) to see highlighting.
- The scroll runs before the search, so the first line of the paragraph moves up out of the scroll region and is lost.
- Matching is case-sensitive and works on the characters currently on screen, not on the original string.

## Program Flow

1. Clear the screen
2. Draw the viewport
3. Print the title
4. Print the paragraph
5. Scroll the viewport up by one row
6. Highlight matches of the search word
7. Print the status line
8. Exit to DOS with `int 0x21` (`AH = 0x4C`)
