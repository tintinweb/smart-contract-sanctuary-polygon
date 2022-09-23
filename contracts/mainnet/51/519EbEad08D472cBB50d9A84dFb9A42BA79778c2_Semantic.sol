// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "../interfaces/ISemantic.sol";
import "../utils/Strings.sol";
import "../access/AccessControl.sol";
import "./Semantic721.sol";

contract Semantic is ISemantic, AccessControl, Semantic721 {
    using Strings for uint256;
    using Strings for address;

    //class
    mapping(uint256 => Class) public classIdForData;
    mapping(string => uint256) public classDataForId;
    uint256 public classSize;
    //subject
    mapping(uint256 => Subject) public subjectIdForData;
    mapping(uint256 => mapping(string => uint256)) public subjectDataForId;
    mapping(uint256 => mapping(uint256 => mapping(string => bool))) public subjectOwner;

    uint256 public subjectSize;
    //predicate
    mapping(uint256 => Predicate) public predicateIdForData;
    mapping(string => uint256) public predicateDataForId;
    uint256 public predicateSize;
    //token
    mapping(uint256 => Turtle) public tokenIdForTurtleData;


    uint256 public totalSupply;

    // createInfo
    uint256 public createdAt;
    uint256 public createdAtBlockNumber;
    address public deployer;



    mapping(string => string) public prefixMap;
    string public constant SUFFIX = " . ";
    string public constant NO_PERMISSION =
        "0x0000000000000000000000000000000000000000";
    string public constant ALL_PERMISSION =
        "0x0000000000000000000000000000000000000001";

    uint256 public constant SOUL_CLASS_ID = 1;
    uint256 public constant OWNER_PREDICATE_ID = 1;

    address public singerPub;

    constructor() {
        deployer = msg.sender;
        createdAt = block.timestamp;
        createdAtBlockNumber = block.number;
    }

    function initialize(
        address owner,
        string memory _uri,
        string memory soulClassValue,
        string memory ownerPredicateValue
    ) public {
        require(deployer == msg.sender, "not deployer");
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _setBaseUri(_uri);

        _setClass(Class(soulClassValue, FieldType.ADDRESS));
        _setPredicate(Predicate(ownerPredicateValue, FieldType.ADDRESS));
    }

    function setBaseUri(string memory _uri)
        public
        onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE))
    {
        _setBaseUri(_uri);
    }

    /**
     * @dev add class
     * @param classes the class array
     */
    function addClasss(Class[] memory classes)
        external
        onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE))
    {
        for (uint256 i = 0; i < classes.length; i++) {
            Class memory class = classes[i];
            require(
                keccak256(abi.encode(class.value)) != keccak256(abi.encode("")),
                "class can not empty"
            );
            require(
                classSize == 0 || classDataForId[class.value] == 0,
                "class already exist"
            );
            _setClass(class);
        }
    }

    /**
     * @dev add predicate
     * @param predicateInfos the predicate
     */
    function addPredicates(Predicate[] memory predicateInfos)
        external
        onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE))
    {
        for (uint256 i = 0; i < predicateInfos.length; i++) {
            Predicate memory predicateInfo = predicateInfos[i];
            require(
                keccak256(abi.encode(predicateInfo.value)) !=
                    keccak256(abi.encode("")),
                "predicate can not empty"
            );
            require(
                keccak256(abi.encode(predicateInfo.predicateType)) !=
                    keccak256(abi.encode("")),
                "predicateType can not empty"
            );
            require(
                predicateSize == 0 || predicateDataForId[predicateInfo.value] == 0,
                "predicate already exist"
            );
            _setPredicate(predicateInfo);
        }
    }


    /**
     * @dev mint SBT , only admin can call
     * @param operateDatas the  operate data
     */
    function adminMint(OperateData[] memory operateDatas)
        external
        onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE))
    {
        for (uint256 i = 0; i < operateDatas.length; i++) {
            OperateData memory operateData = operateDatas[i];

            uint256 subjectId = generateSubjectId(
                operateData.subject.classId,
                operateData.subject.value
            );
            for (
                uint256 j = 0;
                j < operateData.predicateAndObjects.length;
                j++
            ) {
                PredicateAndObject memory predicateAndObject = operateData.predicateAndObjects[j];
                require(
                    predicateAndObject.predicateId <= predicateSize,
                    "predicate undefined"
                );
            }
            _mintTurtle(
                msg.sender,
                subjectId,
                operateData.subject.value,
                operateData.subject.classId,
                operateData.predicateAndObjects
            );
        }
    }

    /**
     * @dev mint SBT
     * @param operateDatas the  operate data
     */
    function mint(OperateData[] memory operateDatas) external {
        for (uint256 i = 0; i < operateDatas.length; i++) {
            OperateData memory operateData = operateDatas[i];
            _checkPermission(
                operateData.subject.classId,
                operateData.subject.value
            );
            uint256 subjectId = generateSubjectId(
                operateData.subject.classId,
                operateData.subject.value
            );
            for (
                uint256 j = 0;
                j < operateData.predicateAndObjects.length;
                j++
            ) {
                PredicateAndObject memory predicateAndObject = operateData
                    .predicateAndObjects[j];
                require(
                    predicateAndObject.predicateId <= predicateSize,
                    "predicate undefined"
                );
            }

        _mintTurtle(
                msg.sender,
                subjectId,
                operateData.subject.value,
                operateData.subject.classId,
                operateData.predicateAndObjects
            );
        }
    }

    /**
     * @dev mint SBT , subject is caller address
     * @param operateDatas the  operate data
     */
    function soulMint(SoulOperateData[] memory operateDatas) external {
        uint256 subjectId = generateSubjectId(
                SOUL_CLASS_ID,
                Strings.toHexString(msg.sender)
            );
        for (uint256 i = 0; i < operateDatas.length; i++) {
            SoulOperateData memory operateData = operateDatas[i];
            for (
                uint256 j = 0;
                j < operateData.predicateAndObjects.length;
                j++
            ) {
                PredicateAndObject memory predicateAndObject = operateData
                    .predicateAndObjects[j];
                require(
                    predicateAndObject.predicateId <= predicateSize,
                    "predicate undefined"
                );
            }
            _mintTurtle(
                msg.sender,
                subjectId,
                Strings.toHexString(msg.sender),
                SOUL_CLASS_ID,
                operateData.predicateAndObjects
            );
        }
    }

    /**
     * @dev claim sbt
     * @param  operateDatas the  operate data
     */
    function claim(ClaimOperateData[] memory operateDatas) external {
        for (uint256 i = 0; i < operateDatas.length; i++) {
            ClaimOperateData memory operateData = operateDatas[i];

            require(
                operateData.expireTime > block.timestamp,
                "signData has expired"
            );
            uint256 subjectId = operateData.subjectId;
            string memory signOriginalData = string.concat(operateData.expireTime.toString(),subjectId.toString());
            for (
                uint256 j = 0;
                j < operateData.predicateAndObjects.length;
                j++
            ) {
                PredicateAndObject memory predicateAndObject = operateData
                    .predicateAndObjects[j];
                require(
                    predicateAndObject.predicateId <= predicateSize,
                    "predicate undefined"
                );
                signOriginalData = string.concat(signOriginalData,predicateAndObject.predicateId.toString(),predicateAndObject.object);
            }

            address singer = _verifyMessage(
                keccak256(abi.encodePacked(signOriginalData)),
                operateData.v,
                operateData.r,
                operateData.s
            );
            require(hasRole(DEFAULT_ADMIN_ROLE,singer), "signData not from singer");
            _mintTurtle(
                msg.sender,
                subjectId,
                subjectIdForData[operateData.subjectId].value,
                subjectIdForData[operateData.subjectId].classId,
                operateData.predicateAndObjects
            );
        }
    }



    /**
     * @dev burn SBT, only admin can operate
     * @param tokenIds  the tokenIds for burn
     */
    function adminBurn(uint256[] memory tokenIds) external  onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)){
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address owner = _ownerOf(tokenIds[i]);
            _burn(owner, tokenIds[i]);
        }
    }

    /**
     * @dev burn SBT
     * @param tokenIds 操作数据
     */
    function burn(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address owner = _ownerOf(tokenIds[i]);
            require(owner == msg.sender,"not owner");
            _burn(owner, tokenIds[i]);
        }
    }

    function checkTurtleExist(uint256 tokenId,uint256 subjectId,uint256 predicateId,string memory object) external view returns (bool){
        Turtle storage turtle = tokenIdForTurtleData[tokenId];
        return subjectId == turtle.subjectId && turtle.predicateIdToObject[predicateId][object];
    }




    function _setClass(Class memory class) private {
        classSize++;
        classIdForData[classSize] = class;
        classDataForId[class.value] = classSize;
        emit AddClass(msg.sender, classSize, class.value);
    }

    function _setPredicate(Predicate memory predicateInfo) private {
        predicateSize++;
        predicateIdForData[predicateSize] = predicateInfo;
        predicateDataForId[predicateInfo.value] = predicateSize;
        emit AddPredicates(
            msg.sender,
            predicateSize,
            predicateInfo.value,
            predicateInfo.predicateType
        );
    }


    function _mintTurtle(
        address owner,
        uint256 subjectId,
        string memory subjectValue,
        uint256 classId,
        PredicateAndObject[] memory predicateAndObjects
    ) private {
        totalSupply++;
        uint256 tokenId = totalSupply;

        string memory rdf = "";
        Turtle storage turtle = tokenIdForTurtleData[tokenId];
        turtle.subjectId = subjectId;
        for (uint256 i = 0; i < predicateAndObjects.length; i++) {
            PredicateAndObject memory predicateAndObject = predicateAndObjects[i];
            if (!turtle.predicateIdToObject[predicateAndObject.predicateId][predicateAndObject.object]){
                turtle.predicateIdToObject[predicateAndObject.predicateId][predicateAndObject.object] = true;
                string memory singleRdf = generateRdf(
                                classId,
                                subjectValue,
                                predicateAndObject.predicateId,
                                predicateAndObject.object
                            );
                rdf = string.concat(rdf, singleRdf);
            }
        }
        _setOwner(tokenId, owner);
        _addBalance(owner);
        emit Mint(msg.sender, tokenId, rdf);
        emit Transfer(address(0), owner, tokenId);
    }

    function _burn(
        address owner,
        uint256 tokenId
    ) private {
        delete tokenIdForTurtleData[tokenId];
        _reduceBalance(owner);
        _removeOwner(tokenId);
        emit Burn(msg.sender, owner, tokenId);
        emit Transfer( owner,address(0), tokenId);
    }

    function generateSubjectId(uint256 classId, string memory subjectValue)
        public
        returns (uint256)
    {
        uint256 subjectId = subjectDataForId[classId][subjectValue];
        if (subjectId == 0) {
            subjectSize++;
            subjectDataForId[classId][subjectValue] = subjectSize;
            subjectIdForData[subjectSize] = Subject(subjectValue, classId);
            subjectId = subjectSize;
            _setSubjectOwner(subjectId);
        }
        return subjectId;
    }

    function generateRdf(
        uint256 classId,
        string memory subjectValue,
        uint256 predicateId,
        string memory object
    ) public view returns (string memory) {
        string memory subject = string.concat(
            classIdForData[classId].value,
            subjectValue
        );
        string memory predicate = predicateIdForData[predicateId].value;
        if (predicateIdForData[predicateId].predicateType == FieldType.STRING) {
            object = string.concat('"', object, '"');
        }
        string memory rdf = string.concat(
            subject,
            " ",
            predicate,
            " ",
            object,
            SUFFIX
        );
        return rdf;
    }

    function _checkPermission(uint256 classId, string memory subjectValue)
        internal
        virtual
    {
        uint256 subjectId = subjectDataForId[classId][subjectValue];
        if (subjectId > 0) {
            require(
                _isSubjectOwner(subjectId) ||
                    subjectOwner[subjectId][OWNER_PREDICATE_ID][string.concat(classIdForData[SOUL_CLASS_ID].value, ALL_PERMISSION)] ,
                "not have permission"
            );
        }
    }

    function _setSubjectOwner(uint256 subjectId) internal virtual {  
        subjectOwner[subjectId][OWNER_PREDICATE_ID][Strings.toHexString(msg.sender)] = true;
    }

    function _isSubjectOwner(uint256 subjectId)
        internal
        virtual
        returns (bool)
    {
        return subjectOwner[subjectId][OWNER_PREDICATE_ID][string.concat(classIdForData[SOUL_CLASS_ID].value, Strings.toHexString(msg.sender))];
    }

    function _verifyMessage(
        bytes32 _hashedMessage,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _hashedMessage)
        );
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ISemantic compliant contract.
 */
interface ISemantic {
    enum FieldType {
        ADDRESS,
        STRING,
        NUMBER
    }

    struct Class {
        string value; 
        FieldType classType;
    }

    struct Subject {
        string value; 
        uint256 classId;
    }

    struct Predicate {
        string value;
        FieldType predicateType;
    }

    struct Triple {
        uint256 subjectId;
        uint256 predicateId;
        string object;
    }

    struct Turtle {
        uint256 subjectId;
        mapping(uint256=>mapping(string=>bool)) predicateIdToObject;
    }

    struct PredicateAndObject{
        uint256 predicateId;
        string object;
    }

    struct OperateData {
        Subject subject;
        PredicateAndObject[]  predicateAndObjects;
    }

    struct SoulOperateData {
        PredicateAndObject[]  predicateAndObjects;
    }


    struct ClaimOperateData {
        uint256 subjectId;
        PredicateAndObject[]  predicateAndObjects;
        uint256 expireTime;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /**
     * @dev add class
     * @param operator the operate,e.g: 0x8d27258136A7AE115461e22F023158dAF3544FD0
     * @param classId the class id,e.g: 1
     * @param classValue  the class value,e.g:  wd:Medal
     */
    event AddClass(
        address indexed operator,
        uint256 indexed classId,
        string classValue
    );

    /**
     * @dev add predicate
     * @param operator the operate,e.g: 0x8d27258136A7AE115461e22F023158dAF3544FD0
     * @param predicateId the predicate id,e.g: 0
     * @param predicate the predicate value,e.g: :holder
     * @param predicateType the predicate field type,e.g: 0
     */
    event AddPredicates(
        address indexed operator,
        uint256 indexed predicateId,
        string predicate,
        FieldType predicateType
    );

    /**
     * @dev mint sbt 
     * @param operator the operate,e.g: 0x854C2B6Cf940959b71fAC98f69598D4002b7525F
     * @param tokenId the token id,e.g: 100
     * @param rdfData   the rdf data,e.g: :0x854C2B6Cf940959b71fAC98f69598D4002b7525F p:following :0x693925dC866541C1B66dBdf1EA182107A274c8C7 .     
     */
    event Mint(
        address indexed operator,
        uint256 indexed tokenId,
        string rdfData 
    );


    /**
     * @dev burn sbt
     * @param operator the operate,e.g: 0x8d27258136A7AE115461e22F023158dAF3544FD0
     * @param owner the owner of tokenId,e.g: 0x854C2B6Cf940959b71fAC98f69598D4002b7525F
     * @param tokenId the tokenId,e.g: 100
     */
    event Burn(
        address indexed operator,
        address indexed owner,
        uint256 indexed tokenId
    );



    /**
     * @dev add class
     */
    function addClasss(Class[] memory classes) external;

    /**
     * @dev add predicate
     */
    function addPredicates(Predicate[] memory predicateInfos) external;


    /**
     * @dev mint SBT
     */
    function mint(OperateData[] memory operateDatas) external;



    /**
     * @dev burn SBT
     */
    function burn(uint256[] memory tokenIds) external;
 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = 1;

            // compute log10(value), and add it to length
            uint256 valueCopy = value;
            if (valueCopy >= 10**64) {
                valueCopy /= 10**64;
                length += 64;
            }
            if (valueCopy >= 10**32) {
                valueCopy /= 10**32;
                length += 32;
            }
            if (valueCopy >= 10**16) {
                valueCopy /= 10**16;
                length += 16;
            }
            if (valueCopy >= 10**8) {
                valueCopy /= 10**8;
                length += 8;
            }
            if (valueCopy >= 10**4) {
                valueCopy /= 10**4;
                length += 4;
            }
            if (valueCopy >= 10**2) {
                valueCopy /= 10**2;
                length += 2;
            }
            if (valueCopy >= 10**1) {
                length += 1;
            }
            // now, length is log10(value) + 1

            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = 1;

            // compute log256(value), and add it to length
            uint256 valueCopy = value;
            if (valueCopy >= 1 << 128) {
                valueCopy >>= 128;
                length += 16;
            }
            if (valueCopy >= 1 << 64) {
                valueCopy >>= 64;
                length += 8;
            }
            if (valueCopy >= 1 << 32) {
                valueCopy >>= 32;
                length += 4;
            }
            if (valueCopy >= 1 << 16) {
                valueCopy >>= 16;
                length += 2;
            }
            if (valueCopy >= 1 << 8) {
                valueCopy >>= 8;
                length += 1;
            }
            // now, length is log256(value) + 1

            return toHexString(value, length);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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

    // /**
    //  * @dev See {IERC165-supportsInterface}.
    //  */
    // function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    //     return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    // }

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
                        Strings.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "../interfaces/ISemantic721.sol";
import "../interfaces/ISemanticMetadata.sol";
import "../utils/Strings.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";


contract Semantic721 is Context, ISemantic721, ISemanticMetadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;


    string private _baseUri;


    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev See {ISemanticMetadata-semanticMetaDataUri}.
     */
    function semanticMetaDataUri() external view returns (string memory) {
        return string.concat(_baseURI(), "sematic/metadata");
    }


    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return _baseUri;
    }


    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }




    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }


    function _setBaseUri(string memory _uri) internal virtual{
        _baseUri = _uri;
    }

    function _setOwner(uint256 tokenId,address  owner) internal virtual{
        _owners[tokenId] = owner;
    }

    function _removeOwner(uint256 tokenId) internal virtual{
        delete _owners[tokenId];
    }

    function _addBalance(address owner)internal  virtual  {
        _balances[owner] = _balances[owner] + 1;

    }

    function _reduceBalance(address owner)internal  virtual  {
        _balances[owner] = _balances[owner] - 1;

    }



    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        
    }


    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

// import "../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface ISemantic721  {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

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

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


interface ISemanticMetadata  {
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


    /**
     * @dev Returns the Uniform Resource Identifier (URI) for semantic metadata
     */
    function semanticMetaDataUri() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}