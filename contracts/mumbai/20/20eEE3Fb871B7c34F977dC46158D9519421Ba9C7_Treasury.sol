// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IToken {
    function withdraw() external;
}

// SPDX-License-Identifier: MIT

/**
 * @title Treasury Contract of DAO Governance
 * @author Lruquaf ---> github.com/Lruquaf
 * @notice this contract is a simple treasury, which can
 * transfer the assets to an address by proposals of the governance
 */

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IToken.sol";

contract Treasury is Ownable {
    IToken public token; // address of token currency of the governance
    uint256 public balance; // balance of treasury

    event Transferred(address to, uint256 amount);
    event Received(address from, uint256 amount);

    /**
     *
     * @param _governance address of the governance contract
     * @param _token address of governance token address
     * @notice transfers ownership of this contract to governance contract
     * @notice transfers token vesting funds to this contract from token contract
     */

    constructor(address _governance, address _token) {
        transferOwnership(_governance);
        token = IToken(_token);
        token.withdraw();
    }

    /**
     *
     * @param to destination address of transfer
     * @param amount asset amount of transfer
     * @notice can be called by only governance contract
     */

    function transfer(address to, uint256 amount) public onlyOwner {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed!");
        emit Transferred(to, amount);
    }

    /**
     * @notice returns balance of this contract
     */

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice can receive ETH for funding
     */

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}