;; CertificationRegistry: Professional Credential Verification System
;; Version: 1.0.0
(define-constant ERR-NOT-ISSUER (err u1))
(define-constant ERR-CREDENTIAL-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-REGISTERED (err u3))
(define-constant ERR-INVALID-STATUS (err u4))
(define-constant ERR-INVALID-LEVEL (err u5))
(define-constant ERR-INVALID-FIELD (err u6))
(define-constant ERR-INVALID-TYPE (err u7))
(define-constant ERR-INVALID-TITLE (err u8))
(define-constant ERR-INVALID-DESCRIPTION (err u9))
(define-constant MIN-LEVEL u1)
(define-data-var next-credential-id uint u1)
(define-map credentials
    uint
    {
        issuer: principal,
        credential-title: (string-utf8 50),
        credential-description: (string-utf8 200),
        field-of-study: (string-utf8 10),
        credential-type: (string-utf8 20),
        status: (string-utf8 10),
        expertise-level: uint
    }
)
(define-private (validate-field (field (string-utf8 10)))
    (or 
        (is-eq field u"Technology")
        (is-eq field u"Medicine")
        (is-eq field u"Finance")
        (is-eq field u"Education")
        (is-eq field u"Legal")
        (is-eq field u"Science")
    )
)
(define-private (validate-type (type (string-utf8 20)))
    (or 
        (is-eq type u"Degree")
        (is-eq type u"Certificate")
        (is-eq type u"License")
        (is-eq type u"Accreditation")
        (is-eq type u"Certification")
    )
)
(define-private (validate-text-length (text (string-utf8 200)) (min-length uint) (max-length uint))
    (let 
        (
            (text-length (len text))
        )
        (and 
            (>= text-length min-length)
            (<= text-length max-length)
        )
    )
)
(define-public (issue-credential 
    (credential-title (string-utf8 50))
    (credential-description (string-utf8 200))
    (field-of-study (string-utf8 10))
    (credential-type (string-utf8 20))
    (expertise-level uint)
)
    (let
        (
            (credential-id (var-get next-credential-id))
        )
        (asserts! (validate-text-length credential-title u3 u50) ERR-INVALID-TITLE)
        (asserts! (validate-text-length credential-description u10 u200) ERR-INVALID-DESCRIPTION)
        (asserts! (>= expertise-level MIN-LEVEL) ERR-INVALID-LEVEL)
        (asserts! (validate-field field-of-study) ERR-INVALID-FIELD)
        (asserts! (validate-type credential-type) ERR-INVALID-TYPE)
        
        (map-set credentials credential-id {
            issuer: tx-sender,
            credential-title: credential-title,
            credential-description: credential-description,
            field-of-study: field-of-study,
            credential-type: credential-type,
            status: u"active",
            expertise-level: expertise-level
        })
        (var-set next-credential-id (+ credential-id u1))
        (ok credential-id)
    )
)
(define-public (revoke-credential (credential-id uint))
    (let
        (
            (credential (unwrap! (map-get? credentials credential-id) ERR-CREDENTIAL-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get issuer credential)) ERR-NOT-ISSUER)
        (asserts! (is-eq (get status credential) u"active") ERR-INVALID-STATUS)
        (ok (map-set credentials credential-id (merge credential { status: u"revoked" })))
    )
)
(define-read-only (get-credential (credential-id uint))
    (ok (map-get? credentials credential-id))
)
(define-read-only (get-issuer (credential-id uint))
    (ok (get issuer (unwrap! (map-get? credentials credential-id) ERR-CREDENTIAL-NOT-FOUND)))
)
