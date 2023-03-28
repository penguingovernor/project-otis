const std = @import("std");
const decode = @import("decode.zig");

pub const InstructionTable = decode.InstructionTable;

pub const Instruction = decode.Instruction;
pub const OperationType = decode.OperationType;
pub const RegisterAccess = decode.RegisterAccess;
pub const OperandType = decode.OperandType;
pub const DecodeError = decode.DecodeError;

pub const getVersion = decode.getVersion;
pub const get8086InstructionTable = decode.get8086InstructionTable;
pub const decode8086Instruction = decode.decode8086Instruction;
pub const mnemonicFromOperationType = decode.mnemonicFromOperationType;
pub const registerNameFromOperand = decode.registerNameFromOperand;
