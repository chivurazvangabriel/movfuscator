.data

# LOOKUP TABLES
.align 4

.macro dt v
    .byte \v
.endm
.equ max_n, 256
.equ max_n_half, 127

# Logic Signed Grids
.macro gen_logic_grid name, operator
\name\():
    .set i, 0
    .rept max_n
        .set i_s, i
        .if i > max_n_half
            .set i_s, i - max_n
        .endif
        
        .set j, 0
        .rept max_n
            .set j_s, j
            .if j > max_n_half
                .set j_s, j - max_n
            .endif
            
            
            .if \operator == 1  # EQ
                .set k, (i_s == j_s)
            .elseif \operator == 2 # NEQ
                .set k, (i_s != j_s)
            .elseif \operator == 3 # G
                .set k, (i_s > j_s)
            .elseif \operator == 4 # GE
                .set k, (i_s >= j_s)
            .elseif \operator == 5 # L
                .set k, (i_s < j_s)
            .elseif \operator == 6 # LE
                .set k, (i_s <= j_s)
            .endif

            .if k == 0
                dt 0
            .else
                dt 1
            .endif
            
            .set j, j + 1
        .endr
        .set i, i + 1
    .endr
.endm

gen_logic_grid eq_grid, 1
gen_logic_grid neq_grid, 2
gen_logic_grid g_grid, 3
gen_logic_grid ge_grid, 4
gen_logic_grid l_grid, 5
gen_logic_grid le_grid, 6

sum_grid:
    .set i, 0
    .rept max_n
        .set j, 0
        .rept max_n
            .byte (i + j) & 0xFF
            .set j, j + 1
        .endr 
        .set i, i + 1
    .endr
sub_grid:
    .set i, 0
    .rept max_n
        .set j, 0
        .rept max_n
            .byte (i - j) & 0xFF
            .set j, j + 1
        .endr 
        .set i, i + 1
    .endr

mul_grid:
    .set i, 0
    .rept max_n
        .set j, 0
        .rept max_n
            .byte (i * j) & 0xFF
            .set j, j + 1
        .endr 
        .set i, i + 1
    .endr

div_grid:
    .set i, 0
    .rept max_n
        .set i_s, i
        .if i > max_n_half
            .set i_s, i - max_n
        .endif
        
        .set j, 0
        .rept max_n
            .set j_s, j
            .if j > max_n_half
                .set j_s, j - max_n
            .endif
            
            .if j_s != 0
                .byte (i_s / j_s) & 0xFF
            .else
                .byte 0
            .endif
            .set j, j + 1
        .endr 
        .set i, i + 1
    .endr

and_grid:
    .set i, 0
    .rept max_n
        .set j, 0
        .rept max_n
            .byte i & j
            .set j, j + 1
        .endr 
        .set i, i + 1
    .endr

or_grid:
    .set i, 0
    .rept max_n
        .set j, 0
        .rept max_n
            .byte i | j
            .set j, j + 1
        .endr 
        .set i, i + 1
    .endr

xor_grid:
    .set i, 0
    .rept max_n
        .set j, 0
        .rept max_n
            .byte i ^ j
            .set j, j + 1
        .endr 
        .set i, i + 1
    .endr

# VARS



fs: .asciz "%d "
fss: .asciz "%s "
endl: .asciz "\n"
f2s: .asciz "%d %d\n"


SCRATCH: dt 0

# 1 + 3 + 4 + 4 = 12 bytes
# var is at 0
# SCRATCH is at 4
# var pointer is at 8
.macro var var_name, initial_value
    \var_name\(): dt \initial_value
    .space 3
    SELECT_\var_name\(): .long SCRATCH, \var_name\()
.endm

.macro label var_name, initial_value
    \var_name\(): dt \initial_value
.endm

.altmacro
.macro label_ra var_name, index, value
    label \var_name\()_ra\index\() \value
.endm

.altmacro
.macro decl_stack_elem id
    var stack_elem_\id\(), 0
.endm

.altmacro
.macro decl_stack_elem_ptr id
    .long SELECT_stack_elem_\id\()
.endm

.equ m_stack_size, 1024

# Virtual Stack
m_stack:
    .set i, 0
    .rept m_stack_size
        decl_stack_elem %i
        .set i, i + 1
    .endr

.align 4
m_stack_ptrs:
    .set i, 0
    .rept m_stack_size
        decl_stack_elem_ptr %i
        .set i, i + 1
    .endr

# Virtual Registers

# Internal
var EXEC_ON, 1
var me, 69
var md, 0
var mdr, 0
var mi1, 0
var mi2, 0
var mi3, 0
var mi4, 0
var mc_eq, 0
var mc_neq, 0
var mc_g, 0
var mc_ge, 0
var mc_l, 0
var mc_le, 0

# For Use

var max, 0
var mbx, 0
var mcx, 0
var mdx, 0
var msi, 0
var mdi, 0
var mbp, 25
var msp, 25

# Register Belt
var m, 0
var m1, 0
var m2, 0
var m3, 0
var m4, 0
var m5, 0
var m6, 0
var m7, 0
var m8, 0

# External label pointers (printf, scanf)

label printf, 200

#
# User defined variables
#
var_decl_start:

var n, 10
var t0, 0
var t1, 5
var t2, 2


#
# User defined labels
#

label et_loop, 0
label et_exit, 1




.text
.global main

# MACROS

# Debug
.macro dbg_endl
    pushl $endl
    pushl $fss
    call printf
    addl $8, %esp
.endm

.macro dbg elem
    movsbl \elem, %eax
    pushl %eax
    call print_debug_string
    addl $4, %esp
.endm

.macro m_dbg elem
    movzbl EXEC_ON, %eax
    cmp $0, %eax
    je 3f 
    movsbl \elem, %eax
    pushl %eax
    call print_debug_string
    addl $4, %esp
    3:
.endm

.macro dbg_all
    dbg m1
    dbg m2
    dbg m3
    dbg m4
    dbg me
.endm

# Set var
.macro m_set n, val
    mov \val, %eax
    movzbl EXEC_ON, %ecx
    mov $\n\() + 4, %edx
    movl (%edx,%ecx,4), %edx
    movb %al, (%edx)
.endm

.macro m_set_f n, val
    movb \val, %al
    movb %al, \n
.endm

.macro m_mov val, n
    m_set n, val
.endm

# Arithmetic & Logic
.macro m_lookup_base table, r, arg1, arg2
    mov \arg1, %eax
    mov \arg2, %ecx
    movzbl %al, %eax
    movzbl %cl, %ecx
    movl $0, %edx
    movb %al, %dh
    movb %cl, %dl
    movsbl \table\()(,%edx,1), %ebx
    movb %bl, me
    m_set \r, me
.endm

.macro m_lookup_base_f table, r, arg1, arg2
    mov \arg1, %eax
    mov \arg2, %ecx
    movzbl %al, %eax
    movzbl %cl, %ecx
    movl $0, %edx
    movb %al, %dh
    movb %cl, %dl
    movsbl \table\()(,%edx,1), %ebx
    movb %bl, \r
.endm

.macro create_op op_name, table_name
    .macro \op_name r, a, b
        m_lookup_base \table_name, \r, \a, \b
    .endm
    .macro \op_name\()_f r, a, b
        m_lookup_base_f \table_name, \r, \a, \b
    .endm
.endm

.macro create_op_a_fromop op_name
    .macro \op_name\()_a r, d
        \op_name d, d, r
    .endm
.endm

.macro create_op_a op_name, table_name
    create_op \op_name, \table_name
    create_op_a_fromop \op_name
.endm

# Boolean Logic

create_op m_eq, eq_grid
create_op m_neq, neq_grid
create_op m_l, l_grid
create_op m_le, le_grid
create_op m_g, g_grid
create_op m_ge, ge_grid

# Logic
create_op_a m_and, and_grid
create_op_a m_or, or_grid
create_op_a m_xor, xor_grid

# Arithmetic

create_op_a m_add, sum_grid
.macro m_inc x1
    m_add_a $1, x1
.endm
create_op_a m_sub, sub_grid

.macro m_dec x1
    m_sub_a $1, x1
.endm
create_op m_mul, mul_grid
.macro m_mul_a x1
    m_mul max, max, x1
.endm
create_op m_div, div_grid
.macro m_div_a x1
    m_div max, max, x1
.endm

# Flow toggler
.macro m_sf_f value
    movb \value, %al
    movb %al, EXEC_ON
.endm

.macro m_sf value
    m_set EXEC_ON, \value
.endm

.macro m_on_f
    movl $1, %eax
    movb %al, EXEC_ON
.endm

.macro m_on
    m_on_f
.endm

.macro m_off_f
    movl $0, %eax
    movb %al, EXEC_ON
.endm

.macro m_off
    m_and EXEC_ON, EXEC_ON, $1
.endm

.macro m_end
    call return
.endm

# Jumps

.macro m_jmp dispatch_id
    m_set md, \dispatch_id
    m_off_f
.endm

.macro m_label dispatch_id
    m_on_f
    m_eq mdr, md, \dispatch_id
    m_sf mdr
.endm

.macro m_jc cond dispatch_id
    m_sf \cond
    m_set md, \dispatch_id
    m_on_f
    m_xor mdr, \cond, $1
    m_sf_f mdr
.endm

# Conditional Jumps

.macro m_cmp x2, x1
    m_eq mc_eq \x1, \x2
    m_neq mc_neq \x1, \x2
    m_l mc_l \x1, \x2
    m_le mc_le \x1, \x2
    m_g mc_g \x1, \x2
    m_ge mc_ge \x1, \x2
.endm

.macro create_conditional_jump cj_name, creg_name
    .macro \cj_name id
        m_jc \creg_name, \id
    .endm
.endm

create_conditional_jump m_je, mc_eq
create_conditional_jump m_jne, mc_neq
create_conditional_jump m_jg, mc_g
create_conditional_jump m_jge, mc_ge
create_conditional_jump m_jl, mc_l
create_conditional_jump m_jle, mc_le



# Stack Manipulation

.macro m_get_stack_elem v, offset
    m_set_f mdr, offset
    movzbl mdr, %esi
    movzbl EXEC_ON, %ecx
    movl m_stack_ptrs(,%esi,4), %edx
    movl (%edx,%ecx,4), %edx
    m_set \v, (%edx)
.endm

.macro m_set_stack_elem v, offset
    m_set_f mdr, offset
    movzbl mdr, %esi
    movzbl EXEC_ON, %ecx
    movl m_stack_ptrs(,%esi,4), %edx
    movl (%edx,%ecx,4), %edx
    movb \v, %al
    movb %al, (%edx)
.endm

.macro m_movmbp offset, reg
    m_add mi1, mbp, \offset
    m_get_stack_elem mi2, mi1
    m_mov mi2, \reg
.endm

.macro m_push v
    m_sub msp, msp, $1
    m_set_stack_elem \v, msp
.endm

.macro m_pop v
    m_get_stack_elem \v, msp
    m_set_stack_elem $-1, msp
    m_add msp, msp, $1
.endm

.macro m_call dest_label, return_adress_label
    # m_add mlp, mlp, $1
    m_push \return_adress_label
    m_jmp \dest_label
    m_label \return_adress_label
.endm

.macro m_ret
    # m_sub mlp, mlp, $1
    m_pop m1
    m_jmp m1
.endm

.macro m_enter
    m_push mbp
    m_set mbp, msp
.endm

.macro m_leave
    m_set msp, mbp
    m_pop mbp
.endm

.altmacro
.macro dbg_stack_elem index
    dbg stack_elem_\index\()
.endm

.altmacro
.macro dbg_stack
    .set i, 0
    .rept 25
        dbg_stack_elem %i
        .set i, i + 1
    .endr
    dbg_endl
.endm

#SYSCALLS

.macro m_int_exit
    m_end
.endm

.macro m_int_print_string string, length
    m_set_f mi1, $20
    m_set mi1, $4
    mov mi1, %eax
    mov $1, %ebx
    mov $\string\(), %ecx
    mov \length\(), %edx
    int $0x80
.endm

.macro m_int c
    m_set_f mi1, $20
    m_set mi1, max
    mov max, %eax
    mov mbx, %ebx
    mov mcx, %ecx
    mov mdx, %edx
    int $0x80
.endm

# Arrays

# PROGRAM
main:

    # MAIN START

        m_mov n, mcx
    m_sub_al $3, mcx
    m_label et_loop
    m_cmpl $0, mcx
    m_je et_exit
    m_mov t0, max
    m_add_a t1, max
    m_add_a t2, max
    m_mov t1, mdx
    m_mov mdx, t0
    m_mov t2, mdx
    m_mov mdx, t1
    m_mov max, t2
    m_loop et_loop
    m_label et_exit
    m_mov $1, max
    m_xor_a mbx, mbx
    m_int $0x80
    


    # MAIN END

    m_label printf
    m_movmbp $-1, max
    m_dbg max
    m_ret

    jmp main

print_debug_string:
    pushl %eax
    pushl $fs
    call printf
    addl $8, %esp
    ret
return:
    cmpb $1, EXEC_ON
    je endp

    ret

endp:
    xorl %eax, %eax
    addl $4, %esp
    ret
