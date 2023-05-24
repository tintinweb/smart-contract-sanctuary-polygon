// SPDX-License-Identifier: GPL-3.0

//
// Original work by Pine.Finance
//  - https://github.com/pine-finance
//
// Authors:
//  - Ignacio Mazzara <@nachomazzara>
//  - Agustin Aguilar <@agusx1211>

// solhint-disable-next-line
pragma solidity 0.8.18;
import {PineCore, IModule, IERC20} from "./PineCore.sol";

contract GelatoPineCore is PineCore {

    constructor(address _FEE_TOKEN_ADDRESS, address owner, address _WRAPPED_NATIVE, address _GELATO_OPS) PineCore(_FEE_TOKEN_ADDRESS, owner, _WRAPPED_NATIVE, _GELATO_OPS) public {}
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
pragma experimental ABIEncoderV2;

enum Module {
    RESOLVER,
    TIME,
    PROXY,
    SINGLE_EXEC
}

struct ModuleData {
    Module[] modules;
    bytes[] args;
}

interface IOps {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

/**
 *Submitted for verification at Etherscan.io on 2020-08-30
 */

/**
 *Submitted for verification at Etherscan.io on 2020-08-30
 */

// SPDX-License-Identifier: GPL-3.0
//
// Original work by Pine.Finance
//  - https://github.com/pine-finance
//
// Authors:
//  - Ignacio Mazzara <@nachomazzara>
//  - Agustin Aguilar <@agusx1211>

pragma solidity 0.8.18;

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
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/libs/ECDSA.sol

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library Verification {

    function getMessageHash(
        address _to
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to));
    }

    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) internal pure returns (bytes32) {
        return
        keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
    }

    function verify(
        address _to,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 messageHash = getMessageHash(_to);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature);
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
// File: contracts/interfaces/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IWETH{
    // Wrap ETH to WETH
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
}

// File: contracts/interfaces/IModule.sol

/**
 * Original work by Pine.Finance
 * - https://github.com/pine-finance
 *
 * Authors:
 * - Ignacio Mazzara <nachomazzara>
 * - Agustin Aguilar <agusx1211>
 */
interface IModule {
    /// @notice receive ETH
    receive() external payable;

    /**
     * @notice Executes an order
     * @param _inputAmountFeeToken - uint256 of the input FeeToken amount (order amount)
     * @param _inputAmountTokenA - uint256 of the input token amount (order amount)
     * @param _owner - Address of the order's owner
     * @param _data - Bytes of the order's data
     * @return bought - amount of output token bought
     */
    function executeLimitOrder(
        uint256 _inputAmountFeeToken,
        uint256 _inputAmountTokenA,
        address payable _owner,
        bytes calldata _data
    ) external returns (uint256 bought);

    /**
     * @notice Executes a stop-loss order
     * @param _inputAmountFeeToken - uint256 of the input FeeToken amount (order amount)
     * @param _inputAmountTokenA - uint256 of the input token amount (order amount)
     * @param _owner - Address of the order's owner
     * @param _data - Bytes of the order's data
     * @return bought - amount of output token bought
     */
    function executeStopLoss(
        uint256 _inputAmountFeeToken,
        uint256 _inputAmountTokenA,
        address payable _owner,
        bytes calldata _data
    ) external returns (uint256 bought);

    /**
     * @notice Check whether an order can be executed or not
     * @param _inputAmountFeeToken - uint256 of the input FeeToken token amount (order amount)
     * @param _inputAmountTokenA - uint256 of the input tokenA amount (order amount)
     * @param _data - Bytes of the order's data
     * @return bool - whether the order can be executed or not
     */
    function canExecuteLimitOrder(
        uint256 _inputAmountFeeToken,
        uint256 _inputAmountTokenA,
        bytes calldata _data
    ) external view returns (bool);

    function getFeeTokenAmountRequired() external returns(uint256);
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor(){
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/PineCore.sol

/**
 * Original work by Pine.Finance
 * - https://github.com/pine-finance
 *
 * Authors:
 * - Ignacio Mazzara <nachomazzara>
 * - Agustin Aguilar <agusx1211>
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address owner) {
        _transferOwnership(owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

import {IOps, ModuleData} from "./interfaces/IOps.sol";

abstract contract PineCore is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    address public NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public FEE_TOKEN;
    address immutable public WRAPPED_NATIVE;
    IOps public GELATO_OPS;

    // Vault token balances
    mapping(address => mapping(address => uint256)) public vaultTokenBalance;

    mapping (address => bytes32) public taskIdOfVault;

    constructor(address _FEE_TOKEN, address owner, address _WRAPPED_NATIVE, address _GELATO_OPS) Ownable(owner) ReentrancyGuard() {
        FEE_TOKEN=_FEE_TOKEN;
        WRAPPED_NATIVE = _WRAPPED_NATIVE;
        GELATO_OPS = IOps(_GELATO_OPS);
    }

    // Events

    event TaskCreated(
        address indexed caller,
        bytes32 taskId,
        address indexed vault,
        uint256 amountFeeToken,
        uint256 amountTokenA,
        address module,
        address FeeToken,
        address tokenA,
        address owner,
        address witness,
        bytes data
    );

    event TaskCancelledAndVaultWithdrawn(
        address indexed vault,
        IModule _module,
        bytes32 indexed taskId,
        address _tokenA,
        address _owner,
        address _witness,
        bytes _data
    );

    event DepositETH(
        bytes32 indexed _key,
        address indexed _caller,
        uint256 _amount,
        bytes _data
    );

    event OrderExecuted(
        address _inputToken,
        address _owner,
        address _witness,
        bytes _data,
        uint256 _amountTokenA,
        uint256 _amountFeeToken,
        uint256 _bought
    );

    event OrderCancelled(
        bytes32 indexed _key,
        address _inputToken,
        address _owner,
        address _witness,
        bytes _data,
        uint256 _amountFeeToken,
        uint256 _amountTokenA
    );

    /**
     * @dev Prevent users to send Ether directly to this contract
     */
    receive() external payable {
        require(
            msg.sender != tx.origin,
            "PineCore#receive: NO_SEND_ETH_PLEASE"
        );
    }

    function changeFeeToken(address _newFeeTokenAddress) onlyOwner external {
        FEE_TOKEN=_newFeeTokenAddress;
    }

    /**
     * @notice Get the vault's address of a token to token/ETH order
     * @param _module - Address of the module to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _data - Bytes of the order's data
     * @return address - The address of the vault
     */
    function vaultOfOrder(
        IModule _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes memory _data
    ) public view returns (address) {
        return getVault(keyOf(_module, _inputToken, _owner, _witness, _data));
    }

    /**
     * @notice Executes an order
     * @dev The sender should use the _secret to sign its own address
     * to prevent front-runnings
     * @param _module - Address of the module to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _data - Bytes of the order's data
     * @param _signature - Signature to calculate the witness
     */
    function executeLimitOrder(
        IModule _module,
        address _inputToken,
        address payable _owner,
        bytes calldata _data,
        bytes calldata _signature
    ) public virtual {
        // Calculate witness using signature
        address witness = Verification.verify(
            msg.sender,
            _signature
        );

        address vault = vaultOfOrder(
            _module,
            _inputToken,
            _owner,
            witness,
            _data
        );

        uint256 amountFeeToken =vaultTokenBalance[vault][FEE_TOKEN];
        uint256 amountTokenA =vaultTokenBalance[vault][_inputToken];
        vaultTokenBalance[vault][FEE_TOKEN] = 0;
        vaultTokenBalance[vault][_inputToken] = 0;

        // send feeToken to module
        IERC20(FEE_TOKEN).transfer(address(_module),amountFeeToken);
        if(_inputToken == NATIVE_ADDRESS){
            // wrap the native token and send to module
            IWETH(WRAPPED_NATIVE).deposit{value: amountTokenA}();
            IWETH(WRAPPED_NATIVE).transfer(address(_module),amountTokenA);
        } else{
            // send erc20 inputToken to module
            IERC20(_inputToken).transfer(address(_module),amountTokenA);
        }

        require(
            amountTokenA > 0 && amountFeeToken > 0,
            "PineCore#executeLimitOrder: INVALID_ORDER"
        );

        uint256 bought = _module.executeLimitOrder(
            amountFeeToken,
            amountTokenA,
            _owner,
            _data
        );

        emit OrderExecuted(
            _inputToken,
            _owner,
            witness,
            _data,
            amountTokenA,
            amountFeeToken,
            bought
        );
    }

    /**
     * @notice Check whether an order exists or not
     * @dev Check the balance of the order
     * @param _module - Address of the module to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _data - Bytes of the order's data
     * @return bool - whether the order exists or not
     */
    function existOrder(
        IModule _module,
        bytes32 _taskId,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data
    ) external view returns (bool) {
        address vault = vaultOfOrder(
            _module,
            _inputToken,
            _owner,
            _witness,
            _data
        );

        return vaultTokenBalance[vault][_inputToken] > 0;
    }

    /**
     * @notice Check whether a limit order can be executed or not
     * @param _module - Address of the module to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _data - Bytes of the order's data
     * @return canExec - whether the order can be executed or not
     * @return execData - function and params to execute
     */
    function canExecuteLimitOrder(
        IModule _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data,
        bytes calldata _signature
    ) external view returns (bool canExec, bytes memory execData) {

        address vault = vaultOfOrder(
            _module,
            _inputToken,
            _owner,
            _witness,
            _data
        );

        // Check balance amount in vault
        canExec = _module.canExecuteLimitOrder(
            vaultTokenBalance[vault][FEE_TOKEN],
            vaultTokenBalance[vault][_inputToken],
            _data
        );

        execData = abi.encodeWithSelector(this.executeLimitOrder.selector, _module, _inputToken, _owner, _data, _signature );
    }

    /**
     * @notice Get the order's key
     * @param _module - Address of the module to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _data - Bytes of the order's data
     * @return bytes32 - order's key
     */
    function keyOf(
        IModule _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes memory _data
    ) public pure returns (bytes32) {
        return
        keccak256(
            abi.encode(_module, _inputToken, _owner, _witness, _data)
        );
    }

    function getVault(bytes32 _key) internal view returns (address) {
        return
        address(uint160(uint256(
                keccak256(
                    abi.encodePacked(
                        bytes1(0xff),
                        address(this),
                        _key
                    )
                )
        )
            )
        );
    }

    // todo remove this func
    function checkTaskClosed(
        ModuleData calldata moduleData,
        bytes calldata execSelectorOrData
    ) public nonReentrant returns(bool){
        bytes32 taskId = GELATO_OPS.createTask(address(this), execSelectorOrData, moduleData, NATIVE_ADDRESS);
    }

    /**
     * @notice User deposits tokens
     * @param _amountFeeToken - Amount of fee token to deposit
     * @param _amountTokenA - Amount of tokenA to deposit
     * @param _module - Address of the module to use for the order execution
     * @param _tokenA - Address of tokenA
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _data - Bytes of the order's data
     */
    function depositTokensAndCreateTask(
        uint256 _amountFeeToken,
        uint256 _amountTokenA,
        IModule _module,
        address _tokenA,
        address payable _owner,
        address _witness,
        ModuleData calldata moduleData,
        bytes calldata execSelectorOrData,
        bytes calldata _data
    ) public nonReentrant {

        // create gelato task
        bytes32 taskId = GELATO_OPS.createTask(address(this), execSelectorOrData, moduleData, NATIVE_ADDRESS);

        address vault = vaultOfOrder(
            _module,
            _tokenA,
            _owner,
            _witness,
            _data
        );

        // map vault to taskId
        taskIdOfVault[vault] = taskId;

        vaultTokenBalance[vault][_tokenA] += _amountTokenA;
        vaultTokenBalance[vault][FEE_TOKEN] += _amountFeeToken;
        // transfer tokenA, if NATIVE its just locked in contract
        if (_tokenA != NATIVE_ADDRESS) {
            IERC20(_tokenA).transferFrom(
                msg.sender,
                address(this),
                _amountTokenA
            );
        }

        // deposit FeeToken, assuming fee token is always ERC20 not native
        IERC20(FEE_TOKEN).transferFrom(
            msg.sender,
            address(this),
            _amountFeeToken
        );

        emit TaskCreated(
            msg.sender,
            taskId,
            vault,
            _amountFeeToken,
            _amountTokenA,
            address(_module),
            FEE_TOKEN,
            _tokenA,
            _owner,
            _witness,
            _data
        );
    }

    function cancelTaskAndWithdrawTokens(
        IModule _module,
        address _tokenA,
        address payable _owner,
        address _witness,
        bytes calldata _data
    ) external {

        require(msg.sender == _owner, "caller is not the owner of the vault");

        address vault = vaultOfOrder(
            _module,
            _tokenA,
            _owner,
            _witness,
            _data
        );

        // cancel task associated with vault
        bytes32 taskId = taskIdOfVault[vault];
        GELATO_OPS.cancelTask(taskId);

        // withdraw tokenA
        if(_tokenA == NATIVE_ADDRESS){
            // send the native token
            _owner.call{value: vaultTokenBalance[vault][_tokenA] }("");
        } else {
            // transfer the erc20 tokenA
            IERC20(_tokenA).transferFrom(
                address(this),
                msg.sender,
                vaultTokenBalance[vault][_tokenA]
            );
        }
        vaultTokenBalance[vault][_tokenA] = 0;

        // withdraw FeeToken
        IERC20(FEE_TOKEN).transferFrom(
            address(this),
            msg.sender,
                vaultTokenBalance[vault][FEE_TOKEN]
        );
        vaultTokenBalance[vault][FEE_TOKEN] = 0;

        emit TaskCancelledAndVaultWithdrawn(
            vault,
            _module,
            taskId,
            _tokenA,
            _owner,
            _witness,
            _data
        );
    }
}