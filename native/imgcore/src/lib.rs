rustler::init!("Elixir.PolicrMini.ImgCore", [hello]);

#[rustler::nif]
fn hello(name: String) -> String {
    _hello(name)
}

fn _hello(name: String) -> String {
    format!("Hello, {}!", name)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hello() {
        let result = _hello(String::from("imgcore"));
        assert_eq!(result, "Hello, imgcore!");
    }
}
