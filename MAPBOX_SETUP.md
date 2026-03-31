# Mapbox Setup Guide

This application uses Mapbox for map functionality in the admin tracking features. Follow these steps to configure your Mapbox token.

## Getting Your Mapbox Token

1. Go to [Mapbox Account](https://account.mapbox.com/)
2. Sign up or log in to your account
3. Navigate to **Access Tokens** section
4. Copy your **Default Public Token** or create a new one

## Configuration

### Option 1: Using Environment Variables (Recommended for Development)

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your Mapbox token:
   ```
   MAPBOX_PUBLIC_TOKEN=pk.eyJ1IjoieW91ci11c2VybmFtZSIsImEiOiJ5b3VyLXRva2VuIn0...
   ```

3. Run the app with the environment variable:
   ```bash
   flutter run --dart-define=MAPBOX_PUBLIC_TOKEN=$MAPBOX_PUBLIC_TOKEN
   ```

### Option 2: Build-time Configuration

Pass the token directly when building:

```bash
flutter build apk --dart-define=MAPBOX_PUBLIC_TOKEN=your_token_here
```

### Option 3: Fallback to OpenStreetMap

If no Mapbox token is provided, the app will automatically fall back to using OpenStreetMap tiles (no token required).

## Important Security Notes

⚠️ **Never commit your `.env` file or actual tokens to version control!**

- The `.env` file is already added to `.gitignore`
- Only commit `.env.example` with placeholder values
- Use environment variables or CI/CD secrets for production builds

## Troubleshooting

**Maps not loading?**
- Check that your Mapbox token is valid
- Verify the token has the correct permissions
- Ensure you're passing the `--dart-define` flag when running

**Using OpenStreetMap instead?**
- The app will automatically use OpenStreetMap if no Mapbox token is configured
- No additional setup required for OpenStreetMap

## Production Deployment

For production builds, configure the Mapbox token in your CI/CD pipeline:

**GitHub Actions:**
```yaml
- name: Build APK
  run: flutter build apk --dart-define=MAPBOX_PUBLIC_TOKEN=${{ secrets.MAPBOX_PUBLIC_TOKEN }}
```

**GitLab CI:**
```yaml
build:
  script:
    - flutter build apk --dart-define=MAPBOX_PUBLIC_TOKEN=$MAPBOX_PUBLIC_TOKEN
```

Make sure to add `MAPBOX_PUBLIC_TOKEN` to your repository secrets.
