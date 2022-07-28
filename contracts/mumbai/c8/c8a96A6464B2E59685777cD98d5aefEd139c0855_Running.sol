// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Running is Ownable {
    uint256 public availableBalances;
    string[] private _domains;

    // Mapping from domain to wallet
    mapping(address => string) private _wallets;
    // Mapping from wallet to domain
    mapping(string => address) private _owners;
    // Mapping wallet to balance
    mapping(string => uint256) private _balances;
    //History for result
    mapping(string => uint256) private _history;
    //Số member bị charge tiền
    uint256 private chargeNumber = 3;
    //Phí rút tiền (%)
    uint256 private chargeFee = 10;
    //Phí bet (%)
    uint256 private betFee = 30;
    //Số tiền bị phạt
    uint256[] private chargeValue = [0.1 ether, 0.07 ether, 0.05 ether];
    //Số tiền bet
    uint256 private betValue = 0.1 ether;

    event Received(string indexed domain, uint256 indexed value);
    event Charged(string indexed domain, uint256 indexed value);
    event Rewarded(string indexed domain, uint256 indexed value);
    event Withdrawed(
        string indexed domain,
        uint256 indexed value,
        uint256 indexed fee
    );
    event Withdrawed(address indexed account, uint256 indexed value);

    constructor(string[] memory domains, address[] memory wallets) {
        require(
            domains.length == wallets.length,
            "Domains and wallets length mismatch"
        );
        for (uint256 i = 0; i < domains.length; i++) {
            string memory domain = domains[i];
            address wallet = wallets[i];
            _wallets[wallet] = domain;
            _owners[domain] = wallet;
        }
        _domains = domains;
    }

    modifier isMember(address wallet) {
        string memory domain = _wallets[wallet];
        bytes memory domainBytes = bytes(domain);
        require(domainBytes.length > 0, "Invalid wallet of sender");
        _;
    }

    modifier enoughBalance(string memory domain, uint256 value) {
        uint256 balance = balanceOf(domain);
        require(balance >= value, "Insufficient domain balance");
        _;
    }

    receive() external payable isMember(msg.sender) {
        string memory domain = _wallets[msg.sender];
        _balances[domain] += msg.value;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here");
    }

    function balanceOf(string memory domain) public view returns (uint256) {
        return _balances[domain];
    }

    function allBalances()
        public
        view
        returns (string[] memory, uint256[] memory)
    {
        uint256[] memory balances = new uint256[](_domains.length);
        for (uint256 i = 0; i < _domains.length; i++) {
            string memory domain = _domains[i];
            balances[i] = balanceOf(domain);
        }
        return (_domains, balances);
    }

    function compare(string memory s1, string memory s2)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function addMember(string memory domain, address wallet) public onlyOwner {
        require(_owners[domain] == address(0), "Domain existed");
        require(!compare(_wallets[wallet], domain), "Wallet existed");
        _owners[domain] = wallet;
        _wallets[wallet] = domain;
        _domains.push(domain);
    }

    function charge(string memory domain, uint256 value)
        internal
        enoughBalance(domain, value)
    {
        unchecked {
            _balances[domain] -= value;
        }
        availableBalances += value;
        emit Charged(domain, value);
    }

    function reward(string memory domain, uint256 value) internal {
        _balances[domain] += value;
        availableBalances -= value;
        emit Rewarded(domain, value);
    }

    function result(string[] memory domains) public onlyOwner {
        for (uint256 i = 0; i < domains.length; i++) {
            string memory domain = domains[i];
            uint256 position = domains.length - i;

            if (position <= chargeNumber) {
                bool isDouble = _history[domain] > 0 &&
                    _history[domain] <= position;
                uint256 value = isDouble
                    ? chargeValue[position - 1] * 2
                    : chargeValue[position - 1];
                charge(domain, value);
            }

            _history[domain] = position;
        }
    }

    function bet(string[] memory domains) public onlyOwner {
        require(domains.length > 1, "Bet list must be more than 1 member");
        for (uint256 i = 0; i < domains.length; i++) {
            string memory domain = domains[i];
            charge(domain, betValue);
        }

        uint256 rewardValue = (betValue * domains.length * (100 - betFee)) /
            100;
        reward(domains[0], rewardValue);
    }

    function random(string[] memory domains)
        public
        view
        returns (string memory)
    {
        uint256 value = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    domains.length
                )
            )
        );
        return domains[value % domains.length];
    }

    function widthdrawToDomain(string memory domain, uint256 value)
        public
        payable
        enoughBalance(domain, value)
    {
        address wallet = msg.sender;
        require(_owners[domain] == wallet, "Invalid withdraw wallet address");

        unchecked {
            _balances[domain] -= value;
        }
        address payable walletPayable = payable(wallet);
        uint256 fee = (value * chargeFee) / 100;
        availableBalances += fee;
        walletPayable.transfer(value - fee);
        emit Withdrawed(domain, value, fee);
    }

    function withdrawFromAvailable(address account, uint256 value)
        public
        payable
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