// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev This is the contract to import/extends if you want to ease your NFT collection management of its data
 */
contract TokenDataHandler is AccessControlEnumerable {
    using Strings for uint256;

    /** Role definition necessary to be able to view token data */
    bytes32 public constant DATA_VIEWER_ROLE = keccak256("DATA_VIEWER_ROLE");
    /** Role definition necessary to be able to manage token data */
    bytes32 public constant DATA_ADMIN_ROLE = keccak256("DATA_ADMIN_ROLE");

    /** @dev URI to be used as base whenever data and policy requires it */
    string private _baseURI;
    /** @dev Optional mapping for token specific URIs */
    mapping(uint256 => string) private _tokenURIs;
    /** @dev Enumerable set used to reference every token ID with specific URI defined */
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet private _tokenIDs;
    /** @dev Is optional token specific URI absolute or not (ie if absolute, base URI will not apply if specific URI is provided) */
    bool private _absoluteTokenURI;
    /** @dev Is token URI based on its ID if token specific URI not provided or not absolute  */
    bool private _idBasedTokenURI;

    /**
     * @dev Event emitted whenever policy for token URI is changed
     * 'admin' Address of the administrator that changed policy for token URI
     * 'baseURI' New URI to be used as base whenever data and policy requires it
     * 'absoluteTokenURI' New mapping for token specific URIs
     * 'idBasedTokenURI' New flag for token URI based on its ID or not
     */
    event Policy4TokenURIChanged(address indexed admin, string baseURI, bool absoluteTokenURI, bool idBasedTokenURI);
    /**
     * @dev Event emitted whenever one token URI is changed
     * 'admin' Address of the administrator that changed the token URI
     * 'tokenID' ID of the token for which URI as been changed
     * 'tokenURI' New URI for given token ID (unless hidden is requested to keep it protected)
     */
    event TokenURIChanged(address indexed admin, uint256 indexed tokenID, string tokenURI);

    /**
     * @dev Contract constructor
     * @param baseURI_ defines URI to be used as base whenever data and policy requires it
     * @param absoluteTokenURI_ defines if optional token specific URI is absolute or not (ie if absolute, base URI will
     * not apply if specific URI is provided)
     * @param idBasedTokenURI_ defines if token URI is based on its ID if token specific URI is not provided or not absolute
     */
    constructor(string memory baseURI_, bool absoluteTokenURI_, bool idBasedTokenURI_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setPolicy4TokenURI(baseURI_, absoluteTokenURI_, idBasedTokenURI_);
    }

    /**
     * @dev Get applicable token URI policy, ie a tuple (baseURI, absoluteTokenURI, idBasedTokenURI) where
     * `baseURI` is used whenever data and policy requires it
     * `absoluteTokenURI` defines if optional token specific URI is absolute or not (ie if absolute, base URI will not apply
     * if specific URI is provided)
     * `idBasedTokenURI` defines if token URI is based on its ID if token specific URI is not provided or not absolute
     */
    function getPolicy4TokenURI() external view returns (string memory baseURI, bool absoluteTokenURI, bool idBasedTokenURI) {
        // As DATA_VIEWER_ROLE OR DATA_ADMIN_ROLE are allowed, cannot use onlyRole
        checkDataViewer();
        return (_baseURI, _absoluteTokenURI, _idBasedTokenURI);
    }
    /**
     * @dev Set applicable token URI policy
     * @param baseURI_ defines URI to be used as base whenever data and policy requires it
     * @param absoluteTokenURI_ defines if optional token specific URI is absolute or not (ie if absolute, base URI will
     * not apply if specific URI is provided)
     * @param idBasedTokenURI_ defines if token URI is based on its ID if token specific URI is not provided or not absolute
     */
    function setPolicy4TokenURI(string memory baseURI_, bool absoluteTokenURI_, bool idBasedTokenURI_) external onlyRole(DATA_ADMIN_ROLE) {
        _setPolicy4TokenURI(baseURI_, absoluteTokenURI_, idBasedTokenURI_);
    }
    /**
     * @dev Set applicable token URI policy
     * @param baseURI_ defines URI to be used as base whenever data and policy requires it
     * @param absoluteTokenURI_ defines if optional token specific URI is absolute or not (ie if absolute, base URI will
     * not apply if specific URI is provided)
     * @param idBasedTokenURI_ defines if token URI is based on its ID if token specific URI is not provided or not absolute
     */
    function _setPolicy4TokenURI(string memory baseURI_, bool absoluteTokenURI_, bool idBasedTokenURI_) internal {
        _baseURI = baseURI_;
        _absoluteTokenURI = absoluteTokenURI_;
        _idBasedTokenURI = idBasedTokenURI_;
        // Send corresponding event
        emit Policy4TokenURIChanged(msg.sender, baseURI_, absoluteTokenURI_, idBasedTokenURI_);
    }

    /**
     * @dev Get applicable base URI for given token ID. Will apply token URI policy regarding ID based URI for returned
     * value calculation
     * @param tokenID Token ID for which to get applicable base URI
     */
    function _getBaseURI(uint256 tokenID) internal view returns (string memory) {
        // No need to complete base URI with token ID
        if(!_idBasedTokenURI || bytes(_baseURI).length == 0) {
            return _baseURI;
        }
        // Complete base URI with token ID
        return string(abi.encodePacked(_baseURI, tokenID.toString()));
    }
    /**
     * Get applicable full URI for given token ID. Will apply full token URI policy for its calculation ie :
     * - If there is no specific token URI, return default base URI behavior
     * - If specific token URI is set AND (Token URI is absolute OR there is no base URI), return the specific token URI.
     * - Otherwise build the full token URI using base URI, token ID if policy require it AND token specific URI
     * @param tokenID ID of the token for which to get the full URI
     */
    function getFullTokenURI(uint256 tokenID) external virtual view returns (string memory) {
        // As DATA_VIEWER_ROLE OR DATA_ADMIN_ROLE are allowed, cannot use onlyRole
        checkDataViewer();
        return _getFullTokenURI(tokenID);
    }
    /**
     * Get applicable full URI for given token ID. Will apply full token URI policy for its calculation ie :
     * - If there is no specific token URI, return default base URI behavior
     * - If specific token URI is set AND (Token URI is absolute OR there is no base URI), return the specific token URI.
     * - Otherwise build the full token URI using base URI, token ID if policy require it AND token specific URI
     * @param tokenID ID of the token for which to get the full URI
     */
    function _getFullTokenURI(uint256 tokenID) internal virtual view returns (string memory) {
        string memory tokenURI_ = _tokenURIs[tokenID];
        // If there is no specific token URI, return default base URI behavior
        if(bytes(tokenURI_).length == 0) {
            // Apply chosen behavior (Should Token ID be used when building URI or not)
            return _getBaseURI(tokenID);
        }
        // If specific token URI is set, apply chosen behavior
        // 1 - Token URI is absolute OR there is no base URI, return the specific token URI.
        if(_absoluteTokenURI || bytes(_baseURI).length == 0) {
            return tokenURI_;
        }
        // 2 - Token URI is NOT absolute when provided AND there is a base URI, apply chosen behavior (Should Token ID be
        // used when building URI or not)
        return string(abi.encodePacked(_getBaseURI(tokenID), tokenURI_));
    }
    /**
     * Get applicable specific URI for given token ID. Depending on policy, should be computed with base URI and token ID
     * to build the full token URI
     * @param tokenID ID of the token for which to get the specific URI
     */
    function getTokenURI(uint256 tokenID) external virtual view returns (string memory) {
        // As DATA_VIEWER_ROLE OR DATA_ADMIN_ROLE are allowed, cannot use onlyRole
        checkDataViewer();
        return _tokenURIs[tokenID];
    }
    /**
     * Set applicable specific URI for given token ID. Depending on policy, it will have to be computed with base URI and
     * token ID to build the full token URI
     * @param tokenID_ ID of the token for which to set the specific URI
     * @param tokenURI_ New specific URI for given token ID
     * @param hideURIFromEvent Should the URI be hidden from sent event
     */
    function setTokenURI(uint256 tokenID_, string memory tokenURI_, bool hideURIFromEvent) external onlyRole(DATA_ADMIN_ROLE) {
        _setTokenURI(tokenID_, tokenURI_, hideURIFromEvent);
    }
    /**
     * Set applicable specific URI for given token ID. Depending on policy, it will have to be computed with base URI and
     * token ID to build the full token URI
     * @param tokenID_ ID of the token for which to set the specific URI
     * @param tokenURI_ New specific URI for given token ID
     * @param hideURIFromEvent Should the URI be hidden from sent event
     */
    function _setTokenURI(uint256 tokenID_, string memory tokenURI_, bool hideURIFromEvent) internal {
        // No token URI update
        if(keccak256(abi.encodePacked(tokenURI_)) == keccak256(abi.encodePacked(_tokenURIs[tokenID_]))) {
            return;
        }
        // Token should not have any specific URI anymore
        if(bytes(tokenURI_).length == 0) {
            // Remove any previous specific URI reference
            delete _tokenURIs[tokenID_];
            _tokenIDs.remove(tokenID_);
        }
        // Define new specific URI
        else {
            _tokenURIs[tokenID_] = tokenURI_;
            _tokenIDs.add(tokenID_);
            if(hideURIFromEvent) {
                tokenURI_ = "*********";
            }
        }
        // Send corresponding event
        emit TokenURIChanged(msg.sender, tokenID_, tokenURI_);
    }

    /**
     * Get the number of token IDs for which specific URI is defined
     */
    function getTokenIDCount() external view returns (uint256) {
        return _tokenIDs.length();
    }
    /**
     * Get the token ID for which specific URI is defined at given index
     * @param index Index of the token ID for which specific URI is defined
     */
    function getTokenID(uint256 index) external view returns (uint256) {
        return _tokenIDs.at(index);
    }

    /**
     * Will check if message sender can safely be considered as a data viewer or not
     */
    function checkDataViewer() public view {
        // As DATA_VIEWER_ROLE OR DATA_ADMIN_ROLE are allowed, cannot use onlyRole
        require(hasRole(DATA_VIEWER_ROLE, _msgSender()) || hasRole(DATA_ADMIN_ROLE, _msgSender()),
                "TokenDataHandler: No allowed to view data");
    }
}

/**
 * @dev Base token data accessor contract implementer. Will provided internal methods that should give access to comprehensive
 * token data
 */
abstract contract BaseTokenDataImplementer is AccessControlEnumerable {

    /**
     * @dev Contract constructor that will initialize default admin role
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev This method should give access to full token URI for given ID with applyed policy
     * @param tokenID ID of the token for which to get the full URI
     */
    function _getFullTokenURI(uint256 tokenID) internal virtual view returns (string memory);
}
/**
 * @dev Base token data accessor contract external implementer, ie will externalize behavior into another contract (ie a
 * deployed TokenDataHandler), acting as a proxy
 */
abstract contract TokenDataImplementerExternal is BaseTokenDataImplementer {
    /** @dev Address of the contract handling token data & process */
    address private _tokenDataHandlerAddress;

    /**
     * @dev Event emitted whenever token data handler contract address is changed
     * 'admin' Address of the administrator that changed token data handler contract address
     * 'contractAddress' Address of the token data handler contract after it is changed
     */
    event TokenDataHandlerContractAddressChanged(address indexed admin, address indexed contractAddress);

    /**
     * @dev Contract constructor
     * @param tokenDataHandlerAddress_ Address of the contract handling token data & process
     */
    constructor(address tokenDataHandlerAddress_)
    BaseTokenDataImplementer() {
        _setTokenDataHandlerAddress(tokenDataHandlerAddress_);
    }

    /**
     * Getter of the address of the contract handling token data & process
     */
    function getTokenDataHandlerAddress() public view returns(address) {
        return _tokenDataHandlerAddress;
    }
    /**
     * Setter of the address of the contract handling token data & process
     */
    function setTokenDataHandlerAddress(address tokenDataHandlerAddress_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenDataHandlerAddress(tokenDataHandlerAddress_);
    }
    /**
     * Setter of address of the contract handling token data & process
     */
    function _setTokenDataHandlerAddress(address tokenDataHandlerAddress_) internal {
        require(tokenDataHandlerAddress_ != address(0), "TokenDataImplementer: TokenDataHandler contract is not valid");
        // No address change
        if(_tokenDataHandlerAddress == tokenDataHandlerAddress_) {
            return;
        }
        // Check that given address can be treated as a TokenDataHandler smart contract cannot be done as every accessible
        // methods are role protected (and therefore, role cannot be set at contract creation)...
        _tokenDataHandlerAddress = tokenDataHandlerAddress_;
        emit TokenDataHandlerContractAddressChanged(msg.sender, _tokenDataHandlerAddress);
    }
    /**
     * Getter of the contract handling token data & process
     */
    function getTokenDataHandler() internal view returns(TokenDataHandler) {
        return TokenDataHandler(getTokenDataHandlerAddress());
    }

    /**
     * @dev This method give access to full token URI for given ID with applyed policy delegating to contract handling
     * token data & process
     * @param tokenID ID of the token for which to get the full URI
     */
    function _getFullTokenURI(uint256 tokenID) internal override view returns (string memory) {
        return getTokenDataHandler().getFullTokenURI(tokenID);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
/**
 * @dev Base token data accessor contract internal implementer, ie will directly extend TokenDataHandler contract
 */
abstract contract TokenDataImplementerInternal is BaseTokenDataImplementer, TokenDataHandler {

    /**
     * @dev Contract constructor
     * @param baseURI_ defines URI to be used as base whenever data and policy requires it
     * @param absoluteTokenURI_ defines if optional token specific URI is absolute or not (ie if absolute, base URI will
     * not apply if specific URI is provided)
     * @param idBasedTokenURI_ defines if token URI is based on its ID if token specific URI is not provided or not absolute
     */
    constructor(string memory baseURI_, bool absoluteTokenURI_, bool idBasedTokenURI_)
    TokenDataHandler(baseURI_, absoluteTokenURI_, idBasedTokenURI_) {
    }

    /**
     * @dev This method give access to full token URI for given ID with applyed policy by delegating to parent contract
     * @param tokenID ID of the token for which to get the full URI
     */
    function _getFullTokenURI(uint256 tokenID) internal override(BaseTokenDataImplementer, TokenDataHandler) view returns (string memory) {
        return TokenDataHandler._getFullTokenURI(tokenID);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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