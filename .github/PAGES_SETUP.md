# GitHub Pages Setup Guide

To enable the live web demo at https://rogue780.github.io/Writr/, you need to enable GitHub Pages for this repository.

## Quick Setup (One-time)

1. Go to your repository on GitHub
2. Click **Settings** (top navigation)
3. Click **Pages** (left sidebar under "Code and automation")
4. Under **Build and deployment**:
   - **Source**: Select "GitHub Actions"
5. Click **Save**

That's it! The next time you push to `main` or a `claude/**` branch, the web version will automatically build and deploy.

## What This Does

Once enabled:
- Every push triggers a web build
- The app is deployed to: https://rogue780.github.io/Writr/
- Updates are live within 2-3 minutes
- No manual deployment needed

## Verification

After setup, go to the Actions tab and look for the "Build and Deploy Web" workflow. Once it completes successfully, visit your live demo URL!

## Troubleshooting

**"Resource not accessible by integration" error:**
- This means Pages hasn't been enabled yet
- Follow the setup steps above

**"404 Not Found" when visiting the URL:**
- Wait 2-3 minutes after first deployment
- Check that the workflow completed successfully in the Actions tab
- Verify Pages is set to use "GitHub Actions" as the source

**Build succeeds but page doesn't update:**
- Clear your browser cache
- Try visiting in an incognito/private window
