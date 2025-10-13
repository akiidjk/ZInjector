const win32 = @import("win32");

pub const system = win32.system;
pub const threads = system.threading;
pub const mem = system.memory;
pub const standard = win32.foundation;
pub const services = win32.system.system_services;
pub const ui = win32.ui;

pub const FALSE = win32.everything.FALSE;
pub const TRUE = win32.everything.TRUE;
pub const INFINITE = win32.everything.INFINITE;
