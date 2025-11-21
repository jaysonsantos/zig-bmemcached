pub const ValidationError = error{
    KeyTooLong,
    ValueTooLarge,
};

pub const Request = extern struct {
    magic: Magic,
    opcode: Opcode,
    key_length: u16,
    extras_length: u8,
    data_type: u8,
    vbucket_id: u16,
    body_length: u32,
    reserved: u32,
    cas: u64,
};

pub const Response = extern struct {
    magic: Magic,
    opcode: Opcode,
    key_length: u16,
    extras_length: u8,
    data_type: u8,
    status: ResponseStatus,
    body_length: u32,
    reserved: u32,
    cas: u64,
};

pub const ResponseStatus = enum(u16) {
    no_error = 0x0000,
    key_not_found = 0x0001,
    key_exists = 0x0002,
    value_too_large = 0x0003,
    invalid_arguments = 0x0004,
    item_not_stored = 0x0005,
    incr_decr_on_non_numeric = 0x0006,
    vbucket_belongs_to_another_server = 0x0007,
    authentication_error = 0x0008,
    authentication_continue = 0x0009,
    unknown_command = 0x0081,
    out_of_memory = 0x0082,
    not_supported = 0x0083,
    internal_error = 0x0084,
    busy = 0x0085,
    temporary_failure = 0x0086,

    pub fn ensure_status_is_ok(status: *const ResponseStatus) !void {
        switch (status.*) {
            .no_error => return,
            else => unreachable // all possible errors should be declared,
        }
    }
};
pub const RequestExtras = extern struct {
    flags: u32,
    expiration: u32,
};

pub const ResponseExtras = extern struct {
    flags: u32,
};

pub const Magic = enum(u8) {
    request = 0x80,
    response = 0x81,
};

pub const Opcode = enum(u8) {
    get = 0x00,
    set = 0x01,
    add = 0x02,
    replace = 0x03,
    delete = 0x04,
    increment = 0x05,
    decrement = 0x06,
    quit = 0x07,
    flush = 0x08,
    getq = 0x09,
    noop = 0x0a,
    version = 0x0b,
    getk = 0x0c,
    getkq = 0x0d,
    append = 0x0e,
    prepend = 0x0f,
    stat = 0x10,
    setq = 0x11,
    addq = 0x12,
    replaceq = 0x13,
    deleteq = 0x14,
    incrementq = 0x15,
    decrementq = 0x16,
    quitq = 0x17,
    flushq = 0x18,
    appendq = 0x19,
    prependq = 0x1a,
    verbosity = 0x1b,
    touch = 0x1c,
    gat = 0x1d,
    gatq = 0x1e,
    sasl_list_mechs = 0x20,
    sasl_auth = 0x21,
    sasl_step = 0x22,
    rget = 0x30,
    rset = 0x31,
    rsetq = 0x32,
    rappend = 0x33,
    rappendq = 0x34,
    rprepend = 0x35,
    rprependq = 0x36,
    rdelete = 0x37,
    rdeleteq = 0x38,
    rincr = 0x39,
    rincrq = 0x3a,
    rdecr = 0x3b,
    rdecrq = 0x3c,
    set_vbucket = 0x3d,
    get_vbucket = 0x3e,
    del_vbucket = 0x3f,
    tap_connect = 0x40,
    tap_mutation = 0x41,
    tap_delete = 0x42,
    tap_flush = 0x43,
    tap_opaque = 0x44,
    tap_vbucket_set = 0x45,
    tap_checkpoint_start = 0x46,
    tap_checkpoint_end = 0x47,
};

