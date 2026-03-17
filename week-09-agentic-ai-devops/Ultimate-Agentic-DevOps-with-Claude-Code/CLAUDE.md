# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project is a Static HTML/CSS portfolio website deployed to AWS using S3 and CloudFront.

There is no build system, package manager, or test framework — this is plain HTML/CSS with no JavaScript framework or dependencies.

## Files

- `index.html` — Main portfolio page (single-page layout with anchor-linked sections)
- `style.css` — All styles for the site
- `privacy.html` — Privacy policy page
- `terms.html` — Terms of service page
- `images/` — Local images (logo, hero, books, profile, signature)

## Deployment (Nginx on Ubuntu)

Students host this with Nginx:
```bash
sudo apt update && sudo apt install nginx -y
sudo cp -r * /var/www/html/
sudo systemctl start nginx
```
Access via `http://<public-ip>`.

## DMI Ownership Proof Requirement

Before deployment, students must edit the footer in `index.html` to add their identity. The existing line:
```html
<p>Crafted with <span>cloud</span> excellence by Pravin Mishra</p>
```
Must be followed by a line like:
```html
<p><strong>Deployed by:</strong> DMI Cohort 2 | Rahul Sharma | Group 4 | Week 1 | 16-01-2026</p>
```

## Architecture Notes

- index.html — main entry point, lives at project root
- /css — all stylesheets, one file per page/section
- /images — all image assets, optimised before committing
- /docs — notes, deployment guides, architecture diagrams


## Convections

- No JavaScript allowed anywhere in this project
- No JavaScript frameworks (React, Vue, Alpine, etc.)
- Mobile-first CSS — write mobile styles first, use min-width media queries for larger screens
- All images stored in /images — never inline or in /css
- CSS class names use kebab-case (e.g. hero-section, nav-link)
- No external CSS frameworks (Bootstrap, Tailwind, etc.) — custom CSS only
