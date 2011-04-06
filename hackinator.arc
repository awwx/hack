(def command-line-arguments ()
  (ac-niltree (scheme (vector->list (current-command-line-arguments)))))

(= args (command-line-arguments))

(def next ()
  (when args (do1 car.args (= args cdr.args))))

(def neednext ()
  (or (next) (err "missing argument")))

(= hacks-wanted nil)
(= destdir nil)
(= action 'run)
(wipe clean)

(while args
  (let arg (next)
    (if (begins arg "-")
         (let arg (trim arg 'front #\-)
           (case arg
             "destdir" (= destdir (neednext))
             "apply"   (= action 'apply)
             "solve"   (= action 'solve)
             "clean"   (set clean)
                       (err "unknown option" arg)))
         (push arg hacks-wanted))))

(def welcome ()
  (prn "The hackinator is at your service."))

(if hacks-wanted

     (let destdir (or destdir (tmpdir))
       (case action

         run   (run-recipe hacks-wanted destdir clean)

         apply (do (apply-recipe hacks-wanted destdir clean)
                   (prn destdir))

         solve (solve hacks-wanted)))

     (welcome))
