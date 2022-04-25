/**
 *Submitted for verification at polygonscan.com on 2022-04-23
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// File: @openzeppelin/contracts/utils/Strings.sol

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

pragma solidity ^0.8.0;

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/access/AccessControl.sol

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
}

// File: contracts/interfaces/EBBERC721.sol

pragma solidity ^0.8.0;

interface BBERC721 is IERC721 {
    function burn(uint256) external;

    function validate(uint256) external view returns (bool);

    function isOwnerOfAll(address, uint256[] calldata)
        external
        view
        returns (bool);

    function getPoints(uint256) external returns (uint16);

    function getType(uint256) external returns (uint8);

    function getParts(uint256) external returns (uint8[4] memory);
}

// File: contracts/libraries/nftBridge.sol

pragma solidity ^0.8.0;

library NFTBridgeLibrary {
    struct LimboRequest {
        address fromContract;
        address sender;
        uint256 id;
        uint256[] nfts;
    }

    struct ReleaseFromLimbo {
        address fromContract;
        address sender;
        uint256[] nfts;
    }

    struct StorageData {
        bool open;
        uint8 maxNFTs;
        uint256 feePerNFT;
    }

    struct SavedMinted {
        address nft;
        address owner;
        uint256[] nfts;
    }

    struct expropiateMany {
        address nft;
        address owner;
        uint256[] nfts;
    }
}

// File: contracts/interfaces/IAgregatorV3.sol

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File: contracts/nftBridgeStorageChainLink.sol

pragma solidity ^0.8.0;

contract NFTBridgeStorageChainLinked is Context, AccessControl {
    struct AgregatorData {
        uint8 decimals;
        uint80 roundId;
        uint256 price;
        uint256 feePerNFT;
    }

    event LimboRequest(NFTBridgeLibrary.LimboRequest);
    event ReleaseFromLimbo(NFTBridgeLibrary.ReleaseFromLimbo);
    event UpdateConfiguration(bool, uint8, uint256);
    event SaveMinted(NFTBridgeLibrary.SavedMinted);

    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    string public constant INVALID_REQUEST = "TC: Invalid request";
    string public constant INVALID_STATUS = "TC: Invalid status";
    string public constant INVALID_NFT_QUANTITY = "TC: Invalid quantity";
    string public constant INVALID_FEE = "TC: Invalid fee";
    string public constant INVALID_VALIDATOR = "TC: Invalid validator";
    string public constant INVALID_INITIAL_NET = "TC: Invalid initial network";
    string public constant INVALID_DESTINY_NET = "TC: Invalid destiny network";
    string public constant INVALID_CONTRACT = "TC: Invalid contract";
    string public constant INVALID_NFT_OWNER = "TC: Invalid owner";
    string public constant INVALID_LIMBO_NFT = "TC: Invalid limbo nft";
    string public constant LOCKED_ADDRESS = "TC: Locked address, wait please.";
    string public constant INVALID_LINK_ROUND = "TC: Invalid round.";

    bool public open = false;
    uint8 public maxNFTs = 10;

    address public creator;

    uint256 public invFee = 500000000000000000;
    uint256 public counter = 1;
    uint256 public unreleasedCounter = 1;
    uint256 public maxDataFeedsTime = 1800;

    AggregatorV3Interface internal priceFeed;

    mapping(address => bool) private contracts; // contract => validation
    mapping(address => mapping(address => uint256[])) private limboNFTs; //Contract => owner => nfts
    mapping(address => mapping(uint256 => address)) private limbo; //Contract => nft => owner
    mapping(address => mapping(uint256 => bool)) private locked; // Contract => nft => locked
    mapping(address => mapping(uint256 => address)) private minted; // Contract => nft => owner

    modifier isOpen() {
        require(open, INVALID_STATUS);
        _;
    }

    constructor() {
        _setupRole(ROLE_ADMIN, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        creator = _msgSender();
    }

    function updatePriceFeedsProxy(address _proxy)
        external
        onlyRole(ROLE_ADMIN)
    {
        priceFeed = AggregatorV3Interface(_proxy);
    }

    function updateMaxDataFeedsTime(uint256 _time)
        external
        onlyRole(ROLE_ADMIN)
    {
        maxDataFeedsTime = _time;
    }

    function getLatestData() external view returns (AgregatorData memory) {
        (uint80 roundId, int256 price, , , ) = priceFeed.latestRoundData();

        uint256 weiPrice = uint256(price) * 10**(18 - priceFeed.decimals());

        return
            AgregatorData(
                priceFeed.decimals(),
                roundId,
                weiPrice,
                invFee / weiPrice
            );
    }

    function getRoundPrice(uint80 _id) external view returns (uint256) {
        (, int256 price, , , ) = priceFeed.getRoundData(_id);
        return uint256(price) * 10**(18 - priceFeed.decimals());
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) * 10**(18 - priceFeed.decimals());
    }

    function isValidRound(uint80 _id) public view returns (bool) {
        (, , uint256 startedAt, , ) = priceFeed.getRoundData(_id);
        return block.timestamp - maxDataFeedsTime <= startedAt;
    }

    function getLatestPricePerNFT() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return invFee / (uint256(price) * 10**(18 - priceFeed.decimals()));
    }

    function getRoundPricePerNFT(uint80 _id) public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.getRoundData(_id);
        return invFee / (uint256(price) * 10**(18 - priceFeed.decimals()));
    }

    function getRoundPrice(uint80 _id, uint256 _nfts)
        public
        view
        returns (uint256)
    {
        return getRoundPricePerNFT(_id) * _nfts;
    }

    function updateConfiguration(
        bool _open,
        uint8 _maxNFTs,
        uint256 _invFee
    ) public onlyRole(ROLE_ADMIN) {
        open = _open;
        maxNFTs = _maxNFTs;
        invFee = _invFee;

        emit UpdateConfiguration(open, maxNFTs, invFee);
    }

    function changeContractState(address _nft, bool _valid)
        public
        onlyRole(ROLE_ADMIN)
    {
        contracts[_nft] = _valid;
    }

    function isValidContract(address _contract) public view returns (bool) {
        return contracts[_contract];
    }

    function getBridgeData()
        public
        view
        returns (NFTBridgeLibrary.StorageData memory)
    {
        return NFTBridgeLibrary.StorageData(open, maxNFTs, invFee);
    }

    function inLimbo(
        address _contract,
        address _owner,
        uint256 _id
    ) public view returns (bool) {
        return limbo[_contract][_id] == _owner;
    }

    function isLocked(address _contract, uint256 _nft)
        public
        view
        returns (bool)
    {
        return locked[_contract][_nft];
    }

    function getOriginalOwner(address _contract, uint256 _id)
        public
        view
        returns (address)
    {
        return limbo[_contract][_id];
    }

    function isOwnerOfAll(
        address _contract,
        address _owner,
        uint256[] memory _ids
    ) public view returns (bool) {
        bool isValid = true;

        for (uint256 i = 0; i < _ids.length; i++) {
            if (
                limbo[_contract][_ids[i]] != _owner ||
                locked[_contract][_ids[i]]
            ) {
                isValid = false;
            }
        }

        return isValid;
    }

    function allAreInLimbo(
        address _contract,
        address _owner,
        uint256[] memory _ids
    ) public view returns (bool) {
        bool allAreInTheLimbo = true;
        for (uint256 i = 0; i < _ids.length; i++) {
            if (
                limbo[_contract][_ids[i]] != _owner ||
                BBERC721(_contract).ownerOf(_ids[i]) != address(this)
            ) {
                return false;
            }
        }
        return allAreInTheLimbo;
    }

    function getLimboNFTs(address _contract, address _owner)
        public
        view
        returns (uint256[] memory)
    {
        return limboNFTs[_contract][_owner];
    }

    function lockMany(address _contract, uint256[] memory _nfts)
        public
        onlyRole(ROLE_ADMIN)
    {
        require(isValidContract(_contract), INVALID_CONTRACT);

        for (uint256 i = 0; i < _nfts.length; i++) {
            locked[_contract][_nfts[i]] = true;
        }
    }

    function unlockMany(address _contract, uint256[] memory _nfts)
        public
        onlyRole(ROLE_ADMIN)
    {
        require(isValidContract(_contract), INVALID_CONTRACT);

        for (uint256 i = 0; i < _nfts.length; i++) {
            locked[_contract][_nfts[i]] = false;
        }
    }

    function createLimboRequestWithMany(
        address _contract,
        uint80 _roundId,
        uint256[] memory _ids
    ) public payable isOpen {
        require(isValidRound(_roundId), INVALID_LINK_ROUND);
        require(isValidContract(_contract), INVALID_CONTRACT);
        require(_ids.length <= maxNFTs, INVALID_NFT_QUANTITY);
        require(msg.value == getRoundPrice(_roundId, _ids.length), INVALID_FEE);

        for (uint256 i = 0; i < _ids.length; i++) {
            BBERC721(_contract).transferFrom(
                _msgSender(),
                address(this),
                _ids[i]
            );

            limboNFTs[_contract][_msgSender()].push(_ids[i]);
            limbo[_contract][_ids[i]] = _msgSender();

            counter++;
        }

        emit LimboRequest(
            NFTBridgeLibrary.LimboRequest(
                _contract,
                _msgSender(),
                counter,
                _ids
            )
        );
    }

    function releaseManyFromLimbo(
        address _contract,
        address _owner,
        uint256[] memory _ids
    ) public onlyRole(ROLE_ADMIN) isOpen {
        require(isValidContract(_contract), INVALID_CONTRACT);
        require(_ids.length <= maxNFTs, INVALID_NFT_QUANTITY);

        for (uint256 i = 0; i < _ids.length; i++) {
            require(limbo[_contract][_ids[i]] == _owner, INVALID_LIMBO_NFT);

            limbo[_contract][_ids[i]] = address(0);
            BBERC721(_contract).burn(_ids[i]);
            releaseNFTFromLimbo(_contract, _owner, _ids[i]);

            unreleasedCounter++;
        }

        emit ReleaseFromLimbo(
            NFTBridgeLibrary.ReleaseFromLimbo(_contract, _msgSender(), _ids)
        );
    }

    function manyMinted(
        address _contract,
        address _owner,
        uint256[] memory _nfts
    ) public onlyRole(ROLE_ADMIN) {
        require(isValidContract(_contract), INVALID_CONTRACT);

        for (uint256 i = 0; i < _nfts.length; i++) {
            require(
                BBERC721(_contract).ownerOf(_nfts[i]) == address(this),
                INVALID_NFT_OWNER
            );

            minted[_contract][_nfts[i]] = _owner;
        }

        emit SaveMinted(NFTBridgeLibrary.SavedMinted(_contract, _owner, _nfts));
    }

    function expropiateMany(
        address _contract,
        address _owner,
        uint256[] memory _nfts
    ) public onlyRole(ROLE_ADMIN) {
        for (uint256 i = 0; i < _nfts.length; i++) {
            require(
                BBERC721(_contract).ownerOf(_nfts[i]) == address(this),
                INVALID_NFT_OWNER
            );

            BBERC721(_contract).transferFrom(
                address(this),
                minted[_contract][_nfts[i]],
                _nfts[i]
            );

            minted[_contract][_nfts[i]] = address(0);
        }

        emit SaveMinted(NFTBridgeLibrary.SavedMinted(_contract, _owner, _nfts));
    }

    function releaseNFTFromLimbo(
        address _contract,
        address _owner,
        uint256 _id
    ) private {
        for (uint256 j = 0; j < limboNFTs[_contract][_owner].length; j++) {
            if (limboNFTs[_contract][_owner][j] == _id) {
                limboNFTs[_contract][_owner][j] = limboNFTs[_contract][_owner][
                    limboNFTs[_contract][_owner].length - 1
                ];

                limboNFTs[_contract][_owner].pop();
                break;
            }
        }
    }

    function withdrawFees() public onlyRole(ROLE_ADMIN) {
        payable(_msgSender()).transfer(address(this).balance);
    }
}