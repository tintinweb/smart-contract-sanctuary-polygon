// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "Counters.sol";
import "Ownable.sol";

contract PostThread is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private msaIds;
    Counters.Counter public schemaIds;

    mapping(address => uint) public addressToMsaId;
    mapping(address => uint[]) public addressToDelegatedMsaIds;

    event MsaRegistered(address sender, uint msaId);
    event Signatures(address givenSig, address expectedSig, bytes32 message);

    struct Message {
        uint onBehalfOf;
        uint schemaId;
        string payload;
        uint timestamp;
    }

    mapping(uint => Message[]) public schemaIdToMessages;
    mapping(uint => string) public idToSchema;

    // SIGNATURE
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    
    function isValidUser(uint256 _number, bytes memory sig, address userAddress) public returns(bool){
        bytes32 message = prefixed(keccak256(abi.encodePacked(_number)));
        address recoveredAddress = recoverSigner(message, sig);
        emit Signatures(userAddress, recoveredAddress, message);
        return (recoveredAddress == userAddress);
    }

    function recoverSigner(bytes32 message, bytes memory sig) public pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    // MSA 
    function createMsaId(address userAddress) public returns (uint) {
        require(addressToMsaId[userAddress] == 0, "User already has msaId");
        msaIds.increment();
        addressToMsaId[userAddress] = msaIds.current();
        emit MsaRegistered(userAddress, addressToMsaId[userAddress]);
        return addressToMsaId[userAddress];
    }

    function getMsaId(address userAddress) public view returns (uint) {
        require(addressToMsaId[userAddress] != 0, "User does not have msaId");
        return addressToMsaId[userAddress];
    }

    function delegateMsaId(address delegatorAddress, address providerAddress) internal {
        require(delegatorAddress != providerAddress, "User cannot delegate to self");
        uint providerMsaId = addressToMsaId[providerAddress];
        uint delegatorMsaId = addressToMsaId[delegatorAddress];
        require(providerMsaId != 0, "Provider does not have msaId");
        require(delegatorMsaId != 0, "Delegator does not have msaId");

        uint[] memory delegatedMsaIds = addressToDelegatedMsaIds[providerAddress];
        for (uint i = 0; i < delegatedMsaIds.length; i++) {
            require(delegatedMsaIds[i] != delegatorMsaId, "msaId already delegated to provider");
        }

        addressToDelegatedMsaIds[providerAddress].push(delegatorMsaId);
    }

    function getDelegatedMsaId(address providerAddress) public view returns (uint[] memory) {
        return addressToDelegatedMsaIds[providerAddress];
    }

    function createSponsoredAccountsWithDelegation(address[] memory delegatorAddresses, bytes[] memory sigs) public returns (uint[] memory) {
        address providerAddress = msg.sender;
        uint providerMsaId = addressToMsaId[providerAddress];
        require(providerMsaId != 0, "Provider does not have msaId");
        
        uint[] memory delegatorMsaIds = new uint[](delegatorAddresses.length);
        for (uint i = 0; i < delegatorAddresses.length; i++) {
            delegatorMsaIds[i] = createMsaId(delegatorAddresses[i]);
            require(isValidUser(providerMsaId, sigs[i], delegatorAddresses[i]), "Invalid signature");
            delegateMsaId(delegatorAddresses[i], providerAddress);
        }

        return delegatorMsaIds;
    }

    function addProviderToMsa(address providerAddress, bytes memory sig) public returns (bool) {
        uint providerMsaId = addressToMsaId[providerAddress];
        require(providerMsaId != 0, "Provider does not have msaId");
        
        uint delegatorMsaId = addressToMsaId[msg.sender];
        require(isValidUser(providerMsaId, sig, providerAddress), "Invalid signature");
        delegateMsaId(msg.sender, providerAddress);

        return true;
    }

    function revokeMsaDelegationByDelegator(address providerAddress) public returns (bool) {
        uint providerMsaId = addressToMsaId[providerAddress];
        require(providerMsaId != 0, "Provider does not have msaId");
        uint delegatorMsaId = addressToMsaId[msg.sender];
        require(delegatorMsaId != 0, "Delegator does not have msaId");

        uint[] memory delegatedMsaIds = addressToDelegatedMsaIds[providerAddress];
        for (uint i = 0; i < delegatedMsaIds.length; i++) {
            if(delegatedMsaIds[i] == delegatorMsaId) {
                addressToDelegatedMsaIds[providerAddress][i] = addressToDelegatedMsaIds[providerAddress][delegatedMsaIds.length - 1];
                addressToDelegatedMsaIds[providerAddress].pop();
                return true;
            }
        }
        require(false, "Delegator is not delegated to provider");
        return false;
    }

    function revokeMsaDelegationByProvider(address delegatorAddress) public returns (bool) {
        address providerAddress = msg.sender;
        uint providerMsaId = addressToMsaId[providerAddress];
        require(providerMsaId != 0, "Provider does not have msaId");
        uint delegatorMsaId = addressToMsaId[delegatorAddress];
        require(delegatorMsaId != 0, "Delegator does not have msaId");

        uint[] memory delegatedMsaIds = addressToDelegatedMsaIds[providerAddress];
        for (uint i = 0; i < delegatedMsaIds.length; i++) {
            if(delegatedMsaIds[i] == delegatorMsaId) {
                addressToDelegatedMsaIds[providerAddress][i] = addressToDelegatedMsaIds[providerAddress][delegatedMsaIds.length - 1];
                addressToDelegatedMsaIds[providerAddress].pop();
                return true;
            }
        }
        require(false, "Delegator is not delegated to provider");
        return false;
    }

    // Schema
    function registerSchema(string memory schema) public returns (uint) {
        schemaIds.increment();
        uint schemaId = schemaIds.current();
        idToSchema[schemaId] = schema;
        return schemaId;
    }

    function getSchema(uint schemaId) public view returns (string memory) {
        return idToSchema[schemaId];
    }

    function getSchemaCount() public view returns (uint) {
        return schemaIds.current();
    }

    // Message
    function addMessagesByProvider(uint[] memory onBehalfOfs, uint schemaId, string[] memory payloads) public returns (bool) {
        require(bytes(idToSchema[schemaId]).length != 0, "Schema does not exist");
        uint providerMsaId = addressToMsaId[msg.sender];
        require(providerMsaId != 0, "Provider does not have msaId");
        uint[] memory delegatedMsaIds = addressToDelegatedMsaIds[msg.sender];
        require(delegatedMsaIds.length != 0, "Provider is not delegated any msaIds");

        uint lastBehalfOf = 0;
        for (uint i = 0; i < payloads.length; i++) {
            bool isDelegated = false;
            if (onBehalfOfs[i] == lastBehalfOf) {
                isDelegated = true;
            } 
            uint j = 0;
            while (j < delegatedMsaIds.length && !isDelegated) {
                if(onBehalfOfs[j] == delegatedMsaIds[j]) {
                    isDelegated = true;
                }
                j++;
            }
            require(isDelegated, "Delegator is not delegated to provider");

            schemaIdToMessages[schemaId].push(Message(
                onBehalfOfs[i], schemaId, payloads[i], block.timestamp
            ));
        }
        return true;
    }

    function addMessagesByUser(uint schemaId, string[] memory payloads) public returns (bool) {
        require(bytes(idToSchema[schemaId]).length != 0, "Schema does not exist");
        uint msaId = addressToMsaId[msg.sender];
        require(msaId != 0, "User does not have msaId");

        for (uint i = 0; i < payloads.length; i++) {
            schemaIdToMessages[schemaId].push(Message(
                msaId, schemaId, payloads[i], block.timestamp
            ));
        }
        return true;
    }
    
    function addMessagesByOwner(uint[] memory onBehalfOfs, uint schemaId, string[] memory payloads) public onlyOwner returns (bool) {
        require(bytes(idToSchema[schemaId]).length != 0, "Schema does not exist");

        for (uint i = 0; i < payloads.length; i++) {
            schemaIdToMessages[schemaId].push(Message(
                onBehalfOfs[i], schemaId, payloads[i], block.timestamp
            ));
        }
        return true;
    }

    function getNumberOfMessages(uint schemaId) public view returns (uint) {
        return schemaIdToMessages[schemaId].length;
    }

    function getMessages(uint schemaId, uint offset) public view returns (Message[100] memory) {
        require(bytes(idToSchema[schemaId]).length != 0, "Schema does not exist");
        Message[100] memory messages;
        uint l = schemaIdToMessages[schemaId].length;
        uint upperBound;
        if (100 * offset > l) {
            return messages;
        } else if (100 * (offset + 1) > l) {
            upperBound = l - 100 * offset;
        } else {
            upperBound = 100;
        }

        for (uint i = 0; i < upperBound; i++) {
            messages[i] = schemaIdToMessages[schemaId][100 * offset + i];
        }
        return messages;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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