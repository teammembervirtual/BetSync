;; BetSync - Synchronized Betting Pools Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-insufficient-payment (err u103))
(define-constant err-pool-closed (err u104))
(define-constant err-already-resolved (err u105))
(define-constant err-invalid-outcome (err u106))
(define-constant err-no-contribution (err u107))
(define-constant err-already-claimed (err u108))
(define-constant err-invalid-input (err u109))

;; Data Variables
(define-data-var next-pool-id uint u1)
(define-data-var platform-fee-rate uint u3) ;; 3% platform fee

;; Data Maps
(define-map betting-pools
  { pool-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 300),
    creator: principal,
    outcome-a: (string-ascii 50),
    outcome-b: (string-ascii 50),
    total-pool-a: uint,
    total-pool-b: uint,
    deadline: uint,
    is-active: bool,
    is-resolved: bool,
    winning-outcome: uint ;; 1 for outcome-a, 2 for outcome-b, 0 for unresolved
  }
)

(define-map pool-contributions
  { pool-id: uint, contributor: principal }
  {
    amount-a: uint,
    amount-b: uint,
    total-contributed: uint,
    rewards-claimed: bool
  }
)

(define-map user-stats
  { user: principal }
  {
    total-wagered: uint,
    total-won: uint,
    pools-participated: uint
  }
)

;; Private Functions
(define-private (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-rate)) u100)
)

(define-private (calculate-payout (contribution uint) (winning-pool uint) (losing-pool uint))
  (if (> winning-pool u0)
    (+ contribution (/ (* contribution losing-pool) winning-pool))
    contribution
  )
)

(define-private (update-user-stats (user principal) (wagered uint) (won uint))
  (let
    (
      (current-stats (default-to { total-wagered: u0, total-won: u0, pools-participated: u0 } 
                                  (map-get? user-stats { user: user })))
    )
    (map-set user-stats
      { user: user }
      {
        total-wagered: (+ (get total-wagered current-stats) wagered),
        total-won: (+ (get total-won current-stats) won),
        pools-participated: (+ (get pools-participated current-stats) u1)
      }
    )
    true
  )
)

;; Input validation functions
(define-private (is-valid-string (str (string-ascii 100)))
  (> (len str) u0)
)

(define-private (is-valid-description (str (string-ascii 300)))
  (> (len str) u0)
)

(define-private (is-valid-outcome-string (str (string-ascii 50)))
  (> (len str) u0)
)

(define-private (is-valid-pool-id (pool-id uint))
  (and (> pool-id u0) (< pool-id (var-get next-pool-id)))
)

;; Public Functions
(define-public (create-pool (title (string-ascii 100)) (description (string-ascii 300)) 
                           (outcome-a (string-ascii 50)) (outcome-b (string-ascii 50)) (duration uint))
  (let
    (
      (pool-id (var-get next-pool-id))
      (deadline (+ block-height duration))
      (validated-title title)
      (validated-description description)
      (validated-outcome-a outcome-a)
      (validated-outcome-b outcome-b)
    )
    ;; Input validation
    (asserts! (is-valid-string validated-title) err-invalid-input)
    (asserts! (is-valid-description validated-description) err-invalid-input)
    (asserts! (is-valid-outcome-string validated-outcome-a) err-invalid-input)
    (asserts! (is-valid-outcome-string validated-outcome-b) err-invalid-input)
    (asserts! (> duration u0) err-insufficient-payment)

    (map-set betting-pools
      { pool-id: pool-id }
      {
        title: validated-title,
        description: validated-description,
        creator: tx-sender,
        outcome-a: validated-outcome-a,
        outcome-b: validated-outcome-b,
        total-pool-a: u0,
        total-pool-b: u0,
        deadline: deadline,
        is-active: true,
        is-resolved: false,
        winning-outcome: u0
      }
    )

    (var-set next-pool-id (+ pool-id u1))

    (ok pool-id)
  )
)

(define-public (join-pool (pool-id uint) (outcome uint) (amount uint))
  (let
    (
      (validated-pool-id pool-id)
      (pool-data (unwrap! (map-get? betting-pools { pool-id: validated-pool-id }) err-not-found))
      (existing-contribution (default-to { amount-a: u0, amount-b: u0, total-contributed: u0, rewards-claimed: false }
                                         (map-get? pool-contributions { pool-id: validated-pool-id, contributor: tx-sender })))
    )
    ;; Input validation
    (asserts! (is-valid-pool-id validated-pool-id) err-invalid-input)
    (asserts! (get is-active pool-data) err-pool-closed)
    (asserts! (< block-height (get deadline pool-data)) err-pool-closed)
    (asserts! (or (is-eq outcome u1) (is-eq outcome u2)) err-invalid-outcome)
    (asserts! (> amount u0) err-insufficient-payment)
    (asserts! (>= (stx-get-balance tx-sender) amount) err-insufficient-payment)

    ;; Transfer bet amount to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    ;; Update contribution record
    (if (is-eq outcome u1)
      (begin
        (map-set pool-contributions
          { pool-id: validated-pool-id, contributor: tx-sender }
          {
            amount-a: (+ (get amount-a existing-contribution) amount),
            amount-b: (get amount-b existing-contribution),
            total-contributed: (+ (get total-contributed existing-contribution) amount),
            rewards-claimed: false
          }
        )
        ;; Update pool total for outcome A
        (map-set betting-pools
          { pool-id: validated-pool-id }
          (merge pool-data { total-pool-a: (+ (get total-pool-a pool-data) amount) })
        )
      )
      (begin
        (map-set pool-contributions
          { pool-id: validated-pool-id, contributor: tx-sender }
          {
            amount-a: (get amount-a existing-contribution),
            amount-b: (+ (get amount-b existing-contribution) amount),
            total-contributed: (+ (get total-contributed existing-contribution) amount),
            rewards-claimed: false
          }
        )
        ;; Update pool total for outcome B
        (map-set betting-pools
          { pool-id: validated-pool-id }
          (merge pool-data { total-pool-b: (+ (get total-pool-b pool-data) amount) })
        )
      )
    )

    (ok true)
  )
)

(define-public (resolve-pool (pool-id uint) (winning-outcome uint))
  (let
    (
      (validated-pool-id pool-id)
      (pool-data (unwrap! (map-get? betting-pools { pool-id: validated-pool-id }) err-not-found))
    )
    ;; Input validation
    (asserts! (is-valid-pool-id validated-pool-id) err-invalid-input)
    (asserts! (is-eq (get creator pool-data) tx-sender) err-unauthorized)
    (asserts! (>= block-height (get deadline pool-data)) err-pool-closed)
    (asserts! (not (get is-resolved pool-data)) err-already-resolved)
    (asserts! (or (is-eq winning-outcome u1) (is-eq winning-outcome u2)) err-invalid-outcome)

    (map-set betting-pools
      { pool-id: validated-pool-id }
      (merge pool-data { 
        is-resolved: true,
        is-active: false,
        winning-outcome: winning-outcome
      })
    )

    (ok true)
  )
)

(define-public (claim-winnings (pool-id uint))
  (let
    (
      (validated-pool-id pool-id)
      (pool-data (unwrap! (map-get? betting-pools { pool-id: validated-pool-id }) err-not-found))
      (contribution-data (unwrap! (map-get? pool-contributions { pool-id: validated-pool-id, contributor: tx-sender }) err-no-contribution))
      (winning-outcome (get winning-outcome pool-data))
      (user-winning-amount (if (is-eq winning-outcome u1) 
                             (get amount-a contribution-data) 
                             (get amount-b contribution-data)))
      (total-winning-pool (if (is-eq winning-outcome u1) 
                            (get total-pool-a pool-data) 
                            (get total-pool-b pool-data)))
      (total-losing-pool (if (is-eq winning-outcome u1) 
                           (get total-pool-b pool-data) 
                           (get total-pool-a pool-data)))
      (gross-payout (calculate-payout user-winning-amount total-winning-pool total-losing-pool))
      (platform-fee (calculate-platform-fee gross-payout))
      (net-payout (- gross-payout platform-fee))
    )
    ;; Input validation
    (asserts! (is-valid-pool-id validated-pool-id) err-invalid-input)
    (asserts! (get is-resolved pool-data) err-invalid-outcome)
    (asserts! (not (get rewards-claimed contribution-data)) err-already-claimed)
    (asserts! (> user-winning-amount u0) err-no-contribution)

    ;; Mark rewards as claimed
    (map-set pool-contributions
      { pool-id: validated-pool-id, contributor: tx-sender }
      (merge contribution-data { rewards-claimed: true })
    )

    ;; Update user stats
    (update-user-stats tx-sender (get total-contributed contribution-data) net-payout)

    ;; Transfer winnings to user
    (stx-transfer? net-payout (as-contract tx-sender) tx-sender)
  )
)

(define-public (close-pool (pool-id uint))
  (let
    (
      (validated-pool-id pool-id)
      (pool-data (unwrap! (map-get? betting-pools { pool-id: validated-pool-id }) err-not-found))
    )
    ;; Input validation
    (asserts! (is-valid-pool-id validated-pool-id) err-invalid-input)
    (asserts! (is-eq (get creator pool-data) tx-sender) err-unauthorized)
    (asserts! (get is-active pool-data) err-pool-closed)

    (map-set betting-pools
      { pool-id: validated-pool-id }
      (merge pool-data { is-active: false })
    )

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-pool-info (pool-id uint))
  (map-get? betting-pools { pool-id: pool-id })
)

(define-read-only (get-contribution-info (pool-id uint) (contributor principal))
  (map-get? pool-contributions { pool-id: pool-id, contributor: contributor })
)

(define-read-only (get-user-stats (user principal))
  (default-to { total-wagered: u0, total-won: u0, pools-participated: u0 } 
              (map-get? user-stats { user: user }))
)

(define-read-only (get-current-pool-id)
  (var-get next-pool-id)
)

(define-read-only (get-platform-fee-rate)
  (var-get platform-fee-rate)
)

(define-read-only (calculate-pool-odds (pool-id uint))
  (match (get-pool-info pool-id)
    pool-data
      (let
        (
          (total-a (get total-pool-a pool-data))
          (total-b (get total-pool-b pool-data))
          (total-pool (+ total-a total-b))
        )
        (if (> total-pool u0)
          {
            odds-a: (if (> total-a u0) (/ (* total-pool u100) total-a) u0),
            odds-b: (if (> total-b u0) (/ (* total-pool u100) total-b) u0)
          }
          { odds-a: u0, odds-b: u0 }
        )
      )
    { odds-a: u0, odds-b: u0 }
  )
)

(define-read-only (get-potential-payout (pool-id uint) (contributor principal))
  (match (get-pool-info pool-id)
    pool-data
      (match (get-contribution-info pool-id contributor)
        contribution-data
          (let
            (
              (amount-a (get amount-a contribution-data))
              (amount-b (get amount-b contribution-data))
              (total-a (get total-pool-a pool-data))
              (total-b (get total-pool-b pool-data))
            )
            {
              payout-if-a-wins: (if (> amount-a u0) (calculate-payout amount-a total-a total-b) u0),
              payout-if-b-wins: (if (> amount-b u0) (calculate-payout amount-b total-b total-a) u0)
            }
          )
        { payout-if-a-wins: u0, payout-if-b-wins: u0 }
      )
    { payout-if-a-wins: u0, payout-if-b-wins: u0 }
  )
)

(define-read-only (is-pool-active (pool-id uint))
  (match (get-pool-info pool-id)
    pool-data (and (get is-active pool-data) (< block-height (get deadline pool-data)))
    false
  )
)
