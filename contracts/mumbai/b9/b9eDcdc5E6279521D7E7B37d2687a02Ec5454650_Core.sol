// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {LimitOrderCore} from "./LimitOrderCore.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IHandler} from "../interfaces/IHandler.sol";

contract Core is LimitOrderCore {
    constructor(address _FEE_TOKEN_ADDRESS, address owner, address _WRAPPED_NATIVE, address _GELATO_OPS) LimitOrderCore(_FEE_TOKEN_ADDRESS, owner, _WRAPPED_NATIVE, _GELATO_OPS) {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

    function getSigner(
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

// SPDX-License-Identifier: None
pragma solidity 0.8.18;

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

    constructor() {
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

import {IOps, ModuleData, Module} from "../interfaces/IOps.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IHandler} from "../interfaces/IHandler.sol";
import {Ownable} from "./Ownable.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {Verification} from "./libs/Verification.sol";
import {VaultData} from "../interfaces/IHandler.sol";

contract LimitOrderCore is Ownable, ReentrancyGuard {
    address public NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public FEE_TOKEN;
    address immutable public WRAPPED_NATIVE;
    IOps public GELATO_OPS;

    // Vault token balances
    mapping(address => VaultData) public vaultData;

    constructor(address _FEE_TOKEN, address __owner, address _WRAPPED_NATIVE, address _GELATO_OPS) Ownable(__owner) ReentrancyGuard() {
        FEE_TOKEN=_FEE_TOKEN;
        WRAPPED_NATIVE = _WRAPPED_NATIVE;
        GELATO_OPS = IOps(_GELATO_OPS);
    }

    // Events
    event TaskCreated(
        address indexed creator,
        address indexed vault,
        bytes32 indexed taskId,
        uint256 amountFeeToken,
        uint256 amountTokenA,
        address handler,
        address FeeToken,
        address witness,
        bytes data
    );

    event OrderExecuted(
        address indexed vault,
        uint256 indexed bought,
        address feeToken,
        uint256 feeAmount,
        uint256 feePaid
    );

    event OrderCancelledAndVaultWithdrawn(
        address indexed vault,
        bytes32 indexed taskId
    );

    event MoreFeeTokenFunded(
        address indexed vault,
        address indexed feeToken,
        uint256 indexed amount
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
        // todo check is event required
        FEE_TOKEN=_newFeeTokenAddress;
    }

    function changeGelatoOps(IOps _newGelatoOps) onlyOwner external {
        GELATO_OPS=_newGelatoOps;
    }

    /**
     * @notice Get the vault's address of a token to token/ETH order
     * @param _handler - Address of the handler to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _swapData - Bytes of the order's data
     * @return address - The address of the vault
     */
    function vaultOfOrder(
        IHandler _handler,
        address _inputToken,
        address feeToken,
        address _owner,
        address _witness,
        bytes memory _swapData
    ) public view returns (address) {
        return getVault(keyOf(_handler, _inputToken, feeToken, _owner, _witness, _swapData));
    }

    /**
     * @notice Check whether an order exists or not
     * @dev Check the balance of the order
     * @param _handler - Address of the handler to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _swapData - Bytes of the order's data
     * @return bool - whether the order exists or not
     */
    function existOrder(
        IHandler _handler,
        address _inputToken,
        address feeToken,
        address payable _owner,
        address _witness,
        bytes calldata _swapData
    ) external view returns (bool) {
        address vault = vaultOfOrder(
            _handler,
            _inputToken,
            feeToken,
            _owner,
            _witness,
            _swapData
        );

        (uint256 tokenBalance, uint256 feeTokenBalance) = (vaultData[vault].tokenBalance, vaultData[vault].feeTokenBalance);

        return tokenBalance > 0 && feeTokenBalance > 0;
    }

    /**
     * @notice Check whether a limit order can be executed or not
     * @param _handler - Address of the handler to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _swapData - Bytes of the order's data
     * @return canExec - whether the order can be executed or not
     * @return execData - function and params to execute
     */
    function canExecuteLimitOrder(
        IHandler _handler,
        address _inputToken,
        address feeToken,
        address payable _owner,
        address _witness,
        bytes calldata _swapData,
        bytes calldata _signature
    ) external view returns (bool canExec, bytes memory execData) {

        address vault = vaultOfOrder(
            _handler,
            _inputToken,
            feeToken,
            _owner,
            _witness,
            _swapData
        );

        // Check balance amount in vault
        canExec = _handler.canExecuteLimitOrder(
            vaultData[vault].feeTokenBalance,
            vaultData[vault].tokenBalance,
            _swapData
        );

        execData = abi.encodeWithSelector(this.executeLimitOrder.selector, _handler, _inputToken, feeToken, _owner, _swapData, _signature);
    }

    /**
     * @notice Get the order's key
     * @param _handler - Address of the handler to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _witness - Address of the witness
     * @param _swapData - Bytes of the order's data
     * @return bytes32 - order's key
     */
    function keyOf(
        IHandler _handler,
        address _inputToken,
        address feeToken,
        address _owner,
        address _witness,
        bytes memory _swapData
    ) public pure returns (bytes32) {
        return
        keccak256(
            abi.encode(_handler, _inputToken, feeToken, _owner, _witness, _swapData)
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

    /**
     * @notice User deposits tokens
     * @param _amountFeeToken - Amount of fee token to deposit
     * @param _amountTokenA - Amount of tokenA to deposit
     * @param _handler - Address of the handler to use for the order execution
     * @param _witness - Address of the witness
     * @param _swapData - Bytes of the order's data
     */
    function depositTokensAndCreateTask(
        uint256 _amountFeeToken,
        uint256 _amountTokenA,
        IHandler _handler,
        address _witness,
        bytes calldata _swapData,
        bytes calldata signature
    ) public payable nonReentrant {

        (,,address[] memory pathNativeSwap,address[] memory pathTokenSwap,,) = abi.decode(_swapData,(uint96, uint256, address[], address[], uint32[], uint32[]));
        address _tokenA = pathTokenSwap[0];
        require(FEE_TOKEN == pathNativeSwap[0] || (pathNativeSwap.length == 0 && FEE_TOKEN == NATIVE_ADDRESS), "Fee token in pathNative swap doesnt match");

        bytes memory resolverData = abi.encode(this.canExecuteLimitOrder.selector,_handler,_tokenA,FEE_TOKEN,msg.sender,_witness,_swapData,signature);

        Module[] memory modules;
        modules[0] = (Module.RESOLVER);
        modules[1] = (Module.PROXY);
        modules[2] = (Module.SINGLE_EXEC);

        bytes[] memory moduleData;
        moduleData[0] = resolverData;
        moduleData[1] = '0x';
        moduleData[2] = '0x';

        ModuleData memory moduleDataGelato = ModuleData(modules,moduleData);

        // create gelato task
        bytes32 taskId = GELATO_OPS.createTask(address(this), abi.encodeWithSelector(this.executeLimitOrder.selector), moduleDataGelato, NATIVE_ADDRESS);

        address vault = vaultOfOrder(
            _handler,
            _tokenA,
            FEE_TOKEN,
            msg.sender,
            _witness,
            _swapData
        );

        vaultData[vault] = VaultData(_amountTokenA, _amountFeeToken, taskId);

        uint256 requiredNative = 0;

        // transfer tokenA, if NATIVE its just locked in contract
        if (_tokenA != NATIVE_ADDRESS) {
            IERC20(_tokenA).transferFrom(
                msg.sender,
                address(this),
                _amountTokenA
            );
        } else {
            requiredNative += _amountTokenA;
        }

        // deposit FeeToken, assuming fee token is always ERC20 not native
        if (FEE_TOKEN != NATIVE_ADDRESS) {
            IERC20(FEE_TOKEN).transferFrom(
                msg.sender,
                address(this),
                _amountFeeToken
            );
        } else {
            requiredNative += _amountFeeToken;
        }

        // Check if correct amount of native token is sent
        require(msg.value == requiredNative, "Incorrect native token amount sent");

        emit TaskCreated(
            msg.sender,
            vault,
            taskId,
            _amountFeeToken,
            _amountTokenA,
            address(_handler),
            FEE_TOKEN,
            _witness,
            _swapData
        );
    }


    /**
     * @notice Executes an order
     * @dev The sender should use the _secret to sign its own address
     * to prevent front-runnings
     * @param _handler - Address of the handler to use for the order execution
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _swapData - Bytes of the order's data
     * @param _signature - Signature to calculate the witness
     */
    function executeLimitOrder(
        IHandler _handler,
        address _inputToken,
        address feeToken,
        address payable _owner,
        bytes calldata _swapData,
        bytes calldata _signature
    ) public virtual {
        // Calculate witness using signature
        address witness = Verification.getSigner(
            msg.sender,
            _signature
        );

        address vault = vaultOfOrder(
            _handler,
            _inputToken,
            feeToken,
            _owner,
            witness,
            _swapData
        );

        (uint256 amountTokenA, uint256 amountFeeToken) = (vaultData[vault].tokenBalance, vaultData[vault].feeTokenBalance);
        // reset vault token and fee token balances
        delete vaultData[vault]; //todo confirm

        // send tokens to handler
        transferToken(_inputToken,amountTokenA,payable(_handler),true);
        transferToken(feeToken,amountFeeToken,payable(_handler),true);

        require(
            amountTokenA > 0 && amountFeeToken > 0,
            "Core#executeLimitOrder: INVALID_ORDER"
        );

        (uint256 bought, uint256 feePaid) = _handler.executeLimitOrder(
            amountFeeToken,
            amountTokenA,
            _owner,
            _swapData
        );

        emit OrderExecuted(
            vault,
            bought,
            feeToken,
            amountFeeToken,
            feePaid
        );
    }


    function cancelTaskAndWithdrawTokens(
        IHandler _handler,
        address _tokenA,
        address feeToken,
        address _witness,
        bytes calldata swapData
    ) external {

        address vault = vaultOfOrder(
            _handler,
            _tokenA,
            feeToken,
            msg.sender,
            _witness,
            swapData
        );

        (uint256 tokenBalance, uint256 feeTokenBalance, bytes32 taskId) = (vaultData[vault].tokenBalance, vaultData[vault].feeTokenBalance, vaultData[vault].taskId);

        // cancel task associated with vault
        GELATO_OPS.cancelTask(taskId);

        transferToken(_tokenA,tokenBalance,payable(msg.sender),false);
        transferToken(feeToken,feeTokenBalance,payable(msg.sender),false);

        delete vaultData[vault];

        emit OrderCancelledAndVaultWithdrawn(
            vault,
            taskId
        );
    }

    function transferToken(address token, uint256 amountToken, address payable to, bool needWrap) internal {
        if(token == NATIVE_ADDRESS){
            if (needWrap){
                // wrap the native token and send to handler
                IWETH(WRAPPED_NATIVE).deposit{value: amountToken}();
                IWETH(WRAPPED_NATIVE).transfer(to,amountToken);
            } else {
                // send native
                (bool success,) = to.call{value:amountToken}("");
                require(success, "Failed to send native token");
            }
        } else {
            // transfer the erc20 fee token
            IERC20(token).transfer(
                to,
                amountToken
            );
        }
    }

    function addMoreFeeTokens(address vault, address feeToken, uint256 amount) external {
        require(vaultData[vault].feeTokenBalance > 0, "trying to add to non-existent order");
        vaultData[vault].feeTokenBalance += amount;
        emit MoreFeeTokenFunded(vault, feeToken, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
    function getOwner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(getOwner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct VaultData{
    uint256 tokenBalance;
    uint256 feeTokenBalance;
    bytes32 taskId;
}

interface IHandler {

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
        address _owner,
        bytes calldata _data
    ) external returns (uint256,uint256);

    /**
     * @notice Check whether an order can be executed or not
     * @param amountFeeToken - uint256 of the input FeeToken token amount (order amount)
     * @param amountTokenA - uint256 of the input token token amount (order amount)
     * @param swapData - Bytes of the order's data
     * @return bool - whether the order can be executed or not
     */
    function canExecuteLimitOrder(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        bytes calldata swapData
    ) external view returns (bool);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IWETH{
    // Wrap ETH to WETH
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
}