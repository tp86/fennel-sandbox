(fn test [modname]
  (print "testing" modname)
  (let [(ok err) (pcall #(require modname))]
    (print ok)
    (print err)))
(test :a)
(test :c.d)
(test :c)
(test :lfs)
(test :lu)
(import-macros {: id
                : d} :mac.test)
(print (d 2))
