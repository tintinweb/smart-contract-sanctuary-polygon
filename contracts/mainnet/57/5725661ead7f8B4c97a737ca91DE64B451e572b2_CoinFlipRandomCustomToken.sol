// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract CoinFlipRandomCustomToken {
    struct CoinFlipStatus {
        uint256 randomNumberKeccak;
        uint256 randomNumber;
        address player;
        bool didWin;
        bool fulfilled;
        CoinFlipSelection choice;
    }

    address public ICETokenAddress = 0xc6C855AD634dCDAd23e64DA71Ba85b8C51E5aD7c;

    mapping(address => CoinFlipStatus[]) public userGameStatuses;

    enum CoinFlipSelection {
        HEADS,
        TAILS,
        SIDE
    }

    mapping(uint256 => CoinFlipStatus) public statuses;
    
    uint256 public gameCounter = 0;

    uint128 constant entryBet = 0.001 ether;

    address public owner;
    
    constructor () payable {
        owner = msg.sender;
    }
    
    function flip(CoinFlipSelection choice, uint256 amount) public {
      IERC20 ICE = IERC20(ICETokenAddress);

      uint256 allowance = ICE.allowance(msg.sender, address(this));

      require(allowance >= amount, "Not enough allowance");
      require((choice == CoinFlipSelection.HEADS || choice == CoinFlipSelection.TAILS), "Invalid choice option.");
      require( address(this).balance >= (entryBet*2), "Insufficient contract balance.");

      require(ICE.transferFrom(msg.sender, address(this), entryBet), "Transfer failed");

      statuses[gameCounter] = CoinFlipStatus({
          randomNumberKeccak: 0,
          randomNumber: 0,
          player: msg.sender,
          didWin: false,
          fulfilled: false,
          choice: choice
      });
      
      statuses[gameCounter].fulfilled = true;
      statuses[gameCounter].randomNumberKeccak = uint(keccak256(abi.encodePacked(msg.sender, block.timestamp, gameCounter)));
      statuses[gameCounter].randomNumber = (statuses[gameCounter].randomNumberKeccak % 1000);

      CoinFlipSelection result = CoinFlipSelection.SIDE;
      
      if (statuses[gameCounter].randomNumber < 475) {
          result = CoinFlipSelection.HEADS;
      } else if (statuses[gameCounter].randomNumber < 950) {
          result = CoinFlipSelection.TAILS;
      }
      
      if (statuses[gameCounter].choice == result) {
          statuses[gameCounter].didWin = true;
          ICE.transferFrom(address(this), msg.sender, entryBet * 2);
      }

      userGameStatuses[statuses[gameCounter].player].push(statuses[gameCounter]);

      gameCounter++;
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "Only CoinFlip owner can change owner.");
        owner = newOwner;
    }

    function getUserGameStatuses(address user) external view returns (CoinFlipStatus[] memory) {
        return userGameStatuses[user];
    }

    function withdrawFunds(uint256 amount) external {
        require(msg.sender == owner, "Only CoinFlip owner can withdraw funds.");
        
        IERC20 ICE = IERC20(ICETokenAddress);

        require(ICE.balanceOf(address(this)) >= amount, "Insufficient CoinFlip balance.");

        uint256 communityShare = amount * 20 / 100;
        uint256 daoShare = amount * 10 / 100;
        uint256 houseShare = amount * 70 / 100;

        ICE.transferFrom(address(this), 0x4FFB9413fb851B3e6E5F9f442bEb902d7619E371, communityShare);
        ICE.transferFrom(address(this), 0xe4AfC24B8dba77C4dFBCc9FAB236d0C4701D06fc, daoShare);
        ICE.transferFrom(address(this), 0x7F19EE3C23F25b4794A25ed25c5418Fb52ff8786, houseShare);
    }
}