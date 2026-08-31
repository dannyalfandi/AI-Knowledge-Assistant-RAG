# Enterprise AI Knowledge Assistant — Requirements

## 1. Project Overview

Enterprise AI Knowledge Assistant adalah platform knowledge base berbasis AI yang memungkinkan perusahaan menyimpan dokumen internal dan memungkinkan user mencari informasi melalui natural language.

User dapat mengajukan pertanyaan dan sistem akan memberikan jawaban berdasarkan dokumen perusahaan menggunakan Retrieval Augmented Generation (RAG).

Dokumen yang dapat digunakan sebagai knowledge base antara lain:

- Company Policy
- FAQ
- Product Manual
- SOP
- Documentation
- Refund Policy
- Shipping Policy

---

## 2. Project Goals

Tujuan utama project:

- Membuat centralized company knowledge base.
- Memungkinkan admin mengelola dokumen perusahaan.
- Memungkinkan user bertanya menggunakan natural language.
- Memberikan jawaban berdasarkan informasi yang terdapat pada dokumen.
- Mengurangi risiko hallucination dengan menggunakan RAG.
- Menampilkan sumber/citation dari jawaban AI.
- Menyimpan conversation history.
- Mengumpulkan feedback dari user.
- Menyediakan dashboard untuk admin.

---

## 3. Target Users

### Admin

Admin bertanggung jawab untuk mengelola knowledge base dan sistem.

Admin dapat:

- Login.
- Mengelola dokumen.
- Upload dokumen.
- Melihat daftar dokumen.
- Melihat status processing dokumen.
- Menghapus dokumen.
- Melihat user.
- Melihat analytics.

### User

User menggunakan sistem untuk mencari informasi dari knowledge base.

User dapat:

- Login.
- Membuat conversation.
- Mengajukan pertanyaan.
- Menerima jawaban AI.
- Melihat citation/source.
- Melihat conversation history.
- Memberikan feedback terhadap jawaban AI.

---

# 4. Functional Requirements

## 4.1 Authentication

System harus menyediakan:

- User registration.
- User login.
- User logout.
- Get current authenticated user.
- Password hashing.
- JWT authentication.

---

## 4.2 Authorization

System memiliki dua role:

- ADMIN
- USER

Admin dapat mengakses fitur administrasi.

User hanya dapat mengakses fitur yang berkaitan dengan penggunaan knowledge assistant.

---

## 4.3 Document Management

Admin dapat:

- Upload document.
- View document list.
- View document detail.
- Delete document.
- View document processing status.

Document memiliki status:

- PENDING
- PROCESSING
- INDEXED
- FAILED

---

## 4.4 Document Processing

System harus dapat:

1. Menerima document.
2. Mengekstrak text dari document.
3. Membersihkan text.
4. Membagi text menjadi chunks.
5. Membuat embedding dari setiap chunk.
6. Menyimpan embedding ke vector database.

MVP document format:

- PDF

Future support:

- DOCX
- TXT

---

## 4.5 Knowledge Retrieval

System harus dapat:

1. Menerima pertanyaan user.
2. Membuat embedding dari pertanyaan.
3. Melakukan semantic similarity search.
4. Mengambil relevant document chunks.
5. Menggunakan hasil retrieval sebagai context untuk LLM.

---

## 4.6 RAG

System menggunakan Retrieval Augmented Generation.

Flow:

User Question
→ Query Embedding
→ Vector Search
→ Relevant Chunks
→ Context
→ LLM
→ Answer

AI harus menggunakan context hasil retrieval sebagai sumber informasi utama.

Jika informasi tidak ditemukan pada knowledge base, AI harus memberitahu user bahwa informasi tidak tersedia.

AI tidak boleh membuat informasi perusahaan yang tidak terdapat pada knowledge base.

---

## 4.7 Chat

User dapat:

- Create conversation.
- Send message.
- Receive AI response.
- View conversation.
- View previous messages.
- Delete conversation.

---

## 4.8 Citation

AI response harus dapat menampilkan source.

Source minimal berisi:

- Document name.
- Page number.
- Relevant document chunk.
- Similarity score.

Contoh:

Refund dapat diajukan maksimal 7 hari setelah produk diterima.

Sources:

- Refund Policy.pdf — Page 4
- Customer Service SOP.pdf — Page 12

---

## 4.9 Conversation History

System harus menyimpan:

- Conversation.
- User message.
- AI response.
- Message sources.
- Timestamp.

User dapat melihat conversation sebelumnya.

---

## 4.10 Feedback

User dapat memberikan:

- Positive feedback.
- Negative feedback.

User juga dapat memberikan optional comment.

---

## 4.11 Admin Dashboard

Admin dashboard menampilkan:

- Total users.
- Total documents.
- Indexed documents.
- Processing documents.
- Failed documents.
- Total conversations.
- Total questions.
- Positive feedback.
- Negative feedback.

---

# 5. Non-Functional Requirements

## 5.1 Security

System harus menyediakan:

- JWT authentication.
- Password hashing.
- Role-based authorization.
- Input validation.
- File type validation.
- File size validation.
- API rate limiting.
- CORS configuration.

---

## 5.2 Performance

System harus:

- Menggunakan pagination untuk data list.
- Menggunakan database indexes.
- Menggunakan vector indexes.
- Memproses document secara asynchronous pada versi production.
- Membatasi jumlah context yang dikirim ke LLM.

---

## 5.3 Reliability

System harus:

- Menyimpan document processing status.
- Menangani processing failure.
- Menyediakan error handling.
- Menyediakan retry mechanism untuk background processing.

---

## 5.4 Maintainability

Backend harus:

- Menggunakan TypeScript.
- Menggunakan layered architecture.
- Memisahkan controller, service, dan repository.
- Menggunakan environment variables.
- Memiliki automated tests untuk bagian penting.

---

## 5.5 Scalability

Architecture harus memungkinkan:

- AI service berjalan secara terpisah.
- Background worker.
- Redis queue.
- Horizontal scaling Node.js API.
- Independent scaling untuk AI service.

---

# 6. MVP Scope

MVP mencakup:

- Authentication.
- Role management.
- Document upload.
- Document management.
- PDF text extraction.
- Text chunking.
- Embedding.
- Vector storage.
- Semantic search.
- RAG.
- Chat.
- Conversation history.
- Citation.

---

# 7. Future Scope

Feature yang tidak termasuk MVP:

- DOCX processing.
- TXT processing.
- Feedback analytics.
- Admin analytics.
- Redis.
- BullMQ.
- Background worker.
- Streaming response.
- Hybrid search.
- Reranking.
- Query rewriting.
- OCR.
- Advanced AI evaluation.
- Prompt injection protection.
