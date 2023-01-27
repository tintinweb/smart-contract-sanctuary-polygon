//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../SecurityUtils.sol";
import "../NumberUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Error_string(uint256 counter, string error);
error Error_bool(uint256 counter, bool error);
error Error_address(uint256 counter, address error);
error Error_bytes4(uint256 counter, bytes4 error);
error Error_bytes32(uint256 counter, bytes32 error);
error Error_bytes(uint256 counter, bytes error);
error Error_int8(uint256 counter, int8 error);
error Error_int32(uint256 counter, int32 error);
error Error_int64(uint256 counter, int64 error);
error Error_int256(uint256 counter, int256 error);
error Error_uint8(uint256 counter, uint8 error);
error Error_uint32(uint256 counter, uint32 error);
error Error_uint64(uint256 counter, uint64 error);
error Error_uint256(uint256 counter, uint256 error);
error Error_Struct(uint256 counter, Decimals.Number_uint256 error);
error Error_Enum(uint256 counter, Enum error);
error Error_Array(uint256 counter, string[] error);

enum Enum{ ASSERT_FALSE, ARITHMETIC, DIV_BY_ZERO,   EMPTY_ARRAY, OUT_OF_BOUNDS }


contract InteractionTest is AccessControlImpl, Ownable {

    uint256 private _counter = 0;

    event Event_string(uint256 counter, string message);
    event Event_bool(uint256 counter, bool message);
    event Event_address(uint256 counter, address message);
    event Event_bytes4(uint256 counter, bytes4 message);
    event Event_bytes32(uint256 counter, bytes32 message);
    event Event_bytes(uint256 counter, bytes message);
    event Event_int8(uint256 counter, int8 message);
    event Event_int32(uint256 counter, int32 message);
    event Event_int64(uint256 counter, int64 message);
    event Event_int256(uint256 counter, int256 message);
    event Event_uint8(uint256 counter, uint8 message);
    event Event_uint32(uint256 counter, uint32 message);
    event Event_uint64(uint256 counter, uint64 message);
    event Event_uint256(uint256 counter, uint256 message);
    event Event_Struct(uint256 counter, Decimals.Number_uint256 message);
    event Event_Enum(uint256 counter, Enum message);
    event Event_Array(uint256 counter, string[] message);

    constructor() {

    }

    function read_AccessControl(bytes32 expectedRole) public view returns(uint256 counter) {
        _checkRole(expectedRole);
        return _counter;
    }
    function write_AccessControl(bytes32 expectedRole) public {
        read_AccessControl(expectedRole);
        _counter++;
    }
    function read_Owner() public view onlyOwner() returns(uint256 counter) {
        return _counter;
    }
    function write_Owner() public {
        read_Owner();
        _counter++;
    }

    function read_require(bool fail, string memory errorOrResult) public pure returns(string memory result) {
        require(!fail, errorOrResult);
        return errorOrResult;
    }
    function write_require(bool fail, string memory errorOrMessage) public {
        read_require(fail, errorOrMessage);
        _counter++;
        emit Event_string(_counter, errorOrMessage);
    }

    function read_string(bool fail, string memory errorOrResult) public view returns(string memory result) {
        if(fail) revert Error_string(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_string(bool fail, string memory errorOrMessage) public {
        read_string(fail, errorOrMessage);
        _counter++;
        emit Event_string(_counter, errorOrMessage);
    }
    function read_bool(bool fail, bool errorOrResult) public view returns(bool result) {
        if(fail) revert Error_bool(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_bool(bool fail, bool errorOrMessage) public {
        read_bool(fail, errorOrMessage);
        _counter++;
        emit Event_bool(_counter, errorOrMessage);
    }
    function read_address(bool fail, address errorOrResult) public view returns(address result) {
        if(fail) revert Error_address(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_address(bool fail, address errorOrMessage) public {
        read_address(fail, errorOrMessage);
        _counter++;
        emit Event_address(_counter, errorOrMessage);
    }
    function read_bytes4(bool fail, bytes4 errorOrResult) public view returns(bytes4 result) {
        if(fail) revert Error_bytes4(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_bytes4(bool fail, bytes4 errorOrMessage) public {
        read_bytes4(fail, errorOrMessage);
        _counter++;
        emit Event_bytes4(_counter, errorOrMessage);
    }
    function read_bytes32(bool fail, bytes32 errorOrResult) public view returns(bytes32 result) {
        if(fail) revert Error_bytes32(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_bytes32(bool fail, bytes32 errorOrMessage) public {
        read_bytes32(fail, errorOrMessage);
        _counter++;
        emit Event_bytes32(_counter, errorOrMessage);
    }
    function read_bytes(bool fail, bytes memory errorOrResult) public view returns(bytes memory result) {
        if(fail) revert Error_bytes(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_bytes(bool fail, bytes memory errorOrMessage) public {
        read_bytes(fail, errorOrMessage);
        _counter++;
        emit Event_bytes(_counter, errorOrMessage);
    }
    function read_int8(bool fail, int8 errorOrResult) public view returns(int8 result) {
        if(fail) revert Error_int8(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_int8(bool fail, int8 errorOrMessage) public {
        read_int8(fail, errorOrMessage);
        _counter++;
        emit Event_int8(_counter, errorOrMessage);
    }
    function read_int32(bool fail, int32 errorOrResult) public view returns(int32 result) {
        if(fail) revert Error_int32(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_int32(bool fail, int32 errorOrMessage) public {
        read_int32(fail, errorOrMessage);
        _counter++;
        emit Event_int32(_counter, errorOrMessage);
    }
    function read_int64(bool fail, int64 errorOrResult) public view returns(int64 result) {
        if(fail) revert Error_int64(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_int64(bool fail, int64 errorOrMessage) public {
        read_int64(fail, errorOrMessage);
        _counter++;
        emit Event_int64(_counter, errorOrMessage);
    }
    function read_int256(bool fail, int256 errorOrResult) public view returns(int256 result) {
        if(fail) revert Error_int256(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_int256(bool fail, int256 errorOrMessage) public {
        read_int256(fail, errorOrMessage);
        _counter++;
        emit Event_int256(_counter, errorOrMessage);
    }
    function read_uint8(bool fail, uint8 errorOrResult) public view returns(uint8 result) {
        if(fail) revert Error_uint8(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_uint8(bool fail, uint8 errorOrMessage) public {
        read_uint8(fail, errorOrMessage);
        _counter++;
        emit Event_uint8(_counter, errorOrMessage);
    }
    function read_uint32(bool fail, uint32 errorOrResult) public view returns(uint32 result) {
        if(fail) revert Error_uint32(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_uint32(bool fail, uint32 errorOrMessage) public {
        read_uint32(fail, errorOrMessage);
        _counter++;
        emit Event_uint32(_counter, errorOrMessage);
    }
    function read_uint64(bool fail, uint64 errorOrResult) public view returns(uint64 result) {
        if(fail) revert Error_uint64(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_uint64(bool fail, uint64 errorOrMessage) public {
        read_uint64(fail, errorOrMessage);
        _counter++;
        emit Event_uint64(_counter, errorOrMessage);
    }
    function read_uint256(bool fail, uint256 errorOrResult) public view returns(uint256 result) {
        if(fail) revert Error_uint256(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_uint256(bool fail, uint256 errorOrMessage) public {
        read_uint256(fail, errorOrMessage);
        _counter++;
        emit Event_uint256(_counter, errorOrMessage);
    }
    function read_Struct(bool fail, Decimals.Number_uint256 memory errorOrResult) public view returns(Decimals.Number_uint256 memory result) {
        if(fail) revert Error_Struct(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_Struct(bool fail, Decimals.Number_uint256 memory errorOrMessage) public {
        read_Struct(fail, errorOrMessage);
        _counter++;
        emit Event_Struct(_counter, errorOrMessage);
    }
    function read_Enum(bool fail, Enum errorOrResult) public view returns(Enum result) {
        if(fail) revert Error_Enum(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_Enum(bool fail, Enum errorOrMessage) public {
        read_Enum(fail, errorOrMessage);
        _counter++;
        emit Event_Enum(_counter, errorOrMessage);
    }
    function read_Array(bool fail, string[] memory errorOrResult) public view returns(string[] memory result) {
        if(fail) revert Error_Array(_counter, errorOrResult);
        return errorOrResult;
    }
    function write_Array(bool fail, string[] memory errorOrMessage) public {
        read_Array(fail, errorOrMessage);
        _counter++;
        emit Event_Array(_counter, errorOrMessage);
    }

    uint[] private uintArray = new uint[](0);
    /**
     * 0x00: Used for generic compiler inserted panics.
     * 0x01: If you call assert with an argument that evaluates to false.
     * 0x11: If an arithmetic operation results in underflow or overflow outside of an unchecked { ... } block.
     * 0x12; If you divide or modulo by zero (e.g. 5 / 0 or 23 % 0).
     * 0x21: If you convert a value that is too big or negative into an enum type.
     * 0x22: If you access a storage byte array that is incorrectly encoded.
     * 0x31: If you call .pop() on an empty array.
     * 0x32: If you access an array, bytesN or an array slice at an out-of-bounds or negative index (i.e. x[i] where i >= x.length or i < 0).
     * 0x41: If you allocate too much memory or create an array that is too large.
     * 0x51: If you call a zero-initialized variable of internal function type.
     * @param whichError What is the desired error
     */
    function read_error(Enum whichError) public returns (uint256 counter) {
        // 0x01: If you call assert with an argument that evaluates to false.
        if(whichError == Enum.ASSERT_FALSE) {
            assert(false);
        }
        // 0x11: If an arithmetic operation results in underflow or overflow outside of an unchecked { ... } block.
        else if(whichError == Enum.ARITHMETIC) {
            uint test = 0;
            test--;
        }
        //  0x12; If you divide or modulo by zero (e.g. 5 / 0 or 23 % 0).
        else if(whichError == Enum.DIV_BY_ZERO) {
            uint test = 0;
            test/test;
        }
        // 0x31: If you call .pop() on an empty array.
        else if(whichError == Enum.EMPTY_ARRAY) {
            uintArray.pop();
        }
        // 0x32: If you access an array, bytesN or an array slice at an out-of-bounds or negative index (i.e. x[i] where i >= x.length or i < 0).
        else if(whichError == Enum.OUT_OF_BOUNDS) {
            uint[] memory array = new uint[](1);
            array[2];
        }
        return _counter;
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

error AccessControl_MissingRole(address account, bytes32 role);

/**
 * @dev Default implementation to use when role based access control is requested. It extends openzeppelin implementation
 * in order to use 'error' instead of 'string message' when checking roles and to be able to attribute admin role for each
 * defined role (and not rely exclusively on the DEFAULT_ADMIN_ROLE)
 */
abstract contract AccessControlImpl is AccessControlEnumerable {

    /**
     * @dev Default constructor
     */
    constructor() {
        // To be done at initialization otherwise it will never be accessible again
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Revert with AccessControl_MissingRole error if `account` is missing `role` instead of a string generated message
     */
    function _checkRole(bytes32 role, address account) internal view virtual override {
        if(!hasRole(role, account)) revert AccessControl_MissingRole(account, role);
    }
    /**
     * @dev Sets `adminRole` as `role`'s admin role. Revert with AccessControl_MissingRole error if message sender is missing
     * current `role`'s admin role or DEFAULT_ADMIN_ROLE
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) public {
        address sender = _msgSender();
        if(!hasRole(getRoleAdmin(role), sender) && !hasRole(DEFAULT_ADMIN_ROLE, sender)) {
            revert AccessControl_MissingRole(sender, getRoleAdmin(role));
        }
        _setRoleAdmin(role, adminRole);
    }
    /**
     * @dev Sets `role` as `role`'s admin role. Revert with AccessControl_MissingRole error if message sender is missing
     * current `role`'s admin role or DEFAULT_ADMIN_ROLE
     */
    function setRoleAdminItself(bytes32 role) public {
        setRoleAdmin(role, role);
    }
    /**
     * @dev Sets DEFAULT_ADMIN_ROLE as `role`'s admin role. Revert with AccessControl_MissingRole error if message sender
     * is missing current `role`'s admin role or DEFAULT_ADMIN_ROLE
     */
    function setRoleAdminDefault(bytes32 role) public {
        setRoleAdmin(role, DEFAULT_ADMIN_ROLE);
    }
}

/**
 * @dev Default implementation to use when contract should be pausable (role based access control is then requested in order
 * to grant access to pause/unpause actions). It extends openzeppelin implementation in order to define publicly accessible
 * and role protected pause/unpause methods
 */
abstract contract PausableImpl is AccessControlImpl, Pausable {
    /** Role definition necessary to be able to pause contract */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Default constructor
     */
    constructor() {}

    /**
     * @dev Pause the contract if message sender has PAUSER_ROLE role. Action protected with whenNotPaused() or with
     * _requireNotPaused() will not be available anymore until contract is unpaused again
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }
    /**
     * @dev Unpause the contract if message sender has PAUSER_ROLE role. Action protected with whenPaused() or with
     * _requirePaused() will not be available anymore until contract is paused again
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Decimals {

    /**
     * @dev Decimal number structure, base on a uint256 value and its applicable decimals number
     */
    struct Number_uint256 {
        uint256 value;
        uint8 decimals;
    }
    /**
     * @dev Decimal number structure, base on a uint32 value and its applicable decimals number
     */
    struct Number_uint32 {
        uint32 value;
        uint8 decimals;
    }
    /**
     * @dev Decimal number structure, base on a uint8 value and its applicable decimals number
     */
    struct Number_uint8 {
        uint8 value;
        uint8 decimals;
    }

    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros(uint256 value_, uint8 decimals_) internal pure returns(uint256 value, uint8 decimals) {
        if(value_ == 0) {
            return (0, 0);
        }
        while(decimals_ > 0 && value_ % 10 == 0) {
            decimals_--;
            value_ = value_/10;
        }
        return (value_, decimals_);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_uint32(uint32 value_, uint8 decimals_) internal pure returns(uint32 value, uint8 decimals) {
        uint256 value_uint256;
        (value_uint256, decimals_) = cleanFromTrailingZeros(value_, decimals_);
        return (uint32(value_uint256), decimals_);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_uint8(uint8 value_, uint8 decimals_) internal pure returns(uint8 value, uint8 decimals) {
        uint256 value_uint256;
        (value_uint256, decimals_) = cleanFromTrailingZeros(value_, decimals_);
        return (uint8(value_uint256), decimals_);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_Number(Number_uint256 memory number) internal pure returns(Number_uint256 memory) {
        (uint256 value, uint8 decimals) = cleanFromTrailingZeros(number.value, number.decimals);
        return Number_uint256(value, decimals);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_Number_uint32(Number_uint32 memory number) internal pure returns(Number_uint32 memory) {
        (uint32 value, uint8 decimals) = cleanFromTrailingZeros_uint32(number.value, number.decimals);
        return Number_uint32(value, decimals);
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros_Number_uint8(Number_uint8 memory number) internal pure returns(Number_uint8 memory) {
        (uint8 value, uint8 decimals) = cleanFromTrailingZeros_uint8(number.value, number.decimals);
        return Number_uint8(value, decimals);
    }

    function align_Number(Decimals.Number_uint256 memory number1_, Decimals.Number_uint256 memory number2_) internal pure
    returns (Decimals.Number_uint256 memory number1, Decimals.Number_uint256 memory number2) {
        if(number1_.decimals < number2_.decimals) {
            number1_.value = number1_.value * 10**(number2_.decimals - number1_.decimals);
            number1_.decimals = number2_.decimals;
        }
        else if(number2_.decimals < number1_.decimals) {
            number2_.value = number2_.value * 10**(number1_.decimals - number2_.decimals);
            number2_.decimals = number1_.decimals;
        }
        return (number1_, number2_);
    }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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