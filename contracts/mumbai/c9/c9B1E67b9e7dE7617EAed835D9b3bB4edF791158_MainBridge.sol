/**
 *Submitted for verification at polygonscan.com on 2023-05-04
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol



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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: bridge/IERC20Child.sol


pragma solidity ^0.8.0;

//Remix style import


//Brownie style import
// import { IERC20 } from "OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol";

/// @dev Interface of the child ERC20 token, for use on sidechains and L2 networks.
interface IERC20Child is IERC20 {
  /**
   * @notice called by bridge gateway when tokens are deposited on root chain
   * Should handle deposits by minting the required amount for the recipient
   *
   * @param recipient an address for whom minting is being done
   * @param amount total amount to mint
   */
  function mint(
    address recipient,
    uint256 amount
  )
    external;

  /**
   * @notice called by bridge gateway when tokens are withdrawn back to root chain
   * @dev Should burn recipient's tokens.
   *
   * @param amount total amount to burn
   */
  function burn(
    uint256 amount
  )
    external;

  /**
   *
   * @param account an address for whom burning is being done
   * @param amount total amount to burn
   */
  function burnFrom(
    address account,
    uint256 amount
  )
    external;
}


// File: bridge/mainbridge.sol


pragma solidity ^0.8.0;

//Remix style import


// //Brownie style import
// import { IERC20 } from "OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol";


contract MainBridge {

    IERC20 private mainToken;

    event TokensLocked(address indexed requester, bytes32 indexed mainDepositHash, uint amount, uint timestamp);
    event TokensUnlocked(address indexed requester, bytes32 indexed sideDepositHash, uint amount, uint timestamp);
    event BridgeInitialized(uint indexed timestamp);
    event TokensBridged(address indexed requester, bytes32 indexed mainDepositHash, uint amount, uint timestamp);
    event TokensReturned(address indexed requester, bytes32 indexed sideDepositHash, uint amount, uint timestamp);
    
        bool bridgeInitState;
    address owner;

        constructor () {
        owner = msg.sender;
    }

    function bridgeTokens (address sideToken,address _requester, uint _bridgedAmount, bytes32 _mainDepositHash)  public {
      IERC20Child(sideToken).mint(_requester,_bridgedAmount);
        emit TokensBridged(_requester, _mainDepositHash, _bridgedAmount, block.timestamp);
    }

    function returnTokens (address sideToken,address _requester, uint _bridgedAmount, bytes32 _sideDepositHash) public {
         IERC20Child(sideToken).burn(_bridgedAmount);
        emit TokensReturned(_requester, _sideDepositHash, _bridgedAmount, block.timestamp);
    }


    modifier onlyOwner {
      require(msg.sender == owner, "Only owner can execute this function");
      _;
    }

    function lockTokens (address contracts ,address _requester, uint _bridgedAmount, bytes32 _mainDepositHash)  external {
        IERC20(contracts).transferFrom(_requester,address(this),_bridgedAmount);
        emit TokensLocked(_requester, _mainDepositHash, _bridgedAmount, block.timestamp);
    }

    function unlockTokens (address contracts ,address _requester, uint _bridgedAmount, bytes32 _sideDepositHash)  external {
        IERC20(contracts).transfer(_requester, _bridgedAmount);
        emit TokensUnlocked(_requester, _sideDepositHash, _bridgedAmount, block.timestamp);
    }
}