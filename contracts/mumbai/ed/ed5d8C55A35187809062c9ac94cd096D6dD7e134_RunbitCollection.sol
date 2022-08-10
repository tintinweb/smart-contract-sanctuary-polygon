// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IRunbit.sol";

contract RunbitCollection is AccessControl {
    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGE_ROLE, admin);
        oracle = IDataFeed(0xF9680D99D6C9589e2a93a78A04A279e509205945);
    }

    struct CardCollection {
        uint64 startId;
        uint64 stock;  // 库存
        uint64 sales;  // 销量
        uint64 price0; // 兑换价格
        uint112 price1; // RB 价格
        uint48 adjust1;
        uint48 adjust2;
        uint48 adjust3;
        uint64 baseSpecialty;
        uint64 baseComfort;
        uint64 baseAesthetic;
        uint32 durability;
        uint16 level;
        uint16 status; //0 不可购买及兑换 1 可购买 2 可兑换 3 可购且可兑换
    }

    struct EquipCollection {
        uint64 startId;
        uint64 stock;
        uint64 sales;
        uint32 level;
        uint16 equipType;
        uint8 status; // 可升级获取 | 可兑换 | 可购买
        uint8 upgradeable;
        uint32 capacity;
        uint48 quality;
        uint64 price0; // 兑换价格
        uint112 price1; // RB 价格
    }

    string cardBaseURI;
    string equipBaseURI;
    IRefStore refs;
    IERC20Burnable RB;
    IDataFeed oracle;
    // can exchange card
    IERC20Burnable cardToken;
    // can exchange equipment
    IERC20Burnable equipToken;
    IRunbitCard NFTCard;
    IRunbitEquip NFTEquip;
    uint256 cardCollectCount;
    uint256 equipCollectCount;
    // cardCollections[collectionId] = collection
    mapping(uint256 => CardCollection) cardCollections;
    // equipCollections[collectionId] = collection
    mapping(uint256 => EquipCollection) equipCollections;
    // forgeNum[equipType][level] = num
    // 当前等级的升级备选collection数量
    mapping(uint256 => mapping(uint256 => uint256)) forgeNum;
    // forgeEquips[equipType][level][index] = collectionId;
    // 当前等级升级的备选collection
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) forgeEquips;
    // forgeFee[equipType][level] = fee
    mapping(uint256 => mapping(uint256 => uint256)) forgeFee;

    modifier onlyReferral {
        require(refs.referrer(msg.sender) != address(0), "Not activated!");
        _;
    }

    function _mintCard(uint256 collectionId) internal {
        CardCollection storage cc = cardCollections[collectionId];
        IRunbitCard.MetaData memory meta;
        uint256 rand = uint256(keccak256(abi.encodePacked(block.coinbase, gasleft(), block.timestamp, blockhash(block.number - 1), oracle.latestAnswer())));
        meta.specialty = uint64(cc.baseSpecialty + (rand & 0xffffffffffffffffffff) % cc.adjust1);
        meta.comfort = uint64(cc.baseComfort + ((rand >> 80) & 0xffffffffffffffffffff) % cc.adjust2);
        meta.aesthetic = uint64(cc.baseAesthetic + ((rand >> 160) & 0xffffffffffffffffffff) % cc.adjust3);
        meta.durability = cc.durability;
        meta.level = cc.level;
        uint256 tokenId = cc.startId + cc.sales;
        string memory uri = string.concat(cardBaseURI, Strings.toString(tokenId), ".png");
        NFTCard.safeMint(msg.sender, tokenId, uri, meta);
        cc.sales += 1;
        emit NFTCardMint(msg.sender, tokenId, collectionId, uri, meta);
    }

    function _mintEquip(uint256 collectionId) internal {
        EquipCollection storage ec = equipCollections[collectionId];
        IRunbitEquip.MetaData memory meta;
        meta.level = ec.level;
        meta.capacity = ec.capacity;
        meta.equipType = ec.equipType;
        meta.quality = ec.quality;
        meta.upgradeable = ec.upgradeable;
        uint256 tokenId = ec.startId + ec.sales;
        string memory uri = string.concat(equipBaseURI, Strings.toString(tokenId), ".png");
        NFTEquip.safeMint(msg.sender, tokenId, uri, meta);
        ec.sales += 1;
        emit NFTEquipMint(msg.sender, tokenId, collectionId, uri, meta);
    }

    function buyCard(uint256 collectionId) external onlyReferral {
        require(collectionId < cardCollectCount, "This Card Collection does not exist!");
        CardCollection memory cc = cardCollections[collectionId];
        require((cc.status & 1) == 1 && cc.sales < cc.stock, "This Card Collection is Out of Stock");
        // burn
        RB.burnFrom(msg.sender, cc.price1);
        // mint
        _mintCard(collectionId);
        emit NFTCardBuy(msg.sender, collectionId, cc.price1);
    }

    function buyEquip(uint256 collectionId) external onlyReferral {
        require(collectionId < equipCollectCount, "This Equip Collection does not exist!");
        EquipCollection memory ec = equipCollections[collectionId];
        require((ec.status & 1) == 1 && ec.sales < ec.stock, "This Card Collection is Out of Stock");
        // burn
        RB.burnFrom(msg.sender, ec.price1);
        // mint
        _mintEquip(collectionId);
        emit NFTEquipBuy(msg.sender, collectionId, ec.price1);
    }
    
    // 兑换属性卡
    function redeemCard(uint256 collectionId) external onlyReferral {
        require(collectionId < cardCollectCount, "This Card Collection does not exist!");
        CardCollection memory cc = cardCollections[collectionId];
        require((cc.status & 2) == 2 && cc.sales < cc.stock, "This Card Collection is Out of Stock");
        // burn
        cardToken.burnFrom(msg.sender, cc.price0);
        // mint
        _mintCard(collectionId);
        emit NFTCardRedeem(msg.sender, collectionId, cc.price0);
    }

    // 兑换装备
    function redeemEquip(uint256 collectionId) external onlyReferral {
        require(collectionId < cardCollectCount, "This Card Collection does not exist!");
        EquipCollection memory ec = equipCollections[collectionId];
        require((ec.status & 2) == 2 && ec.sales < ec.stock, "This Card Collection is Out of Stock");
        // burn
        equipToken.burnFrom(msg.sender, ec.price0);
        // mint
        _mintEquip(collectionId);
        emit NFTEquipRedeem(msg.sender, collectionId, ec.price0);
    }

    // 合成装备
    // 前端检查装备今日是否已使用
    function forgeEquip(uint256 equipId1, uint256 equipId2) external onlyReferral {
        require(NFTEquip.ownerOf(equipId1) == msg.sender, "not owner!");
        require(NFTEquip.ownerOf(equipId2) == msg.sender, "not owner!");
        
        IRunbitEquip.MetaData memory equip1 = NFTEquip.tokenMeta(equipId1);
        IRunbitEquip.MetaData memory equip2 = NFTEquip.tokenMeta(equipId2);
        
        require(equip1.level == equip2.level, "level is unequally!");
        require(equip1.equipType == equip2.equipType, "type is unequally!");
        require(equip1.upgradeable > 0 && equip2.upgradeable > 0, "not upgradeable!");

        uint256 num = forgeNum[equip1.equipType][equip1.level];
        require(num > 0, "can not upgrade!");
        uint256 rand = uint256(keccak256(abi.encodePacked(block.coinbase, gasleft(), block.timestamp, blockhash(block.number - 1), oracle.latestAnswer())));
        uint256 idx = rand % num;
        uint256 cid = forgeEquips[equip1.equipType][equip1.level][idx];
        uint256 lasti = num;
        for(uint i = idx; i < num; ++i) {
            EquipCollection memory ec = equipCollections[cid];
            if(ec.sales < ec.stock && (ec.status & 4) == 4 ) {
                break;
            }
            cid = forgeEquips[equip1.equipType][equip1.level][lasti-1];
            forgeEquips[equip1.equipType][equip1.level][idx] = cid;
            lasti -= 1;
        }
        if(lasti == idx) {
            cid = forgeEquips[equip1.equipType][equip1.level][0];
            for(uint i = 0; i < idx; ++i) {
                EquipCollection memory ec = equipCollections[cid];
                if(ec.sales < ec.stock && (ec.status & 4) == 4 ) {
                    break;
                }
                cid = forgeEquips[equip1.equipType][equip1.level][lasti-1];
                forgeEquips[equip1.equipType][equip1.level][0] = cid;
                lasti -= 1;
            }
        }
        require(lasti > 0, "not avalibale!");
        if (lasti != num) {
            forgeNum[equip1.equipType][equip1.level] = lasti;
        }

        uint256 fee = forgeFee[equip1.equipType][equip1.level];
        // burn
        RB.burnFrom(msg.sender, fee);
        NFTEquip.burn(equipId1);
        NFTEquip.burn(equipId2);
        // mint
        _mintEquip(cid);
        emit NFTEquipForge(msg.sender, cid, equipId1, equipId2, fee);
    }

    // 添加属性卡
    function addCardCollection(CardCollection memory colection) external onlyRole(MANAGE_ROLE) {
        cardCollections[cardCollectCount] = colection;
        emit CardCollectionAdd(cardCollectCount, colection);
        cardCollectCount += 1;
    }

    // 添加装备
    function addEquipCollection(EquipCollection memory ec) external onlyRole(MANAGE_ROLE) {
        equipCollections[equipCollectCount] = ec;
        // 添加到升级装备备选池
        if ((ec.status & 4) == 4) {
            uint256 num = forgeNum[ec.equipType][ec.level];
            forgeEquips[ec.equipType][ec.level][num] = equipCollectCount;
            forgeNum[ec.equipType][ec.level] += 1;
        }
        emit EquipCollectionAdd(equipCollectCount, ec);
        equipCollectCount += 1;
    }

    function setForgeFee(uint256 equipType, uint256 level, uint256 fee) external onlyRole(MANAGE_ROLE) {
        forgeFee[equipType][level] = fee;
    }

    function editCardCollection(uint256 collectionId, uint256 price0, uint256 price1, uint256 status) external onlyRole(MANAGE_ROLE) {
        cardCollections[collectionId].price0 = uint64(price0);
        cardCollections[collectionId].price1 = uint112(price1);
        cardCollections[collectionId].status = uint16(status);
    }

    function editEquipCollection(uint256 collectionId, uint256 price0, uint256 price1, uint256 status) external onlyRole(MANAGE_ROLE) {
        equipCollections[collectionId].price0 = uint64(price0);
        equipCollections[collectionId].price1 = uint112(price1);
        equipCollections[collectionId].status = uint8(status);
    }

    function setCardBaseURI(string memory baseURI) external onlyRole(MANAGE_ROLE) {
        cardBaseURI = baseURI;
    }

    function setEquipBaseURI(string memory baseURI) external onlyRole(MANAGE_ROLE) {
        equipBaseURI = baseURI;
    }

    function setRefs(address _refs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        refs = IRefStore(_refs);
    }

    function setRB(address _rb) external onlyRole(DEFAULT_ADMIN_ROLE) {
        RB = IERC20Burnable(_rb);
    }

    function setOracle(address _oracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        oracle = IDataFeed(_oracle);
    }

    function setCardToken(address _cardToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cardToken = IERC20Burnable(_cardToken);
    }

    function setEquipToken(address _equipToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        equipToken = IERC20Burnable(_equipToken);
    }

    function setCardFactory(address _factory) external onlyRole(DEFAULT_ADMIN_ROLE) {
        NFTCard = IRunbitCard(_factory);
    }

    function setEquipFactory(address _factory) external onlyRole(DEFAULT_ADMIN_ROLE) {
        NFTEquip = IRunbitEquip(_factory);
    }

    function getCardCollection(uint256 collectionId) external view returns (CardCollection memory cc) {
        cc = cardCollections[collectionId];
    }

    function getEquipCollection(uint256 collectionId) external view returns (EquipCollection memory ec) {
        ec = equipCollections[collectionId];
    }

    function getForgeFee(uint256 equipType, uint256 level) external view returns (uint256) {
        return forgeFee[equipType][level];
    }

    function getCardCollectCount() external view returns (uint256) {
        return cardCollectCount;
    }

    function getEquipCollectCount() external view returns (uint256) {
        return equipCollectCount;
    }

    event NFTCardMint(address indexed to, uint256 indexed tokenId, uint256 collectionId, string uri, IRunbitCard.MetaData meta);
    event NFTCardBuy(address indexed buyer, uint256 indexed collectionId, uint256 price);
    event NFTCardRedeem(address indexed buyer, uint256 indexed collectionId, uint256 price);
    event NFTEquipMint(address indexed to, uint256 indexed tokenId, uint256 collectionId, string uri, IRunbitEquip.MetaData meta);
    event NFTEquipBuy(address indexed buyer, uint256 indexed collectionId, uint256 price);
    event NFTEquipRedeem(address indexed buyer, uint256 indexed collectionId, uint256 price);
    event CardCollectionAdd(uint256 indexed collectionId, CardCollection cc);
    event EquipCollectionAdd(uint256 indexed collectionId, EquipCollection cc);
    event NFTEquipForge(address indexed user, uint256 collectionId, uint256 equipId1, uint256 equipId2, uint256 fee);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
pragma solidity ^0.8.14;

interface IRefStore {
    /// referrer
    function referrer(address from) external view returns (address);
    /// add referrer
    function addReferrer(address from, address to) external;
    /// referrer added
    event ReferrerAdded(address indexed to, address from);
}

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}

interface IDataFeed {
    function latestAnswer()  external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}

interface IRunbitRand {
    function getRand(uint256 round) external view returns (uint256);
}

interface IRunbitCard is IERC721 {
    struct MetaData {
        uint64 specialty;
        uint64 comfort;
        uint64 aesthetic;
        uint32 durability;
        uint32 level;
    }

    function safeMint(address to, uint256 tokenId, string memory uri, MetaData memory metaData) external;
    function tokenMeta(uint256 tokenId) external view returns (MetaData memory);
    function burn(uint256 tokenId) external;
}

interface IRunbitEquip is IERC721 {
    struct MetaData {
        uint32 equipType;
        uint32 upgradeable;
        uint64 level;
        uint64 capacity;
        uint64 quality;
    }

    function safeMint(address to, uint256 tokenId, string memory uri, MetaData memory metaData) external;
    function tokenMeta(uint256 tokenId) external view returns (MetaData memory);
    function burn(uint256 tokenId) external;
}

interface IStepCheck {
    function stepCheck(uint256 checkSum, address user) external view returns (uint256);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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