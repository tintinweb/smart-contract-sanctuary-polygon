// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./ERC721Factory.sol";
import "./IERC721Impl.sol";

contract ERC721ManagableFactory is ERC721Factory {

    // Reserved URIs
    string[] public reservedURIs;
    uint256 public reservedURICounter;
    uint256 public reservedURIOffset;

    event ReservedUrisChanged();

    constructor(address collection_, uint256 fee_, address firewall_, string memory defaultUri_, uint256 offset_)
    ERC721Factory(collection_, fee_, firewall_, defaultUri_) {
        bool isDefaultSet = keccak256(bytes(defaultUri_)) != keccak256(bytes(""));
        require(isDefaultSet, 'ERC721Factory: this factory requires setting non empty default uri');
        reservedURIOffset = offset_;
    }

    function _requestUri(uint256 tokenId) internal virtual override {
        require(tokenId > 0 && tokenId > reservedURIOffset && reservedURIOffset + reservedURIs.length > 0
            && reservedURIOffset + reservedURIs.length >= tokenId,
            'ERC721Factory: minting is not available currently, try again later');
        reservedURICounter++;
        _resolveUri(tokenId, reservedURIs[tokenId-reservedURIOffset-1]);
    }

    function _resolveUri(uint256 tokenId, string memory uri) internal virtual override {
        IERC721Impl(collection).setTokenURI(tokenId, uri);
    }

    function delReservedTokenURIs() public onlyOwner {
        require(reservedURICounter == 0,
            'ERC721Factory: no longer can delete reserved token URIs, minting is active');
        delete reservedURIs;
        emit ReservedUrisChanged();
    }

    function addReservedTokenURIs(string[] memory _tokenURIs) public onlyOwner {
        for (uint i=0; i<_tokenURIs.length; i++) reservedURIs.push(_tokenURIs[i]);
        emit ReservedUrisChanged();
    }

    function resolveTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        _resolveDefaultUri(tokenId, uri);
    }

    function resolveTokenURIs(uint256 tokenId, string[] memory uris) public onlyOwner {
        for (uint i=0; i<uris.length; i++) {
            _resolveDefaultUri(tokenId+i, uris[i]);
        }
    }

    function _resolveDefaultUri(uint256 tokenId, string memory uri) internal virtual {
        string memory prevURI = IERC721Impl(collection).getTokenURI(tokenId);
        require(keccak256(bytes(defaultUri)) == keccak256(bytes(prevURI)),
            'ERC721Factory: unable to change non-default URI with this interface');
        _resolveUri(tokenId, uri);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IERC721Impl is IERC721, IERC721Metadata {

    event BaseUriSet(string newBaseUri);
    event TokenUriSet(uint256 indexed tokenId, string uri);
    event ReservedUrisChanged();

    function owner() external view returns (address);

    function mintTo(address minter) external;

    function mintTo(address minter, string memory uri) external;

    function mintTo(address minter, uint256 amount) external;

    function mintTo(address minter, uint256 amount, string[] memory uris) external;

    function canMint(uint256 amount) external view returns (bool);

    function burn(uint256 tokenId) external;

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

    function getTokenURI(uint256 tokenId) external view returns (string memory);

    function totalMinted() external view returns (uint256);

    function totalBurned() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IERC721Factory {

    event ClientSet(address client);
    event CollectionSet(address collection);
    event FeeSet(uint256 fee);
    event MintingSet(bool active);
    event FirewallSet(address firewall);
    event DefaultUriSet(string uri);

    event Withdrawn(address indexed caller, address indexed receiver, uint256 amount);
    event TokenMinted(address indexed minter, uint256 amount);
    
    function mint() external payable;

    function mint(uint256 amount) external payable;

    function mint(address to, uint256 amount) external payable;

    function mintAdmin() external payable;

    function mintAdmin(uint256 amount) external payable;

    function mintAdmin(address to, uint256 amount) external payable;

    function canMint(address minter, uint256 amount) external view returns(bool, string memory);

    function balanceOf() external returns(uint256);

    function withdraw(address to, uint256 amount) external;

    function withdraw(address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IERC721Wrappable {

    event CollectionOwnershipTransferred(address indexed collection, address indexed previousOwner,
        address indexed newOwner);

    function transferCollectionOwnership(address _collection, address _Wrappable) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IERC721Royalty {
    function setBaseURI(string memory _uri) external;

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    function deleteDefaultRoyalty() external;

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external;

    function resetTokenRoyalty(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "../../Access/AccessMinter.sol";
import "./IERC721Wrappable.sol";

abstract contract ERC721Wrappable is Ownable, IERC721Wrappable {

    function transferCollectionOwnership(address _colAddress, address _newOwner) public override onlyOwner {
        require(_colAddress != address(0) && _colAddress != address(this),
            'ERC721Wrappable: collection address needs to be different than zero and current address!');
        require(_newOwner != address(0) && _newOwner != address(this),
            'ERC721Wrappable: new address needs to be different than zero and current address!');
        AccessMinter(_colAddress).changeMinter(_newOwner);
        emit CollectionOwnershipTransferred(_colAddress, address(this), _newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./Extension/ERC721Wrappable.sol";
import "./Extension/IERC721Royalty.sol";
import './Access/IERC721Firewall.sol';
import './IERC721Impl.sol';
import './IERC721Factory.sol';

contract ERC721Factory is IERC721Factory, ERC721Wrappable, IERC721Royalty {

    address public collection;
    IERC721Firewall public firewall;

    uint256 public fee;
    string public defaultUri;
    bool public mintingActive;

    // Modifiers
    modifier onlyWhenCollectionSet() {
        require(collection != address(0), "Factory: collection zero address!");
        _;
    }

    modifier onlyWhenMintable(address minter, uint256 amount) {
        (bool allowed, string memory message) = canMint(minter, amount);
        require(allowed, message);
        _;
    }
    
    constructor(address collection_, uint256 fee_, address firewall_, string memory defaultUri_) {
        setCollection(collection_);
        setMintingActive(false);
        setFee(fee_);
        setFirewall(firewall_);
        setDefaultUri(defaultUri_);
    }

    // Minting
    function mint() public payable override {
        mint(_msgSender(), 1);
    }

    function mint(uint256 amount) public payable override {
        mint(_msgSender(), amount);
    }

    function mint(address to, uint256 amount) public payable override {
        require(_msgSender() == owner() || _msgSender() == address(this) || fee * amount == msg.value,
            'Factory: provided fee does not match required amount!');
        _mint(to, amount);
    }

    function mintAdmin() public payable override {
        mintAdmin(_msgSender(), 1);
    }

    function mintAdmin(uint256 amount) public payable override {
        mintAdmin(_msgSender(), amount);
    }

    function mintAdmin(address to, uint256 amount) public payable override onlyOwner {
        (bool allowed, ) = firewall.canAllocate(to, amount);
        if (!allowed) firewall.setAllocation(to, firewall.currentAllocation(to) + amount);
        mint(to, amount);
    }

    function _mint(address to, uint256 amount) internal onlyWhenMintable(to, amount) {
        firewall.allocate(to, amount);
        bool isDefaultSet = keccak256(bytes(defaultUri)) != keccak256(bytes(""));
        if (isDefaultSet) {
            string[] memory uris = new string[](amount);
            for (uint i=0; i<amount; i++) {
                uris[i] = defaultUri;
            }
            uint256 lastTokenId = IERC721Impl(collection).totalMinted();
            IERC721Impl(collection).mintTo(to, amount, uris);
            for (uint i=0; i<amount; i++) {
                _requestUri(lastTokenId+i+1);
            }
        } else {
            IERC721Impl(collection).mintTo(to, amount, new string[](0));
        }

        emit TokenMinted(to, amount);
    }

    function _requestUri(uint256 tokenId) internal virtual {
        // DO NOTHING, ABSTRACT METHOD
    }

    function _resolveUri(uint256 tokenId, string memory uri) internal virtual {
        // DO NOTHING, ABSTRACT METHOD
    }

    function canMint(address minter, uint256 amount) public override view returns (bool, string memory) {
        bool allowed = false;
        string memory message = "";

        if (collection == address(0)) {
            return (false, "Factory: cannot mint yet");
        }
        allowed = IERC721Impl(collection).canMint(amount);
        if (!allowed) {
            return (false, "Factory: cannot mint more");
        }
        (allowed, message) = firewall.canAllocate(minter, amount);
        if (!allowed) {
            return (false, message);
        }
        if (_msgSender() != owner()) {
            if (!mintingActive) {
                return (false, "Factory: minting disabled!");
            }
            if (firewall.isWhitelistActive() && !firewall.isWhitelisted(minter)) {
                return (false, "Factory: not whitelisted!");
            }
        }
        return (true, "");
    }

    function setMintingActive(bool enabled_) public onlyOwner {
        mintingActive = enabled_;
        emit MintingSet(enabled_);
    }

    function setFee(uint256 fee_) public onlyOwner {
        // zero fee_ is accepted
        fee = fee_;
        emit FeeSet(fee_);
    }   

    function setCollection(address collection_) public onlyOwner {
        collection = collection_;
        emit CollectionSet(collection_);
    }

    function setFirewall(address firewall_) public onlyOwner {
        firewall = IERC721Firewall(firewall_);
        emit FirewallSet(firewall_);
    }

    function setDefaultUri(string memory uri_) public onlyOwner {
        defaultUri = uri_;
        emit DefaultUriSet(uri_);
    }

    // Payments & Ownership
    function balanceOf() external view override returns(uint256) {
        return address(this).balance;
    }

    function withdraw(address to) public override onlyOwner {
        uint256 amount = address(this).balance;
        withdraw(to, amount);
    }

    function withdraw(address to, uint256 amount) public override onlyOwner {
        require(to != address(0), 'Factory: cannot withdraw fees to zero address!');
        payable(to).transfer(amount);
        emit Withdrawn(_msgSender(), to, amount);
    }

    // Owable ERC721 functions
    function setBaseURI(string memory _uri) external override onlyOwner onlyWhenCollectionSet {
        IERC721Royalty(collection).setBaseURI(_uri);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external override onlyOwner onlyWhenCollectionSet {
        IERC721Royalty(collection).setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external override onlyOwner onlyWhenCollectionSet {
        IERC721Royalty(collection).deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external override onlyOwner onlyWhenCollectionSet {
        IERC721Royalty(collection).setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external override onlyOwner onlyWhenCollectionSet {
        IERC721Royalty(collection).resetTokenRoyalty(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "../../Access/IAllocator.sol";
import "../../Access/IWhitelist.sol";

interface IERC721Firewall is IAllocator, IWhitelist {}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IWhitelist { 

    event WhitelistSet(bool status);
    event WhitelistChanged();
    
    function addToWhitelist(address[] memory wallets) external;

    function deleteFromWhitelist(address[] memory wallets) external;

    function setWhitelistActive(bool active) external;

    function isWhitelisted(address wallet) external view returns (bool);

    function isWhitelistActive() external view returns (bool);

    function queryWhitelist(uint256 _cursor, uint256 _limit) external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "@openzeppelin/contracts/utils/Timers.sol";

interface IAllocator {

    struct Allocation {
        address allocator;
        uint256 amount;
    }

    struct Phase {
        Timers.BlockNumber block;
        uint256 mintLimit;
    }

    event MaxBaseAllocation(uint256 amount);
    event MaxAllocation(address indexed allocator, uint256 amount);
    event CurrentAllocation(address indexed allocator, uint256 amount);
    event PhaseSet(uint256 indexed id, uint64 deadline, uint256 limit);
    event AllocatorSet(bool status);

    function setAllocatorActive(bool active) external;

    function isAllocatorActive() external view returns (bool);

    function currentAllocation(address allocator) external view returns(uint256);

    function maximumAllocation(address allocator) external view returns(uint256);

    function totalAllocationLimit() external view returns(uint256);

    function setAllocations(Allocation[] memory allocances) external;

    function setBaseAllocation(uint256 amount) external;

    function setAllocation(address allocator, uint256 amount) external;

    function canAllocate(address allocator, uint256 amount) external view returns(bool, string memory);

    function setPhases(Phase[] memory phases) external;

    function insertPhase(Phase memory phase) external;

    function updatePhase(uint256 phaseId, uint64 timestamp, uint256 minLimit) external;

    function getPhases() external view returns(Phase[] memory);

    function getCurrentPhaseLimit() external view returns(uint256);

    function allocate(address allocator, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Address.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts/access/AccessControl.sol';

contract AccessMinter is Ownable, AccessControl {
    using Address for address;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    address internal currentMinter;
    bool internal canRevoke = false;

    modifier revokable {
        canRevoke = true;
        _;
        canRevoke = false;
    }

    modifier onlyMinter {
        require(hasRole(MINTER_ROLE, msg.sender),
            'AccessMinter: only minter can call this method');
        _;
    }

    modifier onlyMinterOrOwner {
        require(msg.sender == owner() || hasRole(MINTER_ROLE, msg.sender),
            'AccessMinter: only minter or owner can call this method');
        _;
    }

    constructor() {
        _setRoleAdmin(MINTER_ROLE, MINTER_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
        _setupRole(MINTER_ROLE, owner());
        currentMinter = owner();
    }

    function grantRole(bytes32 role, address account) public virtual override revokable {
        AccessControl.grantRole(role, account);

        if(role == MINTER_ROLE) {
            AccessControl.revokeRole(role, currentMinter);
            currentMinter = account;
        }
    }

    function revokeRole(bytes32 role, address account) public virtual override {
        require(canRevoke, "AccessMinter: revoke not allowed!");
        AccessControl.revokeRole(role, account);
    }

    function changeMinter(address account) external returns (bool) {
        grantRole(MINTER_ROLE, account);
        return true;
    }

    function isMinter(address account) public view returns (bool) {
        return hasRole(MINTER_ROLE, account);
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
// OpenZeppelin Contracts v4.4.1 (utils/Timers.sol)

pragma solidity ^0.8.0;

/**
 * @dev Tooling for timepoints, timers and delays
 */
library Timers {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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