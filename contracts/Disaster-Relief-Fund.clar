(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-not-authorized (err u105))
(define-constant err-already-voted (err u106))
(define-constant err-voting-closed (err u107))
(define-constant err-minimum-votes-not-met (err u108))

(define-data-var next-disaster-id uint u1)
(define-data-var total-fund-balance uint u0)
(define-data-var minimum-votes-required uint u3)

(define-map disasters
  { disaster-id: uint }
  {
    location: (string-ascii 100),
    severity: uint,
    requested-amount: uint,
    allocated-amount: uint,
    votes-for: uint,
    votes-against: uint,
    status: (string-ascii 20),
    created-by: principal,
    created-at: uint
  }
)

(define-map disaster-votes
  { disaster-id: uint, voter: principal }
  { vote: bool, voted-at: uint }
)

(define-map authorized-reporters
  { reporter: principal }
  { authorized: bool, added-at: uint }
)

(define-map fund-contributions
  { contributor: principal }
  { total-contributed: uint, last-contribution: uint }
)

(define-public (contribute-to-fund (amount uint))
  (begin
    (asserts! (> amount u0) err-invalid-amount)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set total-fund-balance (+ (var-get total-fund-balance) amount))
    (map-set fund-contributions
      { contributor: tx-sender }
      {
        total-contributed: (+ (default-to u0 (get total-contributed (map-get? fund-contributions { contributor: tx-sender }))) amount),
        last-contribution: stacks-block-height
      }
    )
    (ok amount)
  )
)

(define-public (authorize-reporter (reporter principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-reporters
      { reporter: reporter }
      { authorized: true, added-at: stacks-block-height }
    )
    (ok true)
  )
)

(define-public (revoke-reporter (reporter principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-reporters
      { reporter: reporter }
      { authorized: false, added-at: stacks-block-height }
    )
    (ok true)
  )
)

(define-public (report-disaster (location (string-ascii 100)) (severity uint) (requested-amount uint))
  (let
    (
      (disaster-id (var-get next-disaster-id))
      (reporter-data (map-get? authorized-reporters { reporter: tx-sender }))
    )
    (asserts! (> requested-amount u0) err-invalid-amount)
    (asserts! (and (is-some reporter-data) (get authorized (unwrap-panic reporter-data))) err-not-authorized)
    (asserts! (<= severity u10) err-invalid-amount)
    (map-set disasters
      { disaster-id: disaster-id }
      {
        location: location,
        severity: severity,
        requested-amount: requested-amount,
        allocated-amount: u0,
        votes-for: u0,
        votes-against: u0,
        status: "pending",
        created-by: tx-sender,
        created-at: stacks-block-height
      }
    )
    (var-set next-disaster-id (+ disaster-id u1))
    (ok disaster-id)
  )
)

(define-public (vote-on-disaster (disaster-id uint) (vote-for bool))
  (let
    (
      (disaster-data (map-get? disasters { disaster-id: disaster-id }))
      (existing-vote (map-get? disaster-votes { disaster-id: disaster-id, voter: tx-sender }))
    )
    (asserts! (is-some disaster-data) err-not-found)
    (asserts! (is-none existing-vote) err-already-voted)
    (asserts! (is-eq (get status (unwrap-panic disaster-data)) "pending") err-voting-closed)
    (map-set disaster-votes
      { disaster-id: disaster-id, voter: tx-sender }
      { vote: vote-for, voted-at: stacks-block-height }
    )
    (if vote-for
      (map-set disasters
        { disaster-id: disaster-id }
        (merge (unwrap-panic disaster-data) { votes-for: (+ (get votes-for (unwrap-panic disaster-data)) u1) })
      )
      (map-set disasters
        { disaster-id: disaster-id }
        (merge (unwrap-panic disaster-data) { votes-against: (+ (get votes-against (unwrap-panic disaster-data)) u1) })
      )
    )
    (ok vote-for)
  )
)

(define-public (process-disaster-funding (disaster-id uint))
  (let
    (
      (disaster-data (map-get? disasters { disaster-id: disaster-id }))
      (total-votes (+ (get votes-for (unwrap-panic disaster-data)) (get votes-against (unwrap-panic disaster-data))))
      (approval-ratio (if (> total-votes u0) (/ (* (get votes-for (unwrap-panic disaster-data)) u100) total-votes) u0))
    )
    (asserts! (is-some disaster-data) err-not-found)
    (asserts! (is-eq (get status (unwrap-panic disaster-data)) "pending") err-voting-closed)
    (asserts! (>= total-votes (var-get minimum-votes-required)) err-minimum-votes-not-met)
    (if (>= approval-ratio u60)
      (begin
        (let
          (
            (requested-amount (get requested-amount (unwrap-panic disaster-data)))
            (available-funds (var-get total-fund-balance))
            (allocation-amount (if (<= requested-amount available-funds) requested-amount (/ (* available-funds u80) u100)))
          )
          (asserts! (> allocation-amount u0) err-insufficient-funds)
          (var-set total-fund-balance (- (var-get total-fund-balance) allocation-amount))
          (map-set disasters
            { disaster-id: disaster-id }
            (merge (unwrap-panic disaster-data) 
              { 
                allocated-amount: allocation-amount,
                status: "approved"
              }
            )
          )
          (ok allocation-amount)
        )
      )
      (begin
        (map-set disasters
          { disaster-id: disaster-id }
          (merge (unwrap-panic disaster-data) { status: "rejected" })
        )
        (ok u0)
      )
    )
  )
)

(define-public (withdraw-allocated-funds (disaster-id uint))
  (let
    (
      (disaster-data (map-get? disasters { disaster-id: disaster-id }))
    )
    (asserts! (is-some disaster-data) err-not-found)
    (asserts! (is-eq tx-sender (get created-by (unwrap-panic disaster-data))) err-not-authorized)
    (asserts! (is-eq (get status (unwrap-panic disaster-data)) "approved") err-not-authorized)
    (asserts! (> (get allocated-amount (unwrap-panic disaster-data)) u0) err-insufficient-funds)
    (try! (as-contract (stx-transfer? (get allocated-amount (unwrap-panic disaster-data)) tx-sender (get created-by (unwrap-panic disaster-data)))))
    (map-set disasters
      { disaster-id: disaster-id }
      (merge (unwrap-panic disaster-data) { status: "disbursed" })
    )
    (ok (get allocated-amount (unwrap-panic disaster-data)))
  )
)

(define-public (set-minimum-votes (new-minimum uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set minimum-votes-required new-minimum)
    (ok new-minimum)
  )
)

(define-read-only (get-disaster-info (disaster-id uint))
  (map-get? disasters { disaster-id: disaster-id })
)

(define-read-only (get-total-fund-balance)
  (var-get total-fund-balance)
)

(define-read-only (get-user-vote (disaster-id uint) (voter principal))
  (map-get? disaster-votes { disaster-id: disaster-id, voter: voter })
)

(define-read-only (is-authorized-reporter (reporter principal))
  (default-to false (get authorized (map-get? authorized-reporters { reporter: reporter })))
)

(define-read-only (get-contribution-info (contributor principal))
  (map-get? fund-contributions { contributor: contributor })
)

(define-read-only (get-minimum-votes-required)
  (var-get minimum-votes-required)
)

(define-read-only (get-next-disaster-id)
  (var-get next-disaster-id)
)

(define-read-only (calculate-approval-ratio (disaster-id uint))
  (let
    (
      (disaster-data (map-get? disasters { disaster-id: disaster-id }))
      (votes-for (default-to u0 (get votes-for disaster-data)))
      (votes-against (default-to u0 (get votes-against disaster-data)))
      (total-votes (+ votes-for votes-against))
    )
    (if (> total-votes u0)
      (some (/ (* votes-for u100) total-votes))
      none
    )
  )
)
