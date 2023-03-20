(local fennel (require :fennel))

(local config
  {:a {:root "./libs" :path "?.fnl"}
   :b {:root "./libs/b-version" :path "src/?.fnl"}
   :c {:root "./libs/c-mapped" :path "?/init.fnl;src/?/init.fnl;src/?.fnl" :trim true}})

(fn searcher [modname]
  (case (. config (modname:match "^([^.]+)"))
    {: root : path :trim ?trim}
    (do
      (print "searching for" modname root path ?trim)
      (local modname (if ?trim (modname:match "^[^.]+%.?(.*)") modname))
      (let [search-path (table.concat (icollect [path (path:gmatch "[^;]+")]
                                         (.. root "/" (if ?trim (path:gsub "%?/?" "") path)))
                                      ";")
              filename (package.searchpath modname search-path)]
          (print search-path)
          (when filename
            (values
              (partial fennel.dofile filename nil)
              filename))))

    _ (print "searching skipped")))

(table.insert package.searchers searcher)
