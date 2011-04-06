(def lastpos (s c (o i (- (len s) 1)))
  (if (< i 0)
       nil
      (is (s i) c)
       i
       (lastpos s c (- i 1))))

(def dirpart (path)
  (let path (trim path 'end #\/)
    (aand (lastpos path #\/)
          (cut path 0 it))))

(def filepart (path)
  (aif (lastpos path #\/)
        (cut path (+ it 1))
        path))

(def file-extension (path)
  (let n (filepart path)
    (aif (lastpos n #\.)
          (cut n (+ it 1)))))
