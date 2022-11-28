## Rock Paper Scissors Vyper Game

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
def __init__():
    self.player0 = msg.sender
    self.player1 = 0xdf7CDf6b1A6CC2509218e61fD68e4abf223cbbDE
    self.choice_legend[0] = "Rock"
    self.choice_legend[1] = "Paper"
    self.choice_legend[2] = "Scissors"

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