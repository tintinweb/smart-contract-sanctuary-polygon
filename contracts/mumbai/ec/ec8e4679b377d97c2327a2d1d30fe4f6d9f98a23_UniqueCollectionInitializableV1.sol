/**
 *Submitted for verification at polygonscan.com on 2022-05-13
*/

pragma solidity ^0.8.0;
interface IERC165Upgradeable {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
pragma solidity ^0.8.0;
interface IERC721Upgradeable is IERC165Upgradeable {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
pragma solidity ^0.8.0;
interface IERC721ReceiverUpgradeable {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
pragma solidity ^0.8.0;
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
pragma solidity ^0.8.1;
library AddressUpgradeable {
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
pragma solidity ^0.8.2;
abstract contract Initializable {
    uint8 private _initialized;
    bool private _initializing;
    event Initialized(uint8 version);
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }
    function _setInitializedVersion(uint8 version) private returns (bool) {
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}
pragma solidity ^0.8.0;
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }
    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}
pragma solidity ^0.8.0;
library StringsUpgradeable {
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
pragma solidity ^0.8.0;
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }
    function __ERC165_init_unchained() internal onlyInitializing {
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}
pragma solidity ^0.8.0;
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }
    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
        _afterTokenTransfer(owner, address(0), tokenId);
    }
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}
pragma solidity ^0.8.0;
library CountersUpgradeable {
    struct Counter {
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
pragma solidity ^0.8.0;
interface IAccessControlUpgradeable {
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}
pragma solidity ^0.8.0;
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }
    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }
    mapping(bytes32 => RoleData) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
}
pragma solidity ^0.8.0;
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }
    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}
pragma solidity ^0.8.0;
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }
    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}
pragma solidity ^0.8.0;
library MerkleProofUpgradeable {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }
    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
pragma solidity ^0.8.0;
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
pragma solidity ^0.8.0;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
pragma solidity ^0.8.0;
interface IERC2981 is IERC165 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}
pragma solidity ^0.8.13;
abstract contract RoyaltiesV1 is IERC2981 {
    uint256 public constant HUNDRED_PERCENT = 10000;
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId;
    }
}
pragma solidity ^0.8.13;
contract UniqueCollectionRoyaltiesV1 is RoyaltiesV1 {
    uint256 public royaltyPercentage;
    address public royaltyRecipient;
    function _setTokenRoyalty(
        uint256 _royalty,
        address _recipient
    ) internal {
        _setTokenRoyaltyPercentage(_royalty);
        _setTokenRoyaltyRecipient(_recipient);
    }
    function _setTokenRoyaltyRecipient(
        address _recipient
    ) internal {
        royaltyRecipient = _recipient;
    }
    function _setTokenRoyaltyPercentage(
        uint256 _royalty
    ) internal {
        require(_royalty <= HUNDRED_PERCENT, "Royalties too high");
        royaltyPercentage = _royalty;
    }
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyRecipient;
        royaltyAmount = (salePrice * royaltyPercentage) / HUNDRED_PERCENT;
    }
}
pragma solidity ^0.8.13;
contract UniqueCollectionInitializableV1 is
    Initializable,
    ERC721Upgradeable,
    UniqueCollectionRoyaltiesV1,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
    uint128 public allowListMintEndBlockHeight;
    uint128 public publicMintStartBlockHeight;
    bool public saleActive;
    uint64 public maxSupply;
    uint56 public maxMintPerAddress;
    uint112 public mintPrice;
    uint16 public maxAllowListMintPerAddress;
    string public _extendedBaseURI;
    mapping(address => uint256) public minted;
    bytes32 public allowListMerkleRoot;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    event SaleStatusChanged(
        bool active
    );
    event AllowListMintEndBlockHeightChanged(
        uint128 allowListMintEndBlockHeight
    );
    event PublicMintStartBlockHeightChanged(
        uint128 publicMintStartBlockHeight
    );
    event BaseURIChanged(
        string baseURI
    );
    constructor() initializer {}
    struct InitializeData {
        address roleAdmin;
        address manager;
        uint64 maxSupply;
        uint56 maxMintPerAddress;
        string name;
        string symbol;
        string baseURI;
        uint256 royaltyPercentage;
        address royaltyRecipient;
        uint112 mintPrice;
        uint16 maxAllowListMintPerAddress;
        bytes32 allowListMerkleRoot;
    }
    function initialize(
       InitializeData calldata _init
    ) public initializer {
        require(_init.roleAdmin != address(0), "RoleAdmin is address(0)");
        require(_init.manager != address(0), "Manager is address(0)");
        require(_init.maxSupply > 0, "maxSupply must be greater than 0");
        __ERC721_init(_init.name, _init.symbol);
        __Pausable_init();
        __AccessControl_init();
        maxSupply = _init.maxSupply;
        maxMintPerAddress = _init.maxMintPerAddress;
        allowListMerkleRoot = _init.allowListMerkleRoot;
        maxAllowListMintPerAddress = _init.maxAllowListMintPerAddress;
        mintPrice = _init.mintPrice;
        _tokenIdCounter.increment(); // Ensure we start from ID 1
        _extendedBaseURI = _init.baseURI;
        _grantRole(DEFAULT_ADMIN_ROLE, _init.roleAdmin);
        _grantRole(MANAGER_ROLE, _init.manager);
        _setTokenRoyalty(_init.royaltyPercentage, _init.royaltyRecipient);
        _transferOwnership(_init.manager);
    }
    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "Caller is not manager");
        _;
    }
    modifier onlyProof(
        bytes32[] calldata _merkleProof
    ) {
        require(isProofValid(_merkleProof, _msgSender()), "invalid proof");
        _;
    }
    modifier isSaleActive() {
        require (saleActive, "Sale is not active");
        _;
    }
    modifier tokensLeft() {
        require(_tokenIdCounter.current() <= maxSupply, "Purchase would exceed max tokens");
        _;
    }
    modifier canStillMint(address to, uint256 amount) {
        if (maxMintPerAddress > 0) {
            require(
                minted[to] + amount <= maxMintPerAddress,
                "maxMintPerAddress exceeded"
            );
        }
        _;
    }
    function toggleSaleState(
        bool _saleActive
    ) external onlyManager {
        saleActive = _saleActive;
        emit SaleStatusChanged(_saleActive);
    }
    function setAllowListMintEndBlockHeight(
        uint128 _allowListMintEndBlockHeight
    ) external onlyManager {
        _setAllowListMintEndBlockHeight(_allowListMintEndBlockHeight);
    }
    function setPublicMintStartBlockHeight(
        uint128 _publicMintStartBlockHeight
    ) external onlyManager {
        _setPublicMintStartBlockHeight(_publicMintStartBlockHeight);
    }
    function setSaleStateAndBlockHeights(
        bool _saleActive,
        uint128 _allowListMintEndBlockHeight,
        uint128 _publicMintStartBlockHeight
    ) external onlyManager {
        saleActive = _saleActive;
        _setAllowListMintEndBlockHeight(_allowListMintEndBlockHeight);
        _setPublicMintStartBlockHeight(_publicMintStartBlockHeight);
        emit SaleStatusChanged(_saleActive);
    }
    function setBaseURI(string memory _newBaseURI) external onlyManager {
        _extendedBaseURI = _newBaseURI;
        emit BaseURIChanged(_newBaseURI);
    }
    function setRoyaltyRecipient(address _recipient) external onlyManager {
        _setTokenRoyaltyRecipient(_recipient);
    }
    function decreaseRoyaltyPercentage(uint256 _royaltyPercentage) external onlyManager {
        require(_royaltyPercentage < royaltyPercentage, "royaltyPercentage not lower");
        _setTokenRoyaltyPercentage(_royaltyPercentage);
    }
    function managerMint(address to)
        external
        isSaleActive
        tokensLeft
        canStillMint(to, 1)
        onlyManager
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        minted[to]+=1;
        _safeMint(to, tokenId);
    }
    function allowListMint(bytes32[] calldata _merkleProof)
        external
        payable
        onlyProof(_merkleProof)
        isSaleActive
        tokensLeft
        canStillMint(_msgSender(), 1)
    {
        require(
            block.number < allowListMintEndBlockHeight,
            "not allowList sale"
        );
        if(maxAllowListMintPerAddress > 0) {
            require(
                minted[_msgSender()] < maxAllowListMintPerAddress,
                "already minted"
            );
        }
        require(msg.value >= mintPrice, "price too low");
        minted[_msgSender()]+=1;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }
    function publicMint()
        external
        payable
        isSaleActive
        tokensLeft
        canStillMint(_msgSender(), 1)
    {
        require(
            publicMintStartBlockHeight > 0
            &&
            block.number >= publicMintStartBlockHeight,
            "not public sale"
        );
        require(msg.value >= mintPrice, "price too low");
        minted[_msgSender()]+=1;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }
    function pause() external onlyManager {
        _pause();
    }
    function unpause() external onlyManager {
        _unpause();
    }
    function withdrawNativeTokens(
        address payable _to
    ) external onlyManager {
        require(_to != address(0), "invalid withdraw receiver");
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
    function recoverERC20(
        address _tokenAddress,
        address _receiver,
        uint256 _tokenAmount
    ) external onlyManager {
        IERC20(_tokenAddress).transfer(_receiver, _tokenAmount);
    }
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }
    function isProofValid(
        bytes32[] calldata _merkleProof,
        address _sender
    )
        public
        view
        returns (bool isValid)
    {
        isValid = MerkleProofUpgradeable.verify(
            _merkleProof,
            allowListMerkleRoot,
            keccak256(abi.encodePacked(_sender))
        );
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, RoyaltiesV1, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function _setAllowListMintEndBlockHeight(
        uint128 _allowListMintEndBlockHeight
    ) internal {
        allowListMintEndBlockHeight = _allowListMintEndBlockHeight;
        emit AllowListMintEndBlockHeightChanged(_allowListMintEndBlockHeight);
    }
    function _setPublicMintStartBlockHeight(
        uint128 _publicMintStartBlockHeight
    ) internal {
        publicMintStartBlockHeight = _publicMintStartBlockHeight;
        emit PublicMintStartBlockHeightChanged(_publicMintStartBlockHeight);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _extendedBaseURI;
    }
}