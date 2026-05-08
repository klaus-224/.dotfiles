use modules::modules::{Battery, Cpu, Memory};
use modules::{modules::ToModule, Module};

pub fn get_modules() -> Vec<Module<Box<dyn ToModule>>> {
    [
        Some(Cpu::new(2, 2).into()),
        Some(Memory::new(2, 2).into()),
        Battery::try_new(2).ok().flatten().map(Into::into),
    ]
    .into_iter()
    .flatten()
    .collect()
}

pub const PRE_MODULES: &str = "";
pub const BETWEEN_MODULES: &str = " ";
pub const POST_MODULES: &str = "";
pub const FASTEST_INTERVALL: std::time::Duration = std::time::Duration::from_secs(1);
