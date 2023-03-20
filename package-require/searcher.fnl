(local fennel (require :fennel))

(local config
  {:a {:root "./libs" :path "?.fnl"}
   :b {:root "./libs/b-version" :path "src/?.fnl"}
   :c {:root "./libs/c-mapped" :path "?:init.fnl;src/?/init.fnl;src/?:.fnl"}})

(local [dirsep pathsep substpat]
  (icollect [line (package.config:gmatch "([^\n]+)")]
    line))

(fn escape [pattern]
  (pattern:gsub "%W" "%%%1"))

(local trimming-pattern (escape (.. substpat ":")))

(fn handle-special-patterns [path modname]
  (if (path:match trimming-pattern)
    (values
      (path:gsub trimming-pattern substpat)
      (modname:match "^[^.]+%.?(.*)"))
    (values path modname)))

(fn searcher [modname]
  (case (. config (modname:match "^([^.]+)"))
    {: root : path}
    (let [tried []
          filename (accumulate [filename nil
                                path (path:gmatch (: "[^%s]+" :format (escape pathsep)))
                                &until filename]
                     (let [(path modname) (handle-special-patterns path modname)
                           full-path (.. root dirsep path)
                           (?filename ?error-message) (fennel.search-module modname full-path)]
                       (table.insert tried ?error-message)
                       ?filename))]
      (if filename
        (values
          (partial fennel.dofile filename nil)
          filename)
        (let [tried-files (table.concat tried "\n\t")]
          (if (< _VERSION "Lua 5.4")
            (.. "\n\t" tried-files)
            tried-files))))))

(table.insert (or package.loaders package.searchers) searcher)
