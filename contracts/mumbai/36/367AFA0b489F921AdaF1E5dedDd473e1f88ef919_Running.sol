// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Running is Ownable {
    uint256 public availableBalances;

    // Mapping from domain to wallet
    mapping(string => address) private _wallets;
    // Mapping wallet to balance
    mapping(string => uint256) private _balances;

    //History for result
    mapping(string => uint256) private _history;
    //Số member bị charge tiền
    uint256 private chargeNumber = 3;
    //Số tiền bị phạt
    uint256[] private chargeValue = [0.1 ether, 0.07 ether, 0.05 ether];

    event Received(string indexed domain, uint256 indexed value);
    event Charged(string indexed domain, uint256 indexed value);
    event Withdrawed(string indexed domain, uint256 indexed value);
    event Withdrawed(address indexed account, uint256 indexed value);

    constructor(string[] memory domains, address[] memory wallets) {
        require(
            domains.length == wallets.length,
            "Domains and wallets length mismatch"
        );
        for (uint256 i = 0; i < domains.length; i++) {
            string memory domain = domains[i];
            address wallet = wallets[i];
            _wallets[domain] = wallet;
        }
    }

    function deposit(string memory domain) public payable {
        require(_wallets[domain] == msg.sender, "Invalid wallet or domain");
        _balances[domain] += msg.value;
        emit Received(domain, msg.value);
    }

    function balanceOf(string memory domain) public view returns (uint256) {
        return _balances[domain];
    }

    function charge(string memory domain, uint256 value) internal {
        uint256 balance = balanceOf(domain);
        require(balance >= value, "Insufficient domain balance");
        unchecked {
            _balances[domain] = balance - value;
        }
        availableBalances += value;
        emit Charged(domain, value);
    }

    function result(string[] memory domains) public onlyOwner {
        for (uint256 i = 0; i < domains.length; i++) {
            string memory domain = domains[i];
            require(_wallets[domain] != address(0), "Invalid domain");
            uint256 position = domains.length - i;

            if (position <= chargeNumber) {
                bool isDouble = _history[domain] > 0 && _history[domain] <= chargeNumber;
                uint256 value = isDouble ? chargeValue[position - 1] * 2 : chargeValue[position - 1];
                charge(domain, value);
            }

            _history[domain] = position;
        }
    }

    function widthdrawFromDomain(string memory domain, uint256 value) public {
        address wallet = msg.sender;
        uint256 balance = balanceOf(domain);

        require(balance >= value, "Insufficient wallet balance");
        require(_wallets[domain] == wallet, "Invalid withdraw wallet address");

        unchecked {
            _balances[domain] = balance - value;
        }
        address payable walletPayable = payable(wallet);
        walletPayable.transfer(value);
        emit Withdrawed(domain, value);
    }

    function withdrawFromAvailable(address account, uint256 value)
        public
        onlyOwner
    {
        require(availableBalances >= value, "Insufficient available balance");
        require(account != address(0), "Invalid address");

        unchecked {
            availableBalances = availableBalances - value;
        }
        address payable accountPayable = payable(account);
        accountPayable.transfer(value);
        emit Withdrawed(account, value);
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