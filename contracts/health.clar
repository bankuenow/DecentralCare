;; DecentralCare Health Insurance Marketplace Smart Contract

;; Error Constants
(define-constant ERR_ACCESS_DENIED (err u1000))
(define-constant ERR_ADMIN_ONLY (err u1001))
(define-constant ERR_DUPLICATE_RECORD (err u1002))
(define-constant ERR_RECORD_NOT_FOUND (err u1003))
(define-constant ERR_FUNDS_SHORTAGE (err u1004))
(define-constant ERR_PLAN_NOT_FOUND (err u1005))
(define-constant ERR_COVERAGE_EXPIRED (err u1006))
(define-constant ERR_NO_COVERAGE (err u1007))
(define-constant ERR_PAYMENT_INVALID (err u1008))
(define-constant ERR_PLAN_INACTIVE (err u1009))
(define-constant ERR_INVALID_CLAIM (err u1010))
(define-constant ERR_CLAIM_PROCESSED (err u1011))
(define-constant ERR_INVALID_DURATION (err u1012))
(define-constant ERR_LIMIT_REACHED (err u1013))
(define-constant ERR_INVALID_RATE (err u1014))
(define-constant ERR_INVALID_CATEGORY (err u1015))
(define-constant ERR_INVALID_DESCRIPTION (err u1016))

;; Contract Owner
(define-constant CONTRACT_OWNER tx-sender)

;; Data Variables
(define-data-var treasury-balance uint u0)
(define-data-var total-active-plans uint u0)
(define-data-var claim-counter uint u0)
(define-data-var system-paused bool false)

;; Constants
(define-constant ANNUAL_BLOCK_COUNT u52560)
(define-constant MIN_PREMIUM_AMOUNT u1000)
(define-constant MAX_COVERAGE_AMOUNT u1000000000)
(define-constant MAX_PLANS_PER_PROVIDER u1000)

;; Principal Maps
(define-map healthcare-providers principal
    {
        license-valid: bool,
        plan-count: uint,
        quality-rating: uint,
        active-status: bool,
        registration-height: uint,
        last-update-height: uint
    }
)

(define-map members principal
    {
        is-covered: bool,
        plan-id: uint,
        total-coverage: uint,
        monthly-premium: uint,
        start-height: uint,
        end-height: uint,
        claim-count: uint,
        last-claim-height: uint
    }
)

(define-map health-plans uint
    {
        provider-address: principal,
        health-category: (string-ascii 64),
        premium-rate: uint,
        max-coverage: uint,
        is-active: bool,
        member-count: uint,
        creation-height: uint,
        min-term-blocks: uint,
        max-term-blocks: uint
    }
)

(define-map medical-claims uint
    {
        member-address: principal,
        claim-amount: uint,
        status: (string-ascii 20),
        review-height: uint,
        health-description: (string-ascii 256),
        reviewer: (optional principal),
        processing-duration: uint
    }
)

;; Private Functions
(define-private (check-admin-privileges)
    (is-eq tx-sender CONTRACT_OWNER)
)

(define-private (check-premium-amount (premium-amount uint))
    (>= premium-amount MIN_PREMIUM_AMOUNT)
)

(define-private (check-coverage-amount (coverage-amount uint))
    (and 
        (> coverage-amount u0)
        (<= coverage-amount MAX_COVERAGE_AMOUNT)
    )
)

(define-private (check-category-validity (health-category (string-ascii 64)))
    (let ((category-length (len health-category)))
        (and (> category-length u0) (<= category-length u64))
    )
)

(define-private (check-description-validity (health-description (string-ascii 256)))
    (let ((description-length (len health-description)))
        (and (> description-length u0) (<= description-length u256))
    )
)

;; Read-Only Functions
(define-read-only (get-provider-info (provider-address principal))
    (map-get? healthcare-providers provider-address)
)

(define-read-only (get-member-info (member-address principal))
    (map-get? members member-address)
)

(define-read-only (get-plan-info (plan-id uint))
    (map-get? health-plans plan-id)
)

(define-read-only (get-claim-info (claim-id uint))
    (map-get? medical-claims claim-id)
)

(define-read-only (get-treasury-balance)
    (var-get treasury-balance)
)

(define-read-only (is-system-paused)
    (var-get system-paused)
)

;; Public Functions

;; Register new healthcare provider
(define-public (register-healthcare-provider)
    (let (
        (existing-provider (map-get? healthcare-providers tx-sender))
        (current-height block-height)
    )
    (asserts! (not (var-get system-paused)) ERR_ACCESS_DENIED)
    (asserts! (is-none existing-provider) ERR_DUPLICATE_RECORD)
    (map-set healthcare-providers tx-sender
        {
            license-valid: true,
            plan-count: u0,
            quality-rating: u100,
            active-status: true,
            registration-height: current-height,
            last-update-height: current-height
        }
    )
    (ok true))
)

;; Create new health plan
(define-public (create-health-plan 
    (health-category (string-ascii 64)) 
    (premium-rate uint) 
    (max-coverage uint)
    (min-duration uint)
    (max-duration uint)
)
    (let (
        (provider-info (unwrap! (map-get? healthcare-providers tx-sender) ERR_RECORD_NOT_FOUND))
        (new-plan-id (var-get total-active-plans))
        (current-height block-height)
    )
    (asserts! (not (var-get system-paused)) ERR_ACCESS_DENIED)
    (asserts! (get license-valid provider-info) ERR_ACCESS_DENIED)
    (asserts! (get active-status provider-info) ERR_ACCESS_DENIED)
    (asserts! (< (get plan-count provider-info) MAX_PLANS_PER_PROVIDER) ERR_LIMIT_REACHED)
    (asserts! (check-premium-amount premium-rate) ERR_INVALID_RATE)
    (asserts! (check-coverage-amount max-coverage) ERR_PAYMENT_INVALID)
    (asserts! (>= max-duration min-duration) ERR_INVALID_DURATION)
    (asserts! (check-category-validity health-category) ERR_INVALID_CATEGORY)
    
    (map-set health-plans new-plan-id
        {
            provider-address: tx-sender,
            health-category: health-category,
            premium-rate: premium-rate,
            max-coverage: max-coverage,
            is-active: true,
            member-count: u0,
            creation-height: current-height,
            min-term-blocks: min-duration,
            max-term-blocks: max-duration
        }
    )
    (var-set total-active-plans (+ new-plan-id u1))
    (ok new-plan-id))
)

;; Purchase health plan
(define-public (purchase-health-plan (plan-id uint) (coverage-duration uint))
    (let (
        (selected-plan (unwrap! (map-get? health-plans plan-id) ERR_PLAN_NOT_FOUND))
        (current-height block-height)
        (premium-amount (get premium-rate selected-plan))
    )
    (asserts! (not (var-get system-paused)) ERR_ACCESS_DENIED)
    (asserts! (get is-active selected-plan) ERR_PLAN_INACTIVE)
    (asserts! (is-none (map-get? members tx-sender)) ERR_DUPLICATE_RECORD)
    (asserts! (and 
        (>= coverage-duration (get min-term-blocks selected-plan))
        (<= coverage-duration (get max-term-blocks selected-plan))
    ) ERR_INVALID_DURATION)
    
    (try! (stx-transfer? premium-amount tx-sender (get provider-address selected-plan)))
    
    ;; Update treasury
    (var-set treasury-balance (+ (var-get treasury-balance) premium-amount))
    
    ;; Register member
    (map-set members tx-sender
        {
            is-covered: true,
            plan-id: plan-id,
            total-coverage: (get max-coverage selected-plan),
            monthly-premium: premium-amount,
            start-height: current-height,
            end-height: (+ current-height (* coverage-duration ANNUAL_BLOCK_COUNT)),
            claim-count: u0,
            last-claim-height: u0
        }
    )
    
    ;; Update enrollment count
    (map-set health-plans plan-id
        (merge selected-plan { member-count: (+ (get member-count selected-plan) u1) })
    )
    (ok true))
)

;; Submit health claim
(define-public (submit-health-claim (claim-amount uint) (health-description (string-ascii 256)))
    (let (
        (member-info (unwrap! (map-get? members tx-sender) ERR_NO_COVERAGE))
        (plan-info (unwrap! (map-get? health-plans (get plan-id member-info)) ERR_PLAN_NOT_FOUND))
        (new-claim-id (var-get claim-counter))
        (current-height block-height)
    )
    (asserts! (not (var-get system-paused)) ERR_ACCESS_DENIED)
    (asserts! (get is-covered member-info) ERR_NO_COVERAGE)
    (asserts! (<= claim-amount (get total-coverage member-info)) ERR_PAYMENT_INVALID)
    (asserts! (<= current-height (get end-height member-info)) ERR_COVERAGE_EXPIRED)
    (asserts! (check-description-validity health-description) ERR_INVALID_DESCRIPTION)
    
    ;; Create new claim
    (map-set medical-claims new-claim-id
        {
            member-address: tx-sender,
            claim-amount: claim-amount,
            status: "PENDING",
            review-height: u0,
            health-description: health-description,
            reviewer: none,
            processing-duration: u0
        }
    )
    
    ;; Update claims counter
    (var-set claim-counter (+ new-claim-id u1))
    (ok new-claim-id))
)

;; Process health claim
(define-public (process-health-claim (claim-id uint) (approve-claim bool))
    (let (
        (claim-info (unwrap! (map-get? medical-claims claim-id) ERR_INVALID_CLAIM))
        (member-info (unwrap! (map-get? members (get member-address claim-info)) ERR_NO_COVERAGE))
        (plan-info (unwrap! (map-get? health-plans (get plan-id member-info)) ERR_PLAN_NOT_FOUND))
        (current-height block-height)
    )
    (asserts! (not (var-get system-paused)) ERR_ACCESS_DENIED)
    (asserts! (is-eq tx-sender (get provider-address plan-info)) ERR_ACCESS_DENIED)
    (asserts! (is-eq (get status claim-info) "PENDING") ERR_CLAIM_PROCESSED)
    
    (if approve-claim
        (begin
            ;; Transfer claim amount
            (try! (stx-transfer? (get claim-amount claim-info) (get provider-address plan-info) (get member-address claim-info)))
            ;; Update claim status
            (map-set medical-claims claim-id
                (merge claim-info { 
                    status: "APPROVED",
                    review-height: current-height,
                    reviewer: (some tx-sender),
                    processing-duration: (- current-height (get review-height claim-info))
                })
            )
            ;; Update pool balance
            (var-set treasury-balance (- (var-get treasury-balance) (get claim-amount claim-info)))
        )
        ;; Reject claim
        (map-set medical-claims claim-id
            (merge claim-info { 
                status: "REJECTED",
                review-height: current-height,
                reviewer: (some tx-sender),
                processing-duration: (- current-height (get review-height claim-info))
            })
        )
    )
    (ok true))
)

;; Cancel health plan
(define-public (cancel-health-plan)
    (let (
        (member-info (unwrap! (map-get? members tx-sender) ERR_NO_COVERAGE))
        (plan-info (unwrap! (map-get? health-plans (get plan-id member-info)) ERR_PLAN_NOT_FOUND))
        (remaining-blocks (- (get end-height member-info) block-height))
        (refund-amount (/ (* remaining-blocks (get monthly-premium member-info)) ANNUAL_BLOCK_COUNT))
    )
    (asserts! (not (var-get system-paused)) ERR_ACCESS_DENIED)
    (asserts! (get is-covered member-info) ERR_NO_COVERAGE)
    
    ;; Process refund
    (try! (stx-transfer? refund-amount (get provider-address plan-info) tx-sender))

    ;; Update treasury balance
    (var-set treasury-balance (- (var-get treasury-balance) refund-amount))
    
    ;; Remove member
    (map-delete members tx-sender)
    
    ;; Update enrollment count
    (map-set health-plans (get plan-id member-info)
        (merge plan-info { member-count: (- (get member-count plan-info) u1) })
    )
    (ok true))
)

;; System pause/unpause
(define-public (set-system-status (new-status bool))
    (begin
        (asserts! (check-admin-privileges) ERR_ADMIN_ONLY)
        (var-set system-paused new-status)
        (ok true))
)

;; Emergency shutdown
(define-public (emergency-shutdown)
    (begin
        (asserts! (check-admin-privileges) ERR_ADMIN_ONLY)
        (var-set system-paused true)
        (ok true))
)