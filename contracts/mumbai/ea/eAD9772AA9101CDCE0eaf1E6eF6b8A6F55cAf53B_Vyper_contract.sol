# @version 0.3.1
BYTES_BOUND: constant(uint256) = 32

interface TellorFlex:
    def getCurrentValue(query_id: bytes32) -> Bytes[BYTES_BOUND]: view

reported_value: public(Bytes[BYTES_BOUND])

@external
def ask_val_from_tellor(some_address: address, _query_id: bytes32):
    self.reported_value = TellorFlex(some_address).getCurrentValue(_query_id)