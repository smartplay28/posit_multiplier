"""
Python software model for an approximate 32-bit, es=3 Posit multiplier.
This code models the exact logic of the Verilog implementation, including
the custom iterative mantissa multiplier.

It is used to calculate the error between:
1. The "ideal" mathematical result (float_a * float_b)
2. The "implemented" result (the output of this hardware-modeled script)
"""

def regime(n, num_array):
    """Calculates the regime value (k) and bit count (count)"""
    count = 0
    # Start from index 1 (after sign bit)
    for i in range (1, n-1, 1):
        if(num_array[i] == num_array[i+1]):
            count = count + 1
        else:
            break
    count = count + 1 # Add the final bit that was different

    if num_array[1] == 0: # Regime is 0...01
        k = -count
    else: # Regime is 1...10
        k = count - 1
    
    return k, count 

def exponent(n, es, count, num_array):
    """Extracts the exponent value from the bit array"""
    sum = 0
    index = count + 2 # Start index after sign, regime, and stop bit
    
    if index >= n:
        return 0 # No exponent bits
    else:
        # Loop for 'es' bits or until we run out of bits
        effective_es_bits = min(es, n - index)
        
        current_power = 2**(effective_es_bits - 1)
        
        for i in range(index, index + effective_es_bits, 1):
            sum = sum + num_array[i] * current_power
            current_power = current_power / 2

        exp = int(sum)
        return exp

def fraction(n, count, es, num_array):
    """Extracts the fraction value (1 + f)"""
    index = count + 2 + es # Start index after sign, regime, stop, and exponent
    sum = 0
    
    if index > n: # Meant index >= n
        return 1 # No fraction, just the hidden bit
    else:
        power_index = -1
        # Loop for all remaining bits
        for i in range(index, n, 1):
            sum = sum + num_array[i] * (2**power_index)
            power_index = power_index - 1
            
    fract = 1 + sum
    return fract


def binary_to_twos_complement(binary_list):
    """
    Calculates the two's complement for a negative number.
    NOTE: This logic is from the user's code.
    """
    inverted = [1 - bit for bit in binary_list]
    
    carry = 1
    twos_complement = []
    
    for bit in reversed(inverted):
        if carry == 0:
            twos_complement.append(bit)
            continue
        
        if bit == 0:
            if carry == 1:
                twos_complement.append(1)
                carry = 0
            else:
                twos_complement.append(0)
        else:  
            if carry == 1:
                twos_complement.append(0)
            else:
                twos_complement.append(1)

    if carry == 1:
        twos_complement.append(1)

    twos_complement.reverse()

    # This part is from the user's code, it prepends a '1'
    pos_twos_complement = [1]
    for ele in twos_complement:
        pos_twos_complement.append(ele)

    return pos_twos_complement


def full_adder(a, b, cin):
    """A simple full adder"""
    sum_bit = a ^ b ^ cin     
    carry_out = (a & b) | (cin & (a ^ b))
    return sum_bit, carry_out

def adder(arr1, arr2):
    """Adds two binary arrays"""
    result = []
    carry_in = 0    
    for a, b in zip(reversed(arr1), reversed(arr2)):
        sum_bit, carry_out = full_adder(a, b, carry_in)
        result.append(sum_bit)
        carry_in = carry_out  
    return result[::-1]

def mantissa_multiply(n, es, count1, count2, num_array_a, num_array_b):
    """
    The iterative mantissa multiplier from the user's methodology.
    Note: The user passes count+1 for count1/count2 to align the indices.
    """
    index_a = count1 + 1 + es
    index_b = count2 + 1 + es
    k_arr = []
    flag = 1
    LS = 0

    # This section appears to find the positions of '1's in frac_a
    for i in range(index_a, n):
        if num_array_a[i] == 1:
            LS = LS + flag
            k_arr.append(flag)
            flag = 0
            
        flag = flag + 1

    # Get the fraction bits of B (excluding hidden bit)
    arr = num_array_b[index_b:n]
    
    # Add the hidden bit '1'
    array_1 = [1] + arr[:-1] # This seems to be the mantissa
    
    dup_array = array_1
    i = 0
    n_frac = len(array_1)
    
    # Iterative shift-and-add based on '1's in frac_a
    while (i < len(k_arr)):
        k = k_arr[i]
        k = k % n_frac
        array_2 = dup_array[-k:] + dup_array[:-k] # This is a bitwise rotation
        i = i + 1
        add = adder(array_1, array_2)
        dup_array = array_2
        array_1 = add
        
    return array_1 # This is the final mantissa product

def decimal_to_binary_array(decimal):
    """Converts a decimal integer to a binary list"""
    if decimal == 0:
        return [0]
    
    binary_array = []
    while decimal > 0:
        binary_array.append(decimal % 2)
        decimal = decimal // 2
    
    return binary_array[::-1]



def encoder(SignO, RgmO, ExpO, mantissa, n_bits, es_bits):
    """
    Reconstructs the final posit from its components and
    calculates its decimal value.
    """
    SignO_arr = [SignO]
    RgmO_arr = []
    ExpO_arr = []
    posit_result_arr = []

    # 1. Encode Regime
    if RgmO < 0:
        for i in range(0, abs(RgmO)):
            RgmO_arr.append(0)
        RgmO_arr.append(1) # Stop bit
    else:
        for i in range(0, RgmO+1):
            RgmO_arr.append(1)
        RgmO_arr.append(0) # Stop bit

    # 2. Encode Exponent
    ExpO_arr = decimal_to_binary_array(ExpO)
    # Pad exponent to 'es' bits
    if len(ExpO_arr) < es_bits:
        ExpO_arr = [0] * (es_bits - len(ExpO_arr)) + ExpO_arr

    # 3. Assemble final posit bitstream
    posit_result_arr = SignO_arr + RgmO_arr + ExpO_arr + mantissa
    
    # Truncate to N bits
    if len(posit_result_arr) > n_bits:
        posit_result_arr = posit_result_arr[0:n_bits]
    elif len(posit_result_arr) < n_bits:
        posit_result_arr = posit_result_arr + [0] * (n_bits - len(posit_result_arr))


    print()
    print('Multiplication Result O (Bitstream):')
    for ele in posit_result_arr:
        print(ele, end = '')
    print()

    # 4. Decode the just-encoded result to get its decimal value
    # (This is the logic from the user's code)
    n_O = len(posit_result_arr)
    es_O = es_bits # Use the original 'es'

    k_O, count_O = regime(n_O, posit_result_arr)
    # Need to re-decode the exponent from the *new* bitstream
    exp_O_decoded = exponent(n_O, es_O, count_O, posit_result_arr) 
    
    fraction_O = fraction(n_O, count_O, es_O, posit_result_arr)
    
    # Calculate the decimal value from the *calculated* components,
    # but the *decoded* fraction. This matches the user's buggy logic.
    # Note: This is NOT a fully correct posit decode, but it's
    # what the user's code implements.
    posit_result_decimal = (-1)**SignO * (2**(2**es_O))**RgmO * (2**ExpO) * (fraction_O)
    
    return posit_result_decimal


# --- Main execution ---

# 1. Get and decode number A
n_a, es_a = map(int, input("Enter space-separated n and es: ").split())
num_a = input("Enter the number A: ")

if all(bit in '01' for bit in num_a) and len(num_a) == n_a:
    num_array_a = [int(bit) for bit in num_a]
    sign_a_val = num_array_a[0]
    
    # Handle negative numbers (from user's logic)
    if (num_array_a[0] == 1):
        num_array_a_abs = binary_to_twos_complement(num_array_a[1:])
        # Note: user's code overwrites num_array_a, which is confusing
        # We will use num_array_a_abs for decoding regime/exp/frac
    else:
        num_array_a_abs = num_array_a
        
    k_a, count_a = regime(n_a, num_array_a_abs)
    exp_a = exponent(n_a, es_a, count_a, num_array_a_abs)
    fraction_a = fraction(n_a, count_a, es_a, num_array_a_abs)

    print('sign_a =', sign_a_val)
    print('Rgm_a = ', k_a)
    print('exp_a = ', exp_a)
    print('fraction_a = ', fraction_a)
    
    # This is the "ideal" decimal value of A
    posit_a = (-1)**sign_a_val * (2**(2**es_a))**k_a * (2**exp_a) * (fraction_a)
    print('Posit number_a = ', posit_a)
    print()

else:
    print("Invalid input. Please enter a valid %d-bit binary number." % n_a)
    exit()


# 2. Get and decode number B
n_b, es_b = map(int, input("Enter space-separated n and es: ").split())
num_b = input("Enter the number B: ")

if all(bit in '01' for bit in num_b) and len(num_b) == n_b:
    num_array_b = [int(bit) for bit in num_b]
    sign_b_val = num_array_b[0]
    
    if (num_array_b[0] == 1):
        num_array_b_abs = binary_to_twos_complement(num_array_b[1:])
    else:
        num_array_b_abs = num_array_b
        
    k_b, count_b = regime(n_b, es_b, count_b, num_array_b_abs)
    exp_b = exponent(n_b, es_b, count_b, num_array_b_abs)
    fraction_b = fraction(n_b, count_b, es_b, num_array_b_abs)

    print('sign_b =', sign_b_val)
    print('Rgm_b = ', k_b)
    print('exp_b = ', exp_b)
    print('fraction_b = ', fraction_b)
    
    # This is the "ideal" decimal value of B
    posit_b = (-1)**sign_b_val * (2**(2**es_b))**k_b * (2**exp_b) * (fraction_b)
    print('Posit number_b = ', posit_b)
    print()

else:
    print("Invalid input. Please enter a valid %d-bit binary number." % n_b)
    exit()

# --- 3. Calculate Hardware-Modeled Result ---

# Calculate output components
RgmO = k_a + k_b
ExpO = exp_a + exp_b
SignO = sign_a_val ^ sign_b_val # 0 if same, 1 if different

# Handle exponent carry
exponent_carry_threshold = 2**es_a
if (ExpO >= exponent_carry_threshold):
    ExpO = ExpO - exponent_carry_threshold
    RgmO = RgmO + 1

print('SignO = ', SignO)
print('RgmO = ', RgmO)
print('ExpO = ', ExpO)

# Calculate mantissa using the iterative hardware method
# Note: Passing count+1 to match the user's original logic
# (The user's function expects this offset)
mantissa_product_arr = mantissa_multiply(n_a, es_a, count_a+1, count_b+1, num_array_a_abs, num_array_b_abs)

# The mantissa product has a hidden bit, remove it
mantissa_product_arr = mantissa_product_arr[1:]
mantissa_product_arr.append(0) # Pad with 0


# Encode the final result and get its decimal value
# This 'posit_result2' is the decimal value of your *implemented* logic
posit_result2 = encoder(SignO, RgmO, ExpO, mantissa_product_arr, n_a, es_a)


# --- 4. Calculate Error ---

# This 'posit_result1' is the "ideal" mathematical answer
posit_result1 = posit_a * posit_b

print()
print('Posit_Result_1 (Ideal Math): ', posit_result1)
print('Posit_Result_2 (Your Implementation): ', posit_result2)

# Calculate relative error
if posit_result1 != 0:
    Error = (posit_result1 - posit_result2) / posit_result1 * 100
    print('Error % = ', Error)
else:
    print('Ideal result is 0. Error calculation skipped.')