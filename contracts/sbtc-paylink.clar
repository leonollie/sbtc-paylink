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

;; STATE VARIABLES

;; Auto-incrementing counter for unique payment link IDs
(define-data-var last-id uint u0)

;; Protocol statistics
(define-data-var total-links-created uint u0)
(define-data-var total-links-fulfilled uint u0)
(define-data-var total-volume uint u0)

;; PRIVATE HELPER FUNCTIONS

;; Add payment link ID to a principal's index list
(define-private (add-id-to-creator-list (user principal) (id uint))
  (let (
    (current-data (default-to { ids: (list) } (map-get? links-by-creator { creator: user })))
    (current-list (get ids current-data))
    (new-list (unwrap! (as-max-len? (append current-list id) u50) current-list))
  )
  (begin
    (map-set links-by-creator { creator: user } { ids: new-list })
    new-list
  ))
)

;; Add payment link ID to recipient's index list
(define-private (add-id-to-recipient-list (user principal) (id uint))
  (let (
    (current-data (default-to { ids: (list) } (map-get? links-by-recipient { recipient: user })))
    (current-list (get ids current-data))
    (new-list (unwrap! (as-max-len? (append current-list id) u50) current-list))
  )
  (begin
    (map-set links-by-recipient { recipient: user } { ids: new-list })
    new-list
  ))
)

;; Add payment link ID to fulfiller's index list
(define-private (add-id-to-fulfiller-list (user principal) (id uint))
  (let (
    (current-data (default-to { ids: (list) } (map-get? links-by-fulfiller { fulfiller: user })))
    (current-list (get ids current-data))
    (new-list (unwrap! (as-max-len? (append current-list id) u50) current-list))
  )
  (begin
    (map-set links-by-fulfiller { fulfiller: user } { ids: new-list })
    new-list
  ))
)

;; Check if a payment link has expired
(define-private (is-expired (expires-at uint))
  (>= stacks-block-height expires-at)
)

;; Helper function for batch operations
(define-private (get-link-or-none (id uint))
  (map-get? payment-links { id: id })
)

;; Validate memo input
(define-private (validate-memo (memo (optional (string-ascii 256))))
  (match memo
    some-memo (and (> (len some-memo) u0) (<= (len some-memo) u256))
    true
  )
)

;; Validate payment link ID
(define-private (validate-link-id (id uint))
  (and (> id u0) (<= id (var-get last-id)))
)

;; Validate recipient address
(define-private (validate-recipient (recipient principal))
  (not (is-eq recipient tx-sender))
)

;; READ-ONLY FUNCTIONS

;; Get the current payment link ID counter
(define-read-only (get-last-id)
  (ok (var-get last-id))
)

;; Get protocol statistics
(define-read-only (get-protocol-stats)
  (ok {
    total-links-created: (var-get total-links-created),
    total-links-fulfilled: (var-get total-links-fulfilled),
    total-volume: (var-get total-volume),
    current-block: stacks-block-height
  })
)

;; Retrieve complete details of a specific payment link
(define-read-only (get-payment-link (id uint))
  (match (map-get? payment-links { id: id })
    entry (ok entry)
    (err ERR-NOT-FOUND)
  )
)