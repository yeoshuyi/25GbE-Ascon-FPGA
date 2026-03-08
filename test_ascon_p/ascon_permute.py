import cocotb
from cocotb.triggers import Timer, ReadOnly
import random

def rotate_right(val, r):
    return ((val >> r) | (val << (64-r))) & 0xFFFFFFFFFFFFFFFF

def ascon_round_ref(state, round_const):

    ascon_const = (((0xf - round_const) << 4) | round_const) & 0xFF
    state[2] ^= ascon_const
    
    x = state
    x[0] ^= x[4]; x[4] ^= x[3]; x[2] ^= x[1]
    
    t0 = (x[0] ^ (~x[1] & x[2])) & 0xFFFFFFFFFFFFFFFF
    t1 = (x[1] ^ (~x[2] & x[3])) & 0xFFFFFFFFFFFFFFFF
    t2 = (x[2] ^ (~x[3] & x[4])) & 0xFFFFFFFFFFFFFFFF
    t3 = (x[3] ^ (~x[4] & x[0])) & 0xFFFFFFFFFFFFFFFF
    t4 = (x[4] ^ (~x[0] & x[1])) & 0xFFFFFFFFFFFFFFFF
    
    t1 ^= t0; t0 ^= t4; t3 ^= t2
    t2 = (t2 ^ 0xFFFFFFFFFFFFFFFF) & 0xFFFFFFFFFFFFFFFF

    x0 = t0 ^ rotate_right(t0, 19) ^ rotate_right(t0, 28)
    x1 = t1 ^ rotate_right(t1, 61) ^ rotate_right(t1, 39)
    x2 = t2 ^ rotate_right(t2, 1)  ^ rotate_right(t2, 6)
    x3 = t3 ^ rotate_right(t3, 10) ^ rotate_right(t3, 17)
    x4 = t4 ^ rotate_right(t4, 7)  ^ rotate_right(t4, 41)
    
    return [x0, x1, x2, x3, x4]

class AsconTester:

    def __init__(self, dut):
        self.dut = dut
        
    async def drive_input(self, state, rc):
        """Driver: Put data on the bus"""

        self.dut.x0_in.value = state[0]
        self.dut.x1_in.value = state[1]
        self.dut.x2_in.value = state[2]
        self.dut.x3_in.value = state[3]
        self.dut.x4_in.value = state[4]
        self.dut.round_constant.value = rc
        
    async def monitor_and_check(self, expected_state):
        """Monitor & Scoreboard: Observe output and compare"""

        await Timer(1, unit="ns")
        await ReadOnly()
        
        actual = [
            int(self.dut.x0_out.value),
            int(self.dut.x1_out.value),
            int(self.dut.x2_out.value),
            int(self.dut.x3_out.value),
            int(self.dut.x4_out.value)
        ]

        for i in range(5):
            assert actual[i] == expected_state[i], \
                f"Mismatch at x{i}! Expected {hex(expected_state[i])}, got {hex(actual[i])}"
        
        self.dut._log.info("Round verification passed!")

@cocotb.test()
async def test_acscon_permute(dut): 

    tester = AsconTester(dut)
    
    for i in range(100):

        test_state = [random.getrandbits(64) for _ in range(5)]
        rc = random.randint(0, 11)
        
        await tester.drive_input(test_state, rc)
        
        expected = ascon_round_ref(list(test_state), rc)
        
        await tester.monitor_and_check(expected)

        await Timer(1, units="ps")