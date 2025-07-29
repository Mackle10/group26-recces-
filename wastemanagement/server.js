const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();
const PORT = process.env.PORT || 3000;

// Check if build directory exists
const buildPath = path.join(__dirname, 'build/web');
const indexPath = path.join(buildPath, 'index.html');

// Serve static files from build/web directory
app.use(express.static(buildPath));

// Handle client-side routing
app.get('*', (req, res) => {
  // Check if index.html exists
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.status(404).send(`
      <html>
        <head><title>App Building...</title></head>
        <body>
          <h1>App is being built...</h1>
          <p>Please wait while the Flutter web app is being built. This may take a few minutes.</p>
          <p>Build directory not found at: ${buildPath}</p>
          <script>
            setTimeout(() => window.location.reload(), 5000);
          </script>
        </body>
      </html>
    `);
  }
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Build path: ${buildPath}`);
  console.log(`Index file exists: ${fs.existsSync(indexPath)}`);
}); 