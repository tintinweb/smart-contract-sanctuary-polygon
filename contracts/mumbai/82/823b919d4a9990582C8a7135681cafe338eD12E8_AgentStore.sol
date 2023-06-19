// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Queue.sol";
import "./Agent.sol";
import "./constants.sol";

contract AgentStore is Ownable {
    Agent[COUNT] private agents;
    Queue private expirationQueue;

    function begin(uint256 _tokenId, File calldata _file) public {
        uint _expiration = block.timestamp + COVENANT_DURATION;
        agents[_tokenId].begin(Covenant(_file, _expiration));
        //afterBegin(_tokenId);
    }

    function end(uint256 _tokenId) public {
        agents[_tokenId].end();
        afterEnd(_tokenId);
    }

    function endMy(uint256 _tokenId) public {
        agents[_tokenId].endMy();
        afterEnd(_tokenId);
    }

    function endExpired(uint256 _tokenId) public {
        agents[_tokenId].endExpired();
        afterEnd(_tokenId);
    }

    function afterEnd(uint256 _tokenId) internal {
        expirationQueue.unlink(_tokenId);
    }

    function afterBegin(uint256 _tokenId) internal {
        expirationQueue.push(_tokenId);
    }

    function isCovenantLegallyEnded(uint256 _tokenId) external view returns (bool) {
        return agents[_tokenId].isCovenantLegallyEnded();
    }

    function isCovenantAdministrativelyEnded(uint256 _tokenId) external view returns (bool) {
        return agents[_tokenId].isCovenantAdministrativelyEnded();
    }

    function isCustomerInvoking(uint256 _tokenId) external view returns (bool) {
        return agents[_tokenId].isCustomerInvoking();
    }

    function versionNumber(uint256 _tokenId) external view returns (uint256) {
        return agents[_tokenId].versionNumber();
    }

    function fileNumber(uint256 _tokenId) external view returns (uint) {
        return agents[_tokenId].fileNumber();
    }

    function customer(uint256 _tokenId) external view returns (address) {
        return agents[_tokenId].customer();
    }

    function expiration(uint256 _tokenId) external view returns (uint) {
        return agents[_tokenId].expiration();
    }

    function dump() external view returns (AgentDump[COUNT] memory) {
        AgentDump[COUNT] memory result;
        for (uint256 i = 0; i < COUNT; i++) {
            result[i] = agents[i].dump();
        }
        return result;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

uint256 constant COUNT = 1000;

// Covenants expire after one year. Source: https://qr.ae/pyPsqx
uint constant COVENANT_DURATION = 31556952;

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./constants.sol";

struct File {
    uint fileNumber;
    address customer;
}

struct Covenant {
    File file;
    uint expiration;
}

struct AgentDump {
    bool isCovenantAdministrativelyEnded;
    uint256 version;
    Covenant covenant;
}

contract Agent {
    using Counters for Counters.Counter;

    function createFile(uint _fileNumber, address _customer) public pure returns (File memory) {
        return File(_fileNumber, _customer);
    }

    function createCovenant(File memory _file, uint _expiration) public pure returns (Covenant memory) {
        return Covenant(_file, _expiration);
    }

    Counters.Counter private version;
    Covenant internal covenant;

    function isCovenantLegallyEnded() public view returns (bool) {
        return block.timestamp >= covenant.expiration;
    }

    function isCovenantAdministrativelyEnded() public view returns (bool) {
        return covenant.expiration == 0;
    }

    function isCustomerInvoking() public view returns (bool) {
        return msg.sender == covenant.file.customer;
    }

    function versionNumber() external view returns (uint256) {
        return version.current();
    }

    function fileNumber() external view returns (uint) {
        return covenant.file.fileNumber;
    }

    function customer() external view returns (address) {
        return covenant.file.customer;
    }

    function expiration() external view returns (uint) {
        return covenant.expiration;
    }

    function dump() external view returns (AgentDump memory) {
        return AgentDump(isCovenantAdministrativelyEnded(), version.current(), covenant);
    }

    function _begin(Covenant calldata _covenant) internal {
        // In caller functions check for isCovenantAdministrativelyEnded()
        // double-invocation breaks store logic
        version.increment();
        covenant = _covenant;
    }

    function begin(Covenant calldata _covenant) public {
        require(isCovenantAdministrativelyEnded(), "Contract not ended yet");
        _begin(_covenant);
    }

    function safeBegin(Covenant calldata _covenant) public {
        require(_covenant.expiration > block.timestamp, "Contract expiration is set to a past date");
        if (!isCovenantAdministrativelyEnded()) {
            endExpired();
        }

        _begin(_covenant);
    }

    function _end() internal {
        // double-invocation breaks store logic
        require(!isCovenantAdministrativelyEnded(), "Contract is already over");
        covenant.expiration = 0;
    }

    function end() public {
        if (isCovenantLegallyEnded()) {
            endExpired();
        } else {
            endMy();
        }
    }

    function endExpired() public {
        require(isCovenantLegallyEnded(), "Contract not expired yet");
        _end();
    }

    function endMy() public {
        require(isCustomerInvoking(), "Only current tenant can end the contract this way");
        _end();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./constants.sol";

// For a full-fledged DLL see "@hq20/contracts/contracts/lists/DoubleLinkedList.sol"
// todo https://medium.com/%40hayeah/diving-into-the-ethereum-vm-the-hidden-costs-of-arrays-28e119f04a9b, not much impact though
// todo convert to library after https://github.com/ethereum/solidity/issues/13776
contract Queue {
    uint256[COUNT + 1] private prev;
    uint256[COUNT + 1] private next;

    constructor() {
        prev[COUNT] = COUNT;
        next[COUNT] = COUNT;
    }

    function dump() external view returns (uint256[] memory) {
        // generated with ChatGPT, don't use...
        // https://chat.openai.com/share/d1cb9bcd-2f54-40f1-943d-7fc2736caffd
        
        uint256[] memory result = new uint256[](COUNT + 1);
        uint256 index = 0;
        for (uint256 i = next[COUNT]; i != COUNT; i = next[i]) {
            result[index++] = i;
        }
        
        uint256[] memory newArray = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            newArray[i] = result[i];
        }
        
        return newArray;
    }

    function empty() external view returns (bool) {
        return head() == COUNT;
    }

    function head() public view returns (uint256) {
        return next[COUNT];
    }

    function tail() internal view returns (uint256) {
        return prev[COUNT];
    }

    function unlink(uint256 i) public {
        prev[next[i]] = prev[i];
        next[prev[i]] = next[i];
    }

    function shift() public returns (uint256) {
        uint256 _head = head();
        unlink(_head);
        return _head;
    }

    function insertBefore(uint256 _next, uint256 new_i) internal {
        uint256 _prev = prev[_next];
        next[new_i] = _next;
        prev[new_i] = _prev;
        next[_prev] = new_i;
        prev[_next] = new_i;
    }

    function push(uint256 i) public {
        insertBefore(COUNT, i);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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