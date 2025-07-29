# Flutter Web App Deployment

## Quick Deploy to Heroku

1. **Set up buildpacks:**
   ```bash
   heroku buildpacks:set heroku/nodejs
   heroku buildpacks:add heroku/google-chrome
   heroku buildpacks:add heroku/apt
   ```

2. **Set environment variables:**
   ```bash
   heroku config:set GOOGLEMAPS_KEY=your_google_maps_api_key
   ```

3. **Deploy:**
   ```bash
   git add .
   git commit -m "Deploy Flutter web app"
   git push heroku main
   ```

## Files Added/Modified

- `build.sh`: Build script that installs Flutter and builds the web app
- `package.json`: Added build scripts
- `Procfile`: Updated to build before starting
- `Aptfile`: System dependencies for Flutter
- `server.js`: Serves the built Flutter web app

## Troubleshooting

If you get build errors, check the logs:
```bash
heroku logs --tail
```

The build process may take several minutes on first deployment. 