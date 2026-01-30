.data
.text
_start:
    mov $0x2, %eax
    mov $0x00000001, %edx
    mov $2, %ebx
    div %ebx
et_exit:
