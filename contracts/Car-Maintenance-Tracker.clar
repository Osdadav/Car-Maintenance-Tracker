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
(define-constant ERR-INVALID-INPUT (err u106))

;; Input validation
(define-private (validate-non-zero-uint (value uint))
  (> value u0)
)

(define-private (validate-year (year uint))
  (and 
    (>= year u1900) 
    (<= year u2100)
  )
)

(define-private (validate-non-empty-string (value (string-utf8 500)))
  (> (len value) u0)
)

;; Vehicle registration
(define-public (register-vehicle 
    (vin (string-utf8 17))
    (make (string-utf8 50))
    (model (string-utf8 50))
    (year uint)
    (mileage uint)
  )
  (begin
    ;; Input validation
    (asserts! (validate-non-empty-string vin) ERR-INVALID-INPUT)
    (asserts! (validate-non-empty-string make) ERR-INVALID-INPUT)
    (asserts! (validate-non-empty-string model) ERR-INVALID-INPUT)
    (asserts! (validate-year year) ERR-INVALID-INPUT)
    (asserts! (validate-non-zero-uint mileage) ERR-INVALID-INPUT)
    
    ;; Check if vehicle already exists
    (asserts! (is-none (map-get? vehicles { vin: vin })) ERR-VEHICLE-EXISTS)
    
    ;; Save vehicle info
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
    
    ;; Initialize record counter
    (map-set record-counter
      { vin: vin }
      { count: u0 }
    )
    
    (ok true)
  )
)

;; Register as service provider
(define-public (register-service-provider 
    (name (string-utf8 100)) 
    (timestamp uint)
  )
  (begin
    ;; Input validation
    (asserts! (validate-non-empty-string name) ERR-INVALID-INPUT)
    (asserts! (validate-non-zero-uint timestamp) ERR-INVALID-INPUT)
    
    ;; Register service provider
    (map-set service-providers
      { provider: tx-sender }
      {
        name: name,
        verified: false,
        registration-time: timestamp
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
    (timestamp uint)
  )
  (let (
    (validated-vin vin)
    (validated-service-type service-type)
    (validated-mileage mileage)
    (validated-notes notes)
    (validated-timestamp timestamp)
  )
    ;; Input validation
    (asserts! (validate-non-empty-string validated-vin) ERR-INVALID-INPUT)
    (asserts! (validate-non-empty-string validated-service-type) ERR-INVALID-INPUT)
    (asserts! (validate-non-zero-uint validated-mileage) ERR-INVALID-INPUT)
    (asserts! (validate-non-zero-uint validated-timestamp) ERR-INVALID-INPUT)
    
    ;; Fetch required data
    (let (
      (vehicle (unwrap! (map-get? vehicles { vin: validated-vin }) ERR-VEHICLE-NOT-FOUND))
      (provider (unwrap! (map-get? service-providers { provider: tx-sender }) ERR-NOT-SERVICE-PROVIDER))
      (counter (default-to { count: u0 } (map-get? record-counter { vin: validated-vin })))
      (new-record-id (+ (get count counter) u1))
    )
      ;; Save the maintenance record
      (map-set maintenance-records
        { vin: validated-vin, record-id: new-record-id }
        {
          service-type: validated-service-type,
          service-provider: tx-sender,
          timestamp: validated-timestamp,
          mileage: validated-mileage,
          notes: validated-notes,
          verified: false
        }
      )
      
      ;; Update record counter
      (map-set record-counter
        { vin: validated-vin }
        { count: new-record-id }
      )
      
      ;; Update vehicle mileage if higher
      (if (> validated-mileage (get mileage vehicle))
        (map-set vehicles
          { vin: validated-vin }
          (merge vehicle { mileage: validated-mileage })
        )
        true
      )
      
      (ok new-record-id)
    )
  )
)

;; Verify maintenance record (by vehicle owner)
(define-public (verify-maintenance-record
    (vin (string-utf8 17))
    (record-id uint)
  )
  (let (
    (validated-vin vin)
    (validated-record-id record-id)
  )
    ;; Input validation
    (asserts! (validate-non-empty-string validated-vin) ERR-INVALID-INPUT)
    (asserts! (validate-non-zero-uint validated-record-id) ERR-INVALID-INPUT)
    
    ;; Fetch required data
    (let (
      (vehicle (unwrap! (map-get? vehicles { vin: validated-vin }) ERR-VEHICLE-NOT-FOUND))
      (record (unwrap! (map-get? maintenance-records { vin: validated-vin, record-id: validated-record-id }) ERR-RECORD-NOT-FOUND))
    )
      ;; Check ownership
      (asserts! (is-eq (get owner vehicle) tx-sender) ERR-NOT-OWNER)
      
      ;; Update record verification status
      (map-set maintenance-records
        { vin: validated-vin, record-id: validated-record-id }
        (merge record { verified: true })
      )
      
      (ok true)
    )
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