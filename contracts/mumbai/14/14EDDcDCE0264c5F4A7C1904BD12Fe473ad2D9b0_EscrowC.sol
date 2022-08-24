// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// imports
import "Strings.sol";
import "Ownable.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⠀⣶⣤⣤⣄⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⡀⢻⣿⣿⣿⣿⣿⣿⣷⣦⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣇⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⣀⠀⠀⠀⠀
// ⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠷⠆⠀⠀
// ⠀⠀⠀⣼⣿⣿⡿⠟⠛⠉⣉⣀⠘⣿⣿⣿⡿⠿⠿⠟⠛⠛⠉⣉⣀⣤⣤⣶⠂⠀
// ⠀⠀⣼⠟⠉⣀⣤⣶⣿⣿⣿⣿⣦⣤⣤⣤⡀⢠⣶⣶⣾⣿⣿⣿⣿⣿⣿⠃⠀⠀
// ⠀⠀⢠⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠈⢿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀
// ⠀⠀⠀⠈⠙⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⠸⣿⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠉⠛⠻⢿⣿⣿⣿⣿⣿⣿⣿⠀⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠛⠿⠿⣿⣿⡇⢻⠿⠋⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

contract EscrowC is Ownable {
    // escrow contract, sends ether to a beneficiary address.
    // beta version of the decentralized escrow contract.
    // This is still centralized (relies on Oracle). Decentralized is possible,
    // but need to figure out a few kinks with gas costs and frontrunning.

    struct transaction {
        address sender;
        string recipient; // email
        uint256 amount; // amount to send
    }
    transaction[] public transactions; // array of transactions
    mapping(string => address) emails; // mapping of email to address

    // events
    event Deposit(
        address indexed sender,
        string indexed recipient,
        uint256 amount,
        uint256 index
    );
    event Withdraw(address indexed recipient, uint256 amount);

    // constructor
    constructor() {}

    // deposit ether to escrow.
    function deposit(string calldata _recipient) external payable returns (uint256) {
        require(msg.value > 0, "deposit must be greater than 0");

        // if recipient email address already has a crypto address, send directly
        if (emails[_recipient] != address(0)) {
            // transfer ether directly to recipient
            payable(emails[_recipient]).transfer(msg.value);

            // push & delete transaction to array
            transactions.push(transaction(msg.sender, _recipient, msg.value));
            delete transactions[transactions.length - 1];

            emit Deposit(msg.sender, _recipient, msg.value, transactions.length - 1);
            return transactions.length - 1;
        } else {
            // store new transaction
            transaction memory newTransaction;
            newTransaction.recipient = _recipient;
            newTransaction.amount = msg.value;
            newTransaction.sender = msg.sender;
            transactions.push(newTransaction);
            emit Deposit(msg.sender, _recipient, msg.value, transactions.length - 1);
            // return id of new transaction
            return transactions.length - 1;
        }
    }

    // sender can withdraw deposited ether from a transaction
    function withdrawSender(uint256 _index) external {
        require(_index < transactions.length, "index out of bounds");
        require(
            transactions[_index].sender == msg.sender,
            "only sender can withdraw"
        );

        // transfer ether back to sender
        payable(msg.sender).transfer(transactions[_index].amount);
        emit Withdraw(transactions[_index].sender, transactions[_index].amount);

        // remove transaction from array
        delete transactions[_index];
    }

    // centralized transfer function to transfer ether to recipients newly created wallet
    function withdrawOwner(uint256 _index, address _recipient)
        external
        onlyOwner
    {
        require(_index < transactions.length, "index out of bounds");

        // transfer ether to recipient
        payable(_recipient).transfer(transactions[_index].amount);
        emit Withdraw(_recipient, transactions[_index].amount);

        // remove transaction from array
        delete transactions[_index];
    }

    //// Some utility functions ////

    function getAddress(string calldata _email)
        external
        view
        returns (address)
    {
        return emails[_email];
    }

    function getTransaction(uint256 _index)
        external
        view
        returns (transaction memory)
    {
        return transactions[_index];
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function getTransactionCountSent(address _sender)
        external
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].sender == _sender) {
                count++;
            }
        }
        return count;
    }

    function compareStrings(string memory _a, string memory _b)
        public
        view
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function getTransactionCountReceived(string memory _email)
        external
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (compareStrings(transactions[i].recipient, _email)) {
                count++;
            }
        }
        return count;
    }

    // and that's all!
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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