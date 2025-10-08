# Configuration Setup

## Production Setup

1. Copy `app_config.dart.template` to `app_config.dart`
2. Update the configuration values in `app_config.dart` with your production settings
3. The `app_config.dart` file is ignored by git to prevent committing sensitive credentials

## Configuration Values

- `baseUrl`: Your FileMaker Data API base URL
- `database`: Your FileMaker database name
- `username`: FileMaker API username
- `password`: FileMaker API password
- `connectionTimeout`: API connection timeout in seconds
- `receiveTimeout`: API receive timeout in seconds

## Security

- Never commit `app_config.dart` to version control
- Use environment variables or secure configuration management in production
- Consider using encrypted configuration files for sensitive deployments
