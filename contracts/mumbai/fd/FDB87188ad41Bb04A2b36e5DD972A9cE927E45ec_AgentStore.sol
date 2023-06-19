// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Queue.sol";
import "./Agent.sol";
import "./constants.sol";

contract AgentStore is Ownable {
    using AgentMethods for Agent;
    using QueueMethods for Queue;

    Agent[COUNT] private agents;
    Queue private expirationQueue;

    constructor() {
        expirationQueue.initialize();
    }

    function begin(uint256 _tokenId, File calldata _file) public {
        uint _expiration = block.timestamp + COVENANT_DURATION;
        agents[_tokenId].begin(Covenant(_file, _expiration));
        afterBegin(_tokenId);
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

struct Agent {
    Counters.Counter version;
    Covenant covenant;
}

library AgentMethods {
    using Counters for Counters.Counter;

    function isCovenantLegallyEnded(Agent storage self) internal view returns (bool) {
        return block.timestamp >= self.covenant.expiration;
    }

    function isCovenantAdministrativelyEnded(Agent storage self) internal view returns (bool) {
        return self.covenant.expiration == 0;
    }

    function isCustomerInvoking(Agent storage self) internal view returns (bool) {
        return msg.sender == self.covenant.file.customer;
    }

    function versionNumber(Agent storage self) internal view returns (uint256) {
        return self.version.current();
    }

    function fileNumber(Agent storage self) internal view returns (uint) {
        return self.covenant.file.fileNumber;
    }

    function customer(Agent storage self) internal view returns (address) {
        return self.covenant.file.customer;
    }

    function expiration(Agent storage self) internal view returns (uint) {
        return self.covenant.expiration;
    }

    function dump(Agent storage self) internal view returns (AgentDump memory) {
        return AgentDump(isCovenantAdministrativelyEnded(self), self.version.current(), self.covenant);
    }

    function _begin(Agent storage self, Covenant memory _covenant) internal {
        // In caller functions check for isCovenantAdministrativelyEnded()
        // double-invocation breaks store logic
        self.version.increment();
        self.covenant = _covenant;
    }

    function begin(Agent storage self, Covenant memory _covenant) internal {
        require(isCovenantAdministrativelyEnded(self), "Contract not ended yet");
        _begin(self, _covenant);
    }

    function safeBegin(Agent storage self, Covenant memory _covenant) internal {
        require(_covenant.expiration > block.timestamp, "Contract expiration is set to a past date");
        if (!isCovenantAdministrativelyEnded(self)) {
            endExpired(self);
        }

        _begin(self, _covenant);
    }

    function _end(Agent storage self) internal {
        // double-invocation breaks store logic
        require(!isCovenantAdministrativelyEnded(self), "Contract is already over");
        self.covenant.expiration = 0;
    }

    function end(Agent storage self) internal {
        if (isCovenantLegallyEnded(self)) {
            endExpired(self);
        } else {
            endMy(self);
        }
    }

    function endExpired(Agent storage self) internal {
        require(isCovenantLegallyEnded(self), "Contract not expired yet");
        _end(self);
    }

    function endMy(Agent storage self) internal {
        require(isCustomerInvoking(self), "Only current tenant can end the contract this way");
        _end(self);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./constants.sol";

// For a full-fledged DLL see "@hq20/contracts/contracts/lists/DoubleLinkedList.sol"
// todo https://medium.com/%40hayeah/diving-into-the-ethereum-vm-the-hidden-costs-of-arrays-28e119f04a9b, not much impact though

struct Queue {
    uint256[COUNT + 1] prev;
    uint256[COUNT + 1] next;
}

library QueueMethods {
    function initialize(Queue storage queue) internal {
        queue.prev[COUNT] = COUNT;
        queue.next[COUNT] = COUNT;
    }

    function dump(Queue storage queue) internal view returns (uint256[] memory) {
        // generated with ChatGPT, don't use...
        // https://chat.openai.com/share/d1cb9bcd-2f54-40f1-943d-7fc2736caffd
        
        uint256[] memory result = new uint256[](COUNT + 1);
        uint256 index = 0;
        for (uint256 i = queue.next[COUNT]; i != COUNT; i = queue.next[i]) {
            result[index++] = i;
        }
        
        uint256[] memory newArray = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            newArray[i] = result[i];
        }
        
        return newArray;
    }

    function empty(Queue storage queue) internal view returns (bool) {
        return head(queue) == COUNT;
    }

    function head(Queue storage queue) internal view returns (uint256) {
        return queue.next[COUNT];
    }

    function tail(Queue storage queue) internal view returns (uint256) {
        return queue.prev[COUNT];
    }

    function unlink(Queue storage queue, uint256 i) internal {
        queue.prev[queue.next[i]] = queue.prev[i];
        queue.next[queue.prev[i]] = queue.next[i];
    }

    function shift(Queue storage queue) internal returns (uint256) {
        uint256 _head = head(queue);
        unlink(queue, _head);
        return _head;
    }

    function insertBefore(Queue storage queue, uint256 _next, uint256 new_i) internal {
        uint256 _prev = queue.prev[_next];
        queue.next[new_i] = _next;
        queue.prev[new_i] = _prev;
        queue.next[_prev] = new_i;
        queue.prev[_next] = new_i;
    }

    function push(Queue storage queue, uint256 i) internal {
        insertBefore(queue, COUNT, i);
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