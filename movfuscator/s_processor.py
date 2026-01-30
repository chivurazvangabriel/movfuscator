import re

function_ras = []

def make_ra(ra: str):
    return f"{ra[0]}_ra{ra[1]}"

def convert_arg(arg: str):
    regs = {
        "%eax" : "max",
        "%ebx" : "mbx",
        "%ecx" : "mcx",
        "%edx" : "mdx",
        "%esi" : "msi",
        "%edi" : "mdi",
        "%ebp" : "mbp",
        "%esp" : "msp",
    }

    if regs.get(arg, "") != "":
        return regs.get(arg)
    
    if "$" in arg:
        return arg
    
    return arg

def convert_instr(instr_line: str):
    ret = instr_line
    instr_list = instr_line.split()
    if len(instr_list) == 0:
        return ""
    instr = instr_list[0]
    args = [convert_arg(x.replace(",", "")) for x in instr_list[1:]]

    if ":" in instr:
        ret = f"m_label {instr.replace(":", "")}"
    elif "(%ebp)" in instr_line:
        scale = 0
        if instr == "mov" and "(%ebp)" in args[0]:
            scale = int(args[0].replace("(%ebp)", ""))
            ret = f"m_movmbp ${scale}, {args[1]}"
    else:
        match instr:
            case "enter":
                ret = "m_enter"
            case "call":
                new_ra = (args[0], len(function_ras))
                function_ras.append(new_ra)
                ra_conv = make_ra(new_ra)
                ret = f"m_call {args[0]}, {ra_conv}"
            
            case _:
                args_str = ""
                for s in args:
                    args_str += f"{s}, "
                if args_str != "":
                    args_str = args_str[:len(args_str)-2]

                ret = f"m_{instr} {args_str}"
    
    arith = ["m_add", "m_sub", "m_mul", "m_div", "m_or", "m_xor", "m_and"]
    for k in arith:
        if k in ret:
            ret = ret.replace(k, k + "_a")
            continue

    if "msp" in ret or "mbp" in ret:
        for k in ret:
            if k in "01248":
                ret = ret.replace(k, f"{int(k)//4}")
                break

    return ret

import re

def refactor_syscalls(lines):
    """
    Takes a list of strings (assembly lines), replaces specific 
    multi-line blocks with macros, and returns a new list of strings.
    """
    
    # 1. Join the list into a single string to handle multi-line patterns easily
    # We use '\n' to ensure lines are separated correctly
    content = "\n".join(lines)
    
    # 2. Define Regex Patterns
    
    # PRINT PATTERN
    # Matches the 5-line sequence for printing:
    # mov $4, %eax -> mov $1, %ebx -> mov $VAR, %ecx -> mov $LEN, %edx -> int $0x80
    # Capture group 1: Buffer Address (e.g., x1)
    # Capture group 2: Length (e.g., 14)
    print_regex = (
        r"mov\s+\$4,\s+%eax\s+"
        r"mov\s+\$1,\s+%ebx\s+"
        r"mov\s+\$([^,\s]+),\s+%ecx\s+"  # Capture buffer
        r"mov\s+\$([^,\s]+),\s+%edx\s+"  # Capture length
        r"int\s+\$0x80"
    )
    
    # EXIT PATTERN
    # Matches the 3-line sequence for exiting:
    # movl $1, %eax -> xor %ebx, %ebx -> int $0x80
    exit_regex = (
        r"movl\s+\$1,\s+%eax\s+"
        r"xor\s+%ebx,\s+%ebx\s+"
        r"int\s+\$0x80"
    )

    # 3. Apply Substitutions
    
    # Replace print block with: m_int_print_string x1, $14
    content = re.sub(print_regex, r"int_print_string \1, $\2", content, flags=re.MULTILINE)
    
    # Replace exit block with: m_end
    content = re.sub(exit_regex, "end", content, flags=re.MULTILINE)
    
    # 4. Split back into a list and return
    return content.split("\n")

def process_s_file(input_path, output_path):
    with open(input_path, 'r') as f:
        data = f.readlines()

        result = ""
        format_text = ""
        with open("format.txt", 'r') as format:
            format_text = format.read()

        VARS, LABELS, MAIN, FUNCTION_RA, SYSCALLS = "", "", "", "", ""

        vars, labels, main_instructions, syscalls = [], [], [], []

        
        # Carve syscalls
        # I will assume there are only two types of syscalls:
        # Code 1: exit
        # Code 4: print string

        data = refactor_syscalls(data)
                
        

        # Carve vars
        found_data = False
        for line in data:
            if ".data" in line:
                found_data = True
                continue
            
            if ".text" in line:
                break

            if found_data:
                if "." in line:
                    new_var_list = line.split()
                    var_name = new_var_list[0].replace(":", "")
                    var_value = new_var_list[2]
                    if ".long" in line or ".word" in line or ".byte" in line:
                        vars.append((var_name, var_value, "int"))
                    elif ".ascii" in line:
                        vars.append((var_name, var_value, "ascii"))
                    elif ".asciz" in line:
                        vars.append((var_name, var_value, "asciz"))


            

        # Carve Labels
        for line in data:
            if ":" in line:
                if line.strip()[len(line.strip()) - 1] == ':':
                    labels.append(line.strip().replace(":",""))

        # Carve Main
        found_main = False
        for line in data:
            if "main:" in line:
                found_main = True
                continue

            if found_main:
                instr = convert_instr(line)
                main_instructions.append(instr)
        

        print(*vars)
        print(*labels)
        print(*main_instructions)

        # Convert Labels
        for var in vars:
            if var[2] == "int":
                VARS += f"var {var[0]}, {var[1]}\n"
            elif var[2] == "asciz" or var[2] == "ascii":
                VARS += f"{var[0]}: .{var[2]} {var[1]}\n"


        label_id = 0
        for label in labels:
            if label != "main":
                LABELS += f"label {label}, {label_id}\n"
                label_id += 1

        # Insert main
        inserted_end = False
        for instr in main_instructions:
            if not inserted_end and "m_label" in instr:
                MAIN += f"    m_end\n    {instr}\n"
                inserted_end = True
            else:
                MAIN += f"    {instr}\n"\

        # Add Function Return Adresses
        for ra in function_ras:
            FUNCTION_RA += f"label {make_ra(ra)}, {label_id}\n"
            label_id+=1

        result = format_text.format(VARS=VARS, LABELS=LABELS, MAIN=MAIN, FUNCTION_RA=FUNCTION_RA)

    with open(output_path, 'w') as f:
        f.write(result)