/**
 *Submitted for verification at polygonscan.com on 2022-02-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;


/// @title Bank 0.2.0
/// @author awphi (https://github.com/awphi)
// 
contract Bank {
    mapping(address => uint) funds;

    function withdraw(uint amount) public {
        require(amount > 0, "Invalid withdrawal amount requested.");
        require(funds[msg.sender] >= amount, "Insufficient funds to process withdrawal.");
        require(address(this).balance >= amount, "Bank has insufficient funds to process withdrawal - try again later.");

        funds[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function deposit() public payable {
        require(msg.value > 0, "Invalid deposit amount.");
        funds[msg.sender] += msg.value;
    }

    function balanceOf(address add) public view returns (uint) {
        return funds[add];
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/// @title Roulette 0.2.2
/// @author awphi (https://github.com/awphi)
// 
contract Roulette is Ownable, Bank {
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

  function play() public onlyOwner {
    uint roll = random(37);
    emit OutcomeDecided(roll);

    for (uint i = 0; i < numBets; i++) {
      uint w = calculate_winnings(bets[i], roll);
      if(w > 0) {
        // If player won (w > 0) designate their winnings (incl. stake) to them
        funds[bets[i].player] += w;
      } else if(roll == 0) {
        /** @dev When a 0 is rolled, house will skim all bets. This can be used to pay for more LINK, hosting fees or just treated as profit - 
          it up to the owner. In the long-term, with enough initial capital this is a stable system.
        **/
        funds[owner()] += bets[i].bet_amount;
      }
    }

    numBets = 0;
  }
}