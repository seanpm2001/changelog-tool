use "files"
use "options"
use ".deps/sylvanc/peg"

/*
1. have a part that can validate a changelog file

2. have a part that can remove entries after validating

we want to use part 1 when CI runs

to not allow “invalid” changelogs through

because otherwise removal will go boom

also

look now our CHANGELOG is a langauge
  
lulz
*/

actor Main
  let _env: Env
  var _filename: String = ""
  var _verify: Bool = false

  new create(env: Env) =>
    _env = env
    let options = Options(_env.args)
      .> add("verify", "v", None, Optional)
      // TODO remove empty sections from unreleased, create new unreleased section (release)

    _filename =
      try _env.args(1)
      else usage(); return
      end

    for option in options do
      match option
      | ("verify", None) => _verify = true
      | let err: ParseError =>
        err.report(_env.err)
        usage()
      end
    end

    if _verify then verify()
    else usage()
    end

  fun usage() =>
    _env.out.print(
      """
      changelog-tools <changelog file> [OPTIONS]

      Options:
        --verify, -v     Verify that the changelog is valid.
      """)

  fun verify() =>
    _env.out.print("verifying " + _filename + "...")

    let p = ChangelogParser().eof() 

    let ast =
      with
        file =
          try OpenFile(FilePath(_env.root as AmbientAuth, _filename)) as File
          else _env.err.print("unable to open: " + _filename); return
          end
      do
        let source: String = file.read_string(file.size())
        match p.parse(source)
        | (let n: USize, let ast': AST) =>
          //_env.out.print(recover val Printer(r) end)
          ast'
        | (let offset: USize, let r: Parser) =>
          _env.err.print(String.join(Error(_filename, source, offset, r)))
          return
        else
          _env.err.print("unable to parse file: " + _filename)
          return
        end
      end

    // TODO verification steps on AST

    // _env.out.print(_filename + " is a valid changelog")
