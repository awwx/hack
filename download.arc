(unless bound!download-dir*
  (= download-dir* (homedir "hackinator")))

(def relpathfor (url)
  (or (begins-rest "http://" url)
      (begins-rest "https://" url)))

(def system*code args
   (apply scheme.system*/exit-code args))

(testis (system*code "/bin/true")  0)
(testis (system*code "/bin/false") 1)

(def system* args
  (or (scheme.tnil (apply scheme.system* args))
      (err "system* failed" args)))

;; todo a trailing / in the url will cause wget to download to
;; "index.html", but we don't return that filename.

(def download (url)
  (iflet relpath (relpathfor url)
    (ret file (+ download-dir* "/web-cache/" (relpathfor url))
      (unless (file-exists file)
        (system* "/usr/bin/wget"
                 "--no-verbose"
                 "--no-clobber"
                 "--force-directories"
                 ;; wget appears to be confused by github's "*.github.com"
                 ;; certificate, rather unfortunately
                 "--no-check-certificate"
                 "--directory-prefix" (string download-dir* "/web-cache")
                 url)))
    url))
