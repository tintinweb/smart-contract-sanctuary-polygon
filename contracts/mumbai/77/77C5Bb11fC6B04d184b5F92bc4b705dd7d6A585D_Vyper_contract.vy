from vyper.interfaces import ERC20

implements: ERC20

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

name: public(String[32])
symbol: public(String[32])
decimals: public(uint256)
# NOTE: By declaring `balanceOf` as public, vyper automatically generates a 'balanceOf()' getter
#       method to allow access to account balances.
#       The _KeyType will become a required parameter for the getter and it will return _ValueType.
#       See: https://vyper.readthedocs.io/en/v0.1.0-beta.8/types.html?highlight=getter#mappings
balanceOf: public(HashMap[address, uint256])
# By declaring `allowance` as public, vyper automatically generates the `allowance()` getter
allowance: public(HashMap[address, HashMap[address, uint256]])
# By declaring `totalSupply` as public, we automatically create the `totalSupply()` getter
totalSupply: public(uint256)
minter: address


player0: public(address)
player1: public(address)

player0Choice: public(uint256)
player1Choice: public(uint256)



player0ChoiceMade: public(bool)
player1ChoiceMade: public(bool)

winner: public(address)

choice_legend: public(HashMap[uint256, String[10]]) 
player0choice_legend: public(String[10])
player1choice_legend: public(String[10])

deposit_balance: public(uint256)



@external
def __init__(_name: String[32], _symbol: String[32], _decimals: uint256, _supply: uint256, _player1: address):

    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = _supply
    self.totalSupply = _supply
    self.player1 = _player1
    self.player0 = msg.sender
    self.minter = msg.sender
    log Transfer(empty(address), msg.sender, _supply)




@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @dev Transfer tokens from one address to another.
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    # NOTE: vyper does not allow underflows
    #      so the following subtraction would revert on insufficient allowance
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
         Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@internal
def mint(_to: address, _value: uint256):
    """
    @dev Mint an amount of the token and assigns it to an account.
         This encapsulates the modification of balances such that the
         proper events are emitted.
    @param _to The account that will receive the created tokens.
    @param _value The amount that will be created.
    """
    assert _to != empty(address)
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(empty(address), _to, _value)


@internal
def _burn(_to: address, _value: uint256):
    """
    @dev Internal function that burns an amount of the token of a given
         account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    assert _to != empty(address)
    self.totalSupply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, empty(address), _value)


@external
def burn(_value: uint256):
    """
    @dev Burn an amount of the token of msg.sender.
    @param _value The amount that will be burned.
    """
    self._burn(msg.sender, _value)


@external
def burnFrom(_to: address, _value: uint256):
    """
    @dev Burn an amount of the token from a given account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    self.allowance[_to][msg.sender] -= _value
    self._burn(_to, _value)





## Rock Paper Scissors Vyper Game begin 



@internal
def _resetChoices():
    self.player0Choice = 4
    self.player1Choice = 4
    self.player0ChoiceMade = False
    self.player1ChoiceMade = False


# deposit function that checks if the player is one of the two players.
@external
@payable
def deposit():
    self.deposit_balance += msg.value
    assert msg.sender == self.player0 or msg.sender == self.player1


# reward depositors 
@internal
@payable
def reward():
    send(self.winner, self.deposit_balance)
    self.deposit_balance = 0
    # mint tokens to winner
    self.mint(self.winner, 1000)
    
   

# make a choice in the game, and save the choices made.
@external
def makeChoice(_choice: uint256):
    if msg.sender == self.player0:
        self.player0Choice = _choice
        self.player0ChoiceMade = True
        self.player0choice_legend = self.choice_legend[_choice] 
    elif msg.sender == self.player1:
        self.player1Choice = _choice
        self.player1ChoiceMade = True
        self.player1choice_legend = self.choice_legend[_choice]


# calculate store and winner address + pay out rewards
@external
def reveal():
    if self.player0ChoiceMade and self.player1ChoiceMade:
        if self.player0Choice == self.player1Choice:
            self.winner = empty(address)
            self._resetChoices()
        elif self.player0Choice == 0 and self.player1Choice == 1:
            self.winner = self.player1
            self._resetChoices()
            self.reward()
        elif self.player0Choice == 0 and self.player1Choice == 2:
            self.winner = self.player0
            self._resetChoices()
            self.reward()
        elif self.player0Choice == 1 and self.player1Choice == 0:
            self.winner = self.player0
            self._resetChoices()
            self.reward()
        elif self.player0Choice == 1 and self.player1Choice == 2:
            self.winner = self.player1
            self._resetChoices()
            self.reward()
        elif self.player0Choice == 2 and self.player1Choice == 0:
            self.winner = self.player1
            self._resetChoices()
            self.reward()
        elif self.player0Choice == 2 and self.player1Choice == 1:
            self.winner = self.player0
            self._resetChoices()
            self.reward()
        elif self.player1Choice == 0 and self.player0Choice == 2:
            self.winner = self.player1
            self._resetChoices()
            self.reward()
        elif self.player1Choice == 0 and self.player0Choice == 1:
            self.winner = self.player0
        elif self.player1Choice == 1 and self.player0Choice == 0:
            self.winner = self.player1
            self._resetChoices()
            self.reward()
        elif self.player1Choice == 1 and self.player0Choice == 2:
            self.winner = self.player0
            self._resetChoices()
            self.reward()
        elif self.player1Choice == 2 and self.player0Choice == 0:
            self.winner = self.player0
            self._resetChoices()
            self.reward()
        elif self.player1Choice == 2 and self.player0Choice == 1:
            self.winner = self.player1
            self._resetChoices()
            self.reward()
        else:
            self.winner = empty(address)
            self._resetChoices()
                      
   


# emergency self destruct function much needed here. 
@external
def kill():
    assert msg.sender == self.player0 or msg.sender == self.player1
    selfdestruct(msg.sender)