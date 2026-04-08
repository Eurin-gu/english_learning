# PersonalAssistantWeb (No Mac needed)

This version runs directly in iPhone Safari as a PWA-style web app.

## Features

- OCR import from screenshot/image (Tesseract.js in browser)
- Parse and store:
  - tasks
  - expenses with auto category
  - unknown English words
- Night review list from words added today
- Expense chart
- Shortcut-compatible text import:
  - use URL: `https://your-domain/index.html?text=<encoded_text>`

## Local run

If your Linux machine has Python:

```bash
cd PersonalAssistantWeb
python3 -m http.server 8787
```

Open `http://localhost:8787/index.html`.

## Deploy for iPhone access

Recommended easiest path:

1. Upload this folder to GitHub.
2. Connect repo to Cloudflare Pages / Vercel.
3. Deploy static site.
4. Open deployed URL on iPhone Safari and "Add to Home Screen".

## iPhone Shortcut setup (recommended)

### A) Copy text -> auto parse

1. Open `Shortcuts`.
2. Create a shortcut:
   - `Get Clipboard`
   - `URL Encode` (Clipboard)
   - `Text`:
     `https://your-domain/index.html?auto=1&text=[Encoded Text]`
   - `Open URLs`
3. Run shortcut when you copy text from WeChat/QQ/other apps, it will auto parse.

### B) Screenshot/image -> OCR text -> auto parse

1. Create another shortcut:
   - `Select Photos` (or `Take Screenshot`)
   - `Extract Text from Image` (iOS built-in OCR)
   - `URL Encode` (Extracted Text)
   - `Text`:
     `https://your-domain/index.html?auto=1&text=[Encoded Text]`
   - `Open URLs`
2. This flow is currently the most stable for WeChat payment screenshots.

Then in the app page tap `解析并入库`.
