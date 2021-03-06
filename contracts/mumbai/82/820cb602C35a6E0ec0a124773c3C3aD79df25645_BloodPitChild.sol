// SPDX-License-Identifier: MIT
/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IBloodToken {
  function spend(
        uint256 amount,
        address sender,
        address recipient,
        address redirectAddress,
        uint256 redirectPercentage,
        uint256 burnPercentage
    ) external;
}

contract BloodPitChild is Ownable {
  event Burned(address wallet, uint256 amount);

  IBloodToken public bloodToken;

  address public spendRecipient;
  address public spendRedirect;
  uint8 public redirectPercent;
  uint8 public burnPercent = 70;

  /**
   * @dev Constructor
   * @param _token Address of Blood token.
   * @param _spendRecipient Address of spend recipient.
   */
  constructor(
    address _token, 
    address _spendRecipient
  ) {
    bloodToken = IBloodToken(_token);
    spendRecipient = _spendRecipient;
  }

  /**
   * @dev Function for burning in game tokens and increasing blood pit standing.
   * @notice This contract has to be authorised.
   * @param amount Amount of tokens user is burning in the blood pit.
   */
  function burn(uint256 amount) external {
    bloodToken.spend(
        amount,
        msg.sender,
        spendRecipient,
        spendRedirect,
        redirectPercent,
        burnPercent
    );
    emit Burned(msg.sender, amount);
  }

  /**
    * @dev Update spend parameters.
    * @param _spendRecipient: address to receive BLD from spend
    * @param _spendRedirect: address to receive BLD from spend
    * @param _redirectPercent: percent of BLD to be sent to spendRedirect address
    * @param _burnPercent: percent of BLD to be burned when spend is called
    */
  function setSpendData(
    address _spendRecipient, 
    address _spendRedirect, 
    uint8 _redirectPercent,
    uint8 _burnPercent
  ) external onlyOwner {
    spendRecipient = _spendRecipient;
    spendRedirect = _spendRedirect;
    redirectPercent = _redirectPercent;
    burnPercent = _burnPercent;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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