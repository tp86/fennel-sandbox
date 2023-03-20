(local fennel (require :fennel))

(local config
  {:a {:root "./libs" :path "?.fnl"}
   :b {:root "./libs/b-version" :path "src/?.fnl"}
   :c {:root "./libs/c-mapped" :path "?:init.fnl;src/?/init.fnl;src/?:.fnl"}})

(local trimming-pattern "%?%:")
(fn handle-special-patterns [path modname]
  (if (path:match trimming-pattern)
    (values
      (path:gsub trimming-pattern "?")
      (modname:match "^[^.]+%.?(.*)"))
    (values path modname)))

(fn searcher [modname]
  (case (. config (modname:match "^([^.]+)"))
    {: root : path}
    (let [tried []
          filename (accumulate [filename nil
                                path (path:gmatch "[^;]+")
                                &until filename]
                     (let [(path modname) (handle-special-patterns path modname)
                           full-path (.. root "/" path)
                           (?filename ?error-message) (package.searchpath modname full-path)]
                       (table.insert tried ?error-message)
                       ?filename))]
      (if filename
        (values
          (partial fennel.dofile filename nil)
          filename)
        (table.concat tried "\n\t")))))

(table.insert package.searchers searcher)
