# @version ^0.3.3

# State variables
addresses_set: bool
admin_address: address
withdraw_address: address

# @notice
# self.meeting_pct_takeout["2022-02-23-HKG-HAP"]= 1500
meeting_pct_takeout: HashMap[String[18], uint256]

# @notice
# self.meeting_change_fee["2022-02-23-HKG-HAP"] = 1500
meeting_change_fee: HashMap[String[18], uint256]

# @notice
# self.meeting_cancel_fee["2022-02-23-HKG-HAP"] = 1500
meeting_cancel_fee: HashMap[String[18], uint256]

# @notice
# self.meeting_setup_done["2022-02-23-HKG-HAP"] = true
meeting_setup_done: HashMap[String[18], bool] #

# @notice
# self.meeting_setup["2022-02-23-HKG-HAP"] = [8,9,10,10,15]
meeting_setup: HashMap[String[18], DynArray[uint256, 20]]

# @notice
# self.meeting_race_runners["2022-02-23-HKG-HAP"] = [[0,0,0,0],[0,0,0,0],[0,0,0,0]]
meeting_race_runners: HashMap[String[18], DynArray[DynArray[uint256, 50], 20]]

# @notice
# self.meeting_race_runners_inverse["2022-02-23-HKG-HAP"] = [[1,1,1,1],[1,1,1,1],[1,1,1,1]]
meeting_race_runners_inverse: HashMap[String[18], DynArray[DynArray[uint256, 50], 20]]

# @notice
# self.meeting_race_status["2022-02-23-HKG-HAP"] = [-1,0,1,1,1,]
meeting_race_status: HashMap[String[18], DynArray[int256, 20]]

# @notice
# self.meeting_race_runner_status["2022-02-23-HKG-HAP"] = [[1,0,1,1,1,],[1,0,1,1,1,]]
meeting_race_runner_status: HashMap[String[18], DynArray[DynArray[uint256, 50], 20]]

################################################################################
# START External Win bet state vars
################################################################################

# @notice
# self.meeting_race_runner_win_bet["2022-02-23-HKG-HAP"][1][1] += 1000
meeting_race_runner_win_bet: HashMap[String[18], DynArray[DynArray[uint256, 50], 20]]

# @notice
# self.address_meeting_race_runner_win_bet[0x00]["2022-02-23-HKG-HAP"] = [[0,0,0,0,0],[0,0,0,0,0]]
address_meeting_race_runner_win_bet: HashMap[address, HashMap[String[18], DynArray[DynArray[uint256, 50], 20]]]

# @notice
# self.lookup_address_meeting_race_runner_win_bet[0x00]["2022-02-23-HKG-HAP"] = True
lookup_address_meeting_race_runner_win_bet: HashMap[address, HashMap[String[18], bool]]

################################################################################
# END External Win bet state vars
################################################################################

################################################################################
# START Internal Win bet state vars
################################################################################
# @notice
# self.meeting_race_runner_address_amount_win_bet["2022-02-23-HKG-HAP"][1][1][0x00]
meeting_race_runner_address_amount_win_bet: HashMap[String[18], HashMap[uint256, HashMap[uint256, HashMap[address, uint256]]]]

# @notice
# self.meeting_race_runner_address_win_bet["2022-02-23-HKG-HAP"][1][1][0x00]
meeting_race_runner_address_win_bet: HashMap[String[18], HashMap[uint256, HashMap[uint256, DynArray[address, 50_000]]]]

# @notice
# self.lookup_meeting_race_runner_address_win_bet["2022-02-23-HKG-HAP"][1][1][0x00] = True
lookup_meeting_race_runner_address_win_bet: HashMap[String[18], HashMap[uint256, HashMap[uint256, HashMap[address, bool]]]]

# @notice
# self.meeting_race_runner_address_win_bet_paid["2022-02-23-HKG-HAP"][1][1][0x00] = True
meeting_race_runner_address_win_bet_paid: HashMap[String[18], HashMap[uint256, HashMap[uint256, HashMap[address, bool]]]]

# @notice
# self.meeting_race_runner_address_win_bet_refunded["2022-02-23-HKG-HAP"][1][1][0x00] = True
meeting_race_runner_address_win_bet_refunded: HashMap[String[18], HashMap[uint256, HashMap[uint256, HashMap[address, bool]]]]

################################################################################
# END Internal Win bet state vars
################################################################################


# @notice Initial call to setup the addresses
@external
def setAddresses():
    assert self.addresses_set == False, "Addresses have been set"
    self.admin_address = 0x89300F6AC18C87948c802038D50777a82AAFb081
    self.withdraw_address = 0x67156493946e5696EA9Be7d7E5138E9f9DD53559
    self.addresses_set = True


# @notice Setup the internals of the contract
# @param _meeting What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _meeting_setup The array of races and number of runners [6, 6, 7, 8, 8, 14, 10]
@external
def setup(_meeting: String[18], _meeting_setup: DynArray[uint256, 20]):
    assert self.admin_address == msg.sender, "You are not the admin address"
    assert self.meeting_setup_done[_meeting] == False, "Meeting already setup"

    self.meeting_pct_takeout[_meeting] = 1500 # 1500 basis points = 15.0%
    self.meeting_change_fee[_meeting] = 500 # 500 basis points = 5.0%
    self.meeting_cancel_fee[_meeting] = 1000 # 1000 basis points = 10.0%
    self.meeting_setup[_meeting] = _meeting_setup

    # Iterate the meeting_setup array, we want to create an array of arrays
    # representing races/runers like so
    # [[0,0,0,0,0],[0,0,0,0,0,0,0],[0,0,0,0,0,0,0]]
    # We can then apply this array to be used for a variety of purposes for state tracking
    for i in _meeting_setup:
        temp: DynArray[uint256, 50] = []
        temp_inverse: DynArray[uint256, 50] = []
        # Range logic as per https://bowtiedisland.com/vyper-for-beginners-variables-flow-control-functions-hello-world/
        for ii in range(100):
            if ii != i:
                temp.append(0) # Setup a slot for all runners in
                temp_inverse.append(1) # Setup a slot for all runners
            else:
                break
        self.meeting_race_status[_meeting].append(1)  # We want all race status to be 1 or True
        self.meeting_race_runners[_meeting].append(temp)
        self.meeting_race_runners_inverse[_meeting].append(temp_inverse)

    self.meeting_race_runner_status[_meeting] = self.meeting_race_runners_inverse[_meeting] # We want all race/runners status to be 1 or True
    self.address_meeting_race_runner_win_bet[msg.sender][_meeting] = self.meeting_race_runners[_meeting]
    self.meeting_race_runner_win_bet[_meeting] = self.meeting_race_runners[_meeting]
    self.meeting_setup_done[_meeting] = True


# @notice Get the current state of the contract
# @dev Is a convenience method for accessing contract state.
# @param _meeting What meeting are we talking about - 2022-02-23-HKG-HAP
@external
@view
def contractState(_meeting: String[18]) -> (
    address, # admin_address
    address, # withdraw_address
    uint256, #meeting_pct_takeout
    DynArray[DynArray[uint256, 50], 20], # meeting_race_runners
    DynArray[int256, 20], # meeting_race_status
    DynArray[DynArray[uint256, 50], 20], # meeting_race_runner_status
    DynArray[DynArray[uint256, 50], 20], # race_runner_win_bets
    DynArray[DynArray[uint256, 50], 20] # address_meeting_race_runner_win_bets
):
    return self.admin_address, \
           self.withdraw_address, \
           self.meeting_pct_takeout[_meeting], \
           self.meeting_race_runners[_meeting], \
           self.meeting_race_status[_meeting], \
           self.meeting_race_runner_status[_meeting], \
           self.meeting_race_runner_win_bet[_meeting], \
           self.address_meeting_race_runner_win_bet[msg.sender][_meeting] \


# @notice Set the admin address
# @dev Only the admin address can acess various functions on the contract
# @param _admin_address Wallet address you want to be the admin
@external
def setAdminAddress(_admin_address: address):
    # The factory seems top set the admin/withdraw address as ZERO_ADDRESS
    # we need to be able to set these when the factory deploys the contract
    if self.admin_address == ZERO_ADDRESS:
        self.admin_address = _admin_address
    else:
        assert self.admin_address == msg.sender, "You are not the admin address"
        self.admin_address = _admin_address


# @notice Set the withdraw_address
# @dev Use sparingly, this will receive the contract funds
# @param _withdraw_address Wallet address you want funds to go to
@external
def setWithdrawAddress(_withdraw_address: address):
    # The factory seems top set the admin/withdraw address as ZERO_ADDRESS
    # we need to be able to set these when the factory deploys the contract
    if self.withdraw_address == ZERO_ADDRESS:
        self.withdraw_address = _withdraw_address
    else:
        assert self.admin_address == msg.sender, "You are not the admin address"
        self.withdraw_address = _withdraw_address


# @notice Withdraw funds from the contract
@external
def withdraw():
    assert self.withdraw_address == msg.sender, "You are not the withdraw address"
    send(self.withdraw_address, self.balance)


# @notice Set a race status
# @param _meeting What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _race Which race number to change the status of, 0 indexed
# @param _status 1 is active, 0 is closed
@external
def setRaceStatus(_meeting: String[18], _race: uint256, _status: int256):
    assert self.admin_address == msg.sender, "You are not the admin address"
    self.meeting_race_status[_meeting][_race] = _status


# @notice Set a race/runner status
# @param _meeting What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _race Which race number to change the status of, 0 indexed
# @param _runner Which runner number to change the status of, 0 indexed
# @param _status 1 is active, 0 is closed
@external
@nonreentrant("lock")
def setRaceRunnerStatus(_meeting: String[18], _race: uint256, _runner: uint256, _status: uint256):
    assert self.admin_address == msg.sender, "You are not the admin address"
    assert self.meeting_race_status[_meeting][_race] == 1, "Race not active"

    # Get the addresses for the _meeting, _race, _runner
    addresses: DynArray[address, 50_000] = self.meeting_race_runner_address_win_bet[_meeting][_race][_runner]
    # Now iterate addresses
    length: uint256 = len(self.meeting_race_runner_address_win_bet[_meeting][_race][_runner])
    for i in range(50_000):
        if convert(i, uint256) == length:
            break
        else:
            # Get the user address that has bet on the race/runner
            user_address: address = addresses[i]
            # Check they havent already been refunded
            assert self.meeting_race_runner_address_win_bet_refunded[_meeting][_race][_runner][user_address] != True
            # Get how much they bet
            bet_amount: uint256 = self.meeting_race_runner_address_amount_win_bet[_meeting][_race][_runner][user_address]
            # Send it back to them
            send(user_address, bet_amount)
            # Reset the internal amount bet on the address/race/runner to 0
            self.address_meeting_race_runner_win_bet[user_address][_meeting][_race][_runner] = 0
            # Reset the internal amount bet on the race/runner/address to 0
            self.meeting_race_runner_address_amount_win_bet[_meeting][_race][_runner][user_address] = 0
            # Update that the race/runner/user_address was refunded
            self.meeting_race_runner_address_win_bet_refunded[_meeting][_race][_runner][user_address] = True

    # Set the race/runner status
    self.meeting_race_runner_status[_meeting][_race][_runner] = _status

    # Reset the amount bet on the race/runner
    self.meeting_race_runner_win_bet[_meeting][_race][_runner] = 0


# @notice Address bets on a win
# @dev We need to track an internal and external state, internal is for bet payout
#      external is for presentation to a user
# @param _meeting What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _race Which race number to bet on, 0 indexed
# @param _runner Which runner number to bet on, 0 indexed
@external
@payable
def betWin(_meeting: String[18], _race: uint256, _runner: uint256):
    assert self.meeting_race_status[_meeting][_race] == 1, "Race not active"
    assert self.meeting_race_runner_status[_meeting][_race][_runner] == 1, "Runner not active"

    # Increment the amount bet on the meeting/race/runner
    self.meeting_race_runner_win_bet[_meeting][_race][_runner] += msg.value

    # Internal win bet tracking for efficient payouts
    if (self.lookup_meeting_race_runner_address_win_bet[_meeting][_race][_runner][msg.sender] == False):
        self.lookup_meeting_race_runner_address_win_bet[_meeting][_race][_runner][msg.sender] = True
        self.meeting_race_runner_address_win_bet[_meeting][_race][_runner].append(msg.sender)
    self.meeting_race_runner_address_amount_win_bet[_meeting][_race][_runner][msg.sender] += msg.value

    # External win bet tracking/presentation for address
    if (self.lookup_address_meeting_race_runner_win_bet[msg.sender][_meeting] == False):
        self.address_meeting_race_runner_win_bet[msg.sender][_meeting] = self.meeting_race_runners[_meeting]
        self.lookup_address_meeting_race_runner_win_bet[msg.sender][_meeting] = True
    self.address_meeting_race_runner_win_bet[msg.sender][_meeting][_race][_runner] += msg.value


# @notice Change the win bets from one runner to another
# @dev We need to track an internal and external state, internal is for bet payout
#      external is for presentation to a user
# @param _meeting What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _race Which race number to bet on, 0 indexed
# @param _from_runner Which runner you hace placed a bet on
# @param _to_runner Which runner are you changing your bet to
@external
def changeWinBet(_meeting: String[18], _race: uint256, _from_runner: uint256, _to_runner: uint256):
    assert self.meeting_race_status[_meeting][_race] == 1, "Race not active"
    assert self.meeting_race_runner_status[_meeting][_race][_from_runner] == 1, "Runner not active"
    assert self.meeting_race_runner_status[_meeting][_race][_to_runner] == 1, "Runner not active"
    assert self.lookup_meeting_race_runner_address_win_bet[_meeting][_race][_from_runner][msg.sender] == True, "You have not placed a bet on this race/runner"

    # Interal
    # Get the amount bet on meeting/race/_from_runner and remove it from internals
    amount: uint256 = self.meeting_race_runner_address_amount_win_bet[_meeting][_race][_from_runner][msg.sender]
    self.meeting_race_runner_address_amount_win_bet[_meeting][_race][_from_runner][msg.sender] = empty(uint256)
    self.lookup_meeting_race_runner_address_win_bet[_meeting][_race][_from_runner][msg.sender] = empty(bool)

    # There is a fee for changing your bet
    takeout: uint256 = amount * self.meeting_change_fee[_meeting] / 10000
    amount_new: uint256 =  amount - takeout

    # Increment/Decrement the amount bet on the race - meeting/_from_runner/_to_runner
    self.meeting_race_runner_win_bet[_meeting][_race][_from_runner] -= amount
    self.meeting_race_runner_win_bet[_meeting][_race][_to_runner] += amount_new

    # External
    # Apply the amountNew to the new meeting/race/_to_runner combo
    self.meeting_race_runner_address_amount_win_bet[_meeting][_race][_from_runner][msg.sender] += amount_new
    self.lookup_meeting_race_runner_address_win_bet[_meeting][_race][_to_runner][msg.sender] = True

    # External win bet tracking/presentation for address
    self.address_meeting_race_runner_win_bet[msg.sender][_meeting][_race][_from_runner] = 0
    self.address_meeting_race_runner_win_bet[msg.sender][_meeting][_race][_to_runner] += amount_new


# @notice Cancel the win bet on a runner
# @param _meeting What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _race Which race number to cancel bet on, 0 indexed
# @param _runner Which runner to cancel bet on
@external
def cancelWinBet(_meeting: String[18], _race: uint256, _runner: uint256):
    assert self.meeting_race_status[_meeting][_race] == 1, "Race not active"
    assert self.meeting_race_runner_status[_meeting][_race][_runner] == 1, "Runner not active"
    assert self.lookup_meeting_race_runner_address_win_bet[_meeting][_race][_runner][msg.sender] == True, "You have not placed a bet on this race/runner"

    # Interal
    # Get the amount bet on _meeting/_race/_from_runner and remove it from internals
    amount: uint256 = self.meeting_race_runner_address_amount_win_bet[_meeting][_race][_runner][msg.sender]
    self.meeting_race_runner_address_amount_win_bet[_meeting][_race][_runner][msg.sender] = empty(uint256)
    self.lookup_meeting_race_runner_address_win_bet[_meeting][_race][_runner][msg.sender] = empty(bool)

    # Decrement the amount bet on the _meeting/_race/_runner
    self.meeting_race_runner_win_bet[_meeting][_race][_runner] -= amount

    # External win bet tracking/presentation for address
    self.address_meeting_race_runner_win_bet[msg.sender][_meeting][_race][_runner] = 0

    # There is a fee for cancelling your bet
    takeout: uint256 = amount * self.meeting_cancel_fee[_meeting] / 10000
    amount_return: uint256 =  amount - takeout
    send(msg.sender, amount_return)


event ResultBet:
    _runner_bets: DynArray[uint256, 50]
    _total_bet: uint256
    _payout: uint256
    _runner_bet: uint256
    _payout_per_unit: decimal

# @notice Result the race win bet
# @param _meeting What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _race Which race to result
# @param _winners An array of the winners
@external
@nonreentrant("lock")
def resultWinBet(_meeting: String[18], _race: uint256, _winners: DynArray[uint256, 5]):
    assert self.admin_address == msg.sender, "You are not the admin address"
    assert self.meeting_race_status[_meeting][_race] == 0, "Race is active"

    # https://en.wikipedia.org/wiki/Parimutuel_betting#:~:text=The%20payout%20is%20now%20calculated,a%20remaining%20amount%20of%20%24881.51.
    # https://www.youtube.com/watch?v=nsf46dzgCog
    # Get the runner_bets and sum up how much has been bet on the race
    runner_bets: DynArray[uint256, 50] = self.meeting_race_runner_win_bet[_meeting][_race]
    length: uint256 = len(runner_bets)
    total_bet: uint256 = 0
    for i in range(50):
        if i != length:
            total_bet += runner_bets[i]
        else:
            break

    # Calc the payout in wei
    payout: uint256 = total_bet - (total_bet * self.meeting_pct_takeout[_meeting] / 10_000)

    # Now iterate over the winners array, there could be a two or three way tie,
    # rare but need to deal with it
    runner_bet: uint256 = 0
    for winner in _winners:
        assert self.meeting_race_runner_status[_meeting][_race][winner] == 1, "Runner not active"
        runner_bet += runner_bets[winner]

    if runner_bet == 0:
        # Set the meeting_race_status to -1 == resulted
        self.meeting_race_status[_meeting][_race] = -1

    assert runner_bet > 0, "No money has been bet on the runner/s"
    # Calc the payout_per_unit
    payout_per_unit: decimal = convert(payout, decimal) / convert(runner_bet, decimal)

    # Now iterate the winners again, this time so we can payout
    for winner in _winners:
        # Get the addresses for the _meeting, _race, winner
        addresses: DynArray[address, 50_000] = self.meeting_race_runner_address_win_bet[_meeting][_race][winner]
        # Now iterate _addresses
        length_two: uint256 = len(self.meeting_race_runner_address_win_bet[_meeting][_race][winner])
        for ii in range(50_000):
            if convert(ii, uint256) == length_two:
                break
            else:
                user_address: address = addresses[ii]
                assert self.meeting_race_runner_address_win_bet_paid[_meeting][_race][winner][user_address] != True
                # Now do the payout logic and send them their cash
                bet_amount: uint256 = self.meeting_race_runner_address_amount_win_bet[_meeting][_race][winner][user_address]
                bet_payout: decimal = payout_per_unit * convert(bet_amount, decimal)
                self.meeting_race_runner_address_win_bet_paid[_meeting][_race][winner][user_address] = True
                send(user_address, convert(bet_payout, uint256))

    # Set the meeting_race_status to -1 == resulted
    self.meeting_race_status[_meeting][_race] = -1

    log ResultBet(runner_bets, total_bet, payout, runner_bet, payout_per_unit)