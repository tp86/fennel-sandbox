(local fennel (require :fennel))

(local config
  {:a {:root "./libs" :path "?.fnl"}
   :b {:root "./libs/b-version" :path "src/?.fnl"}})

(fn searcher [modname]
  (case (. config (modname:match "^([^.]+)"))
    {: root : path}
    (let [search-path (.. root "/" path)
          filename (package.searchpath modname search-path)]
      (when filename
        (values
          (partial fennel.dofile filename nil)
          filename)))

    _ (print "searching skipped")))

(table.insert package.searchers 2 searcher)
