# Declare the contract's version
# @version  ^0.2.0

# Custom ERC20 interface with decimals function
interface CustomERC20Interface:
    def decimals() -> uint256: view
    def transfer(to: address, amount: uint256) -> bool: nonpayable

# Variables
token: CustomERC20Interface
owner: public(address)
recipients: public(address[100])
amounts: public(uint256[4])
probabilities: public(uint256[4])
recipient_count: public(uint256)
last_claimed: public(HashMap[address, uint256])

# Events
event Transfer:
    recipient: indexed(address)
    amount: uint256

# Constructor
@external
def __init__(tokenAddress: address):
    self.owner = msg.sender
    self.token = CustomERC20Interface(tokenAddress)

# Set recipients
@external
def setRecipients(_recipients: address[100], count: uint256):
    assert msg.sender == self.owner
    assert 2 <= count and count <= 100, "Number of recipients must be between 2 and 100"
    for i in range(100):
        if i < count:
            self.recipients[i] = _recipients[i]
        else:
            self.recipients[i] = ZERO_ADDRESS
    self.recipient_count = count

# Set amounts and probabilities
@external
def setAmountsAndProbabilities(_amounts: uint256[4], _probabilities: uint256[4]):
    assert msg.sender == self.owner
    decimals: uint256 = self.token.decimals()
    for i in range(4):
        self.amounts[i] = _amounts[i] * (10 ** decimals)
        self.probabilities[i] = _probabilities[i]

# Send funds
@external
def sendFunds():
    recipient_found: bool = False
    for i in range(100):
        if i >= self.recipient_count:
            break
        if self.recipients[i] == msg.sender:
            recipient_found = True
            current_time: uint256 = block.timestamp
            last_claim_time: uint256 = self.last_claimed[msg.sender]

            assert current_time >= last_claim_time + 24 * 60 * 60, "Must wait 24 hours between claims"

            # Random payout selection
            rand_value: uint256 = convert(keccak256(convert(current_time, bytes32)), uint256) % 100
            payout_amount: uint256 = 0
            probability_sum: uint256 = 0

            for j in range(4):
                probability_sum += self.probabilities[j]
                if rand_value < probability_sum:
                    payout_amount = self.amounts[j]
                    break

            self.token.transfer(msg.sender, payout_amount)
            log Transfer(msg.sender, payout_amount)
            self.last_claimed[msg.sender] = current_time
            break

    assert recipient_found, "Caller is not a recipient"