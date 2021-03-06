/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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

library EnumerableMap {

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;

        mapping (bytes32 => uint256) _indexes;
    }

    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;
            MapEntry storage lastEntry = map._entries[lastIndex];

            map._entries[toDeleteIndex] = lastEntry;
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            map._entries.pop();

            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

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

interface IERC1155 is IERC165 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

interface IERC1155MetadataURI is IERC1155 {
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
*/

library SafeMath {

    /**
    * @dev Adds two numbers, throws on overflow.
    */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20 {

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    using EnumerableMap for EnumerableMap.UintToAddressMap;

    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    string public tokenURIPrefix;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    EnumerableMap.UintToAddressMap private _tokenOwners;

    string private _name;

    string private _symbol;

    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    constructor () {
        _name = "HIVENFT";
        _symbol = "NFTTEST";

        _registerInterface(_INTERFACE_ID_ERC1155);
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
        * @dev Internal function to set the token URI for a given token.
        * Reverts if the token ID does not exist.
        * @param tokenId uint256 ID of the token to set its URI
        * @param uri string URI to assign
    */    

    function _setTokenURI(uint256 tokenId, string memory uri) public {
        _tokenURIs[tokenId] = uri;
    }

    /**
        * @dev Internal function to set the token URI for all the tokens.
        * @param _tokenURIPrefix string memory _tokenURIPrefix of the tokens.
    */   

    function _setTokenURIPrefix(string memory _tokenURIPrefix) public {
        tokenURIPrefix = _tokenURIPrefix;
    }

    /**
        * @dev Returns an URI for a given token ID.
        * Throws if the token ID does not exist. May return an empty string.
        * @param tokenId uint256 ID of the token to query
    */    

    function tokenURI(uint256 tokenId) public view  virtual override returns (string memory) { 
        require(_exists(tokenId), "ERC1155Metadata: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = tokenURIPrefix;

        if (bytes(base).length == 0) {
            return  _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
        @notice Get the balance of an account's Tokens.
        @param account  The address of the token holder
        @param tokenId     ID of the Token
        @return        The owner's balance of the Token type requested
     */

    function balanceOf(address account, uint256 tokenId) public view override returns (uint256) {
        require(_exists(tokenId), "ERC1155Metadata: balance query for nonexistent token");
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[tokenId][account];
    }


    /**
        @notice Get the balance of multiple account/token pairs
        @param accounts The addresses of the token holders
        @param ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param operator  Address to add to the set of authorized operators
        @param approved  True if the operator is approved, false to revoke approval
    */

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param account     The owner of the Tokens
        @param operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */

    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param tokenId      ID of the token type
        @param amount   Transfer amount
        @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */    

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(tokenId), _asSingletonArray(amount), data);

        _balances[tokenId][from] = _balances[tokenId][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[tokenId][to] = _balances[tokenId][to].add(amount);

        emit TransferSingle(operator, from, to, tokenId, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, tokenId, amount, data);
    }

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param tokenIds     IDs of each token type (order and length must match _values array)
        @param amounts  Transfer amounts per token type (order and length must match _ids array)
        @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(tokenIds.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, tokenIds, amounts, data);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            _balances[tokenId][from] = _balances[tokenId][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[tokenId][to] = _balances[tokenId][to].add(amount);
        }

        emit TransferBatch(operator, from, to, tokenIds, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, tokenIds, amounts, data);
    }



    /**
        * @dev Internal function to mint a new token.
        * Reverts if the given token ID already exists.
        * @param tokenId uint256 ID of the token to be minted

    */

    function _mint(uint256 tokenId, uint256 _uri) internal {
        require(!_exists(tokenId), "ERC1155: token already minted");
        _tokenOwners.set(tokenId, msg.sender);
        _balances[tokenId][msg.sender] = 1;
        _setTokenURI(tokenId, (Strings.toString(_uri)));
        emit TransferSingle(msg.sender, address(0x0), msg.sender, tokenId, 1);
    }

    /**
        * @dev version of {_mint}.
        *
        * Requirements:
        *
        * - `tokenIds` and `amounts` must have the same length.
    */

    function _mintBatch(address to, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(tokenIds.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, tokenIds, amounts, data);

        for (uint i = 0; i < tokenIds.length; i++) {
            _balances[tokenIds[i]][to] = amounts[i].add(_balances[tokenIds[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, tokenIds, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, tokenIds, amounts, data);
    }

    /**
        * @dev Internal function to burn a specific token.
        * Reverts if the token does not exist.
        * Deprecated, use {ERC721-_burn} instead.
        * @param account owner of the token to burn
        * @param tokenId uint256 ID of the token being burned
        * @param amount uint256 amount of supply being burned
    */    

    function _burn(address account, uint256 tokenId, uint256 amount) internal virtual {
        require(_exists(tokenId), "ERC1155Metadata: burn query for nonexistent token");
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(tokenId), _asSingletonArray(amount), "");

        _balances[tokenId][account] = _balances[tokenId][account].sub(
            amount,
            "ERC_holderTokens1155: burn amount exceeds balance"
        );


        emit TransferSingle(operator, account, address(0), tokenId, amount);
    }


    /**
        * @dev version of {_burn}.
        * Requirements:
        * - `ids` and `amounts` must have the same length.
    */

    function _burnBatch(address account, uint256[] memory tokenIds, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(tokenIds.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), tokenIds, amounts, "");

        for (uint i = 0; i < tokenIds.length; i++) {
            _balances[tokenIds[i]][account] = _balances[tokenIds[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), tokenIds, amounts);
    }


    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, tokenId, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, tokenIds, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

abstract contract VRFRequestIDBase{
    
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed, address _requester, uint256 _nonce) internal pure returns (uint256)
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId( bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32)
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}


interface LinkTokenInterface {

  function allowance( address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender,uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals()external view returns ( uint8 decimalPlaces);

  function decreaseApproval( address spender,uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);

}


abstract contract VRFConsumerBase is VRFRequestIDBase {


  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  function requestRandomness( bytes32 _keyHash,uint256 _fee) internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
   
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);

    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  constructor(address _vrfCoordinator,address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }


  function rawFulfillRandomness(bytes32 requestId,uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

contract HIFENFT is ERC1155, VRFConsumerBase {

    uint256 reservedIds = 1;
    address public owner;
    uint256 public assignedNFTs;

    mapping(uint256 => bool) private isAssigned;

    uint256 tireThreeRewardRate = 50000000000000000;
    uint256 tireTwoRewardRate = 100000000000000000;
    uint256 tireOneRewardRate = 200000000000000000;

    mapping(uint256 => uint256) private lastClaimedTimestamp; // Last time when the reward claimed.
	mapping(uint256 => uint256) private remainingReward; // To store left over reward while converting to NFTs
    mapping(uint => mapping(uint => bool)) isOverlapRewardClaimed;

    //No.of days to pay the recurring maintanance fee. - 28 Days
    uint public subscriptionInterval = 6 hours;


    uint public monthlyTributeFee = 100000000000000000;
    mapping(uint => uint) public nextTimePeriodToPayFee;

    //Previous reward rate for each tire. (Will be used when admin changed reward rate)
    uint previousTireOneRewardRate = tireOneRewardRate;
    uint previousTireTwoRewardRate = tireTwoRewardRate;
    uint previousTireThreeRewardRate = tireThreeRewardRate;
    uint256 private rebaseTime = 1 minutes;


    mapping(uint => uint) rateUpdatedTime; // When the reward get updated

    event RewardClaimed(address Sender, uint256 tokenId, uint256 amount);

    uint256 public initialItemPrice = 10000000000000000000;

    IERC20 public hiveToken;

    address public charityAddress;
    address public rewardPool;
    address public treasuryPool;
    address public liquidityPool;
    address public team;

    mapping( uint256 => uint256) private tokenTier;

    constructor(address _token, address _charity, address _team, address _reward, address _treasury, address _liquidity) ERC1155 () VRFConsumerBase (
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
        ){
        hiveToken = IERC20(_token);
        _setTokenURIPrefix(tokenURIPrefix);
        rateUpdatedTime[1] = block.timestamp;
        rateUpdatedTime[2] = block.timestamp;
        rateUpdatedTime[3] = block.timestamp;
        charityAddress = _charity;
        owner = msg.sender;
        team = _team;
        rewardPool = _reward;
        treasuryPool = _treasury;
        liquidityPool = _liquidity;

	}

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    bytes32  internal keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
    uint256  internal fee = 0.0001 * 10 **18;
    
    mapping(uint256 => bytes32) private requestIds;
    mapping (uint256 => string) private randomIndex;
    mapping(bytes32 => uint256) private tokenIds;
    mapping ( uint256 => bool) private existsIndex;
    
    uint256 private randomResult;
    bytes32 private random;
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() internal returns (bytes32) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 requestId = requestRandomness(keyHash, fee);
        return requestId;
        
    }
    
    
    function getRandomResult(uint256 _tokenId) public view returns(string memory){
        return randomIndex[_tokenId];    
    }
    
    function check(uint256 _randomIndex) internal returns (uint256) {
        if(existsIndex[_randomIndex]) {
            _randomIndex += 1;
           _randomIndex = check(_randomIndex);
           if(_randomIndex > 40000){
               _randomIndex = 21;
               _randomIndex = check(_randomIndex);  
           }
        }
        existsIndex[_randomIndex] = true;
        return _randomIndex;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = (randomness % 39979) + 21;
        random = requestId;
        randomResult = check(randomResult);
        uint256 _tokenId = tokenIds[requestId];
        isOverlapRewardClaimed[rateUpdatedTime[tokenTier[randomResult]]][randomResult] = true;
        nextTimePeriodToPayFee[randomResult] = block.timestamp;
        lastClaimedTimestamp[randomResult] = block.timestamp;
        _mint(randomResult, randomResult);
        setTier(randomResult);
        randomIndex[_tokenId] = (Strings.toString(randomResult));
        _setTokenURI(_tokenId, randomIndex[_tokenId]);
        assignedNFTs += 1;
        
    }

    /** @dev change the Ownership from current owner to newOwner address
        @param newOwner : newOwner address */    

    function ownerTransfership(address newOwner) public onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
        return true;
    }

    function assignedNFTS() public view returns(uint256) {
        return assignedNFTs;
    }

    	// withdraw any matic tokens from the contract
	function withdraw() public onlyOwner {
		require(address(this).balance > 0,"Withdraw: insufficient fund");
        payable(msg.sender).transfer(address(this).balance);
	}

	// reclaim accidentally sent tokens
	function reclaimToken(IERC20 token) public onlyOwner {
		require(address(token) != address(0) && token.balanceOf(address(this)) > 0,"Withdraw: check the token address/balance must be  > 0");
		token.transfer(msg.sender, token.balanceOf(address(this)));
	}


    function mint(uint256 _numofTokensToMint)  public {
        require(_numofTokensToMint <=5, "Mint: minting count exceeds the Max limit");
        require(hiveToken.balanceOf(msg.sender) >= getItemPrice() * _numofTokensToMint, "Insufficent token balance");
        splitAndTransferTokens(getItemPrice() * _numofTokensToMint);
        for(uint8 i = 0; i < _numofTokensToMint; i++) {
        getRandomNumber();
        }
    }



    // function getRandomId() internal view returns(uint256) {
    //     return random(40000);
    // }

    function setTier(uint256 randomId) internal returns(bool) {
        if(randomId >= 1 && randomId <= 200) tokenTier[randomId] = 1;
        if(randomId >= 201 && randomId <= 800) tokenTier[randomId] = 2;
        if(randomId >= 801&& randomId <= 40000) tokenTier[randomId] = 3;

        return true;     
    }

    // function isExists(uint256 randomId) internal returns(uint256) {
    //     if(!isAssigned[randomId] && randomId > 20) {
    //         isAssigned[randomId] = true;
    //     }else{
    //         randomId = getRandomId();
    //         isExists(randomId);
    //     }

    //     return randomId;
    // }

    // function random(uint number) internal view returns(uint256){
    //     return (uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
    //     msg.sender))) % number
    //     ) + 1;
    // }

     // Returns the price of item which will be incremented t0 0.5 Hives after every 8000 NFT
	function getItemPrice() internal view returns (uint256) {
		return initialItemPrice + (500000000000000000 * (assignedNFTs / 8000));
	}

    function splitAndTransferTokens(uint amount) internal {
        uint toRewardPool = amount * (40) / (100); //40 %
        uint toTeam = amount * (5) / (100); // 5 %
        uint toLiquidity = amount * (10) / (100); // 10 %
        uint toCharity = amount * (15) / (1000); // 1.5%

        uint toTreasury = amount - (toRewardPool) - (toTeam) - (toLiquidity) - (toCharity); //Remaining %

        hiveToken.transferFrom(msg.sender, rewardPool, toRewardPool);
        hiveToken.transferFrom(msg.sender, team, toTeam);
        hiveToken.transferFrom(msg.sender, liquidityPool, toLiquidity);
        hiveToken.transferFrom(msg.sender, charityAddress, toCharity);
        hiveToken.transferFrom(msg.sender, treasuryPool, toTreasury);

    }


        //Function to change the reward rate for a particular tire.
    function changeRewardRate(uint tire, uint _rate) public onlyOwner {
		if(tire == 1) {
			tireOneRewardRate = _rate;
		}
		if(tire == 2) {
			tireTwoRewardRate = _rate;
		}
		if(tire == 2) {
			tireThreeRewardRate = _rate;
		}

        rateUpdatedTime[tire] = block.timestamp;

		return;
	}

    function setRebaseTime(uint256 time) public onlyOwner {
        rebaseTime = time;
    }

    //Calculate the reward earned for a paricular token.
    function calculateReward(uint id, uint tire, uint currentRate, uint previousRate) private view returns(uint256){
        uint256 timeDifference = block.timestamp - (lastClaimedTimestamp[id]);
        uint256 numOfDays = timeDifference / (rebaseTime);
        if(isOverlapRewardClaimed[rateUpdatedTime[tire]][id]) {
                return (numOfDays * currentRate) + (remainingReward[id]);
            } else {
                uint256 timeDifferenceTillRewardUpdate = rateUpdatedTime[tire] - (lastClaimedTimestamp[id]);
                uint256 numOfDaysPassed = timeDifferenceTillRewardUpdate / (rebaseTime);
                uint256 rewardsTillRewardUpdate = numOfDaysPassed / (previousRate);

                uint timeDifferenceAfterUpdate = block.timestamp - (rateUpdatedTime[tire]);
                uint256 numOfDaysAfterUpdate = timeDifferenceAfterUpdate / (rebaseTime);
                uint rewardsAfterUpdate = numOfDaysAfterUpdate / (currentRate);

                return rewardsTillRewardUpdate + (rewardsAfterUpdate) + (remainingReward[id]);
            }
    }

    // Returns the total reward earned in the token
    function rewardEarned(uint256 id) public view returns(uint256) {
        uint256 tire = tokenTier[id];
        require(tire > 0, "ID isn't minted yet or Invalid ID");
        if(tire == 1) {
            return calculateReward(id, tire, tireOneRewardRate, previousTireOneRewardRate);
        }
        if(tire == 2) {
            return calculateReward(id, tire, tireTwoRewardRate, previousTireTwoRewardRate);
        }
        if(tire == 3) {
            return calculateReward(id, tire, tireThreeRewardRate, previousTireThreeRewardRate);
        }

        return 0;
    }

    //Claime reward
    function claimReward(uint256 id, uint toUser, uint toCharity) public {
        require(isMaintainanceFeePaid(id), "Please pay maintainance fee before claiming reward!");
        require(balanceOf(msg.sender, id) > 0, "Reward claimer is not the owner of the NFT");
        uint256 amount = rewardEarned(id);
        require(amount > 0, "Wait till next rebase!");
        require(amount >= (toUser + toCharity), "Total of user and charity amount not equal to total reward");
        lastClaimedTimestamp[id] = block.timestamp;
        if(!isOverlapRewardClaimed[rateUpdatedTime[tokenTier[id]]][id]) {
            isOverlapRewardClaimed[rateUpdatedTime[tokenTier[id]]][id] = true;
        }

        remainingReward[id] = amount - (toUser + toCharity);

        if(toUser > 0) {
            hiveToken.transfer(msg.sender, toUser);
        }
        if(toCharity > 0) {
            hiveToken.transfer(charityAddress, toCharity);
        }
        emit RewardClaimed(msg.sender, id, amount);
    }

    //Convert a reward to NFT
	function convertRewardToNFT(uint256 id) public {
		require(balanceOf(msg.sender, id) > 0, "Reward claimer is not the owner of the NFT");
		uint256 totalRewards = rewardEarned(id);
		uint256 numOfNFTs = totalRewards / (getItemPrice());
		require(numOfNFTs > 0, "Insufficent reward balance to convert to NFT");
		//require(rewardEarned(id) >= itemPrice, "Insufficient reward balance to convert to NFT");
		if(numOfNFTs > 5) {
			numOfNFTs = 5;
		}

		uint256 remainingPrice =  totalRewards - (numOfNFTs / (getItemPrice()));
		remainingReward[id] = remainingPrice;
		lastClaimedTimestamp[id] = block.timestamp;
        if(!isOverlapRewardClaimed[rateUpdatedTime[tokenTier[id]]][id]) {
            isOverlapRewardClaimed[rateUpdatedTime[tokenTier[id]]][id] = true;
        }
			mint(numOfNFTs);
	}

    //Pay maintenance fee
    function queensTribute(uint id) public payable {
        uint feeToPay = maintainanceFeeToPay(id);
        require(feeToPay > 0, "Not due yet");
        require(msg.value >= feeToPay, "Insufficient amount to pay!");
        nextTimePeriodToPayFee[id] = nextTimePeriodToPayFee[id] + ((feeToPay / (monthlyTributeFee)) - (subscriptionInterval));
        //Transfer
        (bool sent,) = payable(owner).call{value: msg.value}("");
        require(sent, "Failed to send matic");
    }

    //Returns total maintananceFee to pay for the given token ID//
    function maintainanceFeeToPay(uint id) public view returns(uint) {
        uint feeToPay = 0;
        if( block.timestamp > nextTimePeriodToPayFee[id]) {
            uint numOfMonths = (block.timestamp - (nextTimePeriodToPayFee[id])) / (subscriptionInterval);
            feeToPay = (numOfMonths + (1)) * (monthlyTributeFee);
        }
        return feeToPay;
    }

    //Returns bool, whether maintainance fee is paid or not.
    function isMaintainanceFeePaid(uint id) public view returns(bool) {
        return !(maintainanceFeeToPay(id) > 0);
    }

    function burn(uint256 tokenId, uint256 supply) public {
        _burn(msg.sender, tokenId, supply);
    }

    function burnBatch(uint256[] memory tokenId, uint256[] memory amounts) public {
        _burnBatch(msg.sender, tokenId, amounts);
    }
}