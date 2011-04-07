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

(def parse-git-spec (spec)
  (and (begins spec "git://")
       (iflet p (pos [in _ #\: #\#] spec 6)
         (with (repo (cut spec 0 p)
                rest (cut spec p))
           (if (begins rest "#")
                (iflet p (pos #\: rest)
                  (obj repo     repo
                       revision (cut rest 1 p)
                       file     (cut rest (+ 1 p)))
                  (obj repo     repo
                       revision (cut rest 1)))
                (obj repo repo
                     file (cut rest 1))))
         (obj repo spec))))

(testis (parse-git-spec "foo.arc") nil)

(testis (parse-git-spec "git://github.com/nex3/arc.git")
        (obj repo "git://github.com/nex3/arc.git"))

(testis (parse-git-spec "git://github.com/nex3/arc.git:lib/ns.arc")
        (obj repo "git://github.com/nex3/arc.git"
             file "lib/ns.arc"))

(testis (parse-git-spec "git://github.com/nex3/arc.git#arcc")
        (obj repo     "git://github.com/nex3/arc.git"
             revision "arcc"))

(testis (parse-git-spec "git://github.com/nex3/arc.git#arcc:arcc/ac.arc")
        (obj repo     "git://github.com/nex3/arc.git"
             revision "arcc"
             file     "arcc/ac.arc"))

(def path xs
  (string (intersperse "/" xs)))

(testis (path "abc") "abc")
(testis (path "abc" "def") "abc/def")
(testis (path "abc" "def" "ghi") "abc/def/ghi")

(def git-path (git)
  (path (filenamize (cut git!repo 6))
        (filenamize (or git!revision "master"))))

(testis (git-path (parse-git-spec "git://github.com/nex3/arc.git#arcc"))
        "github.com_nex3_arc.git/arcc")

(def git-revision (git)
  (string git!repo "#" (or git!revision "master")))

(def checkout-git (git)
  (ret gitdir (path download-dir* "git" (git-path git))
    (if (dir-exists gitdir)
         (unless (kb!fetched (git-revision git))
           (w/cwd gitdir
             ;; simply ignore errors if we're not on a branch here
             (system*code "/usr/bin/git" "pull")))
         (do (ensure-dir (dirpart gitdir))
             (w/cwd (dirpart gitdir)
               (system* "/usr/bin/git" "clone" "--no-checkout" git!repo (filepart gitdir)))))
    (unless (kb!fetched (git-revision git))
      (w/cwd gitdir
        (system* "/usr/bin/git" "checkout" (or git!revision "master")))
      (set (kb!fetched (git-revision git))))))

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
  (aif (begins-rest "./" path)
        (full-path base it)
       ;; todo check if we've run out of base path to go up
       (begins-rest "../" path)
        (full-path (dirpart base) it)
       (relative-path path)
        (string base (unless (endmatch "/" base) "/") path)
        path))

(testis (full-path "/foo/bar" "x")      "/foo/bar/x")
(testis (full-path "/foo/bar" "/baz/x") "/baz/x")
(testis (full-path "http://foo.org/" "abc") "http://foo.org/abc")
(testis (full-path "http://foo.org/" "http://example.com/abc") "http://example.com/abc")
(testis (full-path "/foo/bar" "./x")  "/foo/bar/x")
(testis (full-path "/foo/bar" "../x") "/foo/x")
(testis (full-path "https://foo.org/bar/baz" "x") "https://foo.org/bar/baz/x")
(testis (full-path "https://foo.org/bar/baz" "../x") "https://foo.org/bar/x")

(def local-file (basedir n)
  (if (begins n "/")
       n
       (do (unless basedir (err "unable to resolve local file without basedir:" n))
           (full-path basedir n))))

(def network-file? (n)
  (iflet (scheme) (urlish n)
    (in scheme "http://" "https://")))

(def git-file? (n)
  (is (car (urlish n)) "git://"))

(def git-file (hack)
  (let git (parse-git-spec hack)
    (let dir (checkout-git git)
      (path dir git!file))))

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
       (git-file? string.hack)
        (git-file string.hack)
       kb!source.hack
        (source-file it)
        (err "no source file known for hack:" hack)))
