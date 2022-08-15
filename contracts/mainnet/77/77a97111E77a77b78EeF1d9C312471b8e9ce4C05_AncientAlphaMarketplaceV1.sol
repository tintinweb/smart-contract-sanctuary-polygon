// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IToken.sol";

contract AncientAlphaMarketplaceV1 is Ownable {
    //CONSTANT
    uint8 constant public MAX_MINTABLE = 5;
    uint256 constant public BASE_CURRENCY = 1 ether;

    //MANAGERS
    mapping(address => bool) public managers;

    //FOUNDER WALLET
    address public foundersWallet;

    //MARKET OPENER
    bool public isMarketOpen;



    event Purchase(address indexed buyer, uint256 index, uint256 price, uint256 quantity);


    constructor(){
        managers[msg.sender] = true;
        foundersWallet = 0x02367e1ed0294AF91E459463b495C8F8F855fBb8;
        isMarketOpen = true;
    }

    modifier onlyManager(address sender){
        require(managers[sender] == true, "not a manager");
        _;
    }

    function purchase(uint256 index, uint256 quantity) external payable{
        require(isMarketOpen, "market is closed");
        require(quantity > 0 && quantity <= MAX_MINTABLE, "quantity is wrong");
        require(msg.value > 0, "value must be greater than 0");

        emit Purchase(msg.sender, index, msg.value, quantity);
        
    }

    function setFoundersWallet(address newFoundersWallet) external onlyOwner{
        foundersWallet = newFoundersWallet;
    }

    function setManagerStatus(address manager, bool status) external onlyOwner {
        managers[manager] = status;
    }

    function setMarketStatus(bool status) external onlyManager(msg.sender) {
        isMarketOpen = status;
    }
    

    //FUND AND WITHDRAW
    function withdraw() external onlyManager(msg.sender) {
        uint256 _balance = address(this).balance;
        payable(foundersWallet).transfer(_balance);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function balanceOf(address owner) external view returns(uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address, address, uint256) external;
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}