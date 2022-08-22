// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721TokenDescriptor.sol";
import "./IBattleRecord.sol";
import './NFTSVGV2.sol';
import './NFTSVGGekkeiju.sol';
import './NFTSVGDragonNameV2.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import 'base64-sol/base64.sol';

contract MCSTokenDescriptorV2 is IERC721TokenDescriptor, AccessControl {
    using Strings for uint256;

    struct ConstructTokenURIParams {
        uint256 tokenId;
        uint8 cupType;
        string name;
        uint256 entries;
        string date;
        uint256 rank;
        address userAddress;
        uint256 userId;
        address owner;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public _battleRecord;

    constructor(address battleRecord_) {
        _setRoleAdmin(MINTER_ROLE, MINTER_ROLE);
        _setupRole(MINTER_ROLE, _msgSender());
        setBattleRecord(battleRecord_);
    }

    function setBattleRecord(address battleRecord_) public onlyRole(MINTER_ROLE) {
        _battleRecord = battleRecord_;
    }

    function generateName(ConstructTokenURIParams memory params) private pure returns (string memory) {
        string memory dragonName = "";
        if(params.cupType == 1){
             dragonName ="Red Dragon";
        }else if(params.cupType == 2){
             dragonName ="Blue Dragon";
        }else if(params.cupType == 3){
             dragonName ="Baby Dragon";
        }else if(params.cupType == 4){
             dragonName ="Dragon Egg";
        }else if(params.cupType == 5){
             dragonName ="King Dragon";
        }

        return
            string(
                abi.encodePacked(
                    dragonName,
                    " TrophyCard"
                )
            );
    }

    function generateDescription(ConstructTokenURIParams memory params) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "You are the winner of ",
                    params.name,
                    " on ",
                    params.date,
                    "."
                )
            );
    }

    function generateSVGImage(ConstructTokenURIParams memory params) private pure returns (string memory) {
        NFTSVGV2.SVGParams memory svgParams =
            NFTSVGV2.SVGParams({
                tokenId: params.tokenId,
                cupType: params.cupType,
                dragonNameSVG: NFTSVGDragonNameV2.generateDragonSVG(params.cupType),
                name: params.name,
                entries: params.entries,
                date: params.date,
                rank: params.rank,
                userAddress: params.userAddress,
                userId: params.userId,
                owner: params.owner,
                gekkeijuSVG: NFTSVGGekkeiju.generateGekkeijuSVG(params.cupType)
            });

        return NFTSVGV2.generateSVG(svgParams);
    }

    function constructTokenURI(ConstructTokenURIParams memory params) private pure returns (string memory) {
        string memory name = generateName(params);
        string memory description = generateDescription(params);
        string memory image = Base64.encode(bytes(generateSVGImage(params)));

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function trophyDatas(uint256 tokenId)
    public 
    view
    returns (
        uint8 cupType, 
        string memory name, 
        uint entries, 
        string memory date, 
        uint rank, 
        address userAddress, 
        uint256 userId
    ) {
        uint competitionId = tokenId / 10000;
        uint recordId = tokenId % 10000;

        (cupType, name, entries, date) = IBattleRecord(_battleRecord).getCompetetion(competitionId);
        (rank, userAddress, userId) = IBattleRecord(_battleRecord).getRecord(competitionId, recordId);
    }

    function tokenURI(IERC721 token, uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        (
            uint8 cupType, 
            string memory name, 
            uint entries, 
            string memory date, 
            uint256 rank,
            address userAddress, 
            uint256 userId
        ) = trophyDatas(tokenId);

        address owner = token.ownerOf(tokenId);

        return
            constructTokenURI(
                ConstructTokenURIParams({
                    tokenId: tokenId,
                    cupType: cupType,
                    name: name,
                    entries: entries,
                    date: date,
                    rank: rank,
                    userAddress: userAddress,
                    userId: userId,
                    owner: owner
                })
            );
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721TokenDescriptor {
    function tokenURI(IERC721 token, uint256 tokenId)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBattleRecord {

    function getCompetetion(
        uint _competitionId
    ) external view returns(
        uint8,
        string memory,
        uint,
        string memory 
    );
    function getRecord(
        uint _competitionId, uint _recordId
    ) external view returns(
        uint, address, uint
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import './Address.sol';
import './lib/SVGPath.sol';

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a Uniswap NFT
library NFTSVGV2 {
    using Strings for uint256;
    using Address for address;

    struct SVGParams {
        uint256 tokenId;
        uint8 cupType;
        string dragonNameSVG;
        string name;
        uint256 entries;
        string date;
        uint256 rank;
        address userAddress;
        uint256 userId;
        address owner;
        string gekkeijuSVG;
    }

    function generateSVG(SVGParams memory params) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    generateSVGHeader(),
                    '<defs>',
                    generateStyle(params.cupType),
                    generateLinearGradient(),
                    '</defs>',
                    generateSVGPath(params.dragonNameSVG, params.gekkeijuSVG),
                    generateSVGText(params),
                    '</svg>'
                )
            );
    }

    function generateSVGHeader() private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<svg width="500" height="736" viewBox="0 0 500 736" xmlns="http://www.w3.org/2000/svg"',
                " xmlns:xlink='http://www.w3.org/1999/xlink'>"
            )
        );
    }

    function getColor(uint8 cupType) private pure returns (string memory, string memory, string memory, string memory) {
        if(cupType == 1){
            return ("1a1a1a","b60b0b","b60b0b","cab96d");
        }else if(cupType == 2){
            return ("aaaeb2","1b1b1b","0c19df","a8a8a8");
        }else if(cupType == 3){
            return ("c5ab66","1b1b1b","008100","c5ac8a");
        }else if(cupType == 4){
            return ("4f2118","f4ba0b","f4ba0b","ca6d85");
        }else if(cupType == 5){
            return ("1a1a1a","b7a352","b99b3c","cab96d");
        }
        return ("","","","");
    }

    function generateStyle(uint8 cupType) private pure returns (string memory svg) {
        (string memory cardBase, string memory frame, string memory dragon, string memory light)
        = getColor(cupType);

        svg = string(
            abi.encodePacked(
                '<style>',
                '.cardBase{fill: #',
                cardBase,
                ';}.shine{fill-rule: evenodd;mix-blend-mode: overlay; width: 500px; height: 736px;}.frame{stroke: #',
                frame,
                ';}.logo{fill: #',
                frame,
                ';fill-rule; evenodd; font-family: Verdana;}.dragon{stop-color: #',
                dragon,
                ';}.light {fill: #',
                light,
                ';fill-rule: evenodd;mix-blend-mode: overlay;}.text{font-size: 23px;text-anchor: middle;fill: white; font-family: Helvetica;}.text2{font-size: 27px;text-anchor: middle;fill: white; font-family: Helvetica;}',
                '.textAddress{font-size: 14px;text-anchor: middle;fill: url(#address); font-family: Times New Roman;}.addressStop{stop-color: white;stop-opacity: 0;}',
                '</style>'
        )
        );
    }

    function generateSVGText(SVGParams memory params) private pure returns (string memory) {
        string memory nameLocation = '';
        string memory dateLocation = '';
        string memory rankLocation = '';
        string memory userIdLocation = '';

        if(params.cupType == 5){
            nameLocation = '<text x="50%" y="80%" class="text">';
            dateLocation = '</text><text x="50%" y="84%" class="text">';
            rankLocation = '</text><text x="50%" y="88%" class="text">';
            userIdLocation = '</text><text x="50%" y="93%" class="text">User ID : ';
        } else {
            nameLocation = '<text x="50%" y="76%" class="text">';
            dateLocation = '</text><text x="50%" y="80%" class="text">';
            rankLocation = '</text><text x="50%" y="84%" class="text">';
            userIdLocation = '</text><text x="50%" y="89%" class="text">User ID : ';
        }
        
        string memory svg0 = string(
            abi.encodePacked(
                nameLocation,
                params.name,
                dateLocation,
                params.date,
                rankLocation,
                params.rank.toString(),
                '/'
            )
        );

        string memory svg1 = string(
            abi.encodePacked(
                params.entries.toString(),
                userIdLocation,
                params.userId.toString(),
                '</text><text x="370" y="-484" textLength="520" class="textAddress" transform="rotate(90)" >',
                params.userAddress.toAsciiString(),
                '</text><text x="-370" y="16" textLength="520" class="textAddress" transform="rotate(-90)" >',
                params.owner.toAsciiString(),
                '</text>'
            )
        );
        
        return string(
            abi.encodePacked(svg0,svg1)
        );
    }

    function generateSVGPath(string memory dragonNameSVG, string memory gekkeijuSVG) private pure returns (string memory svg) {
        svg = SVGPath.getPath(dragonNameSVG, gekkeijuSVG);
    }

    function generateLinearGradient() private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<linearGradient id="shine" gradientTransform="rotate(320)"><stop offset="0.44" stop-color="white" stop-opacity="0" /><stop offset="0.6" stop-color="white" stop-opacity="0.8" /><stop offset="0.63" stop-color="white" stop-opacity="0" /></linearGradient>',
                '<linearGradient id="shine2" gradientTransform="rotate(40)" x1="0" x2="0" y1="0" y2="1"><stop offset="0.16" stop-color="white" stop-opacity="0" /><stop offset="0.4" stop-color="white" stop-opacity="0.5" /><stop offset="0.66" stop-color="white" stop-opacity="0" /></linearGradient>',
                '<linearGradient id="dragon"><stop offset="0" class="dragon" stop-opacity="0.7" /><stop offset="0.5" class="dragon" stop-opacity="1" /><stop offset="1" class="dragon" stop-opacity="0.7" /></linearGradient>',
                '<linearGradient id="dragoneye"><stop offset="0" stop-color="#fdf6e4" stop-opacity="1"><animate attributeName="stop-opacity" values="0;0;0.8;1;0.8;0" dur="9s" repeatCount="indefinite" /></stop></linearGradient>',
                '<linearGradient id="address"><stop offset="0" class="addressStop">',
                '<animate attributeName="stop-opacity" dur="9s" repeatCount="indefinite" begin="1.6s" values="0.1;0.2;0.4;0.7;1;1;1;1;0.8;0.6;0.3;0.1;0;0;0;0;0" />',
                '</stop><stop offset="0.25" class="addressStop"><animate attributeName="stop-opacity" dur="9s" repeatCount="indefinite" begin="1.6s" values="0;0.1;0.2;0.4;0.7;1;1;1;1;0.8;0.6;0.3;0.1;0;0;0;0" />',
                '</stop><stop offset="0.5" class="addressStop"><animate attributeName="stop-opacity" dur="9s" repeatCount="indefinite" begin="1.6s" values="0;0;0.1;0.2;0.4;0.7;1;1;1;1;0.8;0.6;0.3;0.1;0;0;0" />',
                '</stop><stop offset="0.75" class="addressStop"><animate attributeName="stop-opacity" dur="9s" repeatCount="indefinite" begin="1.6s" values="0;0;0;0.1;0.2;0.4;0.7;1;1;1;1;0.8;0.6;0.3;0.1;0;0" />',
                '</stop><stop offset="1" class="addressStop"><animate attributeName="stop-opacity" dur="9s" repeatCount="indefinite" begin="1.6s" values="0;0;0;0;0.1;0.2;0.4;0.7;1;1;1;1;0.8;0.6;0.3;0.1;0" />',
                '</stop></linearGradient>'
        )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';
import './LeftGekkeiju.sol';
import './RightGekkeiju.sol';

library NFTSVGGekkeiju {
    using Strings for uint256;

    function generateGekkeijuSVG(uint8 cupType) external pure returns (string memory) {
        if(cupType == 5){
            return string(abi.encodePacked(LeftGekkeiju.leftGekkeijuSVG(), RightGekkeiju.rightGekkeijuSVG()));
        }else {
            return "";
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';
import './lib/Cuptype1.sol';
import './lib/Cuptype2.sol';
import './lib/Cuptype3.sol';
import './lib/Cuptype4.sol';
import './lib/Cuptype5.sol';

library NFTSVGDragonNameV2 {
    using Strings for uint256;

    function generateDragonSVG(uint8 cupType) external pure returns (string memory) {
        if(cupType == 1){
            return Cuptype1.getPath();
        }else if(cupType == 2){
            return Cuptype2.getPath();
        }else if(cupType == 3){
            return Cuptype3.getPath();
        }else if(cupType == 4){
            return Cuptype4.getPath();
        }else if(cupType == 5){
            return Cuptype5.getPath();
        }
        return "";
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
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
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
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
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

library Address {

    function toAsciiString(address account) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(account)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }

        return string(
            abi.encodePacked(
                '0x',
                string(s)
        )
        );
    }

    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

library SVGPath {
    using Strings for uint256;

    function getPath(string memory dragonNameSVG, string memory gekkeijuSVG) external pure returns (string memory) {
        return string(
                    abi.encodePacked(
                        '<rect class="cardBase" width="500" height="736" rx="53.832" ry="53.832"/>',
                        '<rect fill="url(#shine)" class="shine" /><rect fill="url(#shine2)" class="shine" />',
                        '<path class="light" d="M53.832,0H446.168A53.691,53.691,0,0,1,486.06,17.688L17.864,722.212A53.688,53.688,0,0,1,0,682.168V53.832A53.832,53.832,0,0,1,53.832,0Z"/>',
                        '<path class="logo" d="M46.89,70.138h9.619V23.482H48.964q-1.555,1.613-8.467,5.184v7.142a16.775,16.775,0,0,1,1.613-.749q0.979-.4,1.44-0.576,2.707-1.152,3.341-1.5V70.138Z" />',
                        '<path class="frame" fill="none" stroke-width="6px" fill-rule="evenodd" d="M424.516,713H75.832A53.832,53.832,0,0,1,22,659.168V99.438H46.168A53.832,53.832,0,0,0,100,45.606V24H424.516a53.832,53.832,0,0,1,53.832,53.832V659.168A53.831,53.831,0,0,1,424.516,713Z" />',
                        dragonNameSVG,
                        gekkeijuSVG,
                        '<path class="logo" d="M190.563,196.762h7.584l3.12-23.472,3.312,23.472h7.488l4.656-38.88h-7.2l-2.352,22.512L204.1,157.93h-5.712l-2.928,22.608-2.3-22.656h-7.3Zm28.7-32.448h7.872V158.89h-7.872v5.424Zm0.048,32.448h7.824V169.018h-7.824v27.744Zm11.472,0h7.824v-21.7a4.76,4.76,0,0,1,2.448-1.008,1.4,1.4,0,0,1,1.224.5,2.705,2.705,0,0,1,.36,1.56v20.64h7.776V175.018a7.721,7.721,0,0,0-1.32-4.68,4.441,4.441,0,0,0-3.816-1.8q-3.408,0-6.672,3.264v-2.784h-7.824v27.744Zm23.136,0h7.824v-21.7a4.754,4.754,0,0,1,2.448-1.008,1.4,1.4,0,0,1,1.224.5,2.705,2.705,0,0,1,.36,1.56v20.64h7.776V175.018a7.728,7.728,0,0,0-1.32-4.68,4.444,4.444,0,0,0-3.816-1.8q-3.41,0-6.672,3.264v-2.784h-7.824v27.744Zm32.207,0.48a9.863,9.863,0,0,0,6.792-2.16q2.423-2.16,2.424-6.336v-2.688h-7.2v2.928q0,2.688-2.016,2.688-1.92,0-1.92-2.976V183.37h11.136V177.8q0-4.56-2.3-6.912t-6.912-2.352a9.882,9.882,0,0,0-7.1,2.424,8.994,8.994,0,0,0-2.544,6.84v10.176a8.994,8.994,0,0,0,2.544,6.84,9.882,9.882,0,0,0,7.1,2.424h0Zm-1.92-17.52V177.37a4.862,4.862,0,0,1,.48-2.544,1.569,1.569,0,0,1,1.392-.72,1.881,1.881,0,0,1,1.512.648,3.388,3.388,0,0,1,.552,2.184v2.784h-3.936Zm14.3,17.04h7.824V178.714q2.064-2.688,4.608-2.688a6.986,6.986,0,0,1,2.544.576v-7.776a4.852,4.852,0,0,0-4.368,1.056,14.885,14.885,0,0,0-2.784,3.744v-4.608h-7.824v27.744Z" />',
                        '<path fill="url(#dragon)" fill-rule="evenodd" d="M169,315v6l-7,10-9-5-3-11,3-9,7-1-3-2-6,1-4,10,4,14,12,7,7-8,3-7v-3l-2-3Zm-15,5-1,1,1,4,4,1,2-3Zm-10,1,2-1,2,7,2,3-5,2-1-4v-7Zm13-14-4,5v6h5v-4l3-2v-2Zm-9-3h2l-4,7-1,6-2-1v-5Zm13-5-1,3,6,10h2l3-1-1-2-2-7h1l-1-2Zm69,29,2,8h3l2-6S231.391,327.268,230,328Zm-5-11,4,9s4.25-6.124,6-6a36.141,36.141,0,0,0-4-4Zm-27,20-1,7h19l3-7h-2l-1,3-5-3-1,3-6,1-3-4h-3Zm-59-15h-9l-1,3,3,3v5l4,1,1,1,6-2S137.092,326.943,139,322Zm10-31-9,2-5,10v2s6.582,1.578,7,4c1.212-2.243,6.886-11.319,11-11C152.449,296.73,149,291,149,291Zm5-2,2,9s14.028-3.1,15-1c0.454-3.079-2-11-2-11S156.135,287.9,154,289Zm18-3s0.669,8.868,1,12c3.048-.491,14,0,14,0s-1.059-11.383-3-13C182.382,285.065,172,286,172,286Zm18,13h8v3l-5,6-5-3Zm15-4-4,5,2,3,4-2v-5Zm-12-3-3,5s10.666-1.592,11,0a44.11,44.11,0,0,0,4-3v-2H193Zm39-70-3,12-3-5-3,3a58.465,58.465,0,0,0,4,6c-1.71,7.6-7,16-7,16s-3.959-8.967-5-8-2,2-2,2l3,12s-0.571,3.76-1,4a11.445,11.445,0,0,1,7,2c0-3.24,6-18,6-18l6-15,1-11h-3Zm-5,34-3,9h3l10-5S232.716,255.456,227,256Zm-24,15h16l1-2s1.128-2.679-6-3A13.5,13.5,0,0,0,203,271Zm-12-1,8,6s-3.841,10.686-5,12a52.881,52.881,0,0,0-5-2l2-3-2-7v-6h2Zm27,2c0.711,2.216-7,12-7,12s0.617,2.391,1,2c5.944-6.076,29-16,29-16l-1-1S219.168,272.474,218,272Zm4-3v1l19-3,3,2v-2l-2-3-4-1Zm45-44,3.966,0.218A98.832,98.832,0,0,1,266,239c3.89-3.4,6-5,6-5l3,4s-7.874,3.158-12,8a110.818,110.818,0,0,0-8,11s-1.531-1.31-4,0-6,5-6,5h-7l1-2,11-8S264.491,239.262,267,225Zm-16,20h4s5.629-6.48,2-6S253.273,244.608,251,245Zm-3,2s-9.976,8.022-13,8a40.88,40.88,0,0,0,4,2s11.8-6.8,13-9C251.574,247.487,248,247,248,247Zm26-16v1l4,4,5-2s2.417-10.364,2-16C282,221.657,274,231,274,231Zm-40,10c0.4,3.232-1.234,9.343-3,11a3.522,3.522,0,0,0,2,1s14.535-6.556,15-8-0.808-2.354,0-3c3.9-3.117,9.718-10.182,12-17a5.416,5.416,0,0,0-1-2l-2-1S241.191,240.354,234,241Zm-6,50s-19.136,8.476-19,9,6,1,6,1l15-6Zm25-5-1,3,13,17,2-1s-1.465-5.214-1-9c-1.332-1.341-2,0-2,0l-2-2s-2.263-10.984,2-13a4.431,4.431,0,0,1-3-1Zm16,26,5,8v-8S268.13,311.739,269,312Zm10-25-3,6,2,9v10h5s9.379-3.643,11-5c-0.275-.246,0-2,0-2l-6,1,1-7,2-4,1-5,4-5s-1.961-2.615-3-2-5,6-5,6l-1,7-5,8-2-4-1-7,2-4-1-2h-1m22,4c-3.245.4-10.912,8.746-11,11s0.3,2.1,2,1,4.3-4.369,12-7C305.459,295.385,304.245,290.6,301,291Zm-26-11s-6.9,7.987-7,10,0.436,9.816,1,11a4.2,4.2,0,0,1,2,0,7.389,7.389,0,0,1,0-5c0.99-2.591,8-11,8-11v-3Zm13-3,4,4s-5.145,5.086-6,7-2,9-2,9l-2,3-1-2,2-12S285,277.845,288,277Zm-42-12,2,3,13-8,1-6-6,4-3,1Zm1,5v6s13.765-3.265,15-2c-0.025-3.251,5-9,5-9l-1-3Zm22-6s-3.164,9.254-2,11c1.5-2.034,8.077-5.7,9-4,0.393-2.411,2.767-8.228,4-9C276.525,261.427,269,264,269,264Zm14-26-1,8s-17.263,3.858-18,5c0.257-.98,1-4,1-4S282.2,237.27,283,238Zm-18,15s4.366,5.573,4,7c2.021-.364,7.369-2.034,10-1a81.28,81.28,0,0,0,2-10S264.934,251.806,265,253Zm18,8-4,8s13.167-3.257,14-2c0.833-.732,3-3,3-3Zm2-25v11s14.612,0.872,15,0,1-8,1-8l-3-4h-9Zm0,13-3,9,15,3s4.288-11.834,3-12S285,249,285,249Zm-7,65-1,6,2,1s9.258,0.171,10-1,0-3,0-3l-3-4S279.139,314.271,278,314Zm20-6-2,2,6,7s3.722-1.54,4-3S298,308,298,308Zm-9,5,2,4v4s9.71-1.172,10-3c-1.716-1.232-7-7-7-7h-2Zm20-14-8,8,8,4,10-10v-2H309Zm-1-12v9l2,1,10,1s1.542-2.566,1-3c-2.291-1.833-3.8-5.451-4-9C315.441,286.029,308,287,308,287Zm10-44h-3l-10,10s13.5,8.314,14,10c1.407-3.133,11-10,11-10Zm-16-8s16.949,2.076,17,5a8.307,8.307,0,0,1,4-4s3.03-13.764,5-14a12.041,12.041,0,0,0-4,0l-5,6S302,231.762,302,235Zm31,20c-2.066.923-10,8-10,8l1,2,9,5,4-11S335.066,254.077,333,255Zm35,28s-3.068,8.157-4,9c1.939,0.014,7.339-.313,7-2S368,283,368,283Zm-4-12s-6.608,23.986-8,29c6.946-4.837,13-25,13-25S367.482,270.565,364,271Zm-38-1c-0.054.006-2.879,13.768-1.976,16.1A12.784,12.784,0,0,0,327,287l-1,11s16.319,2.2,22,4a4.427,4.427,0,0,0,1-3l5-4s5.8-9.965,5-11-8.5,8.932-12,10c0.222-4.863,4-20,4-20s-7.392,17.777-10,18-3,0-3,0,2.065-27.506,2-32a94.044,94.044,0,0,0-4,12Zm-90,29c2.364-.91,10-11,10-11l3-1,25,36-21-8v16l-7-7v-4l-13-14-13,3-2-6s11.982-5.629,13-5C232.092,298.675,235.213,299.3,236,299Zm-76,37-6,6v1l13,5,4-8Zm-9,10h3l12,4,3,4-2,3-19-8Zm146-24,8,16s15.486-1.546,16,0a2.621,2.621,0,0,1,1-2l-20-16Zm-19,1-1,8s6.209,2.408,7,7c3.158,0.221,16,0,16,0l-6-15H278Zm-79,24h17l3,8v3l-13,1Zm-5,6,6,5-1,1h-7l2-6m-16-13-0.374.15L173,342l-2,6s1.428,10.185,3,10,14,0,14,0l3-6-5-6h-2l-3,4m27,10c-0.341,2.487,2,5,2,5l8-3v-2S209.738,360.409,208,360Zm4,7s2.386,5.107,2,7a23.307,23.307,0,0,0,5-2v-8Zm10-5c-0.349.7,0,6,0,6s6,2.072,6,3a74.2,74.2,0,0,1,8-3l-1-2S225.074,364.466,222,362Zm8-22-6,6v10s2.092,3.192,11,6,62.2-2.512,66-3,10-3,10-3l2-7-5-6H290l2,6-2,3-5,1-7-6-2-5-6.784-4L265,343s-4.776,3.816-7,4-10,0-10,0-4.057-3.244-8-7C236.832,339.923,230,340,230,340Zm15,50-3-1-6,10,1,1,8-2v-8Zm12-5,1,4,3,5-14,4v-8S253.415,384.422,257,385Zm29-10c-2.222,2.356-7,5-7,5v3l13,1s9.609,1.406,11,4a83.721,83.721,0,0,0,4-9S288.357,377.154,286,375Zm-6,11-11,10,9,8,15-3,8-12S284,384.889,280,386Zm-62,1c1.344,0.373,25-1,25-1s14.575-6.215,17-5c1.829-.873,9-6,9-6v-7s-21.741-3.734-31,0c-3.192,1.287-13,7-13,7S218.149,383.49,218,387Zm96-45s42.3,0.31,49-8c2.216,1.639,3,9,3,9s-6.439,6.261-8,7c-4.52,2.141-35,1-35,1S314.109,346.92,314,342Zm2,10,6,2h32l6,3-1,5s-9.349,8.459-15,10c-3.529.962-24.062,2.82-31,3s-28.106-2.652-29-10c0.754-.761,3-1,3-1s24.455-2.945,27-5A54.727,54.727,0,0,1,316,352ZM205,416H192l-12,5-1,19-10,14-4,9,12,9s43.268,13.358,46,13,41.567,0.627,47,0c27.769-3.2,66-19,66-19s2.314-4.451,2-5c-3.957-6.926-17.286-23.808-24-29,0.516-2.829,0-22,0-22H300l-1,27s-15.472,5.746-20,6c-0.507-2.963-1-14-1-14l-16,2-1,12H232l-1-10-19,1S203.966,424.847,205,416Zm90-14c0,0.423,3,14,3,14s-7.6,16.611-13,23a5.141,5.141,0,0,0-3,0V426l-25,2,1,11H235l-1-10H214l-6-15s37.8,3.176,49,1S282.4,411.388,295,402ZM171,383l-5,9,0.008,4.479S170.455,398.856,172,400c3.747,2.775,42.41,9.437,51,6,3.789-1.516,8-7,8-7l-2-7s-31.616-.952-34-3a62.454,62.454,0,0,1-5-5Zm-20-18-8-2-6,4s-6.344,11.943,2,15c4.246,1.556,27,4,27,4l3-6,23,1,5,6,3-1,3-4-2-7-17-3-17.575-1.728Zm124,2,8,7-6,4-1,4-5-3,2-10Zm-8,13-7,5,6,11,9-10-8-6m-17,19-1,2,11,11,15-4,1-3s-11.3-7.776-13-9C259.009,397.277,250,399,250,399Zm-16,2-2,4s3.245,7.148,4,7,18-1,18-1v-2l-9-9Zm-3-12,3,8,5-8h-8Zm-2,17-7,4,10,1Zm-20-38-5,3,2,6,5-3Zm-28-3v2s16.389,1.224,18,4c2.009-2.27,7-5,7-5v-2l-3-3H191Zm128-51-4,5,25,18,8-6S305.452,311.537,309,314Zm3-3,28,17,4-4s-15.151-12.808-11-23c-3.507-.433-10-1-10-1Zm24-9s10.854,4.485,12,4,5-6,5-6-2.641,19.54-9,20C340.946,320.221,335.187,301.39,336,302Zm5-49s1.293,28.428,1,34c3.28-4.574,11-31.849,8-35S342.447,250.552,341,253Zm13,9c0.3,3.208-2.729,26.645-4,27,10.2-6.384,13.33-26.617,12-29S353.649,258.223,354,262Zm-49-24-2,1s-0.54,13.791,0,13,10-11,10-11Zm-3,16c0.672,6.184-3,14-3,14l6,5h2l8-9S305.763,256.218,302,254Zm23-12-2,3,15,11v-6S323.6,242,325,242Zm-1,26h-4s-2.284,17.028,1,23c0.9,1.418,2-2,2-2S321.73,272.8,324,268Zm-7-2-10,9v9l2,1,6-1Zm-60,56-1,9,4,3,5-8,8,2v-2l-13-7Zm-26-36-2,2,5,7s4.247,0.131,5-1,4-8,4-8l19-7v-2s-19.346,2.161-22,0c-1.358,4.939-3.7,10.391-5,11S230.815,286.432,231,286Zm-29-13v5s-3.569,9.923-5,10,9,0,9,0l10-15H202Zm-68,34c-0.979,2.105-5.472,11.956-6,11s1,2,1,2h11l-1-10A19.153,19.153,0,0,0,134,307Zm5,30v3l5,7h2s6.305-10.878,10-11c1.024-1.1-1-3-1-3Zm77-17,11,15h3l-7-17Zm5,18,5,2-4,5v5l-2,1-1-6Zm-43-38v2l6,2,3-4h-9Zm-6,1-1,6,5,12,2,1,3,4-1,2-7,13,8-6v11s5.7-3.861,6-8c-0.511,4.019-1,8-1,8s8.633,7.215,14,9a42.257,42.257,0,0,1-6-10c-0.095-1.026,2.3-10.591,4-11,1.568,1.614,8,8,8,8h1s-1-9.433,0-13c2.547,3.984,5.438,7.94,8,10,0.352-3.014,0-17,0-17l-9-5,2-1,7,3h4l12-4,8,8,1,15,10,8s8.252,0.521,10-1,8-10,8-10l9,5,8,12-3-12-14-9-9,11h-7l-9-8-1-12-10-11-14,4-8-4,1-1,7,2-3-7h-6l-8,5-1-5-7,7S173.945,301.729,172,301Zm20,15-3,3h-5v9h8l5-6,7-6h-7l-2,5Zm-15-9,6,11,3-4Zm-11,28,4,3s5.027-5.142,6-8c-1.875-1.538-4-3-4-3S166.9,334.444,166,335Z" />',
                        '<path fill="url(#dragoneye)" fill-rule="evenodd" d="M227,280l-20,11,3,5,11-4Zm-38,8,3,2-3,6v-8Z" />'
                    )
                );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

library LeftGekkeiju {
    using Strings for uint256;

    function leftGekkeijuSVG() internal pure returns (string memory) {
        return '<path class="logo" d="M199.54,529.683c-4.741-5.6-7.34-16.219-6.26-24.181,0.165,0.012.333,0.03,0.5,0.052s0.343,0.051.519,0.084c0.351,0.065.713,0.151,1.083,0.255a18.875,18.875,0,0,1,2.324.834,36.952,36.952,0,0,1,5.071,2.731,52.912,52.912,0,0,1,9.8,7.908c5.66,5.969,6.143,11.795,6.749,19.262-8.714-.453-14.9-1.062-19.789-6.945h0Zm-1.247,12.187c-5.98,4.338-12.58,12.993-14.107,20.577q0.339,0.086.7,0.157t0.729,0.132c0.5,0.079,1.015.141,1.551,0.185a27.639,27.639,0,0,0,3.407.06,41.938,41.938,0,0,0,21.178-7.075c7.224-5.4,7.155-11.247,7.594-18.652-8.815.429-14.766,0.036-21.048,4.616h0ZM177,525.606c-3.712-6.01-4.844-16.487-2.875-23.826,0.155,0.035.311,0.076,0.47,0.121s0.32,0.1.482,0.154c0.325,0.112.658,0.244,1,.395a18.469,18.469,0,0,1,2.1,1.117,36.083,36.083,0,0,1,4.459,3.289,50.285,50.285,0,0,1,8.226,8.83c4.539,6.423,4.219,12.032,3.741,19.246-8.066-1.606-13.786-3.034-17.6-9.326h0Zm-2.844,11.476c-6.237,3.331-13.7,10.645-16.2,17.546,0.2,0.085.415,0.167,0.632,0.245s0.439,0.154.667,0.226q0.684,0.216,1.431.392a26.01,26.01,0,0,0,3.189.532,39.235,39.235,0,0,0,20.844-3.762c7.535-4.13,8.349-9.716,9.8-16.73-8.28-.778-13.813-1.963-20.365,1.551h0ZM155.6,518.323c-2.723-6.288-2.5-16.452.219-23.075q0.216,0.086.435,0.187t0.441,0.218q0.446,0.232.9,0.524a18.834,18.834,0,0,1,1.869,1.373,35.877,35.877,0,0,1,3.847,3.776,48.5,48.5,0,0,1,6.7,9.562c3.471,6.743,2.422,12.038.967,18.863-7.377-2.676-12.6-4.861-15.383-11.428h0Zm-4.252,10.565c-6.384,2.292-14.485,8.163-17.778,14.266,0.182,0.11.371,0.218,0.565,0.325s0.4,0.21.6,0.312c0.412,0.2.847,0.4,1.3,0.581a25.367,25.367,0,0,0,2.946.973,35.445,35.445,0,0,0,6.8,1.079,35.005,35.005,0,0,0,13.413-1.59c7.689-2.825,9.277-8.029,11.63-14.522-7.691-1.916-12.774-3.84-19.478-1.424h0Zm-14.691-20.337c-1.83-6.436-.438-16.154,2.866-22.03,0.131,0.076.264,0.157,0.4,0.244s0.266,0.178.4,0.274c0.268,0.193.538,0.406,0.81,0.636a19.474,19.474,0,0,1,1.642,1.588,36.329,36.329,0,0,1,3.268,4.167,47.438,47.438,0,0,1,5.308,10.085c2.512,6.925.847,11.842-1.427,18.184-6.687-3.6-11.4-6.441-13.263-13.148h0Zm-5.4,9.543c-6.416,1.3-14.924,5.74-18.8,11.013,0.161,0.132.328,0.262,0.5,0.392s0.351,0.257.536,0.384c0.368,0.254.76,0.5,1.171,0.743a25.09,25.09,0,0,0,2.69,1.358,34.789,34.789,0,0,0,6.349,2.023,33.488,33.488,0,0,0,12.99.435c7.694-1.581,9.91-6.331,13-12.227-7.083-2.918-11.709-5.486-18.444-4.121h0Zm-11.637-21.682c-1-6.474,1.426-15.629,5.18-20.728,0.119,0.094.237,0.192,0.356,0.295s0.237,0.212.356,0.325q0.355,0.339.712,0.734a20.222,20.222,0,0,1,1.413,1.772,37.419,37.419,0,0,1,2.7,4.483,46.721,46.721,0,0,1,3.991,10.439c1.625,7-.566,11.473-3.538,17.251C124.812,506.564,120.617,503.15,119.617,496.412Zm-6.351,8.422c-6.346.326-15.063,3.35-19.35,7.768,0.139,0.15.284,0.3,0.435,0.449s0.307,0.3.469,0.447q0.486,0.445,1.036.884a25.435,25.435,0,0,0,2.419,1.7,34.766,34.766,0,0,0,5.841,2.878,32.567,32.567,0,0,0,12.39,2.338c7.566-.382,10.3-4.618,14-9.849-6.44-3.817-10.589-6.957-17.245-6.613h0Zm-8.7-22.635c-0.224-6.417,3.1-14.914,7.179-19.222,0.105,0.108.209,0.222,0.312,0.34s0.207,0.241.31,0.369q0.308,0.382.61,0.818a21.322,21.322,0,0,1,1.181,1.926,38.748,38.748,0,0,1,2.146,4.73A46.236,46.236,0,0,1,119.05,481.8c0.805,6.966-1.827,10.958-5.381,16.108C108.424,492.78,104.768,488.868,104.568,482.2Zm-7.107,7.228c-6.178-.605-14.922,1.03-19.48,4.59q0.175,0.248.368,0.5c0.128,0.167.262,0.333,0.4,0.5q0.417,0.5.9,1.006a26.425,26.425,0,0,0,2.132,2,35.47,35.47,0,0,0,5.279,3.643,32.252,32.252,0,0,0,11.629,4.1c7.315,0.758,10.457-2.922,14.659-7.437-5.761-4.615-9.411-8.255-15.885-8.89h0Zm-6.215-23.722c0.516-6.269,4.634-14.011,8.934-17.509,0.089,0.122.177,0.248,0.264,0.38s0.174,0.267.259,0.407c0.171,0.28.339,0.578,0.5,0.891,0.328,0.626.641,1.316,0.938,2.054a40.447,40.447,0,0,1,1.578,4.917,45.768,45.768,0,0,1,1.525,10.7c0.026,6.846-2.973,10.3-7.011,14.757-4.468-5.751-7.551-10.1-6.989-16.6h0Zm-7.694,5.951c-5.906-1.51-14.506-1.253-19.208,1.441,0.094,0.177.194,0.355,0.3,0.536s0.215,0.361.329,0.544q0.345,0.549.748,1.109a27.519,27.519,0,0,0,1.82,2.255,36.564,36.564,0,0,0,4.649,4.334,32.424,32.424,0,0,0,10.69,5.748c6.939,1.855,10.406-1.226,15-4.969-5.025-5.33-8.14-9.41-14.323-11h0Zm-3.046-23.487c1.184-6.049,5.956-13,10.364-15.733q0.109,0.2.215,0.412t0.207,0.438c0.136,0.3.266,0.617,0.392,0.948,0.252,0.663.483,1.384,0.7,2.151a42.075,42.075,0,0,1,1.031,5.034,45.4,45.4,0,0,1,.395,10.645c-0.674,6.653-3.948,9.564-8.351,13.314-3.692-6.249-6.2-10.937-4.949-17.209h0Zm-8.091,4.69c-5.552-2.33-13.856-3.344-18.584-1.465q0.107,0.279.229,0.566t0.258,0.578q0.272,0.585.6,1.19a28.867,28.867,0,0,0,1.5,2.465,38.074,38.074,0,0,0,3.989,4.909,32.972,32.972,0,0,0,9.637,7.184c6.469,2.837,10.161.352,15.021-2.623-4.275-5.92-6.846-10.355-12.652-12.8h0Zm-0.6-23.991c1.822-5.755,7.156-11.857,11.579-13.833q0.083,0.213.161,0.439t0.151,0.463c0.1,0.316.189,0.648,0.274,0.993,0.171,0.69.317,1.434,0.44,2.22a44.126,44.126,0,0,1,.467,5.1,45.1,45.1,0,0,1-.721,10.467c-1.342,6.388-4.819,8.726-9.495,11.733-2.868-6.656-4.759-11.616-2.856-17.577h0Zm-8.33,3.391c-5.1-3.105-12.948-5.344-17.6-4.266,0.048,0.193.1,0.388,0.157,0.587s0.117,0.4.183,0.6c0.13,0.408.277,0.827,0.44,1.254,0.326,0.853.716,1.738,1.162,2.637a39.8,39.8,0,0,0,3.262,5.4,33.835,33.835,0,0,0,8.42,8.483c5.884,3.753,9.724,1.885,14.755-.3-3.466-6.42-5.455-11.146-10.78-14.406h0ZM65.75,409.2c2.4-5.409,8.178-10.665,12.533-11.953q0.056,0.224.105,0.459t0.094,0.48q0.088,0.492.155,1.023c0.089,0.708.149,1.465,0.184,2.26a46.471,46.471,0,0,1-.085,5.1,44.95,44.95,0,0,1-1.769,10.193c-1.947,6.075-5.547,7.856-10.394,10.136-2.043-6.947-3.318-12.1-.823-17.7h0Zm-8.409,2.149c-4.576-3.783-11.846-7.123-16.331-6.782q0.037,0.294.085,0.6t0.107,0.62q0.119,0.632.281,1.3c0.216,0.886.49,1.813,0.815,2.762a41.521,41.521,0,0,0,2.512,5.788,34.808,34.808,0,0,0,7.115,9.565c5.225,4.547,9.131,3.271,14.231,1.855-2.645-6.8-4.045-11.736-8.816-15.7h0Zm4.724-23.032c2.95-5,9.1-9.377,13.311-10.013,0.017,0.153.032,0.311,0.045,0.471s0.023,0.325.032,0.492c0.017,0.334.025,0.681,0.026,1.039,0,0.717-.03,1.478-0.088,2.272a49.3,49.3,0,0,1-.66,5.044,45.066,45.066,0,0,1-2.82,9.817c-2.529,5.7-6.185,6.922-11.119,8.461-1.168-7.142-1.787-12.408,1.273-17.583h0Zm-8.339.906c-3.955-4.4-10.495-8.77-14.722-9.142,0,0.2,0,.4.009,0.6s0.015,0.415.028,0.628q0.037,0.64.112,1.321c0.1,0.907.248,1.863,0.443,2.848a43.29,43.29,0,0,0,1.7,6.087,35.885,35.885,0,0,0,5.648,10.492c4.457,5.259,8.359,4.581,13.435,3.932-1.763-7.085-2.533-12.159-6.647-16.771h0Zm7.338-21.51c3.451-4.555,9.877-8.086,13.895-8.152q0,0.234-.017.477t-0.031.5c-0.026.336-.061,0.684-0.1,1.042-0.088.715-.21,1.471-0.363,2.255-0.3,1.567-.727,3.247-1.231,4.937a45.624,45.624,0,0,1-3.824,9.368c-3.064,5.3-6.71,5.992-11.643,6.826-0.292-7.23-.254-12.532,3.319-17.248h0Zm-8.133-.253c-3.274-4.907-8.975-10.183-12.871-11.2q-0.037.294-.067,0.6t-0.052.627q-0.045.641-.059,1.327c-0.019.914,0,1.884,0.065,2.889a44.922,44.922,0,0,0,.856,6.282A36.907,36.907,0,0,0,44.91,379.2c3.627,5.846,7.457,5.731,12.422,5.8-0.87-7.255-1-12.39-4.4-17.535h0ZM62.7,347.092c3.918-4.072,10.559-6.77,14.337-6.332-0.025.156-.052,0.314-0.082,0.476s-0.063.325-.1,0.491c-0.07.333-.151,0.677-0.242,1.029-0.18.705-.4,1.446-0.648,2.21-0.5,1.529-1.12,3.154-1.817,4.778a46.721,46.721,0,0,1-4.823,8.839c-3.575,4.87-7.153,5.054-12.008,5.206,0.611-7.218,1.326-12.48,5.379-16.7h0Zm-7.8-1.354c-2.518-5.328-7.252-11.4-10.736-13.015-0.05.191-.1,0.388-0.145,0.589s-0.092.407-.135,0.618c-0.086.421-.165,0.86-0.236,1.314-0.142.909-.254,1.879-0.33,2.89a46.656,46.656,0,0,0-.03,6.383,37.967,37.967,0,0,0,2.447,11.743c2.714,6.327,6.41,6.754,11.18,7.506,0.058-7.322.583-12.443-2.014-18.028h0Zm12.163-18.99c4.357-3.552,11.159-5.437,14.668-4.562-0.047.152-.1,0.308-0.15,0.466s-0.109.318-.167,0.481q-0.176.488-.385,1c-0.277.684-.6,1.4-0.945,2.136-0.7,1.471-1.527,3.023-2.423,4.562a48.7,48.7,0,0,1-5.827,8.233c-4.07,4.4-7.527,4.117-12.229,3.617,1.541-7.106,2.954-12.253,7.458-15.935h0Zm-7.334-2.386c-1.687-5.655-5.319-12.412-8.3-14.577q-0.114.276-.226,0.569t-0.22.6c-0.145.41-.286,0.839-0.421,1.284-0.271.89-.521,1.847-0.744,2.849a48.683,48.683,0,0,0-.967,6.39,39.164,39.164,0,0,0,.664,12.091c1.717,6.7,5.214,7.645,9.71,9.038,1.023-7.283,2.23-12.316.509-18.244h0ZM74.517,306.41c4.78-2.982,11.708-4.053,14.924-2.8q-0.107.221-.223,0.449t-0.243.461q-0.252.468-.539,0.958c-0.382.653-.807,1.332-1.266,2.028-0.917,1.391-1.965,2.848-3.072,4.282a51.858,51.858,0,0,1-6.879,7.528c-4.572,3.894-7.856,3.16-12.325,2.026,2.528-6.886,4.681-11.836,9.623-14.933h0Zm-6.73-3.367c-0.754-5.891-3.1-13.231-5.471-15.908q-0.156.263-.313,0.541t-0.312.573q-0.312.588-.62,1.232c-0.41.858-.811,1.786-1.193,2.764a51.346,51.346,0,0,0-1.991,6.3,40.772,40.772,0,0,0-1.31,12.251c0.6,6.972,3.822,8.417,7.956,10.422,2.056-7.133,3.988-12,3.253-18.171h0ZM84.73,287.549c5.167-2.4,12.192-2.7,15.125-1.14-0.1.139-.2,0.281-0.3,0.424s-0.21.288-.319,0.435q-0.329.441-.7,0.9c-0.489.611-1.023,1.245-1.592,1.891-1.138,1.291-2.411,2.635-3.732,3.948a56.7,56.7,0,0,1-7.933,6.761c-5.06,3.367-8.134,2.239-12.307.53,3.518-6.571,6.408-11.251,11.753-13.748h0Zm-6.019-4.236c0.232-6.018-.7-13.8-2.362-16.912-0.132.163-.266,0.332-0.4,0.5s-0.27.353-.406,0.537q-0.408.554-.823,1.164c-0.552.813-1.108,1.7-1.654,2.636a55.147,55.147,0,0,0-3.05,6.106,43.081,43.081,0,0,0-3.376,12.208c-0.586,7.119,2.3,9.019,6.007,11.564,3.1-6.879,5.757-11.5,6.064-17.808h0Zm19.265-13.437c5.532-1.781,12.644-1.332,15.312.481-0.122.129-.247,0.259-0.377,0.391s-0.262.265-.4,0.4q-0.411.4-.862,0.823c-0.6.559-1.25,1.134-1.935,1.719-1.37,1.17-2.88,2.378-4.427,3.551a63.472,63.472,0,0,1-9.03,5.9c-5.557,2.808-8.389,1.327-12.2-.913,4.538-6.154,8.185-10.489,13.914-12.356h0Zm-5.186-5.014c1.3-6.041,1.951-14.118,1.142-17.605q-0.242.222-.491,0.46t-0.5.492q-0.509.508-1.037,1.075c-0.7.754-1.422,1.581-2.142,2.464a60.848,60.848,0,0,0-4.182,5.81,46.686,46.686,0,0,0-5.609,11.961c-1.877,7.147.6,9.466,3.8,12.494,4.18-6.517,7.586-10.823,9.023-17.151h0ZM114.357,253.7c5.876-1.138,13.08.057,15.52,2.083a95.738,95.738,0,0,1-19.62,10.977c-6.073,2.211-8.635.42-12.008-2.305,5.59-5.635,10.013-9.55,16.108-10.755h0Zm-4.225-5.7c2.448-5.954,4.9-14.178,5.1-17.954-6.332,4.113-15.493,14.132-18.551,20.955-3.289,7.047-1.3,9.743,1.312,13.2,5.3-6.046,9.475-9.96,12.135-16.2h0Zm11.746-5.3,1.156,1.518C82.11,273.344,52.009,325.815,60.114,391.96a168.968,168.968,0,0,0,46.427,96.52c28.1,28.309,70.252,50.166,129.9,44.928A17.286,17.286,0,0,0,237,538.14c-61.5,4.854-104.437-17.97-132.93-47.131A173.055,173.055,0,0,1,57.4,392.343c-7.775-67.335,22.987-120.3,64.477-149.639h0Zm2.125-6.61c7-4.624,18.415-8.242,23.971-8.1-3.328,4.385-11.679,11.78-17.985,16.338-6.6,4.716-11.345,5.485-18.117,7.254,2.726-6.16,4.866-10.749,12.131-15.491h0Z"/>';
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

library RightGekkeiju {
    using Strings for uint256;

    function rightGekkeijuSVG() internal pure returns (string memory) {
        return '<path class="logo" d="M301.46,529.683c4.741-5.6,7.34-16.219,6.26-24.181-0.165.012-.333,0.03-0.5,0.052s-0.343.051-.519,0.084c-0.351.065-.713,0.151-1.083,0.255a18.875,18.875,0,0,0-2.324.834,36.952,36.952,0,0,0-5.071,2.731,52.912,52.912,0,0,0-9.8,7.908c-5.66,5.969-6.143,11.795-6.749,19.262,8.714-.453,14.9-1.062,19.789-6.945h0Zm1.247,12.187c5.979,4.338,12.58,12.993,14.107,20.577q-0.339.086-.7,0.157t-0.729.132c-0.5.079-1.015,0.141-1.551,0.185a27.639,27.639,0,0,1-3.407.06,41.938,41.938,0,0,1-21.178-7.075c-7.224-5.4-7.155-11.247-7.594-18.652,8.815,0.429,14.766.036,21.048,4.616h0ZM324,525.606c3.712-6.01,4.843-16.487,2.875-23.826-0.155.035-.311,0.076-0.47,0.121s-0.32.1-.482,0.154q-0.487.168-1,.395a18.543,18.543,0,0,0-2.1,1.117,36.083,36.083,0,0,0-4.459,3.289,50.285,50.285,0,0,0-8.226,8.83c-4.539,6.423-4.219,12.032-3.741,19.246,8.066-1.606,13.786-3.034,17.6-9.326h0Zm2.844,11.476c6.237,3.331,13.7,10.645,16.2,17.546-0.205.085-.415,0.167-0.632,0.245s-0.439.154-.667,0.226q-0.684.216-1.431,0.392a26.042,26.042,0,0,1-3.189.532,39.235,39.235,0,0,1-20.844-3.762c-7.535-4.13-8.349-9.716-9.8-16.73,8.28-.778,13.813-1.963,20.365,1.551h0ZM345.4,518.323c2.723-6.288,2.5-16.452-.219-23.075q-0.216.086-.435,0.187t-0.441.218q-0.445.232-.9,0.524a18.943,18.943,0,0,0-1.868,1.373,35.877,35.877,0,0,0-3.847,3.776,48.5,48.5,0,0,0-6.7,9.562c-3.471,6.743-2.422,12.038-.967,18.863,7.377-2.676,12.6-4.861,15.383-11.428h0Zm4.252,10.565c6.384,2.292,14.485,8.163,17.778,14.266-0.182.11-.371,0.218-0.565,0.325s-0.4.21-.6,0.312c-0.412.2-.847,0.4-1.3,0.581a25.367,25.367,0,0,1-2.946.973,35.445,35.445,0,0,1-6.8,1.079,35.005,35.005,0,0,1-13.413-1.59c-7.689-2.825-9.277-8.029-11.63-14.522,7.691-1.916,12.774-3.84,19.478-1.424h0Zm14.691-20.337c1.83-6.436.438-16.154-2.866-22.03-0.131.076-.264,0.157-0.4,0.244s-0.266.178-.4,0.274c-0.268.193-.538,0.406-0.81,0.636a19.474,19.474,0,0,0-1.642,1.588,36.329,36.329,0,0,0-3.268,4.167,47.438,47.438,0,0,0-5.308,10.085c-2.512,6.925-.847,11.842,1.427,18.184,6.687-3.6,11.4-6.441,13.263-13.148h0Zm5.4,9.543c6.416,1.3,14.924,5.74,18.8,11.013-0.161.132-.328,0.262-0.5,0.392s-0.351.257-.536,0.384c-0.368.254-.76,0.5-1.171,0.743a25.09,25.09,0,0,1-2.69,1.358,34.789,34.789,0,0,1-6.349,2.023,33.488,33.488,0,0,1-12.99.435c-7.694-1.581-9.91-6.331-13-12.227,7.084-2.918,11.71-5.486,18.445-4.121h0Zm11.636-21.682c1-6.474-1.425-15.629-5.179-20.728-0.119.094-.237,0.192-0.356,0.295s-0.237.212-.356,0.325q-0.355.339-.712,0.734a20.222,20.222,0,0,0-1.413,1.772,37.419,37.419,0,0,0-2.7,4.483,46.721,46.721,0,0,0-3.991,10.439c-1.625,7,.566,11.473,3.538,17.251C376.188,506.564,380.383,503.15,381.382,496.412Zm6.352,8.422c6.346,0.326,15.063,3.35,19.35,7.768-0.139.15-.284,0.3-0.435,0.449s-0.307.3-.469,0.447q-0.486.445-1.036,0.884a25.475,25.475,0,0,1-2.419,1.7,34.766,34.766,0,0,1-5.841,2.878,32.567,32.567,0,0,1-12.39,2.338c-7.566-.382-10.3-4.618-14.005-9.849,6.44-3.817,10.589-6.957,17.245-6.613h0Zm8.7-22.635c0.224-6.417-3.1-14.914-7.179-19.222-0.1.108-.209,0.222-0.312,0.34s-0.207.241-.31,0.369q-0.308.382-.61,0.818a21.322,21.322,0,0,0-1.181,1.926,38.748,38.748,0,0,0-2.146,4.73A46.236,46.236,0,0,0,381.95,481.8c-0.805,6.966,1.827,10.958,5.381,16.108C392.576,492.78,396.232,488.868,396.432,482.2Zm7.107,7.228c6.178-.605,14.922,1.03,19.48,4.59q-0.176.248-.368,0.5c-0.128.167-.262,0.333-0.4,0.5q-0.417.5-.9,1.006a26.3,26.3,0,0,1-2.131,2,35.457,35.457,0,0,1-5.28,3.643,32.247,32.247,0,0,1-11.629,4.1c-7.315.758-10.457-2.922-14.659-7.437,5.761-4.615,9.411-8.255,15.885-8.89h0Zm6.215-23.722c-0.517-6.269-4.634-14.011-8.934-17.509-0.089.122-.177,0.248-0.264,0.38s-0.174.267-.259,0.407c-0.171.28-.339,0.578-0.5,0.891-0.327.626-.64,1.316-0.937,2.054a40.273,40.273,0,0,0-1.578,4.917,45.768,45.768,0,0,0-1.525,10.7c-0.026,6.846,2.973,10.3,7.011,14.757,4.468-5.751,7.551-10.1,6.989-16.6h0Zm7.694,5.951c5.906-1.51,14.506-1.253,19.208,1.441-0.094.177-.193,0.355-0.3,0.536s-0.215.361-.329,0.544q-0.345.549-.748,1.109a27.448,27.448,0,0,1-1.821,2.255,36.52,36.52,0,0,1-4.649,4.334,32.424,32.424,0,0,1-10.689,5.748c-6.94,1.855-10.406-1.226-15-4.969,5.025-5.33,8.14-9.41,14.323-11h0Zm3.046-23.487c-1.184-6.049-5.956-13-10.364-15.733q-0.109.2-.215,0.412t-0.207.438c-0.136.3-.267,0.617-0.393,0.948-0.251.663-.483,1.384-0.695,2.151a42.213,42.213,0,0,0-1.031,5.034,45.428,45.428,0,0,0-.395,10.645c0.674,6.653,3.948,9.564,8.351,13.314,3.692-6.249,6.2-10.937,4.949-17.209h0Zm8.09,4.69c5.553-2.33,13.856-3.344,18.585-1.465-0.072.186-.148,0.375-0.23,0.566s-0.167.383-.258,0.578q-0.272.585-.6,1.19a28.763,28.763,0,0,1-1.5,2.465,38.025,38.025,0,0,1-3.988,4.909,32.972,32.972,0,0,1-9.638,7.184c-6.469,2.837-10.161.352-15.021-2.623,4.275-5.92,6.847-10.355,12.652-12.8h0Zm0.605-23.991c-1.822-5.755-7.156-11.857-11.579-13.833-0.055.142-.108,0.288-0.16,0.439s-0.1.3-.152,0.463c-0.1.316-.189,0.648-0.274,0.993-0.17.69-.317,1.434-0.439,2.22a44.208,44.208,0,0,0-.468,5.1,45.1,45.1,0,0,0,.722,10.467c1.342,6.388,4.819,8.726,9.5,11.733,2.867-6.656,4.759-11.616,2.855-17.577h0Zm8.331,3.391c5.1-3.105,12.947-5.344,17.6-4.266-0.047.193-.1,0.388-0.156,0.587s-0.118.4-.183,0.6c-0.13.408-.277,0.827-0.44,1.254-0.327.853-.717,1.738-1.162,2.637a39.9,39.9,0,0,1-3.262,5.4,33.834,33.834,0,0,1-8.421,8.483c-5.884,3.753-9.723,1.885-14.754-.3,3.466-6.42,5.455-11.146,10.78-14.406h0ZM435.25,409.2c-2.4-5.409-8.179-10.665-12.534-11.953q-0.056.224-.105,0.459c-0.033.156-.065,0.316-0.094,0.48-0.059.328-.11,0.669-0.155,1.023-0.088.708-.149,1.465-0.183,2.26a46.614,46.614,0,0,0,.084,5.1,44.983,44.983,0,0,0,1.769,10.193c1.947,6.075,5.547,7.856,10.394,10.136,2.043-6.947,3.318-12.1.824-17.7h0Zm8.408,2.149c4.576-3.783,11.847-7.123,16.332-6.782q-0.038.294-.085,0.6t-0.108.62q-0.119.632-.281,1.3c-0.216.886-.49,1.813-0.815,2.762a41.514,41.514,0,0,1-2.513,5.788,34.791,34.791,0,0,1-7.114,9.565c-5.225,4.547-9.131,3.271-14.231,1.855,2.645-6.8,4.045-11.736,8.815-15.7h0Zm-4.724-23.032c-2.95-5-9.1-9.377-13.311-10.013-0.017.153-.032,0.311-0.045,0.471s-0.024.325-.032,0.492c-0.017.334-.026,0.681-0.026,1.039,0,0.717.03,1.478,0.088,2.272a49.2,49.2,0,0,0,.661,5.044,45.039,45.039,0,0,0,2.819,9.817c2.529,5.7,6.186,6.922,11.119,8.461,1.168-7.142,1.787-12.408-1.273-17.583h0Zm8.339,0.906c3.955-4.4,10.495-8.77,14.722-9.142,0,0.2,0,.4-0.009.6s-0.015.415-.027,0.628q-0.037.64-.112,1.321c-0.1.907-.248,1.863-0.443,2.848a43.438,43.438,0,0,1-1.695,6.087,35.915,35.915,0,0,1-5.648,10.492c-4.457,5.259-8.359,4.581-13.435,3.932,1.763-7.085,2.533-12.159,6.647-16.771h0Zm-7.338-21.51c-3.45-4.555-9.877-8.086-13.894-8.152,0,0.156.008,0.315,0.016,0.477s0.019,0.327.032,0.5c0.025,0.336.061,0.684,0.105,1.042,0.087,0.715.21,1.471,0.362,2.255,0.305,1.567.727,3.247,1.231,4.937a45.613,45.613,0,0,0,3.824,9.368c3.064,5.3,6.71,5.992,11.643,6.826,0.292-7.23.254-12.532-3.319-17.248h0Zm8.133-.253c3.275-4.907,8.976-10.183,12.872-11.2q0.037,0.294.067,0.6t0.052,0.627q0.043,0.641.059,1.327c0.019,0.914,0,1.884-.065,2.889a45.026,45.026,0,0,1-.856,6.282A36.893,36.893,0,0,1,456.09,379.2c-3.626,5.846-7.457,5.731-12.421,5.8,0.87-7.255,1-12.39,4.4-17.535h0ZM438.3,347.092c-3.918-4.072-10.559-6.77-14.337-6.332,0.024,0.156.052,0.314,0.082,0.476s0.062,0.325.1,0.491c0.071,0.333.152,0.677,0.242,1.029,0.18,0.705.4,1.446,0.648,2.21,0.5,1.529,1.119,3.154,1.817,4.778a46.732,46.732,0,0,0,4.822,8.839c3.575,4.87,7.153,5.054,12.008,5.206-0.611-7.218-1.326-12.48-5.379-16.7h0Zm7.8-1.354c2.518-5.328,7.252-11.4,10.735-13.015,0.05,0.191.1,0.388,0.145,0.589s0.092,0.407.135,0.618c0.086,0.421.165,0.86,0.236,1.314,0.143,0.909.254,1.879,0.331,2.89a46.913,46.913,0,0,1,.03,6.383,37.984,37.984,0,0,1-2.447,11.743c-2.714,6.327-6.41,6.754-11.18,7.506-0.058-7.322-.583-12.443,2.015-18.028h0Zm-12.164-18.99c-4.356-3.552-11.159-5.437-14.667-4.562,0.047,0.152.1,0.308,0.149,0.466s0.109,0.318.168,0.481q0.175,0.488.385,1c0.277,0.684.6,1.4,0.945,2.136,0.7,1.471,1.527,3.023,2.423,4.562a48.685,48.685,0,0,0,5.826,8.233c4.071,4.4,7.528,4.117,12.23,3.617-1.541-7.106-2.955-12.253-7.459-15.935h0Zm7.335-2.386c1.687-5.655,5.319-12.412,8.3-14.577,0.076,0.184.152,0.374,0.226,0.569s0.148,0.4.221,0.6c0.145,0.41.285,0.839,0.421,1.284,0.271,0.89.521,1.847,0.744,2.849a48.648,48.648,0,0,1,.968,6.39,39.159,39.159,0,0,1-.665,12.091c-1.717,6.7-5.213,7.645-9.71,9.038-1.023-7.283-2.23-12.316-.509-18.244h0ZM426.483,306.41c-4.78-2.982-11.708-4.053-14.925-2.8q0.107,0.221.224,0.449t0.242,0.461c0.168,0.312.349,0.632,0.54,0.958,0.382,0.653.807,1.332,1.265,2.028,0.917,1.391,1.965,2.848,3.072,4.282a51.886,51.886,0,0,0,6.879,7.528c4.572,3.894,7.856,3.16,12.326,2.026-2.529-6.886-4.681-11.836-9.623-14.933h0Zm6.73-3.367c0.753-5.891,3.1-13.231,5.471-15.908q0.156,0.263.312,0.541c0.1,0.186.209,0.377,0.313,0.573q0.312,0.588.62,1.232c0.41,0.858.811,1.786,1.193,2.764a51.537,51.537,0,0,1,1.991,6.3,40.776,40.776,0,0,1,1.309,12.251c-0.6,6.972-3.822,8.417-7.956,10.422-2.056-7.133-3.988-12-3.253-18.171h0ZM416.27,287.549c-5.167-2.4-12.192-2.7-15.125-1.14,0.1,0.139.195,0.281,0.3,0.424s0.209,0.288.319,0.435q0.33,0.441.7,0.9c0.488,0.611,1.023,1.245,1.592,1.891,1.138,1.291,2.411,2.635,3.732,3.948a56.691,56.691,0,0,0,7.933,6.761c5.059,3.367,8.134,2.239,12.307.53-3.518-6.571-6.408-11.251-11.753-13.748h0Zm6.019-4.236c-0.232-6.018.705-13.8,2.363-16.912,0.132,0.163.266,0.332,0.4,0.5s0.27,0.353.406,0.537q0.408,0.554.823,1.164c0.552,0.813,1.108,1.7,1.654,2.636a54.987,54.987,0,0,1,3.049,6.106,43.045,43.045,0,0,1,3.376,12.208c0.586,7.119-2.3,9.019-6.006,11.564-3.1-6.879-5.757-11.5-6.065-17.808h0Zm-19.265-13.437c-5.532-1.781-12.644-1.332-15.312.481,0.122,0.129.247,0.259,0.377,0.391s0.262,0.265.4,0.4q0.411,0.4.862,0.823c0.6,0.559,1.25,1.134,1.935,1.719,1.37,1.17,2.88,2.378,4.427,3.551a63.483,63.483,0,0,0,9.03,5.9c5.557,2.808,8.389,1.327,12.2-.913-4.538-6.154-8.185-10.489-13.914-12.356h0Zm5.186-5.014c-1.3-6.041-1.951-14.118-1.143-17.605q0.243,0.222.492,0.46t0.5,0.492q0.509,0.508,1.036,1.075c0.7,0.754,1.423,1.581,2.143,2.464a61.058,61.058,0,0,1,4.182,5.81,46.672,46.672,0,0,1,5.608,11.961c1.877,7.147-.6,9.466-3.8,12.494-4.179-6.517-7.586-10.823-9.022-17.151h0ZM386.643,253.7c-5.876-1.138-13.08.057-15.52,2.083a95.738,95.738,0,0,0,19.62,10.977c6.073,2.211,8.635.42,12.008-2.305-5.59-5.635-10.013-9.55-16.108-10.755h0Zm4.225-5.7c-2.448-5.954-4.9-14.178-5.105-17.954,6.332,4.113,15.493,14.132,18.551,20.955,3.289,7.047,1.3,9.743-1.312,13.2-5.3-6.046-9.475-9.96-12.134-16.2h0Zm-11.746-5.3-1.157,1.518c40.925,29.122,71.026,81.593,62.921,147.738a168.974,168.974,0,0,1-46.427,96.52c-28.1,28.309-70.252,50.166-129.9,44.928A17.286,17.286,0,0,1,264,538.14c61.5,4.854,104.437-17.97,132.929-47.131A173.05,173.05,0,0,0,443.6,392.343c7.775-67.335-22.987-120.3-64.477-149.639h0ZM377,236.094c-7-4.624-18.414-8.242-23.97-8.1,3.328,4.385,11.679,11.78,17.985,16.338,6.6,4.716,11.345,5.485,18.117,7.254-2.726-6.16-4.866-10.749-12.132-15.491h0Z" />';
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

library Cuptype1 {
    using Strings for uint256;

    function getPath() external pure returns (string memory) {
        return '<path class="logo" d="M143.379,134.762h8.592V117.338h2.448l4.272,17.424h8.88l-5.328-18.816a7.232,7.232,0,0,0,3.744-3.6A15.714,15.714,0,0,0,167,106.154q0-5.76-3.264-8.016t-9.648-2.256h-10.7v38.88Zm8.592-22.368V101.642h2.784a3.826,3.826,0,0,1,3.312,1.32,8.662,8.662,0,0,1-.072,8.064q-1.032,1.368-3.624,1.368h-2.4Zm27.648,22.848a9.863,9.863,0,0,0,6.792-2.16q2.423-2.16,2.424-6.336v-2.688h-7.2v2.928q0,2.688-2.016,2.688-1.92,0-1.92-2.976V121.37h11.136V115.8q0-4.56-2.3-6.912t-6.912-2.352a9.882,9.882,0,0,0-7.1,2.424,8.994,8.994,0,0,0-2.544,6.84v10.176a8.994,8.994,0,0,0,2.544,6.84,9.882,9.882,0,0,0,7.1,2.424h0Zm-1.92-17.52V115.37a4.862,4.862,0,0,1,.48-2.544,1.569,1.569,0,0,1,1.392-.72,1.881,1.881,0,0,1,1.512.648,3.388,3.388,0,0,1,.552,2.184v2.784H177.7Zm20.207,17.52a8,8,0,0,0,5.472-2.64v2.16H211.2V95.882h-7.824v12.864a8.207,8.207,0,0,0-5.472-2.208,5.482,5.482,0,0,0-4.776,2.352,10.815,10.815,0,0,0-1.656,6.336V126.7q0,4.224,1.656,6.384a5.656,5.656,0,0,0,4.776,2.16h0Zm3.408-4.992a1.6,1.6,0,0,1-1.488-.84,4.486,4.486,0,0,1-.48-2.232V114.41a4.2,4.2,0,0,1,.5-2.184,1.65,1.65,0,0,1,1.512-.84,4.372,4.372,0,0,1,2.016.624v17.52a4.009,4.009,0,0,1-2.064.72h0Zm25.056,4.512h9.936a19.028,19.028,0,0,0,7.8-1.3,7.692,7.692,0,0,0,3.984-3.984,18.276,18.276,0,0,0,1.176-7.2V108.17a17.944,17.944,0,0,0-1.176-7.128,7.505,7.505,0,0,0-4.008-3.912,20.024,20.024,0,0,0-7.872-1.248h-9.84v38.88Zm8.592-5.952V101.882h1.3a6.051,6.051,0,0,1,2.76.48,2.27,2.27,0,0,1,1.152,1.464,11.763,11.763,0,0,1,.264,2.856v16.944a14.512,14.512,0,0,1-.24,3.048,2.453,2.453,0,0,1-1.128,1.584,5.368,5.368,0,0,1-2.76.552h-1.344Zm18,5.952h7.824V116.714q2.063-2.688,4.607-2.688a6.99,6.99,0,0,1,2.545.576v-7.776a4.852,4.852,0,0,0-4.368,1.056,14.861,14.861,0,0,0-2.784,3.744v-4.608h-7.824v27.744Zm22.8,0.48a4.812,4.812,0,0,0,3.408-1.248,6.948,6.948,0,0,0,1.92-3.168q0.192,0.72.624,3.936h7.008a40.608,40.608,0,0,1-.48-6.912V114.89a8.466,8.466,0,0,0-2.16-6.072,8.188,8.188,0,0,0-6.24-2.28q-4.848,0-7.3,2.376t-2.64,7.368l7.3,0.288,0.192-2.016a3.2,3.2,0,0,1,.432-1.632,1.441,1.441,0,0,1,1.3-.576,1.343,1.343,0,0,1,1.272.624,3.713,3.713,0,0,1,.36,1.824v2.784a48.765,48.765,0,0,0-5.88,2.4,11.629,11.629,0,0,0-3.912,3.216,8.254,8.254,0,0,0-1.632,5.28,7.442,7.442,0,0,0,.744,3.24,6.273,6.273,0,0,0,2.208,2.544,6.1,6.1,0,0,0,3.48.984h0Zm2.784-5.28a1.835,1.835,0,0,1-1.584-.816,3.764,3.764,0,0,1-.576-2.208,5.142,5.142,0,0,1,1.1-3.336,11.6,11.6,0,0,1,3.264-2.616v7.584a2.792,2.792,0,0,1-2.208,1.392h0Zm22.176,14.4q6.24,0,9.048-2.04a8.112,8.112,0,0,0,1.1-11.112,7.937,7.937,0,0,0-5.208-2.256l-7.3-.816a6.177,6.177,0,0,1-2.04-.528,1.017,1.017,0,0,1-.6-0.912,3.142,3.142,0,0,1,.72-1.68,14.1,14.1,0,0,0,4.752.768q4.7,0,7.128-2.5t2.424-7.056a11.846,11.846,0,0,0-1.1-5.184,23.342,23.342,0,0,1,2.28-1.128q1.368-.6,2.04-0.84l-1.824-3.744-1.008.48a7.911,7.911,0,0,0-3.36,2.88,9.255,9.255,0,0,0-6.576-2.16q-4.8,0-7.368,2.5t-2.568,7.152q0,4.752,2.736,7.2a12.159,12.159,0,0,0-2.328,2.592,5.174,5.174,0,0,0-.744,2.784q0,3.36,3.84,4.416-4.32,1.968-4.32,5.52a4.543,4.543,0,0,0,2.736,4.248,16.6,16.6,0,0,0,7.536,1.416h0Zm0.48-23.232a1.681,1.681,0,0,1-1.728-1.08,11.755,11.755,0,0,1-.432-3.864,11.941,11.941,0,0,1,.432-3.936,1.932,1.932,0,0,1,3.456.024,11.966,11.966,0,0,1,.432,3.912,11.73,11.73,0,0,1-.432,3.888,1.684,1.684,0,0,1-1.728,1.056h0Zm0.528,17.568a11.478,11.478,0,0,1-4.2-.552,1.836,1.836,0,0,1-1.272-1.752,3.406,3.406,0,0,1,1.632-2.592l5.136,0.528a10.35,10.35,0,0,1,3.288.7,1.533,1.533,0,0,1,.888,1.464,1.747,1.747,0,0,1-1.32,1.728,13.142,13.142,0,0,1-4.152.48h0Zm21.936-3.456a10.318,10.318,0,0,0,7.152-2.328q2.592-2.328,2.592-6.744V115.61q0-4.416-2.592-6.744a12.164,12.164,0,0,0-14.28-.024q-2.568,2.3-2.568,6.768v10.56q0,4.464,2.568,6.768a10.292,10.292,0,0,0,7.128,2.3h0Zm0.048-5.184a1.626,1.626,0,0,1-1.56-.84,5.43,5.43,0,0,1-.456-2.52V115.082a5.454,5.454,0,0,1,.456-2.5,1.617,1.617,0,0,1,1.56-.864,1.576,1.576,0,0,1,1.536.84,5.706,5.706,0,0,1,.432,2.52V126.7a5.706,5.706,0,0,1-.432,2.52,1.576,1.576,0,0,1-1.536.84h0Zm12.815,4.7h7.824v-21.7a4.76,4.76,0,0,1,2.448-1.008,1.4,1.4,0,0,1,1.224.5,2.705,2.705,0,0,1,.36,1.56v20.64h7.776V113.018a7.721,7.721,0,0,0-1.32-4.68,4.441,4.441,0,0,0-3.816-1.8q-3.408,0-6.672,3.264v-2.784h-7.824v27.744Z" />';
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

library Cuptype2 {
    using Strings for uint256;

    function getPath() external pure returns (string memory) {
        return '<path class="logo" d="M137.667,134.762h11.952q11.76,0,11.76-11.52a10.751,10.751,0,0,0-1.776-6.528,7.215,7.215,0,0,0-5.136-2.832,6.731,6.731,0,0,0,4.224-2.448,8.593,8.593,0,0,0,1.488-5.376,10.663,10.663,0,0,0-1.632-6.336,7.97,7.97,0,0,0-4.3-3.048,22.882,22.882,0,0,0-6.456-.792H137.667v38.88Zm8.592-23.328v-9.792h1.488a5.129,5.129,0,0,1,3.648,1.176,4.558,4.558,0,0,1,1.248,3.48,6.258,6.258,0,0,1-.984,3.888q-0.984,1.248-3.72,1.248h-1.68Zm0,17.328V117.1h1.776q2.784,0,3.912,1.344t1.128,4.656a6.7,6.7,0,0,1-1.128,4.3q-1.128,1.368-3.864,1.368h-1.824Zm18.336,6h7.776V95.882H164.6v38.88Zm16.512,0.48q3.312,0,6.576-3.024v2.544h7.776V107.018h-7.776V129.1a5.454,5.454,0,0,1-2.3.864,1.437,1.437,0,0,1-1.248-.528,2.681,2.681,0,0,1-.384-1.584V107.018h-7.824v21.744a7.615,7.615,0,0,0,1.344,4.68,4.5,4.5,0,0,0,3.84,1.8h0Zm27.168,0a9.864,9.864,0,0,0,6.792-2.16q2.422-2.16,2.424-6.336v-2.688h-7.2v2.928q0,2.688-2.016,2.688-1.922,0-1.921-2.976V121.37h11.137V115.8q0-4.56-2.3-6.912t-6.912-2.352a9.88,9.88,0,0,0-7.1,2.424,8.994,8.994,0,0,0-2.544,6.84v10.176a8.994,8.994,0,0,0,2.544,6.84,9.88,9.88,0,0,0,7.1,2.424h0Zm-1.921-17.52V115.37a4.85,4.85,0,0,1,.481-2.544,1.568,1.568,0,0,1,1.392-.72,1.884,1.884,0,0,1,1.512.648,3.388,3.388,0,0,1,.552,2.184v2.784h-3.937Zm25.728,17.04h9.936a19.028,19.028,0,0,0,7.8-1.3,7.692,7.692,0,0,0,3.984-3.984,18.276,18.276,0,0,0,1.176-7.2V108.17a17.944,17.944,0,0,0-1.176-7.128,7.505,7.505,0,0,0-4.008-3.912,20.024,20.024,0,0,0-7.872-1.248h-9.84v38.88Zm8.592-5.952V101.882h1.3a6.051,6.051,0,0,1,2.76.48,2.27,2.27,0,0,1,1.152,1.464,11.763,11.763,0,0,1,.264,2.856v16.944a14.512,14.512,0,0,1-.24,3.048,2.453,2.453,0,0,1-1.128,1.584,5.368,5.368,0,0,1-2.76.552h-1.344Zm18,5.952H266.5V116.714q2.063-2.688,4.608-2.688a6.99,6.99,0,0,1,2.544.576v-7.776a4.852,4.852,0,0,0-4.368,1.056,14.861,14.861,0,0,0-2.784,3.744v-4.608h-7.824v27.744Zm22.8,0.48a4.812,4.812,0,0,0,3.408-1.248,6.948,6.948,0,0,0,1.92-3.168q0.192,0.72.624,3.936h7.008a40.608,40.608,0,0,1-.48-6.912V114.89a8.466,8.466,0,0,0-2.16-6.072,8.188,8.188,0,0,0-6.24-2.28q-4.848,0-7.3,2.376t-2.64,7.368l7.3,0.288,0.192-2.016a3.2,3.2,0,0,1,.432-1.632,1.441,1.441,0,0,1,1.3-.576,1.343,1.343,0,0,1,1.272.624,3.713,3.713,0,0,1,.36,1.824v2.784a48.765,48.765,0,0,0-5.88,2.4,11.629,11.629,0,0,0-3.912,3.216,8.254,8.254,0,0,0-1.632,5.28,7.442,7.442,0,0,0,.744,3.24,6.273,6.273,0,0,0,2.208,2.544,6.1,6.1,0,0,0,3.48.984h0Zm2.784-5.28a1.835,1.835,0,0,1-1.584-.816,3.764,3.764,0,0,1-.576-2.208,5.142,5.142,0,0,1,1.1-3.336,11.6,11.6,0,0,1,3.264-2.616v7.584a2.792,2.792,0,0,1-2.208,1.392h0Zm22.176,14.4q6.24,0,9.048-2.04a8.112,8.112,0,0,0,1.1-11.112,7.937,7.937,0,0,0-5.208-2.256l-7.3-.816a6.177,6.177,0,0,1-2.04-.528,1.017,1.017,0,0,1-.6-0.912,3.142,3.142,0,0,1,.72-1.68,14.1,14.1,0,0,0,4.752.768q4.7,0,7.128-2.5t2.424-7.056a11.846,11.846,0,0,0-1.1-5.184,23.342,23.342,0,0,1,2.28-1.128q1.368-.6,2.04-0.84l-1.824-3.744-1.008.48a7.911,7.911,0,0,0-3.36,2.88,9.255,9.255,0,0,0-6.576-2.16q-4.8,0-7.368,2.5t-2.568,7.152q0,4.752,2.736,7.2a12.159,12.159,0,0,0-2.328,2.592,5.174,5.174,0,0,0-.744,2.784q0,3.36,3.84,4.416-4.32,1.968-4.32,5.52a4.543,4.543,0,0,0,2.736,4.248,16.6,16.6,0,0,0,7.536,1.416h0Zm0.48-23.232a1.681,1.681,0,0,1-1.728-1.08,11.755,11.755,0,0,1-.432-3.864,11.941,11.941,0,0,1,.432-3.936,1.932,1.932,0,0,1,3.456.024,11.966,11.966,0,0,1,.432,3.912,11.73,11.73,0,0,1-.432,3.888,1.684,1.684,0,0,1-1.728,1.056h0Zm0.528,17.568a11.478,11.478,0,0,1-4.2-.552,1.836,1.836,0,0,1-1.272-1.752A3.406,3.406,0,0,1,303.6,133.8l5.136,0.528a10.35,10.35,0,0,1,3.288.7,1.533,1.533,0,0,1,.888,1.464,1.747,1.747,0,0,1-1.32,1.728,13.142,13.142,0,0,1-4.152.48h0Zm21.936-3.456a10.318,10.318,0,0,0,7.152-2.328q2.592-2.328,2.592-6.744V115.61q0-4.416-2.592-6.744a12.164,12.164,0,0,0-14.28-.024q-2.568,2.3-2.568,6.768v10.56q0,4.464,2.568,6.768a10.292,10.292,0,0,0,7.128,2.3h0Zm0.048-5.184a1.626,1.626,0,0,1-1.56-.84,5.43,5.43,0,0,1-.456-2.52V115.082a5.454,5.454,0,0,1,.456-2.5,1.617,1.617,0,0,1,1.56-.864,1.576,1.576,0,0,1,1.536.84,5.706,5.706,0,0,1,.432,2.52V126.7a5.706,5.706,0,0,1-.432,2.52,1.576,1.576,0,0,1-1.536.84h0Zm12.815,4.7h7.824v-21.7a4.76,4.76,0,0,1,2.448-1.008,1.4,1.4,0,0,1,1.224.5,2.705,2.705,0,0,1,.36,1.56v20.64h7.776V113.018a7.721,7.721,0,0,0-1.32-4.68,4.441,4.441,0,0,0-3.816-1.8q-3.408,0-6.672,3.264v-2.784H342.24v27.744Z" />';
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

library Cuptype3 {
    using Strings for uint256;

    function getPath() external pure returns (string memory) {
        return '<path class="logo" d="M133.3,134.762h11.952q11.758,0,11.76-11.52a10.757,10.757,0,0,0-1.776-6.528,7.219,7.219,0,0,0-5.136-2.832,6.734,6.734,0,0,0,4.224-2.448,8.6,8.6,0,0,0,1.488-5.376,10.67,10.67,0,0,0-1.632-6.336,7.974,7.974,0,0,0-4.3-3.048,22.887,22.887,0,0,0-6.456-.792H133.3v38.88Zm8.592-23.328v-9.792h1.488a5.132,5.132,0,0,1,3.648,1.176,4.561,4.561,0,0,1,1.248,3.48,6.264,6.264,0,0,1-.984,3.888q-0.986,1.248-3.72,1.248h-1.68Zm0,17.328V117.1h1.776q2.782,0,3.912,1.344t1.128,4.656a6.706,6.706,0,0,1-1.128,4.3q-1.13,1.368-3.864,1.368h-1.824Zm23.712,6.48a4.816,4.816,0,0,0,3.408-1.248,6.957,6.957,0,0,0,1.92-3.168q0.19,0.72.624,3.936h7.008a40.5,40.5,0,0,1-.48-6.912V114.89a8.466,8.466,0,0,0-2.16-6.072,8.189,8.189,0,0,0-6.24-2.28q-4.85,0-7.3,2.376t-2.64,7.368l7.3,0.288,0.192-2.016a3.181,3.181,0,0,1,.432-1.632,1.439,1.439,0,0,1,1.3-.576,1.344,1.344,0,0,1,1.272.624,3.713,3.713,0,0,1,.36,1.824v2.784a48.7,48.7,0,0,0-5.88,2.4,11.61,11.61,0,0,0-3.912,3.216,8.248,8.248,0,0,0-1.632,5.28,7.428,7.428,0,0,0,.744,3.24,6.258,6.258,0,0,0,2.208,2.544,6.1,6.1,0,0,0,3.48.984h0Zm2.784-5.28a1.835,1.835,0,0,1-1.584-.816,3.764,3.764,0,0,1-.576-2.208,5.137,5.137,0,0,1,1.1-3.336,11.59,11.59,0,0,1,3.264-2.616v7.584a2.794,2.794,0,0,1-2.208,1.392h0Zm26.927,5.28a5.1,5.1,0,0,0,4.464-2.3,10.942,10.942,0,0,0,1.585-6.288V114.7a10.7,10.7,0,0,0-1.464-5.9,4.98,4.98,0,0,0-4.488-2.256,8.354,8.354,0,0,0-3.072.624,9.881,9.881,0,0,0-2.977,1.872V95.882h-7.823v38.88h7.823V132.65a9.112,9.112,0,0,0,5.952,2.592h0Zm-3.791-5.04a3.638,3.638,0,0,1-2.161-.768v-17.28a3.662,3.662,0,0,1,2.257-.912,1.564,1.564,0,0,1,1.464.792,4.175,4.175,0,0,1,.456,2.088v12.96a4.639,4.639,0,0,1-.48,2.256,1.631,1.631,0,0,1-1.536.864h0Zm13.871,12.624h1.776a10.953,10.953,0,0,0,6.336-1.656q2.4-1.656,3.312-5.736l6.384-28.416H215.81l-2.64,16.032-3.5-16.032h-7.344l6.528,23.376a20.978,20.978,0,0,1,1.008,4.656,1.857,1.857,0,0,1-1.08,1.848,8.474,8.474,0,0,1-3.384.5v5.424Zm31.056-8.064h9.936a19.025,19.025,0,0,0,7.8-1.3,7.689,7.689,0,0,0,3.984-3.984,18.258,18.258,0,0,0,1.176-7.2V108.17a17.926,17.926,0,0,0-1.176-7.128,7.5,7.5,0,0,0-4.008-3.912,20.021,20.021,0,0,0-7.872-1.248h-9.84v38.88Zm8.592-5.952V101.882h1.3a6.048,6.048,0,0,1,2.76.48,2.264,2.264,0,0,1,1.152,1.464,11.713,11.713,0,0,1,.264,2.856v16.944a14.444,14.444,0,0,1-.24,3.048,2.446,2.446,0,0,1-1.128,1.584,5.366,5.366,0,0,1-2.76.552h-1.344Zm18,5.952h7.824V116.714q2.064-2.688,4.608-2.688a6.986,6.986,0,0,1,2.544.576v-7.776a4.852,4.852,0,0,0-4.368,1.056,14.885,14.885,0,0,0-2.784,3.744v-4.608h-7.824v27.744Zm22.8,0.48a4.814,4.814,0,0,0,3.408-1.248,6.957,6.957,0,0,0,1.92-3.168q0.19,0.72.624,3.936H298.8a40.608,40.608,0,0,1-.48-6.912V114.89a8.466,8.466,0,0,0-2.16-6.072,8.189,8.189,0,0,0-6.24-2.28q-4.85,0-7.3,2.376t-2.64,7.368l7.3,0.288,0.192-2.016a3.181,3.181,0,0,1,.432-1.632,1.441,1.441,0,0,1,1.3-.576,1.344,1.344,0,0,1,1.272.624,3.713,3.713,0,0,1,.36,1.824v2.784a48.7,48.7,0,0,0-5.88,2.4,11.619,11.619,0,0,0-3.912,3.216,8.254,8.254,0,0,0-1.632,5.28,7.428,7.428,0,0,0,.744,3.24,6.266,6.266,0,0,0,2.208,2.544,6.1,6.1,0,0,0,3.48.984h0Zm2.784-5.28a1.835,1.835,0,0,1-1.584-.816,3.764,3.764,0,0,1-.576-2.208,5.137,5.137,0,0,1,1.1-3.336,11.6,11.6,0,0,1,3.264-2.616v7.584a2.794,2.794,0,0,1-2.208,1.392h0Zm22.176,14.4q6.238,0,9.048-2.04a8.112,8.112,0,0,0,1.1-11.112,7.942,7.942,0,0,0-5.208-2.256l-7.3-.816a6.169,6.169,0,0,1-2.04-.528,1.016,1.016,0,0,1-.6-0.912,3.142,3.142,0,0,1,.72-1.68,14.1,14.1,0,0,0,4.752.768q4.7,0,7.128-2.5t2.424-7.056a11.86,11.86,0,0,0-1.1-5.184,23.229,23.229,0,0,1,2.28-1.128q1.368-.6,2.04-0.84l-1.824-3.744-1.008.48a7.9,7.9,0,0,0-3.36,2.88,9.257,9.257,0,0,0-6.576-2.16q-4.8,0-7.368,2.5t-2.568,7.152q0,4.752,2.736,7.2a12.131,12.131,0,0,0-2.328,2.592,5.165,5.165,0,0,0-.744,2.784q0,3.36,3.84,4.416-4.32,1.968-4.32,5.52a4.543,4.543,0,0,0,2.736,4.248,16.6,16.6,0,0,0,7.536,1.416h0Zm0.48-23.232a1.681,1.681,0,0,1-1.728-1.08,11.755,11.755,0,0,1-.432-3.864,11.941,11.941,0,0,1,.432-3.936,1.932,1.932,0,0,1,3.456.024,11.966,11.966,0,0,1,.432,3.912,11.73,11.73,0,0,1-.432,3.888,1.684,1.684,0,0,1-1.728,1.056h0ZM311.81,138.7a11.471,11.471,0,0,1-4.2-.552,1.834,1.834,0,0,1-1.272-1.752,3.4,3.4,0,0,1,1.632-2.592l5.136,0.528a10.364,10.364,0,0,1,3.288.7,1.534,1.534,0,0,1,.888,1.464,1.748,1.748,0,0,1-1.32,1.728,13.151,13.151,0,0,1-4.152.48h0Zm21.935-3.456a10.318,10.318,0,0,0,7.152-2.328q2.592-2.328,2.592-6.744V115.61q0-4.416-2.592-6.744a12.164,12.164,0,0,0-14.28-.024q-2.568,2.3-2.568,6.768v10.56q0,4.464,2.568,6.768a10.3,10.3,0,0,0,7.128,2.3h0Zm0.048-5.184a1.627,1.627,0,0,1-1.56-.84,5.443,5.443,0,0,1-.456-2.52V115.082a5.467,5.467,0,0,1,.456-2.5,1.618,1.618,0,0,1,1.56-.864,1.576,1.576,0,0,1,1.536.84,5.706,5.706,0,0,1,.432,2.52V126.7a5.706,5.706,0,0,1-.432,2.52,1.576,1.576,0,0,1-1.536.84h0Zm12.816,4.7h7.824v-21.7a4.754,4.754,0,0,1,2.448-1.008,1.4,1.4,0,0,1,1.224.5,2.705,2.705,0,0,1,.36,1.56v20.64h7.776V113.018a7.728,7.728,0,0,0-1.32-4.68,4.444,4.444,0,0,0-3.816-1.8q-3.41,0-6.672,3.264v-2.784h-7.824v27.744Z" />';
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

library Cuptype4 {
    using Strings for uint256;

    function getPath() external pure returns (string memory) {
        return '<path class="logo" d="M146.355,134.762h9.936a19.025,19.025,0,0,0,7.8-1.3,7.689,7.689,0,0,0,3.984-3.984,18.258,18.258,0,0,0,1.176-7.2V108.17a17.926,17.926,0,0,0-1.176-7.128,7.5,7.5,0,0,0-4.008-3.912,20.021,20.021,0,0,0-7.872-1.248h-9.84v38.88Zm8.592-5.952V101.882h1.3a6.048,6.048,0,0,1,2.76.48,2.264,2.264,0,0,1,1.152,1.464,11.713,11.713,0,0,1,.264,2.856v16.944a14.444,14.444,0,0,1-.24,3.048,2.446,2.446,0,0,1-1.128,1.584,5.366,5.366,0,0,1-2.76.552h-1.344Zm18,5.952h7.824V116.714q2.064-2.688,4.608-2.688a6.986,6.986,0,0,1,2.544.576v-7.776a4.852,4.852,0,0,0-4.368,1.056,14.885,14.885,0,0,0-2.784,3.744v-4.608h-7.824v27.744Zm22.8,0.48a4.814,4.814,0,0,0,3.408-1.248,6.957,6.957,0,0,0,1.92-3.168q0.191,0.72.624,3.936h7.008a40.608,40.608,0,0,1-.48-6.912V114.89a8.466,8.466,0,0,0-2.16-6.072,8.189,8.189,0,0,0-6.24-2.28q-4.85,0-7.3,2.376t-2.64,7.368l7.3,0.288,0.192-2.016a3.181,3.181,0,0,1,.432-1.632,1.441,1.441,0,0,1,1.3-.576,1.344,1.344,0,0,1,1.272.624,3.713,3.713,0,0,1,.36,1.824v2.784a48.7,48.7,0,0,0-5.88,2.4,11.619,11.619,0,0,0-3.912,3.216,8.254,8.254,0,0,0-1.632,5.28,7.428,7.428,0,0,0,.744,3.24,6.266,6.266,0,0,0,2.208,2.544,6.1,6.1,0,0,0,3.48.984h0Zm2.784-5.28a1.835,1.835,0,0,1-1.584-.816,3.764,3.764,0,0,1-.576-2.208,5.137,5.137,0,0,1,1.1-3.336,11.6,11.6,0,0,1,3.264-2.616v7.584a2.794,2.794,0,0,1-2.208,1.392h0Zm22.176,14.4q6.239,0,9.048-2.04a8.112,8.112,0,0,0,1.1-11.112,7.942,7.942,0,0,0-5.208-2.256l-7.3-.816a6.177,6.177,0,0,1-2.04-.528,1.016,1.016,0,0,1-.6-0.912,3.142,3.142,0,0,1,.72-1.68,14.1,14.1,0,0,0,4.752.768q4.7,0,7.128-2.5t2.424-7.056a11.86,11.86,0,0,0-1.1-5.184,23.229,23.229,0,0,1,2.28-1.128q1.368-.6,2.04-0.84l-1.824-3.744-1.008.48a7.9,7.9,0,0,0-3.36,2.88,9.257,9.257,0,0,0-6.576-2.16q-4.8,0-7.368,2.5t-2.568,7.152q0,4.752,2.736,7.2a12.131,12.131,0,0,0-2.328,2.592,5.165,5.165,0,0,0-.744,2.784q0,3.36,3.84,4.416-4.32,1.968-4.32,5.52a4.543,4.543,0,0,0,2.736,4.248,16.6,16.6,0,0,0,7.536,1.416h0Zm0.48-23.232a1.681,1.681,0,0,1-1.728-1.08,11.755,11.755,0,0,1-.432-3.864,11.941,11.941,0,0,1,.432-3.936,1.932,1.932,0,0,1,3.456.024,11.966,11.966,0,0,1,.432,3.912,11.73,11.73,0,0,1-.432,3.888,1.684,1.684,0,0,1-1.728,1.056h0Zm0.528,17.568a11.471,11.471,0,0,1-4.2-.552,1.834,1.834,0,0,1-1.272-1.752,3.4,3.4,0,0,1,1.632-2.592l5.136,0.528a10.364,10.364,0,0,1,3.288.7,1.534,1.534,0,0,1,.888,1.464,1.748,1.748,0,0,1-1.32,1.728,13.151,13.151,0,0,1-4.152.48h0Zm21.935-3.456a10.318,10.318,0,0,0,7.152-2.328q2.592-2.328,2.592-6.744V115.61q0-4.416-2.592-6.744a12.164,12.164,0,0,0-14.28-.024q-2.568,2.3-2.568,6.768v10.56q0,4.464,2.568,6.768a10.3,10.3,0,0,0,7.128,2.3h0Zm0.048-5.184a1.627,1.627,0,0,1-1.56-.84,5.443,5.443,0,0,1-.456-2.52V115.082a5.467,5.467,0,0,1,.456-2.5,1.618,1.618,0,0,1,1.56-.864,1.576,1.576,0,0,1,1.536.84,5.706,5.706,0,0,1,.432,2.52V126.7a5.706,5.706,0,0,1-.432,2.52,1.576,1.576,0,0,1-1.536.84h0Zm12.816,4.7h7.824v-21.7a4.754,4.754,0,0,1,2.448-1.008,1.4,1.4,0,0,1,1.224.5,2.705,2.705,0,0,1,.36,1.56v20.64h7.776V113.018a7.728,7.728,0,0,0-1.32-4.68,4.444,4.444,0,0,0-3.816-1.8q-3.409,0-6.672,3.264v-2.784h-7.824v27.744Zm34.655,0h17.568v-5.808h-8.976V117.338h6.768v-5.952h-6.768v-9.648h8.88V95.882H291.169v38.88Zm28.848,9.6q6.238,0,9.048-2.04a8.112,8.112,0,0,0,1.1-11.112,7.942,7.942,0,0,0-5.208-2.256l-7.3-.816a6.169,6.169,0,0,1-2.04-.528,1.016,1.016,0,0,1-.6-0.912,3.142,3.142,0,0,1,.72-1.68,14.1,14.1,0,0,0,4.752.768q4.7,0,7.128-2.5t2.424-7.056a11.86,11.86,0,0,0-1.1-5.184,23.229,23.229,0,0,1,2.28-1.128q1.368-.6,2.04-0.84l-1.824-3.744-1.008.48a7.9,7.9,0,0,0-3.36,2.88,9.257,9.257,0,0,0-6.576-2.16q-4.8,0-7.368,2.5t-2.568,7.152q0,4.752,2.736,7.2a12.131,12.131,0,0,0-2.328,2.592,5.165,5.165,0,0,0-.744,2.784q0,3.36,3.84,4.416-4.32,1.968-4.32,5.52a4.543,4.543,0,0,0,2.736,4.248,16.6,16.6,0,0,0,7.536,1.416h0Zm0.48-23.232a1.681,1.681,0,0,1-1.728-1.08,11.755,11.755,0,0,1-.432-3.864,11.941,11.941,0,0,1,.432-3.936,1.932,1.932,0,0,1,3.456.024,11.966,11.966,0,0,1,.432,3.912,11.73,11.73,0,0,1-.432,3.888,1.684,1.684,0,0,1-1.728,1.056h0Zm0.528,17.568a11.471,11.471,0,0,1-4.2-.552,1.834,1.834,0,0,1-1.272-1.752,3.4,3.4,0,0,1,1.632-2.592l5.136,0.528a10.364,10.364,0,0,1,3.288.7,1.534,1.534,0,0,1,.888,1.464,1.748,1.748,0,0,1-1.32,1.728,13.151,13.151,0,0,1-4.152.48h0Zm21.839,5.664q6.24,0,9.048-2.04a8.112,8.112,0,0,0,1.1-11.112,7.937,7.937,0,0,0-5.208-2.256l-7.3-.816a6.177,6.177,0,0,1-2.04-.528,1.017,1.017,0,0,1-.6-0.912,3.142,3.142,0,0,1,.72-1.68,14.1,14.1,0,0,0,4.752.768q4.7,0,7.128-2.5t2.424-7.056a11.846,11.846,0,0,0-1.1-5.184,23.342,23.342,0,0,1,2.28-1.128q1.368-.6,2.04-0.84l-1.824-3.744-1.008.48a7.911,7.911,0,0,0-3.36,2.88,9.255,9.255,0,0,0-6.576-2.16q-4.8,0-7.368,2.5t-2.568,7.152q0,4.752,2.736,7.2a12.159,12.159,0,0,0-2.328,2.592,5.174,5.174,0,0,0-.744,2.784q0,3.36,3.84,4.416-4.32,1.968-4.32,5.52a4.543,4.543,0,0,0,2.736,4.248,16.6,16.6,0,0,0,7.536,1.416h0Zm0.48-23.232a1.681,1.681,0,0,1-1.728-1.08,11.755,11.755,0,0,1-.432-3.864,11.941,11.941,0,0,1,.432-3.936,1.932,1.932,0,0,1,3.456.024,11.966,11.966,0,0,1,.432,3.912,11.73,11.73,0,0,1-.432,3.888,1.684,1.684,0,0,1-1.728,1.056h0Zm0.528,17.568a11.478,11.478,0,0,1-4.2-.552,1.836,1.836,0,0,1-1.272-1.752,3.406,3.406,0,0,1,1.632-2.592l5.136,0.528a10.35,10.35,0,0,1,3.288.7,1.533,1.533,0,0,1,.888,1.464,1.747,1.747,0,0,1-1.32,1.728,13.142,13.142,0,0,1-4.152.48h0Z" />';
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

library Cuptype5 {
    using Strings for uint256;

    function getPath() external pure returns (string memory) {
        return '<path class="logo" d="M137.572,134.762h8.592V119.113l0.913-1.537,5.616,17.186h8.737l-7.537-21.314,7.2-17.569h-8.4l-6.529,15.889V95.879h-8.592v38.884Zm25.583-32.451h7.873V96.887h-7.873v5.424Zm0.048,32.451h7.825V107.015H163.2v27.747Zm11.472,0H182.5v-21.7a4.988,4.988,0,0,1,2.448-1.008c1.2,0,1.584.72,1.584,2.064v20.642h7.777V113.016c0-3.7-1.728-6.481-5.137-6.481-2.448,0-4.656,1.249-6.672,3.265v-2.785h-7.825v27.747Zm32.16,9.6c8.545,0,11.857-2.833,11.857-8.161,0-4.08-2.16-6.721-6.912-7.249l-7.3-.816c-1.968-.24-2.64-0.672-2.64-1.44a2.921,2.921,0,0,1,.72-1.68,14.29,14.29,0,0,0,4.752.768c6.337,0,9.553-3.552,9.553-9.553a12.315,12.315,0,0,0-1.1-5.184,34.85,34.85,0,0,1,4.32-1.968l-1.824-3.745-1.008.48a8.062,8.062,0,0,0-3.36,2.881c-1.536-1.44-3.7-2.161-6.577-2.161-6.384,0-9.937,3.409-9.937,9.649,0,3.313.96,5.617,2.737,7.2-1.921,1.68-3.073,3.168-3.073,5.376,0,2.353,1.392,3.745,3.841,4.417-2.545,1.152-4.321,2.928-4.321,5.52C196.562,142.539,200.6,144.363,206.835,144.363Zm0.48-23.234c-1.776,0-2.16-1.392-2.16-4.945,0-3.7.384-4.992,2.16-4.992s2.16,1.344,2.16,4.992S209.091,121.129,207.315,121.129Zm0.528,17.569c-3.984,0-5.472-.768-5.472-2.3A3.332,3.332,0,0,1,204,133.8l5.136,0.528c3.217,0.336,4.177.816,4.177,2.16C213.316,138.266,211.348,138.7,207.843,138.7Zm24.335-3.936h9.937c10.033,0,12.961-3.744,12.961-12.481V108.168c0-8.641-2.928-12.29-13.057-12.29h-9.841v38.884Zm8.593-5.953v-26.93h1.3c3.792,0,4.176,1.392,4.176,4.8v16.946c0,3.5-.24,5.184-4.128,5.184h-1.344Zm18,5.953h7.824v-18.05a5.892,5.892,0,0,1,4.609-2.688,6.839,6.839,0,0,1,2.544.576v-7.777a4.322,4.322,0,0,0-1.2-.144c-2.592,0-4.176,1.777-5.953,4.945v-4.609H258.77v27.747Zm22.8,0.48c2.928,0,4.656-2.112,5.329-4.416,0.1,0.336.432,2.448,0.624,3.936h7.008a39.446,39.446,0,0,1-.48-6.913V114.888c0-4.9-2.784-8.353-8.4-8.353-6.48,0-9.648,3.073-9.936,9.745l7.3,0.288,0.192-2.016c0.048-1.248.384-2.208,1.728-2.208,1.3,0,1.633,1.008,1.633,2.448v2.784c-5.233,1.825-11.425,3.985-11.425,10.9C275.138,131.738,277.346,135.242,281.57,135.242Zm2.784-5.281c-1.344,0-2.16-1.152-2.16-3.024,0-2.784,1.776-4.464,4.369-5.952v7.584A2.866,2.866,0,0,1,284.354,129.961Zm22.176,14.4c8.545,0,11.857-2.833,11.857-8.161,0-4.08-2.16-6.721-6.912-7.249l-7.3-.816c-1.968-.24-2.64-0.672-2.64-1.44a2.921,2.921,0,0,1,.72-1.68,14.29,14.29,0,0,0,4.752.768c6.337,0,9.553-3.552,9.553-9.553a12.315,12.315,0,0,0-1.1-5.184,34.85,34.85,0,0,1,4.32-1.968l-1.824-3.745-1.008.48a8.062,8.062,0,0,0-3.36,2.881c-1.536-1.44-3.7-2.161-6.577-2.161-6.384,0-9.937,3.409-9.937,9.649,0,3.313.961,5.617,2.737,7.2-1.92,1.68-3.073,3.168-3.073,5.376,0,2.353,1.393,3.745,3.841,4.417-2.544,1.152-4.321,2.928-4.321,5.52C296.257,142.539,300.29,144.363,306.53,144.363Zm0.48-23.234c-1.776,0-2.16-1.392-2.16-4.945,0-3.7.384-4.992,2.16-4.992s2.16,1.344,2.16,4.992S308.786,121.129,307.01,121.129Zm0.528,17.569c-3.984,0-5.472-.768-5.472-2.3A3.332,3.332,0,0,1,303.7,133.8l5.136,0.528c3.217,0.336,4.177.816,4.177,2.16C313.011,138.266,311.043,138.7,307.538,138.7Zm21.936-3.456c5.9,0,9.745-3.024,9.745-9.073V115.608c0-6.048-3.841-9.073-9.745-9.073-5.953,0-9.7,3.025-9.7,9.073v10.561C319.777,132.218,323.521,135.242,329.474,135.242Zm0.048-5.184c-1.536,0-2.016-1.249-2.016-3.361V115.08c0-2.064.48-3.36,2.016-3.36s1.968,1.248,1.968,3.36V126.7C331.49,128.809,331.058,130.058,329.522,130.058Zm12.814,4.7h7.825v-21.7a4.988,4.988,0,0,1,2.448-1.008c1.2,0,1.584.72,1.584,2.064v20.642h7.777V113.016c0-3.7-1.728-6.481-5.136-6.481-2.449,0-4.657,1.249-6.673,3.265v-2.785h-7.825v27.747Zm-151.773,62h7.585l3.12-23.474,3.312,23.474h7.489l4.656-38.884h-7.2l-2.353,22.514L204.1,157.926h-5.712l-2.929,22.61-2.3-22.658h-7.3Zm28.7-32.451h7.873v-5.425h-7.873v5.425Zm0.048,32.451h7.825V169.015h-7.825v27.747Zm11.472,0h7.825v-21.7a4.988,4.988,0,0,1,2.448-1.008c1.2,0,1.584.72,1.584,2.064v20.642h7.777V175.016c0-3.7-1.728-6.481-5.136-6.481-2.449,0-4.657,1.248-6.673,3.265v-2.785h-7.825v27.747Zm23.136,0h7.824v-21.7a5,5,0,0,1,2.449-1.008c1.2,0,1.584.72,1.584,2.064v20.642h7.776V175.016c0-3.7-1.728-6.481-5.136-6.481-2.448,0-4.656,1.248-6.673,3.265v-2.785h-7.824v27.747Zm32.208,0.48c5.76,0,9.217-2.88,9.217-8.5v-2.688h-7.2v2.928c0,2.016-.864,2.688-2.016,2.688s-1.92-.816-1.92-2.976v-5.328h11.137V177.8c0-6.048-3.072-9.265-9.217-9.265-6,0-9.649,3.313-9.649,9.265v10.177C276.481,193.881,280.081,197.242,286.13,197.242Zm-1.92-17.522v-2.352c0-2.544.72-3.264,1.872-3.264,1.2,0,2.064.624,2.064,2.832v2.784H284.21Zm14.3,17.042h7.824v-18.05a5.889,5.889,0,0,1,4.609-2.688,6.839,6.839,0,0,1,2.544.576v-7.777a4.322,4.322,0,0,0-1.2-.144c-2.593,0-4.177,1.776-5.953,4.945v-4.609h-7.824v27.747Z"/>';
    }
}

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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