/**
 *Submitted for verification at polygonscan.com on 2022-03-14
*/

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.9;

library Strings {

    function toString(uint256 value) internal pure returns (string memory) {

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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
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
    event tokenBaseURI(string value);
    event RoyaltyInfoChanged(address indexed receiver, uint96 indexed fee);



    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function AssignedNFTs() external view returns (uint256);
    function mint(address creator, string memory uri, uint256 supply) external;
    function setRoyaltyFee(address receiver, uint96 _royalty) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
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

interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);

}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract ERC1155 is Context, ERC165, IERC1155, IERC2981 {
    using Address for address;
    using Strings for uint256;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;
    
    string private tokenURIPrefix = "https://gateway.pinata.cloud/ipfs/";

    uint256 public totalSupply;

    // Optional mapping for token URIs
    
   mapping(uint256 => string) private _tokenURIs;

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private royaltyFeeInfo;

    address public operator;

    EnumerableMap.UintToAddressMap private _tokenOwners;

    string private _name = "2022.02.14_BytheHorns";

    string private _symbol = "LA Times";

    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;


    constructor () {
        totalSupply = 1;
        _registerInterface(_INTERFACE_ID_ERC1155);
        _registerInterface(_INTERFACE_ID_ERC2981);
        royaltyFeeInfo = RoyaltyInfo(_msgSender(),1000);

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

    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC1155Metadata: URI query for nonexistent token");
        _tokenURIs[tokenId] = uri;
    }


    function AssignedNFTs() public view virtual override returns (uint256) {
        return _tokenOwners.length();
    }

    function _setTokenURIPrefix(string memory _tokenURIPrefix) internal {
        tokenURIPrefix = _tokenURIPrefix;
        emit tokenBaseURI(_tokenURIPrefix);
    }

    function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice) external view virtual override returns (address, uint256)

    {
        RoyaltyInfo memory royalty  = royaltyFeeInfo;

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / 10000;

        return (royalty.receiver, royaltyAmount);

    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setRoyaltyFee(address receiver, uint96 feeNumerator) external {
        require(receiver != address(0), "ERC2981: invalid receiver");
        require(msg.sender == operator,"ERC1155: caller doesn't have operator role");
        royaltyFeeInfo = RoyaltyInfo(receiver, feeNumerator);
        emit RoyaltyInfoChanged(receiver, feeNumerator);
    }

    /**
        * @dev Returns an URI for a given token ID.
        * Throws if the token ID does not exist. May return an empty string.
        * @param tokenId uint256 ID of the token to query
    */    

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC1155Metadata: URI query for nonexistent token");
        
        string memory base = tokenURIPrefix;

        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    function mint(address creator, string memory uri, uint256 supply) public {
        require(msg.sender == operator,"ERC1155: caller doesn't have operator Role");
        uint256 tokenId = 1;
        _mint(creator, tokenId, supply, uri);
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
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param approved  True if the operator is approved, false to revoke approval
    */

    function setApprovalForAll(address _operator, bool approved) public virtual override {
        require(_msgSender() != _operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][_operator] = approved;
        emit ApprovalForAll(_msgSender(), _operator, approved);
    }

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param account     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */

    function isApprovedForAll(address account, address _operator) public view override returns (bool) {
        return _operatorApprovals[account][_operator];
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
        require( _balances[tokenId][from] >= amount,"ERC1155: insufficient balance for transfer");

        address _operator = _msgSender();

        _beforeTokenTransfer(_operator, from, to, _asSingletonArray(tokenId), _asSingletonArray(amount), data);
        
        _balances[tokenId][from] = _balances[tokenId][from] - amount;
        _balances[tokenId][to] = _balances[tokenId][to] + amount;

        emit TransferSingle(_operator, from, to, tokenId, amount);

        _doSafeTransferAcceptanceCheck(_operator, from, to, tokenId, amount, data);
    }



    /**
        * @dev Internal function to mint a new token.
        * Reverts if the given token ID already exists.
        * @param tokenId uint256 ID of the token to be minted
        * @param _supply uint256 supply of the token to be minted
        * @param _uri string memory URI of the token to be minte
    */

    function _mint(address from, uint256 tokenId, uint256 _supply, string memory _uri) internal {
        
        require(!_exists(tokenId), "ERC1155: token already minted");
        require(from != address(0),"ERC1155: address should not be Zero");
        require(_supply != 0, "Supply should be positive");
        require(bytes(_uri).length > 0, "uri should be set");

        _operatorApprovals[from][msg.sender] = true;
        _tokenOwners.set(tokenId, from);
        _balances[tokenId][from] = _supply;
        _setTokenURI(tokenId, _uri);
        emit ApprovalForAll(from, msg.sender, true);

        emit TransferSingle(from, address(0x0), from, tokenId, _supply);
        emit URI(_uri, tokenId);
    }

    /**
        * @dev Internal function to burn a specific token.
        * Reverts if the token does not exist.
        * Deprecated, use {ERC1155-_burn} instead.
        * @param account owner of the token to burn
        * @param tokenId uint256 ID of the token being burned
        * @param amount uint256 amount of supply being burned
    */    

    function _burn(address account, uint256 tokenId, uint256 amount) internal virtual {
        require(_exists(tokenId), "ERC1155Metadata: burn query for nonexistent token");
        require(account != address(0), "ERC1155: burn from the zero address");
        require( _balances[tokenId][account] >= amount,"ERC1155: insufficient balance for transfer");
        address _operator = _msgSender();

        _beforeTokenTransfer(_operator, account, address(0), _asSingletonArray(tokenId), _asSingletonArray(amount), "");

        _balances[tokenId][account] = _balances[tokenId][account] - amount;


        emit TransferSingle(_operator, account, address(0), tokenId, amount);
    }


    function _beforeTokenTransfer(
        address _operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address _operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(_operator, from, tokenId, amount, data) returns (bytes4 response) {
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
        address _operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(_operator, from, tokenIds, amounts, data) returns (bytes4 response) {
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

contract BytheHorns is ERC1155 {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event OperatorChanged(address indexed operator, address indexed newoperator);

    constructor (address _operator) ERC1155 () {
        owner = msg.sender;
        setOperator(_operator);

    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /** @dev change the Ownership from current owner to newOwner address
        @param newOwner : newOwner address */    

    function transferOwnership(address newOwner) public onlyOwner returns(bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function setOperator(address _operator) public onlyOwner returns(bool) {
        require(_operator!= address(0),"Operator: operator is the Zero address");
        emit OperatorChanged(operator, _operator);
        operator = _operator;
        return true;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
         _setTokenURIPrefix(_baseURI);
    }

    function burn(uint256 tokenId, uint256 supply) public {
        _burn(msg.sender, tokenId, supply);
    }

}