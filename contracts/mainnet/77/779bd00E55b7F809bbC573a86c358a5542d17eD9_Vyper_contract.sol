"""
@title Treasury
@license GNU AGPLv3
@author msugarm
@notice
    Treasury is a simple contract that only action of what can do is send tokens

    Default governance is initializer (msg.sender)
"""

activation: public(uint256)
governance: public(address)
proposedGovernance: public(address)

# @notice Emitted when a new Governance is proposed
# @param governance Address of governance
event GovernanceProposed:
    governance: indexed(address)
# @notice Emitted when a new Governance is accepted
# @param governance Address of governance
event GovernanceAccepted:
    governance: indexed(address)

@internal
def erc20_safe_transfer(token: address, receiver: address, amount: uint256):
    # Used only to send tokens that are not the type managed by this Vault.
    # HACK: Used to handle non-compliant tokens like USDT
    response: Bytes[32] = raw_call(
        token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(receiver, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) > 0:
        assert convert(response, bool), "Transfer failed!"


@external
def transferTokens(token: address, to: address, amount: uint256):
    """
    @notice send an tokens to 'to'
    """
    assert msg.sender == self.governance, "!governance"
    self.erc20_safe_transfer(token, to, amount)

@external
def transferNative(to: address, amount: uint256):
    """
    @notice send native token to 'to'
    """
    assert msg.sender == self.governance, "!governance"
    send(to, amount)

@payable
@external
def receive():
    pass


# Governance
@external
def proposeGovernance(governance: address):
    """
    @notice
        Nominate a new address to use as governance.

        The change does not go into effect immediately. This function sets a
        pending change, and the governance address is not updated until
        the proposed governance address has accepted the responsibility.

        This may only be called by the current governance address.
    @param governance The address requested to take over Vault governance.
    """
    assert msg.sender == self.governance, "!governance"
    log GovernanceProposed(msg.sender)
    self.proposedGovernance = governance


@external
def acceptGovernance():
    """
    @notice
        Once a new governance address has been proposed using proposeGovernance(),
        this function may be called by the proposed address to accept the
        responsibility of taking over governance for this contract.

        This may only be called by the proposed governance address.
    @dev
        proposeGovernance() should be called by the existing governance address,
        prior to calling this function.
    """
    assert msg.sender == self.proposedGovernance, "!proposedGovernance"
    self.governance = msg.sender
    log GovernanceAccepted(msg.sender)

@external
def initialize(governance: address):
    """
    @notice
        Initializes the Treasury, this is called only once, when the contract is
        deployed.
    @param governance The address authorized for governance interactions.
    """
    assert self.activation == 0  # dev: no devops199    
    self.governance = governance
    self.activation = block.timestamp