# @version ^0.3.3

# USDC interface
interface i_usdc:
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable

CHANGE_CANCEL_FEE: uint256

# USDC contract address
s_usdc_address: public(address)

# State variables
s_addresses_set: bool
s_admin_address: public(address)
s_withdraw_address: public(address)

# @notice
# ["2022-02-23-HKG-HAP"] = true
s_meeting_setup_done: HashMap[String[18], bool]

# @notice
# ["2022-02-23-HKG-HAP"] = [-1,0,1,1,1,]
s_meeting_race_status: HashMap[String[18], DynArray[uint256, 20]]

# @notice
# ["2022-02-23-HKG-HAP"] = [[1,0,1,1,1,],[1,0,1,1,1,]]
s_meeting_race_runner_status: HashMap[String[18], DynArray[DynArray[uint256, 50], 20]]

# @notice
# [address][bet_key] = 100000
s_win_place_bets: HashMap[address, HashMap[Bytes[480], uint256]]


# @notice setup the contract
# @param _usdc_adddress address on the USDC contract
@external
def __init__(_usdc_adddress: address):
    self.CHANGE_CANCEL_FEE = 1500
    self.s_usdc_address = _usdc_adddress


# @notice Initial call to setup the addresses
@external
def setAddresses():
    assert self.s_addresses_set == False, "Addresses have been set"
    self.s_admin_address = 0x89300F6AC18C87948c802038D50777a82AAFb081
    self.s_withdraw_address = 0x67156493946e5696EA9Be7d7E5138E9f9DD53559
    self.s_addresses_set = True


# @notice Allow the contract to receive USDC
# @param _amount The amount of USDC to send to the contract
@internal
def _receiveUSDC(_amount: uint256):
    success: bool = i_usdc(self.s_usdc_address).transferFrom(msg.sender, self, _amount)
    assert success == True, "Contract did not receive USDC"


# @notice Allow the contract to receive USDC
# @param _amount The amount of USDC to send to the contract
@external
def receiveUSDC(_amount: uint256):
    self._receiveUSDC(_amount)


# @notice Setup the internals of the contract
# @param _meeting_key What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _meeting_setup The array of races and number of runners [6, 6, 7, 8, 8, 14, 10]
@external
def setup(_meeting_key: String[18], _meeting_setup: DynArray[uint256, 20]):
    assert self.s_admin_address == msg.sender, "You are not the admin address"
    assert self.s_meeting_setup_done[_meeting_key] == False, "Meeting already setup"

    for _race in _meeting_setup:
        _runners: DynArray[uint256, 50] = []
        for i in range(100):
            if i != _race:
                _runners.append(1)
            else:
                break

        self.s_meeting_race_status[_meeting_key].append(1)
        self.s_meeting_race_runner_status[_meeting_key].append(_runners)

    self.s_meeting_setup_done[_meeting_key] = True


# @notice Get the meeting_race_status for a given meeting_key
# @dev Is a convenience method for accessing contract state.
# @param _meeting_key What meeting are we talking about - 2022-02-23-HKG-HAP
@external
@view
def raceStatus(_meeting_key: String[18]) -> (DynArray[uint256, 20]):
    return self.s_meeting_race_status[_meeting_key]


# @notice Set a race status
# @param _meeting What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _race Which race number to change the status of, 0 indexed
# @param _status 1 is active, 0 is closed
@external
def setRaceStatus(_meeting_key: String[18], _race: uint256, _status: uint256):
    assert self.s_admin_address == msg.sender, "You are not the admin address"
    self.s_meeting_race_status[_meeting_key][_race] = _status


# @notice Get the meeting_race_runner_status for a given meeting_key
# @dev Is a convenience method for accessing contract state.
# @param _meeting_key What meeting are we talking about - 2022-02-23-HKG-HAP
@external
@view
def raceRunnerStatus(_meeting_key: String[18]) -> (DynArray[DynArray[uint256, 50], 20]):
    return self.s_meeting_race_runner_status[_meeting_key]


# @notice Set a race/runner status
# @param _meeting What meeting are we talking about - 2022-02-23-HKG-HAP
# @param _race Which race number to change the status of, 0 indexed
# @param _runner Which runner number to change the status of, 0 indexed
# @param _status 1 is active, 0 is closed
@external
def setRaceRunnerStatus(_meeting_key: String[18], _race: uint256, _runner: uint256, _status: uint256):
    assert self.s_admin_address == msg.sender, "You are not the admin address"
    assert self.s_meeting_race_status[_meeting_key][_race] == 1, "Race not active"

    self.s_meeting_race_runner_status[_meeting_key][_race][_runner] = _status


# @notice Set the admin address
# @dev Only the admin address can acess various functions on the contract
# @param _admin_address Wallet address you want to be the admin
@external
def setAdminAddress(_admin_address: address):
    # The factory seems top set the admin/withdraw address as ZERO_ADDRESS
    # we need to be able to set these when the factory deploys the contract
    if self.s_admin_address == ZERO_ADDRESS:
        self.s_admin_address = _admin_address
    else:
        assert self.s_admin_address == msg.sender, "You are not the admin address"
        self.s_admin_address = _admin_address


# @notice Set the withdraw_address
# @dev Use sparingly, this will receive the contract funds
# @param _withdraw_address Wallet address you want funds to go to
@external
def setWithdrawAddress(_withdraw_address: address):
    # The factory seems top set the admin/withdraw address as ZERO_ADDRESS
    # we need to be able to set these when the factory deploys the contract
    if self.s_withdraw_address == ZERO_ADDRESS:
        self.s_withdraw_address = _withdraw_address
    else:
        assert self.s_admin_address == msg.sender, "You are not the admin address"
        self.s_withdraw_address = _withdraw_address


event WinOrPlaceBet:
    bet_key: Bytes[480]
    wl_operator: String[2]
    wl_operator_fee: uint256
    wallet: address
    bet_type: String[10]
    action: String[10]
    meeting_key: String[18]
    race: uint256
    runner: uint256
    amount: uint256


@external
def createWinBet(_wl_operator: String[2], _meeting_key: String[18], _race: uint256, _runner: uint256, _amount: uint256):
    assert self.s_meeting_race_status[_meeting_key][_race] == 1, "Race not active"
    assert self.s_meeting_race_runner_status[_meeting_key][_race][_runner] == 1, "Runner not active"

    self._receiveUSDC(_amount)
    _bet_key: Bytes[480] = _abi_encode(_wl_operator, "win", _meeting_key, _race, _runner)
    self.s_win_place_bets[msg.sender][_bet_key] += _amount

    log WinOrPlaceBet(
        _bet_key, _wl_operator, 0, msg.sender, "win", "create", _meeting_key,
        _race, _runner, self.s_win_place_bets[msg.sender][_bet_key]
    )


@external
def changeWinBet(_wl_operator: String[2], _meeting_key: String[18], _race: uint256, _from_runner: uint256, _to_runner: uint256):
    assert self.s_meeting_race_status[_meeting_key][_race] == 1, "Race not active"
    assert self.s_meeting_race_runner_status[_meeting_key][_race][_from_runner] == 1, "From runner not active"
    assert self.s_meeting_race_runner_status[_meeting_key][_race][_to_runner] == 1, "To runner not active"

    old_bet_key: Bytes[480] = _abi_encode(_wl_operator, "win", _meeting_key, _race, _from_runner)
    new_bet_key: Bytes[480] = _abi_encode(_wl_operator, "win", _meeting_key, _race, _to_runner)

    bet_amount: uint256 = self.s_win_place_bets[msg.sender][old_bet_key]

    if bet_amount > 0:
        # There is a fee for changing your bet
        takeout: uint256 = bet_amount * self.CHANGE_CANCEL_FEE / 10000
        bet_amount_new: uint256 =  bet_amount - takeout
        self.s_win_place_bets[msg.sender][old_bet_key] = 0
        self.s_win_place_bets[msg.sender][new_bet_key] += bet_amount_new

        log WinOrPlaceBet(
            old_bet_key, _wl_operator, 0, msg.sender, "win", "change", _meeting_key,
            _race, _from_runner, self.s_win_place_bets[msg.sender][old_bet_key]
        )
        log WinOrPlaceBet(
            new_bet_key, _wl_operator, 0, msg.sender, "win", "change", _meeting_key,
            _race, _to_runner, self.s_win_place_bets[msg.sender][new_bet_key]
        )

    else:
      raise "You have not placed a bet on this race/runner"


@external
def cancelWinBet(_wl_operator: String[2], _meeting_key: String[18], _race: uint256, _runner: uint256):
    assert self.s_meeting_race_status[_meeting_key][_race] == 1, "Race not active"
    assert self.s_meeting_race_runner_status[_meeting_key][_race][_runner] == 1, "Runner not active"

    bet_key: Bytes[480] = _abi_encode(_wl_operator, "win", _meeting_key, _race, _runner)
    bet_amount: uint256 = self.s_win_place_bets[msg.sender][bet_key]

    if bet_amount > 0:
        self.s_win_place_bets[msg.sender][bet_key] = 0

        # There is a fee for cancelling your bet
        takeout: uint256 = bet_amount * self.CHANGE_CANCEL_FEE / 10000
        amount_return: uint256 =  bet_amount - takeout

        # Return the USDC less the takeout
        i_usdc(self.s_usdc_address).approve(self, amount_return)
        i_usdc(self.s_usdc_address).transferFrom(self, msg.sender, amount_return)

        log WinOrPlaceBet(
            bet_key, _wl_operator, 0, msg.sender, "win", "cancel", _meeting_key,
            _race, _runner, self.s_win_place_bets[msg.sender][bet_key]
        )
    else:
      raise "You have not placed a bet on this race/runner"


@external
def resultWinBet(_meeting_key: String[18], _race: uint256, _winners: DynArray[uint256, 5]):
    pass