#include <stdio.h>
#include <stdint.h>
#include <vpi_user.h>

static uint32_t get_vpi_u32(vpiHandle h) {
    s_vpi_value val_s;
    val_s.format = vpiIntVal;
    vpi_get_value(h, &val_s);
    return (uint32_t)val_s.value.integer;
}

static int alu_predict_calltf(PLI_BYTE8 *user_data) {
    vpiHandle systf_handle, arg_itr, h_a, h_b, h_op, h_res, h_z, h_s, h_c, h_o;
    uint32_t a, b, opcode;
    uint32_t result = 0;
    uint8_t zero_flag = 0, sign_flag = 0, carry_flag = 0, overflow_flag = 0;

    systf_handle = vpi_handle(vpiSysTfCall, NULL);
    arg_itr = vpi_iterate(vpiArgument, systf_handle);
    
    h_a    = vpi_scan(arg_itr);
    h_b    = vpi_scan(arg_itr);
    h_op   = vpi_scan(arg_itr);
    h_res  = vpi_scan(arg_itr);
    h_z    = vpi_scan(arg_itr);
    h_s    = vpi_scan(arg_itr);
    h_c    = vpi_scan(arg_itr);
    h_o    = vpi_scan(arg_itr);

    a      = get_vpi_u32(h_a);
    b      = get_vpi_u32(h_b);
    opcode = get_vpi_u32(h_op) & 0xF;

    uint8_t shamt = b & 0x1F;

    switch(opcode) {
        case 0x0: // ADD
        {
            uint64_t sum = (uint64_t)a + (uint64_t)b;
            result = (uint32_t)sum;
            carry_flag = (sum >> 32) & 1;
            overflow_flag = ((~(a ^ b)) & (a ^ result)) >> 31;
            break;
        }
        case 0x1: // SUB
        {
            uint64_t diff = (uint64_t)a - (uint64_t)b;
            result = (uint32_t)diff;
            carry_flag = (diff >> 32) & 1;
            overflow_flag = ((a ^ b) & (a ^ result)) >> 31;
            break;
        }
        case 0x2: // AND
            result = a & b;
            break;
        case 0x3: // OR
            result = a | b;
            break;
        case 0x4: // XOR
            result = a ^ b;
            break;
        case 0x5: // SLT
            result = (a < b) ? 1 : 0;
            break;
        case 0x6: // SLL
            if (shamt != 0) {
                carry_flag = (a >> (32 - shamt)) & 1;
            } else {
                carry_flag = 0;
            }
            result = a << shamt;
            break;
        case 0x7: // SRL
            result = a >> shamt;
            break;
        case 0x8: // SRA
            // cast a to signed
            result = (int32_t)a >> shamt;
            break;
        default:
            break;
    }

    zero_flag = (result == 0);
    sign_flag = (result >> 31) & 1;

    s_vpi_value out_val;
    out_val.format = vpiIntVal;

    out_val.value.integer = result;
    vpi_put_value(h_res, &out_val, NULL, vpiNoDelay);

    out_val.value.integer = zero_flag;
    vpi_put_value(h_z, &out_val, NULL, vpiNoDelay);
    
    out_val.value.integer = sign_flag;
    vpi_put_value(h_s, &out_val, NULL, vpiNoDelay);

    out_val.value.integer = carry_flag;
    vpi_put_value(h_c, &out_val, NULL, vpiNoDelay);

    out_val.value.integer = overflow_flag;
    vpi_put_value(h_o, &out_val, NULL, vpiNoDelay);
    
    vpi_free_object(arg_itr);
    return 0;
}

void register_alu_predict_systf() {
    s_vpi_systf_data tf_data;

    tf_data.type        = vpiSysTask;
    tf_data.sysfunctype = 0;
    tf_data.tfname      = "$alu_predict_vpi";
    tf_data.calltf      = alu_predict_calltf;
    tf_data.compiletf   = NULL;
    tf_data.sizetf      = NULL;
    tf_data.user_data   = NULL;
    vpi_register_systf(&tf_data);
}

void (*vlog_startup_routines[])(void) = {
    register_alu_predict_systf,
    0
};