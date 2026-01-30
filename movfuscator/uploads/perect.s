.data
    x: .long 5
    fs: .asciz "%d"

.text
.global main

main:
    
    mov x, %eax
    push %eax
    call fact
    addl $4, %esp

    push %eax
    push $fs
    call printf
    add $8, %esp

    xor %eax, %eax
    ret

fact:
    enter $0, $0

    mov 8(%ebp), %eax
    cmp $0, %eax
    je ret1

    dec %eax
    push %eax
    call fact
    add $4, %esp

    mul 8(%ebp)

    leave
    ret

ret1:
    mov $1, %eax
    leave
    ret