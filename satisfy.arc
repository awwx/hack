; Any sufficiently complicated Lisp program contains an ad-hoc,
; informally-specified, bug-ridden, slow implementation of half of a
; constraint satisfaction solver?

; In particular, I foolishly enumerate all options, and then sort by
; preference.  Naturally impractical for anything but the most trivial
; problems, but maybe useful as a model.

(def new-kb ()
  (obj conflicts (table) needs (table)
       alternatives-to (table) alternatives-for (table)
       before (table) after (table) abstract (table)
       preference (table) source (table) apply (table)
       patch (table) filename (table) have (table)
       wanted (queue) fetched (table)))

(implicit kb (new-kb))

(def copy-kb (x)
  (case type.x
    cons  (cons (copy-kb car.x) (copy-kb cdr.x))
    table (let h (table)
            (each (k v) x
              (= (h (copy-kb k)) (copy-kb v)))
            h)
          x))

(def all-of (relation a)
  (keys kb.relation.a))

(def transitive-closure (relation inverse x y)
  (if (is x y)
       (err "oops, application of" relation "to itself" x))

  (if (or kb.relation.x.y kb.inverse.y.x)
       (err "conflicting" relation x y))

  (unless kb.relation.y.x

    (or= kb.relation.y (table))
    (set kb.relation.y.x)
    (or= kb.inverse.x (table))
    (set kb.inverse.x.y)

    (map [transitive-closure relation inverse x _] (all-of inverse y))
    (map [transitive-closure relation inverse _ y] (all-of relation x)))
  t)

; A patches B

(def patches (a b)
  (= kb!patch.a b)
  (= kb!apply.a 'patch)
  (need a b))

; the hack that A patches

(def hack-patched-by (a)
  kb!patch.a)

; A and B conflict if both applied in the same program

(def conflict (a b)
  (if (is a b) (err "hack can't conflict with itself" a))
  (set (kb!conflicts (list a b)))
  (set (kb!conflicts (list b a))))

(def conflicts (a b)
  (kb!conflicts (list a b)))

(w/kb (new-kb)
  (conflict 'a 'b)
  (testis (conflicts 'a 'b) t)
  (testis (conflicts 'b 'a) t)
  (testis (conflicts 'a 'c) nil))

(def maxif (a b)
  (if (and a b)
       (max a b)
      a a
      b b))
      
(testis (maxif 3 5)     5)
(testis (maxif 3 nil)   3)
(testis (maxif nil 5)   5)
(testis (maxif nil nil) nil)

(def preference (hack pref)
  (= kb!preference.hack (maxif pref kb!preference.hack)))

(def prefer (hack)
  (preference hack 2))

(def recommend (hack)
  (preference hack 0.5))

(def pref (hack)
  (or kb!preference.hack 0))

(def better1 (hacka hackb)
  (> pref.hacka pref.hackb))

(def score (hacks)
  (sum pref hacks))

(w/kb (new-kb)
  (preference 'a 2)
  (preference 'b -1)
  (testis (score '(a b c d)) 1))

(def better (hacks1 hacks2)
  (> (score hacks1) (score hacks2)))

(w/kb (new-kb)
  (preference 'a 2)
  (preference 'm -3)
  (testis (better '(a e f) '(b m n r s )) t))

; hack A needs hack B
;
; note this doesn't imply that one necessarily needs to be loaded
; before the other

(def need (a b)
  (unless atom.b (err "not an atom" b))
  (push b kb!needs.a))

; all the hacks that A directly needs

(def needs (a)
  kb!needs.a)

(def astring (x)
  (isa x 'string))

(def asym (x)
  (isa x 'sym))

(def less (a b)
  (if (single a)
       (less (car a) (car b))
      (acons a)
       (and (or (iso (car a) (car b)) (less (car a) (car b)))
            (less (cdr a) (cdr b)))
      (or (and asym.a asym.b) (and astring.a astring.b))
       (< a b)
      (and asym.a astring.b)
       t))

(testis (less '(a b) '(a c)) t)

(mac testset (a b)
  `(testis (sort less ,a) ,b))

(w/kb (new-kb)
  (need 'a 'b)
  (need 'a 'c)
  (testset (needs 'a) '(b c)))

; B is a drop-in replacement for A
; (not necessarily symmetric)

(def alternative (a b)
  (push b kb!alternatives-to.a)
  (push a kb!alternatives-for.b))

; applying A provides feature B

(def provide (a b)
  (abstract b)
  (alternative b a))

; all alternatives to hack A, not including A

(def alternatives-to (a)
  kb!alternatives-to.a)

(def alternatives-for (a)
  kb!alternatives-for.a)

; all alternatives to hack A, including A

(def inclusive-alternatives-to (hack)
  (cons hack (alternatives-to hack)))

(def inclusive-alternatives-for (hack)
  (cons hack (alternatives-for hack)))

; all hacks such that if the hack is going to be applied at all, it
; needs to be applied before A.

; If B needs to be applied before A, and C is a drop-in replacement
; for B, then we assume that if A and C are both loaded then C also
; needs to be applied before A.  (Maybe this won't always be true, but
; it seems like it may turn out to be a reasonable default).

(def befores (a)
  (dedup (mappend inclusive-alternatives-to (all-of 'before a))))

;; (def afters (a)
;;   (all-of 'after a))

; if A and B are both applied, B needs to be applied first

(def apply-before (a b)
  (transitive-closure 'before 'after b a))

(w/kb (new-kb)
  (apply-before 'a 'b)
  (testis (befores 'a) '(b))
  (testis (befores 'b) '())
  (testis (befores 'c) '()))

(w/kb (new-kb)
  (apply-before 'a 'b)
  (apply-before 'b 'c)
  (testset (befores 'a) '(b c)))

; A needs B, and B has to be applied first.

(def prereq (a b)
  (need a b)
  (apply-before a b))

; A is an abstract hack (such as a feature) which is used describing
; dependencies ("X needs feature A which is provided by Y"), but can't
; be loaded itself.

(def abstract (a)
  (set kb!abstract.a))

; A concrete hack is one that can actually be loaded or applied.

(def concrete (a)
  (no kb!abstract.a))

(def filenamize (hack)
  (let hack string.hack
    (urlencode
     (subst "_" "/"
      (subst "__" "_" hack)))))

(def hack-filename (hack)
  (or kb!filename.hack
      (let src kb!source.hack
        (filenamize (string hack "." (file-extension (if (atom src) src (last src))))))))

(def source (hack src)
  (= kb!source.hack src)
  (when (endmatch ".arc" (hack-filename hack))
    (= kb!apply.hack 'arc-load)
    ;; todo (prereq hack 'arc) ?
    ))

(def store (hack)
  (= kb!apply.hack 'store))

(def executable (filename)
  (= kb!executable filename))

; we already have hack A

(def have (a)
  (set kb!have.a))

(def hacks-we-already-have ()
  (keys kb!have))

(w/kb (new-kb)
  (have 'a)
  (testset (hacks-we-already-have) '(a))
  (have 'b)
  (testset (hacks-we-already-have) '(a b)))

(def has-conflict (hack recipe)
  (some [conflicts hack _] (+ (hacks-we-already-have) recipe)))

(w/kb (new-kb)
  (have 'a)
  (have 'b)
  (conflict 'a 'c)
  (testis (has-conflict 'c nil) t)
  (testis (has-conflict 'd nil) nil))

(def cross2 (l1 l2)
  (accum a
    (each x1 l1
      (each x2 l2
        (a (cons x1 x2))))))

(def cross (ls)
  (if (no ls)
       nil
      (no (cdr ls))
       (map list (car ls))
       (cross2 (car ls) (cross (cdr ls)))))

(testis (cross '((a b c) (d e) (f)))
        '((a d f) (a e f) (b d f) (b e f) (c d f) (c e f)))

(def sort-recipe (recipe)
  (sort < recipe))

(def conflicted-recipe (recipe)
  (some [has-conflict _ recipe] recipe))

(w/kb (new-kb)
  (conflict 'a 'c)
  (testis (conflicted-recipe '(a b c)) t))

(def provided (hack recipe)
  (some hack
        (mappend inclusive-alternatives-for
                 (+ (hacks-we-already-have) recipe))))

(w/kb (new-kb)
  (testis (provided 'b '(a b c)) t))

(w/kb (new-kb)
  (alternative 'a 'b)
  (testis (provided 'a '(b m n)) t)
  (testis (provided 'c '(b m n)) nil))

(def needs-satisfied (hack recipe)
  (all [provided _ recipe] (needs hack)))

(w/kb (new-kb)
  (need 'a 'b)
  (alternative 'b 'c)
  (testis (needs-satisfied 'a '(m n c o p)) t)
  (testis (needs-satisfied 'a '(m n o p)) nil))

(def unfulfilled-needs (recipe)
  (keep [~provided _ recipe] (mappend needs recipe)))

(w/kb (new-kb)
  (need 'a 'b)
  (need 'a 'c)
  (testis (unfulfilled-needs '(m n c a p)) '(b)))

(def unneeded (recipe)
  (keep [provided _ (rem _ recipe)] recipe))

(w/kb (new-kb)
  (alternative 'a 'b)
  (testis (unneeded '(a b)) '(a)))

(def dedup-recipes (recipes)
  (dedup (sort less recipes)))

(def options-for-removing-unneeded-hacks (recipe)
  (dedup-recipes
   (aif (unneeded recipe)
         (mappend [options-for-removing-unneeded-hacks (rem _ recipe)] it)
         (list recipe))))

(w/kb (new-kb)
 (alternative 'a 'b)
 (testis (options-for-removing-unneeded-hacks '(a b)) '((b))))

(w/kb (new-kb)
  (alternative 'a 'b)
  (alternative 'b 'a)
  (testis (options-for-removing-unneeded-hacks '(a b)) '((a) (b))))

(def cross-alternatives (recipe)
  (map [sort less (dedup _)]
       (cross (map inclusive-alternatives-to recipe))))

(def replacements (recipe)
  (rem conflicted-recipe
       (dedup-recipes
        (mappend [options-for-removing-unneeded-hacks _]
                 (cross-alternatives recipe)))))

(w/kb (new-kb)
  (alternative 'a 'd)
  (alternative 'b 'd)
  (testis (replacements '(a b c))
          '((a b c)
            (c d))))

(w/kb (new-kb)
  (alternative 'a 'd)
  (alternative 'b 'd)
  (alternative 'b 'e)
  (alternative 'c 'e)
  (testis (replacements '(a b c))
          '((a b c)
            (a e)
            (c d)
            (d e))))

(w/kb (new-kb)
  (alternative 'a 'd)
  (alternative 'b 'd)
  (alternative 'b 'e)
  (alternative 'c 'e)
  (conflict 'c 'd)
  (testis (replacements '(a b c))
          '((a b c)
            (a e)
            (d e))))

(def add-hack (hack recipe)
  (insert-sorted less hack
    (rem [provided _ (cons hack (rem _ recipe))] recipe)))

(w/kb (new-kb)
  (alternative 'c 'd)
  (testis (add-hack 'd '(a b c)) '(a b d)))

(def recipes-to-fulfill-need (need recipe)
  (sort less 
    (rem conflicted-recipe
         (map [add-hack _ recipe] (inclusive-alternatives-to need)))))

(w/kb (new-kb)
  (alternative 'b 'd)
  (testis (recipes-to-fulfill-need 'b '(a c m))
          '((a b c m)
            (a c d m))))

(w/kb (new-kb)
  (alternative 'b 'd)
  (conflict 'b 'm)
  (testis (recipes-to-fulfill-need 'b '(a c m))
          '((a c d m))))

(w/kb (new-kb)
  (alternative 'b 'd)
  (alternative 'c 'd)
  (testis (recipes-to-fulfill-need 'b '(a c))
          '((a b c)
            (a d))))

(def fulfill-needs (recipe)
  (aif (car (unfulfilled-needs recipe))
        (dedup-recipes (mappend fulfill-needs
                                (recipes-to-fulfill-need it recipe)))
        (list recipe)))

(w/kb (new-kb)
  (need 'a 'b)
  (need 'a 'c)
  (alternative 'b 'd)
  (alternative 'c 'd)
  (testset (fulfill-needs '(a)) '((a b c) (a d))))

(w/kb (new-kb)
  (need 'a 'b)
  (need 'b 'c)
  (testset (fulfill-needs '(a)) '((a b c))))

(def all-concrete (recipe)
  (all concrete recipe))

(def solutions (wanted)
  (keep all-concrete
        (dedup-recipes
         (mappend fulfill-needs (replacements wanted)))))

(def satisfy ((o wanted (qlist kb!wanted)))
  (sort better (solutions wanted)))

(w/kb (new-kb)
  (prereq 'a 'b)
  (alternative 'a 'c)
  (prereq 'c 'd)
  (preference 'b 1)
  (preference 'd 2)
  (testis (satisfy '(a)) '((c d) (a b))))

(w/kb (new-kb)
  (provide 'a 'f)
  (provide 'b 'f)
  (preference 'a 1)
  (preference 'b 2)
  (testis (satisfy '(f)) '((b) (a))))

(def can-load-first (hack hacks)
  (~find [mem _ (befores hack)] hacks))

(w/kb (new-kb)
  (apply-before 'a 'b)
  (apply-before 'b 'c)
  (testis (can-load-first 'a '(b c d)) nil)
  (testis (can-load-first 'b '(a c d)) nil)
  (testis (can-load-first 'c '(a b d)) t))

;; if circular load dependencies are ever a problem in practice they
;; should be a conflict instead of an error

(def load-order (recipe)
  (if (or (no recipe) (single recipe))
       recipe
       (let next (find [can-load-first _ (rem _ recipe)] recipe)
         (unless next (err "circular load order" recipe))
         (cons next (load-order (rem next recipe))))))

(w/kb (new-kb)
  (apply-before 'a 'b)
  (apply-before 'b 'c)
  (testis (load-order '(b c a)) '(c b a)))
