// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20WLDY {
function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function METATXNEXECUTOR_ROLE() external view returns (bytes32);

    function MINTER_ROLE() external view returns (bytes32);

    function PAUSER_ROLE() external view returns (bytes32);

    function UPGRADER_ROLE() external view returns (bytes32);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function domainSeparator() external view returns (bytes32);

    function executeMetaTransaction ( address userAddress, bytes memory functionSignature, bytes32 sigR, bytes32 sigS, uint8 sigV ) external returns ( bytes memory);

    function getChainId() external view returns (uint256);

    function getNonce(address user) external view returns (uint256 nonce);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function initialize() external;

    function initializemetatxns() external;

    function messagehash() external view returns (bytes32);

    function mint(address to, uint256 amount) external;

    function name() external view returns (string memory);

    function pause() external;

    function paused() external view returns (bool);

    function proxiableUUID() external view returns (bytes32);

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function unpause() external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./utils/ContextMixin.sol";

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
abstract contract Ownable is ContextMixin {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


contract ContextMixin {
    function _msgSender()
        internal
        view
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
    
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/Ownable.sol";
import "./lib/utils/math/SafeMath.sol";
import "./IERC20WLDY.sol";

contract MinterContract is Ownable {
    using SafeMath for uint256;
    struct Config {
        bool initialized;
        IERC20WLDY token;
        address beneficiary;
        address treasury;
        uint256 start;
        uint256 duration;
        uint256 beneficiaryMintAllowed;
        uint256 treasuryMintAllowed;
    }

    Config public config;
    uint256 public beneficiaryTotalMinted;
    uint256 public treasuryTotalMinted;
    uint256 private beneficiaryCoinMintPerSec;
    uint256 private treasuryCoinMintPerSec;

    function initialize(
        address _token,
        address _beneficiary,
        address _treasury,
        uint256 _start,
        uint256 _duration,
        uint256 _beneficiaryMintAllowed,
        uint256 _treasuryMintAllowed
    ) public onlyOwner {
        require(!config.initialized);

        beneficiaryTotalMinted = 0;
        treasuryTotalMinted = 0;
        beneficiaryCoinMintPerSec = _beneficiaryMintAllowed.mul(1 ether).div(_duration);
        treasuryCoinMintPerSec = _treasuryMintAllowed.mul(1 ether).div(_duration);
        config.initialized = true;
        config.token = IERC20WLDY(_token);
        config.beneficiary = _beneficiary;
        config.treasury = _treasury;
        config.start = _start;
        config.duration = _duration;
        config.beneficiaryMintAllowed = _beneficiaryMintAllowed;
        config.treasuryMintAllowed = _treasuryMintAllowed;
    }

    function setToken(address _token) public onlyOwner {
        require(config.initialized);
        config.token = IERC20WLDY(_token);
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        require(config.initialized);
        config.beneficiary = _beneficiary;
    }
    function setTreasury(address _treasury) public onlyOwner {
        require(!config.initialized);
        config.treasury = _treasury;
    }

    function setDuration(uint256 _duration) public onlyOwner {
        require(config.initialized);
        config.duration = _duration;
        beneficiaryCoinMintPerSec = config.beneficiaryMintAllowed.mul(1 ether).div(_duration);
        treasuryCoinMintPerSec = config.treasuryMintAllowed.mul(1 ether).div(_duration);
    }

    function setBeneficiaryMintAllowed(uint256 _beneficiaryMintAllowed) public onlyOwner {
        require(config.initialized);
        config.beneficiaryMintAllowed = _beneficiaryMintAllowed;
        beneficiaryCoinMintPerSec = _beneficiaryMintAllowed.mul(1 ether).div(config.duration);
    }

    function setTreasuryMintAllowed(uint256 _treasuryMintAllowed) public onlyOwner {
        require(config.initialized);
        config.treasuryMintAllowed = _treasuryMintAllowed;
        treasuryCoinMintPerSec = _treasuryMintAllowed.mul(1 ether).div(config.duration);
    }

    function release() public {
        require(block.timestamp > config.start);
        uint256 beneficiarycoins = getreleasable_beneficiary();
        uint256 treasurycoins = getreleasable_treasury();
        config.token.mint(config.beneficiary, beneficiarycoins);
        config.token.mint(config.treasury, treasurycoins);
        beneficiaryTotalMinted = beneficiaryTotalMinted + beneficiarycoins;
        treasuryTotalMinted = treasuryTotalMinted + treasurycoins;
        config.start = block.timestamp;
    }
    function getreleasable_beneficiary() public view returns (uint256) {
        return block.timestamp.sub(config.start).mul(beneficiaryCoinMintPerSec);
    }
    function getreleasable_treasury() public view returns (uint256) {
        return block.timestamp.sub(config.start).mul(treasuryCoinMintPerSec);
    }

}