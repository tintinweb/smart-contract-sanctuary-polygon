//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.7.0;

import "./DIDRegistry.sol";

contract DIDRegistryRecoverable is DIDRegistry {

    uint private maxAttempts;
    uint private minControllers;
    uint private resetSeconds;

    constructor(uint _minKeyRotationTime, uint _maxAttempts, uint _minControllers, uint _resetSeconds) DIDRegistry( _minKeyRotationTime ) public {
        maxAttempts = _maxAttempts;
        minControllers = _minControllers;
        resetSeconds = _resetSeconds;
    }

    mapping(address => address[]) public recoveredKeys;
    mapping(address => uint) public failedAttempts;
    mapping(address => uint) public lastAttempt;

    function recover(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, address proofController) public {
        require(controllers[identity].length >= minControllers, "Identity must have the minimum of controllers");
        bytes32 hash = keccak256(abi.encodePacked(byte(0x19), byte(0), this, nonce[identityController(identity)], identity, "recover", proofController));
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer == proofController, "Invalid signature");

        require(failedAttempts[identity] < maxAttempts || block.timestamp - lastAttempt[identity] > resetSeconds, "Exceeded attempts");

        if( _getControllerIndex( identity, proofController ) < 0 ) return;

       if( block.timestamp - lastAttempt[identity] > resetSeconds ){
            failedAttempts[identity] = 0;
            delete recoveredKeys[identity];
        }
        lastAttempt[identity] = block.timestamp;

        int recoveredIndex = _getRecoveredIndex(identity, proofController);
        if (recoveredIndex >= 0) {
            failedAttempts[identity] += 1;
            return;
        }

        recoveredKeys[identity].push(proofController);

        if (recoveredKeys[identity].length >= controllers[identity].length.div(2).add(1)) {
            changeController(identity, identity, proofController);
            delete recoveredKeys[identity];
        }
    }

    function _getRecoveredIndex(address identity, address controller) internal view returns (int) {
        for (uint i = 0; i < recoveredKeys[identity].length; i++) {
            if (recoveredKeys[identity][i] == controller) {
                return int(i);
            }
        }
        return -1;
    }

}

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.7.0;

import "./SafeMath.sol";
import "./IDIDRegistry.sol";
import "./BaseRelayRecipient.sol";

contract DIDRegistry is IDIDRegistry, BaseRelayRecipient {

    using SafeMath for uint256;

    mapping(address => address[]) public controllers;
    mapping(address => DIDConfig) private configs;
    mapping(address => uint) public changed;
    mapping(address => uint) public nonce;

    uint private minKeyRotationTime;

    constructor( uint _minKeyRotationTime ) public {
        minKeyRotationTime = _minKeyRotationTime;
    }

    modifier onlyController(address identity, address actor) {
        require(actor == identityController(identity), 'Not authorized');
        _;
    }

    function getControllers(address subject) public view returns (address[] memory) {
        return controllers[subject];
    }

    function identityController(address identity) public view returns (address) {
        uint len = controllers[identity].length;
        if (len == 0) return identity;
        if (len == 1) return controllers[identity][0];
        DIDConfig storage config = configs[identity];
        address controller = address(0);
        if( config.automaticRotation ){
            uint currentController = block.timestamp.div( config.keyRotationTime ).mod( len );
            controller = controllers[identity][currentController];
        } else {
            if( config.currentController >= len ){
                controller = controllers[identity][0];
            } else {
                controller = controllers[identity][config.currentController];
            }
        }
        if (controller != address(0)) return controller;
        return identity;
    }

    function checkSignature(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, bytes32 hash) internal returns (address) {
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer == identityController(identity));
        nonce[signer]++;
        return signer;
    }

    function setCurrentController(address identity, uint index) internal {
        DIDConfig storage config = configs[identity];
        config.currentController = index;
    }

    function _getControllerIndex(address identity, address controller) internal view returns (int) {
        for (uint i = 0; i < controllers[identity].length; i++) {
            if (controllers[identity][i] == controller) {
                return int(i);
            }
        }
        return - 1;
    }

    function addController(address identity, address actor, address newController) internal onlyController(identity, actor) {
        int controllerIndex = _getControllerIndex(identity, newController);

        if (controllerIndex < 0) {
            if( controllers[identity].length == 0 ){
                controllers[identity].push( identity );
            }
            controllers[identity].push( newController );
        }
    }

    function removeController(address identity, address actor, address controller) internal onlyController(identity, actor) {
        require( controllers[identity].length > 1, 'You need at least two controllers to delete' );
        require( identityController(identity) != controller , 'Cannot delete current controller' );
        int controllerIndex = _getControllerIndex(identity, controller);

        require( controllerIndex >= 0, 'Controller not exist' );

        uint len = controllers[identity].length;
        address lastController = controllers[identity][len - 1];
        controllers[identity][uint(controllerIndex)] = lastController;
        if( lastController == identityController(identity) ){
            configs[identity].currentController = uint(controllerIndex);
        }
        delete controllers[identity][len - 1];
        controllers[identity].pop();
    }

    function changeController(address identity, address actor, address newController) internal onlyController(identity, actor) {
        int controllerIndex = _getControllerIndex(identity, newController);

        require( controllerIndex >= 0, 'Controller not exist' );

        if (controllerIndex >= 0) {
            setCurrentController(identity, uint(controllerIndex));

            emit DIDControllerChanged(identity, newController, changed[identity]);
            changed[identity] = block.number;
        }
    }

    function enableKeyRotation(address identity, address actor, uint keyRotationTime) internal onlyController(identity, actor) {
        require( keyRotationTime >= minKeyRotationTime, 'Invalid minimum key rotation time' );
        configs[identity].automaticRotation = true;
        configs[identity].keyRotationTime = keyRotationTime;
    }

    function disableKeyRotation(address identity, address actor) internal onlyController(identity, actor) {
        configs[identity].automaticRotation = false;
    }

    function addController(address identity, address controller) external override {
        addController(identity, _msgSender(), controller);
    }

    function removeController(address identity, address controller) external override {
        removeController(identity, _msgSender(), controller);
    }

    function changeController(address identity, address newController) external override {
        changeController(identity, _msgSender(), newController);
    }

    function changeControllerSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, address newController) external override {
        bytes32 hash = keccak256(abi.encodePacked(byte(0x19), byte(0), this, nonce[identityController(identity)], identity, "changeController", newController));
        changeController(identity, checkSignature(identity, sigV, sigR, sigS, hash), newController);
    }

    function setAttribute(address identity, address actor, bytes memory name, bytes memory value, uint validity) internal onlyController(identity, actor) {
        emit DIDAttributeChanged(identity, name, value, block.timestamp + validity, changed[identity]);
        changed[identity] = block.number;
    }

    function setAttribute(address identity, bytes calldata name, bytes calldata value, uint validity) external override {
        setAttribute(identity, _msgSender(), name, value, validity);
    }

    function setAttributeSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, bytes calldata name, bytes calldata value, uint validity) external override {
        bytes32 hash = keccak256(abi.encodePacked(byte(0x19), byte(0), this, nonce[identityController(identity)], identity, "setAttribute", name, value, validity));
        setAttribute(identity, checkSignature(identity, sigV, sigR, sigS, hash), name, value, validity);
    }

    function revokeAttribute(address identity, address actor, bytes memory name, bytes memory value) internal onlyController(identity, actor) {
        emit DIDAttributeChanged(identity, name, value, 0, changed[identity]);
        changed[identity] = block.number;
    }

    function revokeAttribute(address identity, bytes calldata name, bytes calldata value) external override {
        revokeAttribute(identity, _msgSender(), name, value);
    }

    function revokeAttributeSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, bytes calldata name, bytes calldata value) external override {
        bytes32 hash = keccak256(abi.encodePacked(byte(0x19), byte(0), this, nonce[identityController(identity)], identity, "revokeAttribute", name, value));
        revokeAttribute(identity, checkSignature(identity, sigV, sigR, sigS, hash), name, value);
    }

    function enableKeyRotation(address identity, uint keyRotationTime) external override {
        enableKeyRotation(identity, _msgSender(), keyRotationTime);
    }

    function disableKeyRotation(address identity) external override {
        disableKeyRotation(identity, _msgSender());
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.7.0;

interface IDIDRegistry {
    struct DIDConfig {
        uint256 currentController;
        bool automaticRotation;
        uint256 keyRotationTime;
    }

    event DIDControllerChanged(
        address indexed identity,
        address controller,
        uint256 previousChange
    );

    event DIDAttributeChanged(
        address indexed identity,
        bytes name,
        bytes value,
        uint256 validTo,
        uint256 previousChange
    );

    /*
    function addController(address identity, address controller) external;
    function removeController(address identity, address controller) external;
    function changeController(address identity, address newController) external;
    function changeControllerSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, address newController) external;
    function setAttribute(address identity, bytes memory name, bytes memory value, uint validity) external;
    function setAttributeSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, bytes memory name, bytes memory value, uint validity) external;
    function revokeAttribute(address identity, bytes memory name, bytes memory value) external;
    function revokeAttributeSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, bytes memory name, bytes memory value) external;
    function enableKeyRotation (address identity, uint keyRotationTime) external;
    function disableKeyRotation (address identity) external;
    */
    function addController(address identity, address controller) external;

    function removeController(address identity, address controller) external;

    function changeController(address identity, address newController) external;

    function changeControllerSigned(
        address identity,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        address newController
    ) external;

    function setAttribute(
        address identity,
        bytes calldata name,
        bytes calldata value,
        uint256 validity
    ) external;

    function setAttributeSigned(
        address identity,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        bytes calldata name,
        bytes calldata value,
        uint256 validity
    ) external;

    function revokeAttribute(
        address identity,
        bytes calldata name,
        bytes calldata value
    ) external;

    function revokeAttributeSigned(
        address identity,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        bytes calldata name,
        bytes calldata value
    ) external;

    function enableKeyRotation(address identity, uint256 keyRotationTime)
        external;

    function disableKeyRotation(address identity) external;
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient{

    /*
     * Forwarder singleton we accept calls from
     */
    address internal trustedForwarder = 0x3B62E51E37d090453600395Ff1f9bdf4d7398404;

    /**
     * return the sender of this call.
     * if the call came through our Relay Hub, return the original sender.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual returns (address sender) {
        bytes memory bytesSender;
        (,bytesSender) = trustedForwarder.call(abi.encodeWithSignature("getMsgSender()"));

        return abi.decode(bytesSender, (address));
    }
}