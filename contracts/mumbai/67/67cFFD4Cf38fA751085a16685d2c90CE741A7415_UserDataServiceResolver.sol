// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


/**
 * @title UDS User Data Service based partly on ENS contracts (especially for resolvers)
 */
contract UDS  {
  
    address public _owner; // uds owner
    uint256 public chainId;
    mapping(bytes32 => address) private _resolvers;

    mapping(bytes32 => address) public owner; // profile data owner
    constructor() {
        _owner = msg.sender;
    }

    function _chainId() internal {
        chainId = block.chainid;
    }

    function isPolygon() internal view returns(bool) {
        return chainId == 137 || chainId == 80001;
    }

    function isMainnet() internal view returns(bool) {
        return chainId == 1 || chainId == 5;
    }

    function setResolver(bytes32 rootNode, address resolver) external {
        _resolvers[rootNode] = resolver;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../../resolvers/AllResolvers.sol";
import "./UDS.sol";

contract UserDataServiceResolver is AllResolvers {
    UDS uds;

        /**
     * A mapping of authorisations. An address that is authorised for a profile name
     * may make any changes to the name that the owner could, but may not update
     * the set of authorisations.
     * (node, owner, caller) => isAuthorised
     */
    mapping(bytes32=>mapping(address=>mapping(address=>bool))) public authorisations;
    event AuthorisationChanged(bytes32 indexed profileId, address indexed owner, address indexed target, bool isAuthorised);

    constructor(address _uds) {
        uds = UDS(_uds);
    }

     function setAuthorisation(bytes32 profileId, address target, bool isAuthorised) external {
        authorisations[profileId][msg.sender][target] = isAuthorised;
        emit AuthorisationChanged(profileId, msg.sender, target, isAuthorised);
    }

    function isAuthorised(bytes32 profileId) internal  view returns(bool) {
        address owner = uds.owner(profileId);
        return owner == msg.sender || authorisations[profileId][owner][msg.sender];
    }


    function multicall(bytes[] calldata data) external returns(bytes[] memory results) {
        results = new bytes[](data.length);
        for(uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success);
            results[i] = result;
        }
        return results;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IdentResolver.sol";
import "./NameResolver.sol";
import "./ProfileResolver.sol";
import "./MetaDataResolver.sol";

abstract contract AllResolvers is IdentResolver, NameResolver, ProfileResolver, MetaDataResolver {
  function supportsInterface(bytes4 interfaceID) virtual override(IdentResolver, MetaDataResolver, NameResolver, ProfileResolver) public pure returns(bool) {
        return super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../utils/BytesUtils.sol";


abstract contract BaseResolver is ERC165, BytesUtils {

bytes4 private constant INTERFACE_META_ID = 0x01ffc9a7;

    function supportsInterface(bytes4 interfaceID) virtual public override pure returns(bool) {
        return interfaceID == INTERFACE_META_ID;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./BaseResolver.sol";

abstract contract IdentResolver is BaseResolver {
   
   bytes4 constant private IDENT_INTERFACE_ID = 0x0e2f9f10;

   mapping(uint256 => string) private _idents; // external user identifier for ie database
   
    function ident(uint256 tokenId) external view returns (string memory) {
        return _idents[tokenId];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == IDENT_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./BaseResolver.sol";

abstract contract MetaDataResolver is BaseResolver {

   bytes4 constant private METADATA_INTERFACE_ID = 0xe3684e39;
   bytes4 constant private METAVALUE_INTERFACE_ID = 0x4dc34682;
   bytes4 constant private SETMETA_INTERFACE_ID = 0x08730f07;


   mapping(uint256 => bytes32) private _metadataIds;
   mapping(bytes32 => bool) private _idExists;
   mapping(bytes32 => mapping(string => bool)) private _keysAvailable;
   mapping(string => bytes32) private _keyNames;
   mapping(string => bool) private _keyExists;
   mapping(bytes32 => mapping(bytes32 => bytes)) private _keyValMetas;
   mapping(uint256 => address) private _metaOwners;
   
    enum DataTypes {
        PROFILE_STRING,
        IMAGE,
        HASH,
        SELECTION,
        URI,
        WALLET,
        NO_RENDER
    }

   struct KeyValMeta {
    bytes32 key;
    DataTypes dType;
    bytes dValue;
    bool editable;
    bool encrypted;
   }

   event MetaDataAdded(uint256 tokenid, bytes32 metaid, bytes32 keyid);


function metadata(uint256 tokenId) external view returns(bytes32) {
    return _metadataIds[tokenId];
}

function getMetaValue(bytes32 keyId, bytes32 id) internal view returns(bytes memory) {
    return _keyValMetas[keyId][id];
}

function metaValue(uint256 tokenId, string memory keyStr) external view returns(KeyValMeta memory kv) {
    bytes32 id = this.metadata(tokenId);
    bytes memory bVals = getMetaValue(metaKey(id, keyStr), id);
    kv = abi.decode(bVals, (KeyValMeta));
}

function metaKey(bytes32 metaId, string memory keyStr) internal view returns(bytes32) {
    if(!isKeyAvailable(metaId, keyStr)) {
        revert("invalid key requested");
    }
    return _keyNames[keyStr];
}

function isKeyAvailable(bytes32 metaId, string memory keyStr) internal view returns(bool) {
    return _keysAvailable[metaId][keyStr] == true;
}

function setMetaData(uint256 tokenId, string memory keyStr, uint _dtype, bytes memory value, bool editable, bool encrypted) external {
    require(msg.sender == _metaOwners[tokenId], "only owner can set metas");
    bytes32 id = keccak256(abi.encode(tokenId));
    if(_idExists[id] != true) {
        _idExists[id] = true;
        _metadataIds[tokenId] = id;
    }
    if(_keyExists[keyStr] != true) {
        _keyExists[keyStr] = true;
        _keyNames[keyStr] = keccak256(abi.encodePacked(keyStr));
    }
    bytes32 keyId = _keyNames[keyStr];
    KeyValMeta memory kv = KeyValMeta(keyId, DataTypes(_dtype), abi.encode(value), editable, encrypted);
    _keyValMetas[id][keyId] = abi.encode(kv);
    emit MetaDataAdded(tokenId, id, keyId);
}

 function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == METADATA_INTERFACE_ID || interfaceID == METAVALUE_INTERFACE_ID 
        || interfaceID == SETMETA_INTERFACE_ID 
        || super.supportsInterface(interfaceID);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./BaseResolver.sol";

abstract contract NameResolver is BaseResolver {
   
   bytes4 constant private NAME_INTERFACE_ID = 0x00ad800c;

   mapping(uint256 => string) private _names; // external user identifier
   
    function name(uint256 tokenId) external view returns (string memory) {
        return _names[tokenId];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == NAME_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./BaseResolver.sol";

abstract contract ProfileResolver is BaseResolver {

   bytes4 constant private PROFILE_INTERFACE_ID = 0x72cd2b1a;

   mapping(uint256 => bytes32) private _profiles;

    function profile(uint256 tokenId) public view returns(bytes32) {
        return _profiles[tokenId];
    }

     function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == PROFILE_INTERFACE_ID || super.supportsInterface(interfaceID);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract BytesUtils {
     function bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}