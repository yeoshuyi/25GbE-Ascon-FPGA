import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge
import random


def int_to_state(val):
    """Split 320 to 64 bit blocks"""
    return [(val >> (64 * i)) & 0xFFFFFFFFFFFFFFFF for i in reversed(range(5))]

def state_to_int(state):
    """Recombine"""
    res = 0
    for s in state:
        res = (res << 64) | s
    return res

def ascon_permutate(state):
    """Derived from meichlseder's Ascon Algo"""
    rounds = 12
    S = state.copy()

    for r in range(12-rounds, 12):
        S[2] ^= (0xf0 - r*0x10 + r*0x1)
        S[0] ^= S[4]
        S[4] ^= S[3]
        S[2] ^= S[1]
        T = [(S[i] ^ 0xFFFFFFFFFFFFFFFF) & S[(i+1)%5] for i in range(5)]
        for i in range(5):
            S[i] ^= T[(i+1)%5]
        S[1] ^= S[0]
        S[0] ^= S[4]
        S[3] ^= S[2]
        S[2] ^= 0XFFFFFFFFFFFFFFFF
        S[0] ^= rotr(S[0], 19) ^ rotr(S[0], 28)
        S[1] ^= rotr(S[1], 61) ^ rotr(S[1], 39)
        S[2] ^= rotr(S[2],  1) ^ rotr(S[2],  6)
        S[3] ^= rotr(S[3], 10) ^ rotr(S[3], 17)
        S[4] ^= rotr(S[4],  7) ^ rotr(S[4], 41)
    
    return S

def rotr(val: int, r: int) -> int:
    return (val >> r) | ((val & (1<<r)-1) << (64-r)) & 0xFFFFFFFFFFFFFFFF


@cocotb.test()
async def ascon_xof(dut):
    clock = Clock(dut.clk, 3.1, unit="ns")
    cocotb.start_soon(clock.start())

    dut.reset.value = 1
    dut.start.value = 0
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)

    iv_state = [0x00400c0000000000, 0, 0, 0, 0]
    expected_init = ascon_permutate(iv_state)

    #tuple_val = random.getrandbits(104)
    tuple_val = 0x000102030405060708090A0B0C
    dut.tuple_in.value = tuple_val
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0

    for i in range(100):
        cycles_waited = 0
        while not dut.done.value:
            await RisingEdge(dut.clk)
            cycles_waited += 1
            if cycles_waited > 20:
                raise AssertionError("Timeout: 'done' signal never asserted!")
            
        actual_digest = dut.digest.value.to_unsigned()

        #Python Calculation
        b0 = (tuple_val >> 40) & 0xFFFFFFFFFFFFFFFF
        low_40_bits = tuple_val & 0xFFFFFFFFFF
        b1 = (low_40_bits << 24) | 0x800000 
        s = expected_init.copy()
        s[0] ^= b0
        s = ascon_permutate(s)
        s[0] ^= b1
        s = ascon_permutate(s)
        expected_digest = s[0]

        dut._log.info(f"Checking Permutation #{i}")
        dut._log.debug(f"  Message: {hex(tuple_val)}")
        dut._log.debug(f"  Expected: {hex(expected_digest)}")
        dut._log.debug(f"  Actual:   {hex(actual_digest)}")
        dut._log.debug(f"  Latency:   {cycles_waited} cycles")
        
        assert actual_digest == expected_digest, (
            f"Match Failed at Trial {i}\n"
            f"Input Tuple: {hex(tuple_val)}\n"
            f"Expected:    {hex(expected_digest)}\n"
            f"Actual:      {hex(actual_digest)}\n"
            f"Latency:     {cycles_waited} cycles"
        )

        tuple_val = random.getrandbits(104)
        dut.tuple_in.value = tuple_val

        dut.start.value = 1
        await RisingEdge(dut.clk)
        dut.start.value = 0
        
    dut._log.info("Done.")