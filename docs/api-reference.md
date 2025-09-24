# API Reference

The JIDO Conductor Agent Service provides a REST API for managing agents, templates, and runs.

## Base URL

All API endpoints are served at:
```
http://127.0.0.1:8745/api
```

## Authentication

All requests must include a Bearer token in the Authorization header:
```
Authorization: Bearer <session-token>
```

## Endpoints

### Templates

#### List Templates
```http
GET /api/templates
```

**Response:**
```json
[
  {
    "id": "template-uuid",
    "name": "Template Name",
    "version": "1.0.0",
    "description": "Template description",
    "author": "Author Name",
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

#### Get Template
```http
GET /api/templates/:id
```

**Response:**
```json
{
  "id": "template-uuid",
  "name": "Template Name",
  "version": "1.0.0",
  "description": "Template description",
  "author": "Author Name",
  "schema": {},
  "created_at": "2024-01-01T00:00:00Z"
}
```

#### Install Template
```http
POST /api/templates/install
Content-Type: multipart/form-data
```

**Request Body:**
- `file`: ZIP file containing the template

**Response:**
```json
{
  "id": "template-uuid",
  "name": "Installed Template",
  "status": "installed"
}
```

### Runs

#### List Runs
```http
GET /api/runs
```

**Response:**
```json
[
  {
    "id": "run-uuid",
    "template_id": "template-uuid",
    "status": "running",
    "started_at": "2024-01-01T00:00:00Z",
    "config": {}
  }
]
```

#### Get Run
```http
GET /api/runs/:id
```

**Response:**
```json
{
  "id": "run-uuid",
  "template_id": "template-uuid",
  "status": "running",
  "started_at": "2024-01-01T00:00:00Z",
  "config": {},
  "logs": []
}
```

#### Create Run
```http
POST /api/runs
Content-Type: application/json
```

**Request Body:**
```json
{
  "template": "template-uuid",
  "config": {
    "key": "value"
  },
  "budget": {
    "max_tokens": 10000,
    "max_cost_usd": 1.0
  },
  "schedule": null,
  "secretsRef": "secrets-key"
}
```

**Response:**
```json
{
  "id": "run-uuid",
  "status": "running",
  "started_at": "2024-01-01T00:00:00Z"
}
```

#### Stop Run
```http
POST /api/runs/:id/stop
```

**Response:**
```json
{
  "id": "run-uuid",
  "status": "stopped"
}
```

#### Get Run Logs (SSE)
```http
GET /api/runs/:id/logs
Accept: text/event-stream
```

**Response:** Server-Sent Events stream
```
event: log
data: {"timestamp": "2024-01-01T00:00:00Z", "level": "info", "message": "Log message"}

event: status
data: {"status": "completed", "timestamp": "2024-01-01T00:00:01Z"}
```

### Secrets

#### List Secrets
```http
GET /api/secrets
```

**Response:**
```json
[
  {
    "key": "secret-key",
    "description": "Secret description",
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

#### Set Secret
```http
POST /api/secrets
Content-Type: application/json
```

**Request Body:**
```json
{
  "key": "secret-key",
  "value": "secret-value",
  "description": "Optional description"
}
```

**Response:**
```json
{
  "key": "secret-key",
  "status": "saved"
}
```

#### Delete Secret
```http
DELETE /api/secrets/:key
```

**Response:**
```json
{
  "key": "secret-key",
  "status": "deleted"
}
```

## WebSocket Events

Connect to receive real-time updates:
```
ws://127.0.0.1:8745/socket/websocket
```

### Event Types

- `run:created` - New run started
- `run:updated` - Run status changed
- `run:log` - New log entry
- `run:completed` - Run finished
- `run:error` - Run encountered an error

## Error Responses

All errors follow this format:
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {}
  }
}
```

### Common Error Codes

- `UNAUTHORIZED` - Invalid or missing token
- `NOT_FOUND` - Resource not found
- `VALIDATION_ERROR` - Invalid request data
- `INTERNAL_ERROR` - Server error

## Rate Limiting

The API is not rate-limited as it runs locally, but be mindful of system resources when making many concurrent requests.