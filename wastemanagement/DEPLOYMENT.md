# Flutter Web App Deployment Guide

## Prerequisites

1. Heroku CLI installed
2. Git repository set up
3. Google Maps API key (for map functionality)

## Deployment Steps

### 1. Set up Heroku App

```bash
# Create a new Heroku app
heroku create your-app-name

# Set the buildpacks
heroku buildpacks:set heroku/nodejs
heroku buildpacks:add heroku/google-chrome
heroku buildpacks:add heroku/apt
```

### 2. Set Environment Variables

```bash
# Set your Google Maps API key
heroku config:set GOOGLEMAPS_KEY=your_actual_google_maps_api_key
```

### 3. Deploy

```bash
# Add all files to git
git add .

# Commit changes
git commit -m "Deploy Flutter web app"

# Push to Heroku
git push heroku main
```

### 4. Open the App

```bash
heroku open
```

## Troubleshooting

### If the app shows "App is being built..."

1. Check the build logs:
   ```bash
   heroku logs --tail
   ```

2. Ensure all buildpacks are set correctly:
   ```bash
   heroku buildpacks
   ```

3. Try rebuilding:
   ```bash
   heroku builds:cancel
   git commit --allow-empty -m "Trigger rebuild"
   git push heroku main
   ```

### Common Issues

1. **Build fails**: Check if Flutter is properly installed and all dependencies are available
2. **404 errors**: Ensure the build/web directory is created with index.html
3. **Environment variables**: Make sure GOOGLEMAPS_KEY is set correctly

## File Structure

- `build.sh`: Build script that installs Flutter and builds the web app
- `server.js`: Express server to serve the built Flutter web app
- `package.json`: Node.js configuration
- `Procfile`: Heroku process definition
- `heroku.yml`: Heroku build configuration
- `static.json`: Static site configuration
- `.buildpacks`: Buildpack configuration
- `Aptfile`: System dependencies

## Notes

- The app uses Flutter 3.24.5
- Web renderer is set to HTML for better compatibility
- The build process may take several minutes on first deployment
- Make sure to set your actual Google Maps API key in Heroku config 