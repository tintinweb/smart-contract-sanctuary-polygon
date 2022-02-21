/**
 *Submitted for verification at polygonscan.com on 2022-02-20
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;


/// @title Bank 0.1.0
/// @author awphi (https://github.com/awphi)
/// @notice Bank from GlassCasino - L3 BSc ComSci Project @ Durham University
/// @dev -
// 
contract Bank {
    mapping(address => uint) funds;

    function withdraw(uint amount) public {
        require(amount > 0);
        require(funds[msg.sender] >= amount);
        require(address(this).balance >= amount);

        funds[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function deposit() public payable {
        require(msg.value > 0);
        funds[msg.sender] += msg.value;
    }

    function balance() public view returns (uint) {
        return funds[msg.sender];
    }
}

/// @title Owmed 0.1.0
/// @author awphi (https://github.com/awphi)
/// @notice Owned from GlassCasino - L3 BSc ComSci Project @ Durham University
/// @dev -
// 
contract Owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyHouse {
        require(msg.sender == owner, "Transaction sender is not contract owner.");
        _;
    }
}

/// @title Roulette 0.2.0
/// @author awphi (https://github.com/awphi)
/// @notice Roulette game from GlassCasino - L3 BSc ComSci Project @ Durham University
/// @dev See get_winnings function for bet types/bet operand breakdown
// 
contract Roulette is Owned, Bank {
  struct Bet {
    uint16 bet_type;
    uint16 bet;
    uint64 timestamp;
    address player;

    uint256 bet_amount;
  }

  uint128 numBets = 0;
  Bet[128] bets;

  // Used so dApp can listen to emitted event to update UIs as soon as the outcome is rolled
  event OutcomeDecided(uint roll);
  event BetPlaced(Bet bet);

  function get_bets() public view returns (Bet[] memory) {
    Bet[] memory ret = new Bet[](numBets);

    for(uint i = 0; i < numBets; i ++) {
      ret[i] = bets[i];
    }

    return ret;
  }

  function get_bets_length() public view returns (uint128) {
    return numBets;
  }

  function get_max_bets() public view returns (uint) {
    return bets.length;
  }

  function place_bet(uint16 bet_type, uint256 bet_amount, uint16 bet) public {
    require(bet_amount > 0, "Invalid bet amount.");
    require(funds[msg.sender] >= bet_amount, "Insufficient funds to cover bet.");
    require(numBets < bets.length, "Maximum bets reached.");

    funds[msg.sender] -= bet_amount;
    bets[numBets] = Bet(bet_type, bet, uint64(block.timestamp), msg.sender, bet_amount);
    numBets += 1;
    emit BetPlaced(bets[bets.length - 1]);
  }

  // Note: Replace with chainlink
  function random(uint mod) public view returns (uint) {
    return
      uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % mod;
  }

  function is_red(uint roll) public pure returns (bool) {
    if (roll < 11 || (roll > 18 && roll < 29)) {
      // Red odd, black even
      return roll % 2 == 1;
    } else {
      return roll % 2 == 0;
    }
  }

  function calculate_winnings(Bet memory bet, uint roll) public pure returns (uint) {
    // House edge
    if (roll == 0) {
      return 0;
    }

    /*
    COLOUR = 0,
    ODDEVEN = 1,
    STRAIGHTUP = 2,
    HIGHLOW = 3, 
    COLUMN = 4, 
    DOZENS = 5, 
    SPLIT = 6, 
    STREET = 7, 
    CORNER = 8, 
    LINE = 9, 
    FIVE = 10, 
    BASKET = 11, 
    SNAKE = 12 
    */

    if (bet.bet_type == 0) {
      // 0 = red, 1 = black
      if (bet.bet == (is_red(roll) ? 0 : 1)) {
        return bet.bet_amount * 2;
      }
    } else if (bet.bet_type == 1) {
      // 0 = even, 1 = odd
      if (bet.bet == (roll % 2)) {
        return bet.bet_amount * 2;
      }
    } else if (bet.bet_type == 2) {
      if (bet.bet == roll) {
        return bet.bet_amount * 35;
      }
    }

    return 0;
  }

  function play() public onlyHouse {
    uint roll = random(37);
    emit OutcomeDecided(roll);

    for (uint i = 0; i < numBets; i++) {
      uint w = calculate_winnings(bets[i], roll);
      if(w > 0) {
        // If player won (w > 0) designate their winnings (incl. stake) to them
        funds[bets[i].player] += w;
      } else {
        // Else player lost, stake is designated to the house to pay off winners & VRF fees etc.
        funds[owner] += bets[i].bet_amount;
      }
    }

    numBets = 0;
  }
}