// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Running is Ownable {
    uint256 public availableBalances;

    mapping(string => mapping(address => uint256)) private _balances;
    mapping(string => address[]) private _wallets;

    event Received(string domain, uint256 value);
    event Charged(string domain, uint256 value);
    event Withdrawed(string domain, uint256 value);
    event Withdrawed(address account, uint256 value);

    function deposit(string memory domain) public payable {
        _balances[domain][msg.sender] += msg.value;
        _wallets[domain].push(msg.sender);
        emit Received(domain, msg.value);
    }

    function balanceOf(string memory domain) public view returns (uint256) {
        address[] memory wallets = _wallets[domain];
        uint256 totalBalance = 0;
        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            totalBalance += _balances[domain][wallet];
        }
        return totalBalance;
    }

    function balanceOfAddress(string memory domain, address wallet)
        public
        view
        returns (uint256)
    {
        return _balances[domain][wallet];
    }

    function charge(string memory domain, uint256 value) public onlyOwner {
        uint256 domainBalance = balanceOf(domain);
        require(domainBalance >= value, "Insufficient domain balance");

        address[] memory wallets = _wallets[domain];
        uint256 chargedValue = 0;
        for (uint256 i = 0; i < wallets.length; i++) {
            if (chargedValue == value) break;
            address wallet = wallets[i];
            uint256 walletBalance = balanceOfAddress(domain, wallet);

            if (walletBalance >= value - chargedValue) {
                unchecked {
                    _balances[domain][wallet] =
                        walletBalance -
                        (value - chargedValue);
                }
                chargedValue = value;
            } else {
                chargedValue += walletBalance;
                _balances[domain][wallet] = 0;
            }
        }
        availableBalances += value;
        emit Charged(domain, value);
    }

    function batchCharge(string[] memory domains, uint256[] memory values)
        public
        onlyOwner
    {
        require(
            domains.length == values.length,
            "Domains and values length mismatch"
        );
        for (uint256 i = 0; i < domains.length; i++) {
            charge(domains[i], values[i]);
        }
    }

    function widthdrawFromDomain(string memory domain, uint256 value) public {
        uint256 walletBalance = balanceOfAddress(domain, msg.sender);
        require(walletBalance >= value, "Insufficient wallet balance");
        address payable senderPayable = payable(msg.sender);
        senderPayable.transfer(value);
        emit Withdrawed(domain, value);
    }

    function withdrawFromAvailable(address account, uint256 value)
        public
        onlyOwner
    {
        require(availableBalances >= value, "Insufficient available balance");
        address payable accountPayable = payable(account);
        accountPayable.transfer(value);
        emit Withdrawed(account, value);
        unchecked {
            availableBalances = availableBalances - value;
        }
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