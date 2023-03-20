(fn test [modname]
  (print "testing" modname)
  (let [(ok err) (pcall #(require modname))]
    (print ok)
    (print err)))
(test :a)
