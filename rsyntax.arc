(implicit basedir*)

(def tolist (x)
  (if (acons x) x (list x)))

(def apply-hack-assert (hack args)
  (let p args
    (let arg (fn (assert)
               (unless p (err "assertion needs argument" assert))
               (do1 car.p (= p cdr.p)))
      (while p
        (let assert (arg nil)
          (case assert
            source   (source hack (full-path basedir* (arg assert)))
            prereq   (each x (tolist (arg assert))
                       (prereq hack x))
            apply    (= kb!apply.hack (arg assert))
            need     (each x (tolist (arg assert))
                       (need hack x))
            patches  (patches hack (arg assert))
            provides (provide hack (arg assert))
            replaces (alternative (arg assert) hack)
                     (err "unknown assert" assert))
          )))))

(def apply-assertion ((hack . rest))
  (if (is hack 'base)
       (apply rsyntax-base rest)
      (is hack 'executable)
       (executable (car rest))
      (is hack 'prefer)
       (each hack rest
         (prefer hack))
       (apply-hack-assert hack rest)))

; to support using a recipe file as a script, local files can
; leave off the ".recipe" extension

(def recipe-file (n)
  (or (or (is (filepart n) "recipe")
          (is (file-extension n) "recipe"))
      (and (local-file? n)
           (in (simple-file-extension n) nil "recipe"))))
       
(def absolutize-file (basedir hack)
  (if (relative-file hack)
       (do (unless basedir (err "unable to resolve relative file without base dir" hack))
           (full-path basedir hack))
       hack))

(def wanted (hack)
  (enq (if symbolic.hack
            sym.hack
            (absolutize-file basedir* string.hack))
       kb!wanted))

(def apply-wanted (hack)
  (if (recipe-file string.hack)
       (load-recipe-file (full-path basedir* string.hack))
       (wanted hack)))

(def apply-datum (datum)
  (if (acons datum)
       (apply-assertion datum)
       (apply-wanted datum))
  nil)

(def rsyntax-base (base . datums)
  (w/basedir* base (map apply-datum datums)))

(def remove-lines-beginning-with-hash (s)
  (tostring:fromstring s
    (whilet line (readline)
      (unless (re-match "^\\s*(#)" line) (prn line)))))

(def read-recipe-file (basedir hack)
  (readall:remove-lines-beginning-with-hash:filechars:source-file
   hack basedir))

(def load-recipe-file (hack)
  (w/basedir* (dirpart hack)
    (each x (readfile (source-file hack))
      (apply-datum x))))
