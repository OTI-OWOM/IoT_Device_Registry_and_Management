;; title: IoT_Device_Registry_and_Management
;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-DEVICE-EXISTS (err u101))
(define-constant ERR-DEVICE-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-INVALID-PARAMETERS (err u104))

;; Tokens for Device Interactions
(define-fungible-token device-token)

;; Device Metadata Structure
(define-map devices
  { device-id: (buff 32) }
  {
    owner: principal,
    public-key: (buff 33),
    device-type: (string-ascii 50),
    registration-timestamp: uint,
    last-activity-timestamp: uint,
    reputation-score: uint,
    is-active: bool,
    metadata-uri: (string-ascii 256),
    device-location: {
      latitude: int,
      longitude: int
    },
    device-capabilities: (list 10 (string-ascii 50))
  }
)

;; Device Verification Mapping
(define-map device-verifications
  { device-id: (buff 32) }
  {
    verification-count: uint,
    total-verification-score: uint,
    last-verified-timestamp: uint
  }
)

;; Device Access Control Mapping
(define-map device-access-control
  { device-id: (buff 32), authorized-user: principal }
  {
    access-level: (string-ascii 20),
    expiration-block: uint
  }
)

;; Enhanced Device Registration
(define-public (register-device
  (device-id (buff 32))
  (public-key (buff 33))
  (device-type (string-ascii 50))
  (metadata-uri (string-ascii 256))
  (location { latitude: int, longitude: int })
  (capabilities (list 10 (string-ascii 50)))
)
  (begin
    ;; Validate input parameters
    (asserts! (> (len device-type) u0) ERR-INVALID-PARAMETERS)
    (asserts! (is-none (map-get? devices { device-id: device-id })) ERR-DEVICE-EXISTS)
    
    ;; Register device with comprehensive metadata
    (map-set devices 
      { device-id: device-id }
      {
        owner: tx-sender,
        public-key: public-key,
        device-type: device-type,
        registration-timestamp: stacks-block-height,
        last-activity-timestamp: stacks-block-height,
        reputation-score: u100,
        is-active: true,
        metadata-uri: metadata-uri,
        device-location: location,
        device-capabilities: capabilities
      }
    )
    
    ;; Initialize verification tracking
    (map-set device-verifications
      { device-id: device-id }
      {
        verification-count: u0,
        total-verification-score: u0,
        last-verified-timestamp: stacks-block-height
      }
    )
    
    ;; Mint initial device tokens
    (try! (ft-mint? device-token u100 tx-sender))
    
    (ok true)
  )
)

;; Advanced Device Data Verification
(define-public (verify-device-data
  (device-id (buff 32))
  (verification-score uint)
  (data-hash (buff 32))
)
  (let 
    (
      (verification (unwrap! 
        (map-get? device-verifications { device-id: device-id }) 
        ERR-DEVICE-NOT-FOUND
      ))
      (device (unwrap! 
        (map-get? devices { device-id: device-id }) 
        ERR-DEVICE-NOT-FOUND
      ))
    )
    
    ;; Advanced verification logic
    (asserts! (> verification-score u0) ERR-UNAUTHORIZED)
    
    (map-set device-verifications
      { device-id: device-id }
      {
        verification-count: (+ (get verification-count verification) u1),
        total-verification-score: (+ (get total-verification-score verification) verification-score),
        last-verified-timestamp: stacks-block-height
      }
    )
    
    ;; Reward verification with tokens
    (try! (ft-mint? device-token verification-score tx-sender))
    
    (ok true)
  )
)

;; Device Access Control
(define-public (grant-device-access
  (device-id (buff 32))
  (authorized-user principal)
  (access-level (string-ascii 20))
  (duration uint)
)
  (let 
    (
      (device (unwrap! (map-get? devices { device-id: device-id }) ERR-DEVICE-NOT-FOUND))
    )
    
    (asserts! (is-eq tx-sender (get owner device)) ERR-UNAUTHORIZED)
    
    (map-set device-access-control
      { device-id: device-id, authorized-user: authorized-user }
      {
        access-level: access-level,
        expiration-block: (+ stacks-block-height duration)
      }
    )
    
    (ok true)
  )
)

;; Advanced Device Interaction Tracking
(define-map device-interactions
  { device-id: (buff 32), interaction-type: (string-ascii 50) }
  {
    interaction-count: uint,
    last-interaction-timestamp: uint
  }
)

;; Record Device Interaction
(define-public (record-device-interaction
  (device-id (buff 32))
  (interaction-type (string-ascii 50))
)
  (let 
    (
      (current-interaction 
        (default-to 
          { interaction-count: u0, last-interaction-timestamp: stacks-block-height }
          (map-get? device-interactions { device-id: device-id, interaction-type: interaction-type })
        )
      )
    )
    
    (map-set device-interactions
      { device-id: device-id, interaction-type: interaction-type }
      {
        interaction-count: (+ (get interaction-count current-interaction) u1),
        last-interaction-timestamp: stacks-block-height
      }
    )
    
    (ok true)
  )
)

;; Additional Helper Functions
(define-read-only (get-device-interactions
  (device-id (buff 32))
  (interaction-type (string-ascii 50))
)
  (map-get? device-interactions { device-id: device-id, interaction-type: interaction-type })
)

(define-data-var contract-paused bool false)

;; Pausability Modifier
(define-public (toggle-contract-pause)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set contract-paused (not (var-get contract-paused)))
    (ok (var-get contract-paused))
  )
)

;; Role-Based Access Control
(define-map contract-roles 
  { role: (string-ascii 20), user: principal }
  { authorized: bool }
)

;; Role Management
(define-public (assign-role 
  (role (string-ascii 20))
  (user principal)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (map-set contract-roles 
      { role: role, user: user }
      { authorized: true }
    )
    (ok true)
  )
)

;; NEW FEATURE: Emergency Stop Mechanism
(define-public (emergency-stop)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set contract-paused true)
    ;; Optional: Additional emergency shutdown logic
    (ok true)
  )
)

