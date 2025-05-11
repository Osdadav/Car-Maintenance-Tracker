;; Car Maintenance Tracker
;; A contract for logging and verifying vehicle maintenance records

;; Data maps
(define-map vehicles
  { vin: (string-utf8 17) }
  { 
    owner: principal,
    make: (string-utf8 50),
    model: (string-utf8 50),
    year: uint,
    mileage: uint
  }
)

(define-map maintenance-records
  { vin: (string-utf8 17), record-id: uint }
  {
    service-type: (string-utf8 100),
    service-provider: principal,
    timestamp: uint,
    mileage: uint,
    notes: (string-utf8 500),
    verified: bool
  }
)

(define-map service-providers
  { provider: principal }
  {
    name: (string-utf8 100),
    verified: bool,
    registration-time: uint
  }
)

(define-map record-counter
  { vin: (string-utf8 17) }
  { count: uint }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-VEHICLE-EXISTS (err u101))
(define-constant ERR-VEHICLE-NOT-FOUND (err u102))
(define-constant ERR-NOT-OWNER (err u103))
(define-constant ERR-NOT-SERVICE-PROVIDER (err u104))
(define-constant ERR-RECORD-NOT-FOUND (err u105))

;; Vehicle registration
(define-public (register-vehicle 
    (vin (string-utf8 17))
    (make (string-utf8 50))
    (model (string-utf8 50))
    (year uint)
    (mileage uint)
  )
  (begin
    (asserts! (is-none (map-get? vehicles { vin: vin })) ERR-VEHICLE-EXISTS)
    
    (map-set vehicles
      { vin: vin }
      {
        owner: tx-sender,
        make: make,
        model: model,
        year: year,
        mileage: mileage
      }
    )
    
    (map-set record-counter
      { vin: vin }
      { count: u0 }
    )
    
    (ok true)
  )
)

;; Register as service provider
(define-public (register-service-provider (name (string-utf8 100)))
  (let ((current-time (get-block-height)))
    (map-set service-providers
      { provider: tx-sender }
      {
        name: name,
        verified: false,
        registration-time: current-time
      }
    )
    (ok true)
  )
)

;; Add maintenance record
(define-public (add-maintenance-record
    (vin (string-utf8 17))
    (service-type (string-utf8 100))
    (mileage uint)
    (notes (string-utf8 500))
  )
  (let (
    (vehicle (unwrap! (map-get? vehicles { vin: vin }) ERR-VEHICLE-NOT-FOUND))
    (provider (unwrap! (map-get? service-providers { provider: tx-sender }) ERR-NOT-SERVICE-PROVIDER))
    (current-time (get-block-height))
    (counter (default-to { count: u0 } (map-get? record-counter { vin: vin })))
    (new-record-id (+ (get count counter) u1))
  )
    (map-set maintenance-records
      { vin: vin, record-id: new-record-id }
      {
        service-type: service-type,
        service-provider: tx-sender,
        timestamp: current-time,
        mileage: mileage,
        notes: notes,
        verified: false
      }
    )
    
    (map-set record-counter
      { vin: vin }
      { count: new-record-id }
    )
    
    ;; Update vehicle mileage if higher
    (if (> mileage (get mileage vehicle))
      (map-set vehicles
        { vin: vin }
        (merge vehicle { mileage: mileage })
      )
      true
    )
    
    (ok new-record-id)
  )
)

;; Verify maintenance record (by vehicle owner)
(define-public (verify-maintenance-record
    (vin (string-utf8 17))
    (record-id uint)
  )
  (let (
    (vehicle (unwrap! (map-get? vehicles { vin: vin }) ERR-VEHICLE-NOT-FOUND))
    (record (unwrap! (map-get? maintenance-records { vin: vin, record-id: record-id }) ERR-RECORD-NOT-FOUND))
  )
    (asserts! (is-eq (get owner vehicle) tx-sender) ERR-NOT-OWNER)
    
    (map-set maintenance-records
      { vin: vin, record-id: record-id }
      (merge record { verified: true })
    )
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-vehicle-info (vin (string-utf8 17)))
  (map-get? vehicles { vin: vin })
)

(define-read-only (get-maintenance-record (vin (string-utf8 17)) (record-id uint))
  (map-get? maintenance-records { vin: vin, record-id: record-id })
)

(define-read-only (get-service-provider (provider principal))
  (map-get? service-providers { provider: provider })
)

(define-read-only (get-record-count (vin (string-utf8 17)))
  (get count (default-to { count: u0 } (map-get? record-counter { vin: vin })))
)