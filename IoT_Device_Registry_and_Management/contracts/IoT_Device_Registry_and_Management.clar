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


