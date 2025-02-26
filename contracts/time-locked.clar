;; C-Vault: Decentralized Time-Locked Asset Management
;; A time-locked vault contract for STX tokens


;; Error codes
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NO_VAULT (err u101))
(define-constant ERR_VAULT_LOCKED (err u102))
(define-constant ERR_INVALID_UNLOCK_TIME (err u103))
(define-constant ERR_ZERO_DEPOSIT (err u104))
(define-constant ERR_INSUFFICIENT_FUNDS (err u105))
(define-constant ERR_BENEFICIARY_ALREADY_SET (err u106))
(define-constant ERR_INVALID_BENEFICIARY (err u107))

;; Data structures
(define-map vaults
  { owner: principal }
  {
    balance: uint,
    unlock-height: uint,
    beneficiary: (optional principal)
  }
)

;; Helper functions

;; Define our own max function since Clarity doesn't have a built-in max
(define-private (get-max (a uint) (b uint))
  (if (>= a b) a b)
)

;; Read-only functions

;; Get vault details for a user
(define-read-only (get-vault (owner principal))
  (default-to
    {
      balance: u0,
      unlock-height: u0,
      beneficiary: none
    }
    (map-get? vaults { owner: owner })
  )
)

;; Check if vault exists
(define-read-only (vault-exists (owner principal))
  (is-some (map-get? vaults { owner: owner }))
)

;; Check if vault is unlocked
(define-read-only (is-vault-unlocked (owner principal))
  (let (
    (vault (get-vault owner))
    (current-height block-height)
  )
    (>= current-height (get unlock-height vault))
  )
)

;; Public functions

;; Create or add to vault with time lock
(define-public (deposit (amount uint) (unlock-height uint))
  (let (
    (sender tx-sender)
    (current-height block-height)
    (existing-vault (get-vault sender))
  )
    ;; Validate input parameters
    (asserts! (> amount u0) ERR_ZERO_DEPOSIT)
    (asserts! (> unlock-height current-height) ERR_INVALID_UNLOCK_TIME)
    
    ;; Check if vault exists
    (if (vault-exists sender)
      ;; If vault exists, update it
      (let (
        (new-balance (+ (get balance existing-vault) amount))
        (max-unlock-height (get-max unlock-height (get unlock-height existing-vault)))
      )
        ;; Transfer STX to contract
        (try! (stx-transfer? amount sender (as-contract tx-sender)))
        
        ;; Update vault
        (map-set vaults
          { owner: sender }
          {
            balance: new-balance,
            unlock-height: max-unlock-height,
            beneficiary: (get beneficiary existing-vault)
          }
        )
        (ok new-balance)
      )
      ;; If vault doesn't exist, create it
      (begin
        ;; Transfer STX to contract
        (try! (stx-transfer? amount sender (as-contract tx-sender)))
        
        ;; Create new vault
        (map-set vaults
          { owner: sender }
          {
            balance: amount,
            unlock-height: unlock-height,
            beneficiary: none
          }
        )
        (ok amount)
      )
    )
  )
)

;; Withdraw from vault
(define-public (withdraw (amount uint))
  (let (
    (sender tx-sender)
    (vault (get-vault sender))
    (vault-balance (get balance vault))
    (unlock-height (get unlock-height vault))
  )
    ;; Check if vault exists
    (asserts! (vault-exists sender) ERR_NO_VAULT)
    
    ;; Check if amount is valid
    (asserts! (<= amount vault-balance) ERR_INSUFFICIENT_FUNDS)
    
    ;; Check if vault is unlocked
    (asserts! (is-vault-unlocked sender) ERR_VAULT_LOCKED)
    
    ;; Transfer STX from contract to sender
    (try! (as-contract (stx-transfer? amount tx-sender sender)))
    
    ;; Update vault balance
    (if (is-eq amount vault-balance)
      ;; If withdrawing entire balance, delete vault
      (map-delete vaults { owner: sender })
      ;; Otherwise update balance
      (map-set vaults
        { owner: sender }
        {
          balance: (- vault-balance amount),
          unlock-height: unlock-height,
          beneficiary: (get beneficiary vault)
        }
      )
    )
    
    (ok true)
  )
)

;; Set beneficiary for emergency access
(define-public (set-beneficiary (beneficiary-address principal))
  (let (
    (sender tx-sender)
    (vault (get-vault sender))
  )
    ;; Check if vault exists
    (asserts! (vault-exists sender) ERR_NO_VAULT)
    
    ;; Validate beneficiary address
    ;; Ensure beneficiary is not the same as owner
    (asserts! (not (is-eq beneficiary-address sender)) ERR_INVALID_BENEFICIARY)
    
    ;; Ensure beneficiary is not already set or is the same
    (asserts! (or
        (is-none (get beneficiary vault))
        (is-eq (some beneficiary-address) (get beneficiary vault))
      )
      ERR_BENEFICIARY_ALREADY_SET
    )
    
    ;; Update vault with beneficiary
    (map-set vaults
      { owner: sender }
      {
        balance: (get balance vault),
        unlock-height: (get unlock-height vault),
        beneficiary: (some beneficiary-address)
      }
    )
    
    (ok true)
  )
)

;; Beneficiary withdrawal
(define-public (beneficiary-withdraw (vault-owner principal))
  (let (
    (sender tx-sender)
    (vault (get-vault vault-owner))
    (vault-balance (get balance vault))
    (vault-beneficiary (get beneficiary vault))
  )
    ;; Check if vault exists
    (asserts! (vault-exists vault-owner) ERR_NO_VAULT)
    
    ;; Check if beneficiary is set and matches sender
    (asserts! (and
      (is-some vault-beneficiary)
      (is-eq (some sender) vault-beneficiary)
    ) ERR_UNAUTHORIZED)
    
    ;; Check if vault is unlocked
    (asserts! (is-vault-unlocked vault-owner) ERR_VAULT_LOCKED)
    
    ;; Transfer STX from contract to beneficiary
    (try! (as-contract (stx-transfer? vault-balance tx-sender sender)))
    
    ;; Delete vault after complete withdrawal
    (map-delete vaults { owner: vault-owner })
    
    (ok true)
  )
)

;; Get contract balance (for testing)
(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)