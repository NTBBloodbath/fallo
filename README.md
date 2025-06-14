<div align="center">

# Fallo

[![LuaRocks](https://img.shields.io/luarocks/v/NTBBloodbath/fallo?style=for-the-badge&logo=lua)](https://luarocks.org/modules/ntbbloodbath/fallo)
![GitHub License](https://img.shields.io/github/license/NTBBloodbath/fallo?style=for-the-badge&logo=gitbook)

Fallo (failure in Spanish) is a modern error handling library for Lua, highly inspired by Rust's `Result`.

</div>

## Usage

TBD

> [!NOTE]
>
> Check out the [examples](./examples) directory for usage examples.

## Contribute
1. Fork it (https://github.com/NTBBloodbath/fallo/fork)
2. Create your feature branch (<kbd>git checkout -b my-new-feature</kbd>)
3. Commit your changes (<kbd>git commit -am "feat: add some feature"</kbd>). **Please use [semantic commits](https://www.conventionalcommits.org/en/v1.0.0/)**.
4. Push to the branch (<kbd>git push origin my-new-feature</kbd>)
5. Create a new Pull Request.

> [!IMPORTANT]
>
> Before commit your changes, make sure to format the code by running `stylua {lua,test}/**/*.lua`, and run `busted` to make sure all tests works correctly.

## TODO
- [ ] Coroutine-based async error handling
- [ ] Expose configuration options (e.g. enable/disable stack traces)
- [ ] Improve structured errors through metatables

## License
Fallo is licensed under [LGPL-3.0+](./LICENSE).
