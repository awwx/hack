(def sha224 (file)
  (car (tokens (tostring (system (+ "sha224sum " file))))))

(def untar (tarfile)
  (ret tardir (string download-dir* "/untar/" (sha224 tarfile))
    (unless (dir-exists tardir)
      (ensure-dir tardir)
      (w/cwd tardir
        (system* "/bin/tar"
          "-x"
          "-f" tarfile)))))

; restrictively defined to be only lower case letters

(def simple-file-extension (n)
  (aif (re-match "(\\.[a-z]+)$" n) (car it)))

(def urlish (n)
  (aif (re-match "^([a-z]+://)(.+)" n) it))

(def local-file? (n)
  (and (~urlish n)
       (or (begins n "/")
           (begins n ".")
           (simple-file-extension n))))

(def absolute-file (n)
  (in (n 0) #\/ #\. #\~))

(def relative-path (path)
  (and (~urlish path)
       (~absolute-file path)))

(def relative-file (hack)
  (and (in type.hack 'string 'sym)
       (relative-path string.hack)
       (simple-file-extension string.hack)))

(def full-path (base path)
  (if (relative-path path)
       (string base (unless (endmatch "/" base) "/") path)
       path))

(testis (full-path "/foo/bar" "x")      "/foo/bar/x")
(testis (full-path "/foo/bar" "/baz/x") "/baz/x")
(testis (full-path "http://foo.org/" "abc") "http://foo.org/abc")
(testis (full-path "http://foo.org/" "http://example.com/abc") "http://example.com/abc")

(def local-file (basedir n)
  (if (begins n "/")
       n
       (do (unless basedir (err "unable to resolve local file without basedir:" n))
           (full-path basedir n))))

(def network-file? (n)
  (iflet (scheme) (urlish n)
    (in scheme "http://" "https://")))

(def compound-file (n)
  (aif (urlish n)
        (compound-file (cadr it))
       (posmatch "//" n)))

(def compound-parts (n)
  (iflet p (posmatch "//" n (aif (urlish n) (len (car it)) 0))
    (list (cut n 0 p) (cut n (+ p 2)))))

(def unpack (n)
  (let (collection item) (compound-parts n)
    (if (endmatch ".tar" collection)
         (let tardir (untar (source-file collection))
           (ret source (string tardir "/" item)
             (unless (file-exists source)
               (err "oops, source file not found in tar file:" collection tardir item))))
         (err "don't know how to unpack" collection))))

(def symbolic (hack)
  (if (in type.hack 'string 'sym)
    (let hack string.hack
      (and (~urlish hack)
           (~simple-file-extension hack)
           (~absolute-file hack)
           (~compound-file hack)))))

(def symbolify (hack)
  (if (symbolic hack) (sym hack) hack))

(def baseof (basedir hack)
  (if ;; might need this for a symbolic name to a recipe file?
      ;;(symbolic hack)
      ;; (aand kb!src.hack (baseof it))
      (compound-file hack)
       (caseof (car compound-parts hack))
      (relative-file hack)
       basedir
      (or (absolute-file hack) (urlish hack))
       (dirpart hack)))

(def source-file (hack (o basedir))
  (aif (compound-file string.hack)
        (unpack string.hack)
       (local-file? string.hack)
        (local-file basedir string.hack)
       (network-file? string.hack)
        (download hack)
       kb!source.hack
        (source-file it)
        (err "no source file known for hack:" hack)))

