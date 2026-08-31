# Database Design

## 1. Database Overview

The AI Customer Support / Knowledge Base Platform uses PostgreSQL as the primary relational database.

PostgreSQL is responsible for:

- User and role management
- Document metadata
- Document chunks
- Conversation history
- Messages
- Message sources / citations
- User feedback
- Vector embeddings through pgvector

The actual uploaded document files (for example PDF files) are stored separately from PostgreSQL.

The database stores document metadata and the storage location of the physical file.

### Technology

- PostgreSQL
- pgvector
- Prisma ORM
- Node.js / TypeScript backend

---

# 2. Entities

The MVP consists of 8 main entities:

1. `Role`
2. `User`
3. `Document`
4. `DocumentChunk`
5. `Conversation`
6. `Message`
7. `MessageSource`
8. `Feedback`

---

## 2.1 Role Entity

The `Role` entity defines the access level of a user.

### Fields

| Field     | Type     | Constraints      | Description       |
| --------- | -------- | ---------------- | ----------------- |
| id        | UUID     | PK               | Primary key       |
| name      | enum     | UNIQUE, NOT NULL | User role         |
| createdAt | DateTime | NOT NULL         | Created timestamp |
| updatedAt | DateTime | NOT NULL         | Updated timestamp |

### Role Values

- `ADMIN`
- `USER`

### Rules

- Role name must be unique.
- A role can be assigned to multiple users.

---

## 2.2 User Entity

The `User` entity represents an authenticated application user.

### Fields

| Field        | Type     | Constraints      | Description       |
| ------------ | -------- | ---------------- | ----------------- |
| id           | UUID     | PK               | Primary key       |
| roleId       | UUID     | FK, NOT NULL     | References `Role` |
| email        | String   | UNIQUE, NOT NULL | User email        |
| passwordHash | String   | NOT NULL         | Hashed password   |
| name         | String   | NOT NULL         | Display name      |
| isActive     | Boolean  | NOT NULL         | Account status    |
| createdAt    | DateTime | NOT NULL         | Created timestamp |
| updatedAt    | DateTime | NOT NULL         | Updated timestamp |

### Rules

- Email must be unique.
- Passwords must never be stored in plaintext.
- `passwordHash` contains only the password hash.
- Every user must have exactly one role.
- A user can have multiple conversations.
- A user can upload multiple documents.
- A user can provide multiple feedback records.

---

## 2.3 Document Entity

The `Document` entity represents a knowledge-base document uploaded by a user, primarily an administrator.

Examples:

- Refund Policy.pdf
- Product Manual.pdf
- Customer Service SOP.pdf
- Shipping Policy.pdf
- Company Policy.pdf

### Fields

| Field        | Type     | Constraints  | Description                    |
| ------------ | -------- | ------------ | ------------------------------ |
| id           | UUID     | PK           | Primary key                    |
| uploadedById | UUID     | FK, NOT NULL | User who uploaded the document |
| originalName | String   | NOT NULL     | Original uploaded filename     |
| storedName   | String   | NOT NULL     | Internal storage filename      |
| filePath     | String   | NOT NULL     | Physical/object storage path   |
| mimeType     | String   | NOT NULL     | File MIME type                 |
| fileSize     | BigInt   | NOT NULL     | File size in bytes             |
| status       | enum     | NOT NULL     | Document processing status     |
| errorMessage | String?  | NULLABLE     | Processing error message       |
| createdAt    | DateTime | NOT NULL     | Created timestamp              |
| updatedAt    | DateTime | NOT NULL     | Updated timestamp              |

### Document Status

- `PENDING`
- `PROCESSING`
- `INDEXED`
- `FAILED`

### Rules

- Every document must belong to a user through `uploadedById`.
- `originalName` stores the filename provided by the user.
- `storedName` is an internally generated filename.
- `filePath` stores the location of the actual document.
- Uploaded files are not stored directly inside PostgreSQL.
- A document can have multiple document chunks.
- A document can only be used for RAG retrieval after it reaches `INDEXED`.
- Failed documents can be retried.

### Example

```text
originalName:
Refund Policy.pdf

storedName:
550e8400-e29b-41d4-a716-446655440000.pdf

filePath:
documents/550e8400-e29b-41d4-a716-446655440000.pdf
```

ERD Design:
┌──────────────┐
│ Role │
├──────────────┤
│ id PK │
│ name UNIQUE │
│ createdAt │
│ updatedAt │
└──────┬───────┘
│
│ 1:N
▼
┌──────────────┐
│ User │
├──────────────┤
│ id PK │
│ roleId FK │
│ email UNIQUE │
│ passwordHash │
│ name │
│ isActive │
│ createdAt │
│ updatedAt │
└───┬─────┬────┘
│ │
│ │
│ └────────────────────────┐
│ │
│ 1:N │ 1:N
▼ ▼
┌──────────────┐ ┌──────────────┐
│ Conversation │ │ Document │
├──────────────┤ ├──────────────┤
│ id PK │ │ id PK │
│ userId FK │ │ uploadedByFK │
│ title │ │ originalName │
│ createdAt │ │ storedName │
│ updatedAt │ │ filePath │
└──────┬───────┘ │ mimeType │
│ │ fileSize │
│ 1:N │ status │
▼ │ errorMessage │
┌──────────────┐ │ createdAt │
│ Message │ │ updatedAt │
├──────────────┤ └──────┬───────┘
│ id PK │ │
│ conversationFK │ 1:N
│ role │ ▼
│ content │ ┌──────────────┐
│ createdAt │ │DocumentChunk │
└───┬──────┬───┘ ├──────────────┤
│ │ │ id PK │
│ │ │ documentIdFK │
│ │ │ content │
│ │ │ chunkIndex │
│ │ │ pageNumber │
│ │ │ tokenCount │
│ │ │ embedding │
│ │ │ createdAt │
│ │ └──────┬───────┘
│ │ │
│ │ 1:N │ 1:N
│ ▼ ▼
│ ┌──────────────┐ ┌──────────────┐
│ │MessageSource │◄─────│DocumentChunk │
│ ├──────────────┤ └──────────────┘
│ │ id PK │
│ │ messageId FK │
│ │ chunkId FK │
│ │ score │
│ │ createdAt │
│ └──────────────┘
│
│ 1:N
▼
┌──────────────┐
│ Feedback │
├──────────────┤
│ id PK │
│ userId FK │
│ messageId FK │
│ type │
│ comment │
│ createdAt │
│ updatedAt │
└──────────────┘
