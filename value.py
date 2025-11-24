"""
Python software model for an approximate 32-bit, es=3 Posit multiplier.
Faithfully models a real (slightly buggy) Verilog hardware implementation.
Used to measure exact error vs ideal floating-point multiplication.
"""

def regime(n, num_array):
    """Calculates the regime value (k) and bit count (count)"""
    count = 0
    # Start from index 1 (after sign bit)
    for i in range(1, n-1):
        if num_array[i] == num_array[i+1]:
            count += 1
        else:
            break
    count += 1  # Add the final bit that was different

    if num_array[1] == 0:   # Regime is 0...01
        k = -count
    else:                   # Regime is 1...10
        k = count - 1
    
    return k, count 

def exponent(n, es, count, num_array):
    """Extracts the exponent value from the bit array"""
    sum_val = 0
    index = count + 2  # Start after sign, regime, and stop bit
    
    if index >= n:
        return 0  # No exponent bits
    
    effective_es_bits = min(es, n - index)
    current_power = 2 ** (effective_es_bits - 1)
    
    for i in range(index, index + effective_es_bits):
        sum_val += num_array[i] * current_power
        current_power //= 2

    return int(sum_val)

def fraction(n, count, es, num_array):
    """Extracts the fraction value (1 + f)"""
    index = count + 2 + es  # After sign, regime, stop bit, and exponent
    sum_val = 0
    
    if index >= n:
        return 1.0  # Only hidden bit
    
    power_index = -1
    for i in range(index, n):
        sum_val += num_array[i] * (2 ** power_index)
        power_index -= 1
            
    return 1.0 + sum_val


def binary_to_twos_complement(binary_list):
    """Converts negative posit (without sign bit) to two's complement form"""
    inverted = [1 - bit for bit in binary_list]
    carry = 1
    twos_complement = []
    
    for bit in reversed(inverted):
        if carry == 0:
            twos_complement.append(bit)
            continue
        
        if bit == 0:
            twos_complement.append(1)
            carry = 0
        else:
            twos_complement.append(0)
            if carry == 1:
                carry = 1

    if carry == 1:
        twos_complement.append(1)

    twos_complement.reverse()
    pos_twos_complement = [1] + twos_complement
    return pos_twos_complement


def full_adder(a, b, cin):
    sum_bit = a ^ b ^ cin     
    carry_out = (a & b) | (cin & (a ^ b))
    return sum_bit, carry_out

def adder(arr1, arr2):
    """Adds two binary arrays (same length assumed)"""
    result = []
    carry_in = 0    
    for a, b in zip(reversed(arr1), reversed(arr2)):
        sum_bit, carry_out = full_adder(a, b, carry_in)
        result.append(sum_bit)
        carry_in = carry_out  
    if carry_in:
        result.append(carry_in)
    return result[::-1]


def mantissa_multiply(n, es, count1, count2, num_array_a, num_array_b):
    """Custom iterative mantissa multiplier from the original Verilog"""
    index_a = count1 + 1 + es
    index_b = count2 + 1 + es
    k_arr = []
    flag = 1
    LS = 0

    # Find positions of 1s in fraction of A
    for i in range(index_a, n):
        if num_array_a[i] == 1:
            LS += flag
            k_arr.append(flag)
            flag = 0
        flag += 1

    # Fraction bits of B (without hidden bit)
    arr = num_array_b[index_b:n]
    array_1 = [1] + arr[:-1]  # Restore hidden bit, exclude possible extra bit
    dup_array = array_1.copy()
    i = 0
    n_frac = len(array_1)
    
    while i < len(k_arr):
        k = k_arr[i] % n_frac
        array_2 = dup_array[-k:] + dup_array[:-k]  # Rotate left by k
        add = adder(array_1, array_2)
        array_1 = add
        dup_array = array_2
        i += 1
        
    return array_1


def decimal_to_binary_array(decimal):
    if decimal == 0:
        return [0]
    binary_array = []
    while decimal > 0:
        binary_array.append(decimal % 2)
        decimal //= 2
    return binary_array[::-1]


def encoder(SignO, RgmO, ExpO, mantissa, n_bits, es_bits):
    """Encodes final posit and returns its approximate decimal value (hardware-style)"""
    SignO_arr = [SignO]
    RgmO_arr = []
    
    # Encode Regime
    if RgmO < 0:
        RgmO_arr = [0] * abs(RgmO) + [1]
    else:
        RgmO_arr = [1] * (RgmO + 1) + [0]

    # Encode Exponent
    ExpO_arr = decimal_to_binary_array(ExpO)
    if len(ExpO_arr) < es_bits:
        ExpO_arr = [0] * (es_bits - len(ExpO_arr)) + ExpO_arr

    # Assemble full bitstream
    posit_result_arr = SignO_arr + RgmO_arr + ExpO_arr + mantissa
    
    # Truncate or zero-pad to n_bits
    if len(posit_result_arr) > n_bits:
        posit_result_arr = posit_result_arr[:n_bits]
    elif len(posit_result_arr) < n_bits:
        posit_result_arr += [0] * (n_bits - len(posit_result_arr))

    print("\nMultiplication Result O (Bitstream):")
    print("".join(map(str, posit_result_arr)))

    # Decode back (with hardware quirks)
    n_O = len(posit_result_arr)
    k_O, count_O = regime(n_O, posit_result_arr)
    exp_O_decoded = exponent(n_O, es_bits, count_O, posit_result_arr)
    fraction_O = fraction(n_O, count_O, es_bits, posit_result_arr)
    
    # Note: Uses original ExpO (not decoded), as in real buggy hardware
    posit_result_decimal = (-1)**SignO * (2**(2**es_bits))**RgmO * (2**ExpO) * fraction_O
    
    return posit_result_decimal


# ================================
#           MAIN PROGRAM
# ================================

# Input A
n_a, es_a = map(int, input("Enter space-separated n and es: ").split())
num_a = input("Enter the number A (binary): ").strip()

if len(num_a) == n_a and all(c in '01' for c in num_a):
    num_array_a = [int(bit) for bit in num_a]
    sign_a_val = num_array_a[0]
    
    if sign_a_val == 1:
        num_array_a_abs = binary_to_twos_complement(num_array_a[1:])
    else:
        num_array_a_abs = num_array_a
    
    k_a, count_a = regime(n_a, num_array_a_abs)
    exp_a = exponent(n_a, es_a, count_a, num_array_a_abs)
    fraction_a = fraction(n_a, count_a, es_a, num_array_a_abs)

    print(f"sign_a = {sign_a_val}")
    print(f"Rgm_a = {k_a}")
    print(f"exp_a = {exp_a}")
    print(f"fraction_a = {fraction_a:.10f}")
    
    posit_a = (-1)**sign_a_val * (2**(2**es_a))**k_a * (2**exp_a) * fraction_a
    print(f"Posit number A = {posit_a}")
    print()
else:
    print("Invalid input A")
    exit()

# Input B
n_b, es_b = map(int, input("Enter space-separated n and es for B: ").split())
num_b = input("Enter the number B (binary): ").strip()

if len(num_b) == n_b and all(c in '01' for c in num_b):
    num_array_b = [int(bit) for bit in num_b]
    sign_b_val = num_array_b[0]
    
    if sign_b_val == 1:
        num_array_b_abs = binary_to_twos_complement(num_array_b[1:])
    else:
        num_array_b_abs = num_array_b
        
    k_b, count_b = regime(n_b, num_array_b_abs)                  # Fixed line
    exp_b = exponent(n_b, es_b, count_b, num_array_b_abs)
    fraction_b = fraction(n_b, count_b, es_b, num_array_b_abs)

    print(f"sign_b = {sign_b_val}")
    print(f"Rgm_b = {k_b}")
    print(f"exp_b = {exp_b}")
    print(f"fraction_b = {fraction_b:.10f}")
    
    posit_b = (-1)**sign_b_val * (2**(2**es_b))**k_b * (2**exp_b) * fraction_b
    print(f"Posit number B = {posit_b}")
    print()
else:
    print("Invalid input B")
    exit()


# Hardware-modeled multiplication
RgmO = k_a + k_b
ExpO = exp_a + exp_b
SignO = sign_a_val ^ sign_b_val

print(f"SignO = {SignO}")
print(f"RgmO (before carry) = {RgmO}")
print(f"ExpO (before carry) = {ExpO}")

# Exponent carry into regime
if ExpO >= (1 << es_a):
    ExpO -= (1 << es_a)
    RgmO += 1

print(f"RgmO (final) = {RgmO}")
print(f"ExpO (final) = {ExpO}")

# Mantissa multiplication (hardware iterative method)
mantissa_product_arr = mantissa_multiply(n_a, es_a, count_a + 1, count_b + 1, num_array_a_abs, num_array_b_abs)

# Remove hidden bit and pad with zero (as in original hardware)
mantissa_final = mantissa_product_arr[1:] + [0]

# Final encoding
posit_result2 = encoder(SignO, RgmO, ExpO, mantissa_final, n_a, es_a)

# Ideal result
posit_result1 = posit_a * posit_b

print("\n" + "="*50)
print(f"Posit_Result_1 (Ideal Math)       : {posit_result1}")
print(f"Posit_Result_2 (Hardware Model)   : {posit_result2}")
if posit_result1 != 0:
    Error = (posit_result1 - posit_result2) / posit_result1 * 100
    print(f"Relative Error (%)                : {Error:.10f}%")
else:
    print("Ideal result is zero → error undefined.")
print("="*50)
