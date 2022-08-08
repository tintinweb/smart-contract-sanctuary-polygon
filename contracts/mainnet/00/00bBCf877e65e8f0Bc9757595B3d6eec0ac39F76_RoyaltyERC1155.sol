/**
 *Submitted for verification at polygonscan.com on 2022-08-08
*/

pragma solidity ^0.8.0;


interface IAccessControl {
    
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    
    function hasRole(bytes32 role, address account) external view returns (bool);

    
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    
    function grantRole(bytes32 role, address account) external;

    
    function revokeRole(bytes32 role, address account) external;

    
    function renounceRole(bytes32 role, address account) external;
}

interface IAccessControlEnumerable is IAccessControl {
    
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    
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

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    
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

    
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

library EnumerableSet {
    
    
    
    
    
    
    
    

    struct Set {
        
        bytes32[] _values;
        
        
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            
            
            
            

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                
                set._values[toDeleteIndex] = lastvalue;
                
                set._indexes[lastvalue] = valueIndex; 
            }

            
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
        return set._values[index];
    }

    
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC1155 is IERC165 {
    
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    
    event URI(string value, uint256 indexed id);

    
    function balanceOf(address account, uint256 id) external view returns (uint256);

    
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    
    function setApprovalForAll(address operator, bool approved) external;

    
    function isApprovedForAll(address account, address operator) external view returns (bool);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IERC1155Receiver is IERC165 {
    
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC1155MetadataURI is IERC1155 {
    
    function uri(uint256 id) external view returns (string memory);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        return account.code.length > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    
    mapping(uint256 => mapping(address => uint256)) private _balances;

    
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    
    string private _uri;

    
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
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
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
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

interface IERC2981 is IERC165 {
    
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

contract RoyaltyERC1155 is ERC1155, Ownable, AccessControlEnumerable, IERC2981 {

    
    uint16 public constant  FEE_DENOMINATOR = 10000;

    
    uint16 public constant  MAX_PLATFORM_ROYALTIES = 3000;

    
    bytes32 public constant ROLE_MINTER = keccak256("ROLE_MINTER");

    
    bytes32 public constant ROLE_AUCTION_ADMIN = keccak256("ROLE_AUCTION_ADMIN");

    
    bytes32 public constant ROLE_TOKEN_ADMIN = keccak256("ROLE_TOKEN_ADMIN");

    
    struct Royalty {
        address payable to;
        uint16          basisPoints;
    }

    
    struct Sale {
        
        uint256         saleId;

        
        address payable from;

        
        
        address payable to;

        
        uint256         amount;

        
        uint            price;
    }

    
    event SaleAnnounce(uint256 saleId, uint256 indexed tokenId, address from, address to, uint price);

    
    event SaleComplete(uint256 indexed saleId, uint256 indexed tokenId, address from, address to, uint price);

    
    mapping( uint256 => Royalty[] ) public royalties;

    
    mapping( uint256 => Sale )      public sales;

    
    mapping( uint256 => uint32 )    public  salesCounter;

    
    uint256 public nextId;

    
    uint256 public nextSaleId;

    
    bool    public directTransferLocked;

    
    uint16  public commissionFee;

    
    uint16  public primarySalesFee;

    
    uint16  public secondarySalesFee;

    
    address payable public feeAddress;

    
    string private _name;

    
    string private _symbol;

    
    constructor(
        string memory uri_,
        uint16 commissionFee_,
        uint16 primarySalesFee_,
        uint16 secondarySalesFee_,
        string memory name_,
        string memory symbol_
    ) ERC1155(uri_) {
        address sender = _msgSender();
        nextId = 1;
        nextSaleId = 1;
        _name = name_;
        _symbol = symbol_;
        directTransferLocked = true;
        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(ROLE_MINTER, sender);
        _grantRole(ROLE_AUCTION_ADMIN, sender);
        _grantRole(ROLE_TOKEN_ADMIN, sender);
        updateFees(commissionFee_, primarySalesFee_, secondarySalesFee_, payable(sender));
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual
    override(ERC1155, AccessControlEnumerable, IERC165) returns (bool) {
        return
        ERC1155.supportsInterface(interfaceId) ||
        AccessControlEnumerable.supportsInterface(interfaceId) ||
        interfaceId == type(IERC2981).interfaceId;
    }


    
    function mint(address to, uint256 amount,
        address payable[] calldata royaltyAddresses, uint16[] calldata royaltyBasisPoints,
        bytes calldata data) external onlyRole(ROLE_MINTER)
        returns (uint256)
    {
        require(royaltyAddresses.length == royaltyBasisPoints.length, "royalty array size mismatch");

        uint16 totRoyMax = MAX_PLATFORM_ROYALTIES;

        uint256 id = nextId;
        Royalty[] storage royaltyArray = royalties[id];
        for (uint i=0; i < royaltyAddresses.length; i++) {
            totRoyMax += royaltyBasisPoints[i];
            royaltyArray.push( Royalty(royaltyAddresses[i], royaltyBasisPoints[i]) );
        }
        require(totRoyMax <= FEE_DENOMINATOR, "royalty + fees exceed 100%");

        _mint(to, id, amount, data);

        nextId += 1;
        return id;
    }

    
    function burn(address from, uint256 id, uint256 amount) external {
        address operator = _msgSender();
        require(
            operator == from ||
            hasRole(ROLE_TOKEN_ADMIN, operator) ||
            isApprovedForAll(from, operator), "No authority to burn token");
        _burn(from, id, amount);
    }

    
    function setDirectTransferLocked(bool lock) external onlyRole(DEFAULT_ADMIN_ROLE) {
        directTransferLocked = lock;
    }

    
    function setUri(string memory newuri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(!directTransferLocked, "direct transfer locked");
        ERC1155.safeTransferFrom(from, to, id, amount, data);
    }

    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(!directTransferLocked, "direct transfer locked");
        ERC1155.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    
    function sell(address payable from, address payable to, uint256 id, uint256 amount, uint256 price) external returns(uint256) {
        require(_msgSender() == from || hasRole(ROLE_AUCTION_ADMIN, _msgSender()), "not token owner nor admin");
        require(from != to, "cannot sell to self");
        require(amount > 0, "amount must be > 0");
        require(balanceOf(from, id) >= amount, "insufficient token balance");
        if (sales[id].saleId != 0) {
            _revokeSale(id); 
        }

        uint256 saleId = nextSaleId;
        nextSaleId += 1;

        sales[id] = Sale(saleId, from, to, amount, price);
        emit SaleAnnounce(saleId, id, from, to, price);
        return saleId;
    }

    
    function hasSale(uint256 tokenId) external view returns(bool) {
        return (sales[tokenId].saleId != 0);
    }

    
    function getSale(uint256 tokenId) external view returns(Sale memory) {
        Sale memory sale = sales[tokenId];
        require (sale.saleId != 0, "sale not found for tokenId");
        return sale;
    }

    
    function revokeSale(uint256 tokenId) external {
        _revokeSale(tokenId);
    }


    
    function claimSale(uint256 tokenId, bytes calldata data) external payable {
        Sale memory sale = sales[tokenId];
        address to = _msgSender();

        require(sale.saleId != 0, "no sale found for token");
        require(sale.from != to, "cannot claim to self");
        require(sale.to == address(0) || sale.to == to, "not the intended sale recipient");
        require(sale.price == msg.value, "incorrect amount for sale");

        uint256 remainingValue = msg.value;
        Royalty[] memory tokenRoyalties = _buildCompleteRoyaltyArray(tokenId);
        for (uint i=0; i < tokenRoyalties.length; i++) {
            uint256 rtyAmount = tokenRoyalties[i].basisPoints * msg.value / FEE_DENOMINATOR;
            Address.sendValue(tokenRoyalties[i].to, rtyAmount);
            remainingValue -= rtyAmount;
        }
        Address.sendValue(sale.from, remainingValue);

        _safeTransferFrom(sale.from, to, tokenId, sale.amount, data);
        salesCounter[tokenId] += 1;
        delete sales[tokenId];

        emit SaleComplete(sale.saleId, tokenId, sale.from, sale.to, sale.price);
    }

    
    function _buildCompleteRoyaltyArray(uint256 tokenId) internal view returns(Royalty[] memory) {
        Royalty[] memory storedRoyalties = royalties[tokenId];
        uint royaltiesCount = storedRoyalties.length;
        uint16  platFees = platformFees(tokenId);
        if (platFees > 0) {
            royaltiesCount += 1;
        }
        Royalty[] memory royArr = new Royalty[](royaltiesCount);
        for (uint i=0; i < storedRoyalties.length; ++i) {
            royArr[i] = storedRoyalties[i];
        }
        if (platFees > 0) {
            royArr[royaltiesCount - 1] = Royalty(feeAddress, platFees);
        }
        return royArr;
    }

    
    function _revokeSale(uint256 tokenId) internal {
        address caller = _msgSender();
        Sale memory s = sales[tokenId];
        require(s.saleId != 0, "no sale found for token");
        require(s.from == caller || hasRole(ROLE_AUCTION_ADMIN, caller), "not your sale, cannot revoke");
        delete sales[tokenId];
        emit SaleComplete(s.saleId, tokenId, s.from, s.from, 0);
    }

    
    function _beforeTokenTransfer(
        address ,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory 
    ) internal override virtual {

        if (from != address(0) && to != address(0) && msg.value == 0) {
            
            for (uint i=0; i < ids.length; i++) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];

                if (sales[id].saleId != 0) {
                    require(balanceOf(from, id)  >= amount + sales[id].amount,
                        "pending sale outweighs transfer");
                }
            }
        }
    }

    
    function updateFees(uint16 commission, uint16 primarySales, uint16 secondarySales, address payable payToAddress)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(commission + primarySales <= MAX_PLATFORM_ROYALTIES, "Primary exceeding max");
        require(commission + secondarySales <= MAX_PLATFORM_ROYALTIES, "Secondary exceeding max");
        require(payToAddress != address(0), "Cannot set void payable address");
        commissionFee = commission;
        primarySalesFee = primarySales;
        secondarySalesFee = secondarySales;
        feeAddress = payToAddress;
    }

    
    function platformFees(uint256 _tokenId) public view returns(uint16) {
        return salesCounter[_tokenId] == 0 ? commissionFee + primarySalesFee : commissionFee + secondarySalesFee;
    }

    
    function royaltyCount(uint256 _tokenId) external view returns(uint16) {
        return uint16(royalties[_tokenId].length);
    }

    
    function royaltyRecord(uint256 _tokenId, uint16 _index) public view returns(Royalty memory) {
        Royalty[] memory royalty = royalties[_tokenId];
        require(royalty.length > _index, "No record for given index");
        return royalty[_index];
    }

    
    function royaltyInfoIdx(uint256 _tokenId, uint256 _salePrice, uint16 _index)
        public
        view
        virtual
        returns (address, uint256)
    {
        Royalty memory royalty = royaltyRecord(_tokenId, _index);
        uint256 royaltyAmount = (_salePrice * royalty.basisPoints) / FEE_DENOMINATOR;
        return (royalty.to, royaltyAmount);
    }

    
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return royaltyInfoIdx(_tokenId, _salePrice, 0);
    }


    
    function name() public view virtual returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    
    function kill() public onlyOwner {
        selfdestruct(payable(owner()));
    }
}