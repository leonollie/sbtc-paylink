;; sBTC PayLink - Decentralized Bitcoin Payment Request Protocol
;;
;; Title: sBTC PayLink - Bitcoin Payment Request System
;;
;; Summary: A decentralized protocol for creating shareable Bitcoin payment requests
;; using sBTC on the Stacks blockchain, enabling seamless peer-to-peer transactions
;; with built-in escrow, expiration handling, and comprehensive payment tracking.
;;
;; Description: sBTC PayLink revolutionizes Bitcoin payments by providing a trustless,
;; time-bound payment request system. Users can create payment links with specific
;; amounts, expiration dates, and optional memos. Recipients can fulfill these requests
;; by transferring sBTC, with automatic state management and complete audit trails.
;; The protocol supports batch operations, comprehensive indexing, and robust security
;; measures including overflow protection and state validation.
;;
;; Key Features:
;; - Decentralized payment request creation and fulfillment
;; - Automatic expiration handling with customizable timeframes
;; - Comprehensive payment state management (pending/paid/expired/canceled)
;; - Built-in memo system for payment descriptions
;; - Multi-index system for efficient querying by creator/recipient
;; - Batch operations support for enhanced UX
;; - Complete audit trail with event emission
;; - Robust security with input validation and overflow protection


;; ERROR CONSTANTS

(define-constant ERR-TAG-EXISTS u100)
(define-constant ERR-NOT-PENDING u101)
(define-constant ERR-INSUFFICIENT-FUNDS u102)
(define-constant ERR-NOT-FOUND u103)
(define-constant ERR-UNAUTHORIZED u104)
(define-constant ERR-EXPIRED u105)
(define-constant ERR-INVALID-AMOUNT u106)
(define-constant ERR-EMPTY-MEMO u107)
(define-constant ERR-MAX-EXPIRATION-EXCEEDED u108)
(define-constant ERR-SELF-PAYMENT u109)
(define-constant ERR-INVALID-RECIPIENT u110)

;; STATE CONSTANTS

(define-constant STATE-PENDING "pending")
(define-constant STATE-PAID "paid")
(define-constant STATE-EXPIRED "expired")
(define-constant STATE-CANCELED "canceled")

;; PROTOCOL CONFIGURATION

;; Official sBTC token contract address
(define-constant SBTC-CONTRACT 'ST1F7QA2MDF17S807EPA36TSS8AMEFY4KA9TVGWXT.sbtc-token)

;; Contract owner for potential governance functions
(define-constant CONTRACT-OWNER tx-sender)

;; Maximum expiration time: 30 days in blocks (~10 min per block)
(define-constant MAX-EXPIRATION-BLOCKS u4320)

;; Minimum payment amount (1 satoshi equivalent)
(define-constant MIN-PAYMENT-AMOUNT u1)

;; Maximum list size for indexing
(define-constant MAX-LIST-SIZE u50)

;; Maximum batch operation size
(define-constant MAX-BATCH-SIZE u20)

;; DATA STORAGE MAPS

;; Main storage for payment requests with comprehensive metadata
(define-map payment-links
  { id: uint }
  {
    creator: principal,
    recipient: principal,
    amount: uint,
    created-at: uint,
    expires-at: uint,
    memo: (optional (string-ascii 256)),
    state: (string-ascii 16),
    payment-tx: (optional (buff 32)),
    fulfiller: (optional principal)
  }
)

;; Index mapping creators to their payment link IDs
(define-map links-by-creator
  { creator: principal }
  { ids: (list 50 uint) }
)

;; Index mapping recipients to payment link IDs assigned to them
(define-map links-by-recipient
  { recipient: principal }
  { ids: (list 50 uint) }
)

;; Index for tracking fulfilled payments by fulfiller
(define-map links-by-fulfiller
  { fulfiller: principal }
  { ids: (list 50 uint) }
)