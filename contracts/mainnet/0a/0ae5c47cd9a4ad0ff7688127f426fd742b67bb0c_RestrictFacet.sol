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
pragma solidity ^0.8.19;

import "../libraries/LibAppStorage.sol";

contract RestrictFacet {
    function getUserExecutionCount(
        address _walletAddress,
        string calldata _functionName
    ) external view returns (uint256) {
        return LibAppStorage.getUserExecutionCount(_walletAddress, _functionName);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./LibERC2771Context.sol";

struct AppStorage {
    string cardName;
    string cardSymbol;
    string cardImageCID;
    string cardAnimationCID;
    // Mapping from card id to card info
    mapping(uint256 => MetadataStruct) cardMetadata;
    // Mapping from card id to user address
    mapping(uint256 => address[]) cardUsers;
    // Mapping from project id to card ids
    mapping(uint256 => uint256[]) projectCardIds;
    // Mapping from wallet address to last created card id
    mapping(address => uint256) userLatestCardId;
    // Mapping from user address to card ids
    mapping(address => uint256[]) userCardsIds;
    mapping(address => mapping(uint256 => MintDetailStruct)) mintDetails;
    // Mapping from project id to project info
    mapping(uint256 => ProjectStruct) projects;
    // Mapping from project name to project id
    mapping(string => uint256) projectMapping;
    // Mapping from user address to project ids
    mapping(address => uint256[]) userProjects;
    mapping(address => mapping(uint256 => ExistStruct)) userProjectExists;
    // Mapping from project id to user address
    mapping(uint256 => address[]) projectUsers;
    mapping(uint256 => mapping(address => ExistStruct)) projectUserExists;
    // Mapping from project id to user admin
    mapping(uint256 => mapping(address => uint256)) operatorAdmins;
    // Mapping from user address to method execution count
    mapping(address => mapping(string => uint256)) userExecutionCount;
}

struct MetadataStruct {
    uint256 cardId;
    uint256 projectId;
    uint256 createdAt;
    string name;
    string imageCID;
    string description;
    string role;
    string category;
    string twitter;
    string opensea;
    string discord;
    address createdBy;
}

struct ProjectStruct {
    uint256 id;
    string name;
    string imageCID;
    string description;
    address createdBy;
    string displayName;
    string website;
    string twitter;
    string discord;
}

struct MintDetailStruct {
    uint256 isMinted;
    uint256 index; // NOTE: Start at one.
    uint256 mintedAt;
    address mintedBy;
}

struct ExistStruct {
    uint256 isExisted;
    uint256 index; // NOTE: Start at one.
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }

    function getUserExecutionCount(address _user, string calldata _functionName) internal view returns (uint256) {
        return appStorage().userExecutionCount[_user][_functionName];
    }
}

contract Modifiers {
    modifier onlyTrustedForwarder() {
        require(LibERC2771Context.isTrustedForwarder(msg.sender), "ERC2771Context: caller is not a trusted forwarder");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LibContext {
    function msgSender() internal view returns (address) {
        return msg.sender;
    }

    function msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./LibContext.sol";

library LibERC2771Context {
    bytes32 constant CONTEXT_STORAGE_POSITION = keccak256("diamond.standard.context.storage");

    struct ContextStorage {
        mapping(address => uint256) trustedForwarders;
    }

    function contextStorage() internal pure returns (ContextStorage storage cs) {
        bytes32 position = CONTEXT_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

    function updateTrustedForwarder(address _trustedForwarder, bool _isTrusted) internal {
        ContextStorage storage cs = contextStorage();
        cs.trustedForwarders[_trustedForwarder] = _isTrusted ? 1 : 2;
    }

    function isTrustedForwarder(address _forwarder) internal view returns (bool) {
        return contextStorage().trustedForwarders[_forwarder] == 1;
    }

    function msgSender() internal view returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return LibContext.msgSender();
        }
    }

    function msgData() internal view returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return LibContext.msgData();
        }
    }
}