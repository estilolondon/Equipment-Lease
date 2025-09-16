;; Equipment Lease Marketplace Smart Contract
;; A comprehensive decentralized platform for tokenizing equipment leases, enabling secure lease agreements,
;; automated payment processing, maintenance tracking, and transferable lease rights through NFTs

;; Error constants
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-RESOURCE-NOT-FOUND (err u101))
(define-constant ERR-RESOURCE-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-AMOUNT-VALUE (err u103))
(define-constant ERR-INSUFFICIENT-BALANCE (err u104))
(define-constant ERR-LEASE-PERIOD-EXPIRED (err u105))
(define-constant ERR-LEASE-INACTIVE-STATE (err u106))
(define-constant ERR-INVALID-DURATION-PERIOD (err u107))
(define-constant ERR-EQUIPMENT-UNAVAILABLE (err u108))
(define-constant ERR-PAYMENT-PROCESSING-FAILED (err u109))
(define-constant ERR-INVALID-PRINCIPAL-ADDRESS (err u110))
(define-constant ERR-MAINTENANCE-REQUIRED (err u111))
(define-constant ERR-INVALID-INPUT-DATA (err u112))

;; Contract administration
(define-data-var marketplace-administrator principal tx-sender)
(define-data-var platform-service-fee uint u250)
(define-data-var emergency-pause-status bool false)

;; Global counters for unique identifiers
(define-data-var total-equipment-registered uint u0)
(define-data-var total-lease-agreements uint u0)
(define-data-var total-payment-transactions uint u0)
(define-data-var total-maintenance-records uint u0)

;; Equipment category constants
(define-constant construction-equipment "construction")
(define-constant medical-equipment "medical")
(define-constant industrial-equipment "industrial")
(define-constant technology-equipment "technology")
(define-constant automotive-equipment "automotive")

;; Equipment condition constants
(define-constant brand-new-condition "new")
(define-constant excellent-condition "excellent")
(define-constant good-condition "good")
(define-constant fair-condition "fair")

;; Payment transaction types
(define-constant monthly-rental-payment "monthly")
(define-constant security-deposit-payment "deposit")
(define-constant penalty-payment "penalty")
(define-constant maintenance-payment "maintenance")

;; Equipment asset registry with comprehensive details
(define-map equipment-asset-registry
  { equipment-identifier: uint }
  {
    equipment-name: (string-ascii 256),
    detailed-description: (string-ascii 512),
    asset-owner: principal,
    estimated-value: uint,
    equipment-category: (string-ascii 64),
    current-condition: (string-ascii 32),
    availability-status: bool,
    next-maintenance-due: uint,
    registration-timestamp: uint
  }
)

;; Comprehensive lease agreement records
(define-map lease-agreement-registry
  { lease-identifier: uint }
  {
    associated-equipment-id: uint,
    equipment-lessor: principal,
    equipment-lessee: principal,
    lease-start-block: uint,
    lease-end-block: uint,
    monthly-rental-amount: uint,
    required-security-deposit: uint,
    lease-active-status: bool,
    total-amount-paid: uint,
    next-payment-deadline: uint,
    agreement-created-timestamp: uint
  }
)

;; NFT representation of lease rights
(define-non-fungible-token lease-rights-token uint)

;; Detailed payment transaction history
(define-map payment-transaction-history
  { lease-identifier: uint, transaction-identifier: uint }
  {
    payment-amount: uint,
    transaction-timestamp: uint,
    payment-category: (string-ascii 32),
    paying-party: principal
  }
)

;; Equipment maintenance and service records
(define-map equipment-maintenance-log
  { equipment-identifier: uint, maintenance-record-id: uint }
  {
    maintenance-category: (string-ascii 64),
    service-cost: uint,
    service-provider: principal,
    maintenance-timestamp: uint,
    service-description: (string-ascii 256)
  }
)

;; Input validation helper functions
(define-private (validate-equipment-category (category-input (string-ascii 64)))
  (or (is-eq category-input construction-equipment)
      (is-eq category-input medical-equipment)
      (is-eq category-input industrial-equipment)
      (is-eq category-input technology-equipment)
      (is-eq category-input automotive-equipment))
)

(define-private (validate-equipment-condition (condition-input (string-ascii 32)))
  (or (is-eq condition-input brand-new-condition)
      (is-eq condition-input excellent-condition)
      (is-eq condition-input good-condition)
      (is-eq condition-input fair-condition))
)

(define-private (validate-payment-category (payment-category (string-ascii 32)))
  (or (is-eq payment-category monthly-rental-payment)
      (is-eq payment-category security-deposit-payment)
      (is-eq payment-category penalty-payment)
      (is-eq payment-category maintenance-payment))
)

(define-private (validate-equipment-identifier (equipment-id uint))
  (and (> equipment-id u0) 
       (<= equipment-id (var-get total-equipment-registered)))
)

(define-private (validate-lease-identifier (lease-id uint))
  (and (> lease-id u0) 
       (<= lease-id (var-get total-lease-agreements)))
)

(define-private (validate-string-not-empty (input-string (string-ascii 256)))
  (> (len input-string) u0)
)

(define-private (validate-long-string-not-empty (input-string (string-ascii 512)))
  (> (len input-string) u0)
)

(define-private (validate-medium-string-not-empty (input-string (string-ascii 64)))
  (> (len input-string) u0)
)

;; Access control and state validation
(define-private (verify-administrator-access)
  (is-eq tx-sender (var-get marketplace-administrator))
)

(define-private (verify-marketplace-active)
  (not (var-get emergency-pause-status))
)

;; Equipment registration and management functions
(define-public (register-equipment-asset (asset-name (string-ascii 256)) 
                                        (asset-description (string-ascii 512))
                                        (asset-value uint)
                                        (asset-category (string-ascii 64))
                                        (asset-condition (string-ascii 32)))
  (let ((new-equipment-id (+ (var-get total-equipment-registered) u1)))
    (asserts! (verify-marketplace-active) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> asset-value u0) ERR-INVALID-AMOUNT-VALUE)
    (asserts! (validate-string-not-empty asset-name) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-long-string-not-empty asset-description) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-equipment-category asset-category) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-equipment-condition asset-condition) ERR-INVALID-INPUT-DATA)
    
    (map-set equipment-asset-registry
      { equipment-identifier: new-equipment-id }
      {
        equipment-name: asset-name,
        detailed-description: asset-description,
        asset-owner: tx-sender,
        estimated-value: asset-value,
        equipment-category: asset-category,
        current-condition: asset-condition,
        availability-status: true,
        next-maintenance-due: (+ block-height u8640),
        registration-timestamp: block-height
      }
    )
    
    (var-set total-equipment-registered new-equipment-id)
    (ok new-equipment-id)
  )
)

(define-public (modify-equipment-availability (equipment-id uint) (new-availability-status bool))
  (let ((equipment-data (unwrap! (map-get? equipment-asset-registry { equipment-identifier: equipment-id }) ERR-RESOURCE-NOT-FOUND)))
    (asserts! (verify-marketplace-active) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-equipment-identifier equipment-id) ERR-INVALID-INPUT-DATA)
    (asserts! (is-eq tx-sender (get asset-owner equipment-data)) ERR-UNAUTHORIZED-ACCESS)
    
    (map-set equipment-asset-registry
      { equipment-identifier: equipment-id }
      (merge equipment-data { availability-status: new-availability-status })
    )
    (ok true)
  )
)

;; Lease agreement creation and management
(define-public (establish-lease-agreement (target-equipment-id uint)
                                        (prospective-lessee principal)
                                        (lease-duration-blocks uint)
                                        (monthly-rental-fee uint)
                                        (required-deposit uint))
  (let (
    (equipment-data (unwrap! (map-get? equipment-asset-registry { equipment-identifier: target-equipment-id }) ERR-RESOURCE-NOT-FOUND))
    (new-lease-id (+ (var-get total-lease-agreements) u1))
  )
    (asserts! (verify-marketplace-active) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-equipment-identifier target-equipment-id) ERR-INVALID-INPUT-DATA)
    (asserts! (is-eq tx-sender (get asset-owner equipment-data)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (get availability-status equipment-data) ERR-EQUIPMENT-UNAVAILABLE)
    (asserts! (> lease-duration-blocks u0) ERR-INVALID-DURATION-PERIOD)
    (asserts! (> monthly-rental-fee u0) ERR-INVALID-AMOUNT-VALUE)
    (asserts! (>= required-deposit u0) ERR-INVALID-AMOUNT-VALUE)
    (asserts! (is-standard prospective-lessee) ERR-INVALID-PRINCIPAL-ADDRESS)
    
    (map-set lease-agreement-registry
      { lease-identifier: new-lease-id }
      {
        associated-equipment-id: target-equipment-id,
        equipment-lessor: tx-sender,
        equipment-lessee: prospective-lessee,
        lease-start-block: block-height,
        lease-end-block: (+ block-height lease-duration-blocks),
        monthly-rental-amount: monthly-rental-fee,
        required-security-deposit: required-deposit,
        lease-active-status: false,
        total-amount-paid: u0,
        next-payment-deadline: (+ block-height u4320),
        agreement-created-timestamp: block-height
      }
    )
    
    (map-set equipment-asset-registry
      { equipment-identifier: target-equipment-id }
      (merge equipment-data { availability-status: false })
    )
    
    (try! (nft-mint? lease-rights-token new-lease-id prospective-lessee))
    
    (var-set total-lease-agreements new-lease-id)
    (ok new-lease-id)
  )
)

;; Payment processing system
(define-public (process-lease-payment (target-lease-id uint) (transaction-type (string-ascii 32)))
  (let (
    (lease-data (unwrap! (map-get? lease-agreement-registry { lease-identifier: target-lease-id }) ERR-RESOURCE-NOT-FOUND))
    (new-transaction-id (+ (var-get total-payment-transactions) u1))
    (transaction-amount (if (is-eq transaction-type security-deposit-payment)
                         (get required-security-deposit lease-data)
                         (get monthly-rental-amount lease-data)))
    (platform-fee-amount (/ (* transaction-amount (var-get platform-service-fee)) u10000))
    (lessor-receiving-amount (- transaction-amount platform-fee-amount))
  )
    (asserts! (verify-marketplace-active) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-lease-identifier target-lease-id) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-payment-category transaction-type) ERR-INVALID-INPUT-DATA)
    (asserts! (or (is-eq tx-sender (get equipment-lessee lease-data)) 
                  (is-eq tx-sender (get equipment-lessor lease-data))) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (<= block-height (get lease-end-block lease-data)) ERR-LEASE-PERIOD-EXPIRED)
    
    (try! (stx-transfer? lessor-receiving-amount tx-sender (get equipment-lessor lease-data)))
    
    (if (> platform-fee-amount u0)
      (try! (stx-transfer? platform-fee-amount tx-sender (var-get marketplace-administrator)))
      true
    )
    
    (map-set payment-transaction-history
      { lease-identifier: target-lease-id, transaction-identifier: new-transaction-id }
      {
        payment-amount: transaction-amount,
        transaction-timestamp: block-height,
        payment-category: transaction-type,
        paying-party: tx-sender
      }
    )
    
    (let ((updated-lease-data (merge lease-data {
      lease-active-status: true,
      total-amount-paid: (+ (get total-amount-paid lease-data) transaction-amount),
      next-payment-deadline: (if (is-eq transaction-type monthly-rental-payment)
                              (+ block-height u4320)
                              (get next-payment-deadline lease-data))
    })))
      (map-set lease-agreement-registry { lease-identifier: target-lease-id } updated-lease-data)
    )
    
    (var-set total-payment-transactions new-transaction-id)
    (ok new-transaction-id)
  )
)

;; Lease termination procedures
(define-public (terminate-lease-agreement (target-lease-id uint))
  (let ((lease-data (unwrap! (map-get? lease-agreement-registry { lease-identifier: target-lease-id }) ERR-RESOURCE-NOT-FOUND)))
    (asserts! (verify-marketplace-active) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-lease-identifier target-lease-id) ERR-INVALID-INPUT-DATA)
    (asserts! (or (is-eq tx-sender (get equipment-lessor lease-data))
                  (is-eq tx-sender (get equipment-lessee lease-data))) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (get lease-active-status lease-data) ERR-LEASE-INACTIVE-STATE)
    
    (map-set lease-agreement-registry
      { lease-identifier: target-lease-id }
      (merge lease-data { lease-active-status: false })
    )
    
    (let ((equipment-data (unwrap! (map-get? equipment-asset-registry { equipment-identifier: (get associated-equipment-id lease-data) }) ERR-RESOURCE-NOT-FOUND)))
      (map-set equipment-asset-registry
        { equipment-identifier: (get associated-equipment-id lease-data) }
        (merge equipment-data { availability-status: true })
      )
    )
    
    (try! (nft-burn? lease-rights-token target-lease-id (get equipment-lessee lease-data)))
    
    (ok true)
  )
)

;; Maintenance tracking system
(define-public (document-maintenance-service (target-equipment-id uint)
                                           (service-type (string-ascii 64))
                                           (service-cost uint)
                                           (service-description (string-ascii 256)))
  (let (
    (equipment-data (unwrap! (map-get? equipment-asset-registry { equipment-identifier: target-equipment-id }) ERR-RESOURCE-NOT-FOUND))
    (new-maintenance-id (+ (var-get total-maintenance-records) u1))
  )
    (asserts! (verify-marketplace-active) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-equipment-identifier target-equipment-id) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-medium-string-not-empty service-type) ERR-INVALID-INPUT-DATA)
    (asserts! (>= service-cost u0) ERR-INVALID-AMOUNT-VALUE)
    (asserts! (validate-string-not-empty service-description) ERR-INVALID-INPUT-DATA)
    (asserts! (is-eq tx-sender (get asset-owner equipment-data)) ERR-UNAUTHORIZED-ACCESS)
    
    (map-set equipment-maintenance-log
      { equipment-identifier: target-equipment-id, maintenance-record-id: new-maintenance-id }
      {
        maintenance-category: service-type,
        service-cost: service-cost,
        service-provider: tx-sender,
        maintenance-timestamp: block-height,
        service-description: service-description
      }
    )
    
    (map-set equipment-asset-registry
      { equipment-identifier: target-equipment-id }
      (merge equipment-data { next-maintenance-due: (+ block-height u8640) })
    )
    
    (var-set total-maintenance-records new-maintenance-id)
    (ok new-maintenance-id)
  )
)

;; Lease rights token transfer
(define-public (transfer-lease-rights (target-lease-id uint) (new-lessee principal))
  (let ((lease-data (unwrap! (map-get? lease-agreement-registry { lease-identifier: target-lease-id }) ERR-RESOURCE-NOT-FOUND)))
    (asserts! (verify-marketplace-active) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-lease-identifier target-lease-id) ERR-INVALID-INPUT-DATA)
    (asserts! (is-eq tx-sender (get equipment-lessee lease-data)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (get lease-active-status lease-data) ERR-LEASE-INACTIVE-STATE)
    (asserts! (is-standard new-lessee) ERR-INVALID-PRINCIPAL-ADDRESS)
    
    (try! (nft-transfer? lease-rights-token target-lease-id tx-sender new-lessee))
    
    (map-set lease-agreement-registry
      { lease-identifier: target-lease-id }
      (merge lease-data { equipment-lessee: new-lessee })
    )
    
    (ok true)
  )
)

;; Data retrieval functions
(define-read-only (get-equipment-details (equipment-id uint))
  (map-get? equipment-asset-registry { equipment-identifier: equipment-id })
)

(define-read-only (get-lease-agreement-details (lease-id uint))
  (map-get? lease-agreement-registry { lease-identifier: lease-id })
)

(define-read-only (get-payment-transaction-details (lease-id uint) (transaction-id uint))
  (map-get? payment-transaction-history { lease-identifier: lease-id, transaction-identifier: transaction-id })
)

(define-read-only (get-maintenance-service-record (equipment-id uint) (record-id uint))
  (map-get? equipment-maintenance-log { equipment-identifier: equipment-id, maintenance-record-id: record-id })
)

(define-read-only (check-lease-payment-overdue (lease-id uint))
  (match (map-get? lease-agreement-registry { lease-identifier: lease-id })
    lease-data (and (get lease-active-status lease-data) (> block-height (get next-payment-deadline lease-data)))
    false
  )
)

(define-read-only (check-equipment-maintenance-due (equipment-id uint))
  (match (map-get? equipment-asset-registry { equipment-identifier: equipment-id })
    equipment-data (>= block-height (get next-maintenance-due equipment-data))
    false
  )
)

(define-read-only (get-lease-rights-token-holder (lease-id uint))
  (nft-get-owner? lease-rights-token lease-id)
)

(define-read-only (get-total-equipment-count)
  (var-get total-equipment-registered)
)

(define-read-only (get-total-lease-count)
  (var-get total-lease-agreements)
)

;; Administrative management functions
(define-public (update-marketplace-administrator (new-administrator principal))
  (begin
    (asserts! (verify-administrator-access) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-standard new-administrator) ERR-INVALID-PRINCIPAL-ADDRESS)
    (var-set marketplace-administrator new-administrator)
    (ok true)
  )
)

(define-public (modify-platform-service-fee (new-fee-rate uint))
  (begin
    (asserts! (verify-administrator-access) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (<= new-fee-rate u1000) ERR-INVALID-AMOUNT-VALUE)
    (var-set platform-service-fee new-fee-rate)
    (ok true)
  )
)

(define-public (toggle-marketplace-emergency-pause)
  (begin
    (asserts! (verify-administrator-access) ERR-UNAUTHORIZED-ACCESS)
    (var-set emergency-pause-status (not (var-get emergency-pause-status)))
    (ok (var-get emergency-pause-status))
  )
)

(define-public (execute-emergency-fund-withdrawal (withdrawal-amount uint))
  (begin
    (asserts! (verify-administrator-access) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (var-get emergency-pause-status) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> withdrawal-amount u0) ERR-INVALID-AMOUNT-VALUE)
    (try! (stx-transfer? withdrawal-amount (as-contract tx-sender) (var-get marketplace-administrator)))
    (ok true)
  )
)