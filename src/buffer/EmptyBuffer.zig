const root = @import("root");
const Buffer = root.Buffer;

_empty: void,

// pub fn buffer() Buffer {
//     return Buffer{
//         .dataptr = undefined,
//         .vtable = &.{
//             .edit = root.Buffer.BufferVtable.nullEdit,
//             .move = root.Buffer.BufferVtable.nullMove,
//         },
//     };
// }
