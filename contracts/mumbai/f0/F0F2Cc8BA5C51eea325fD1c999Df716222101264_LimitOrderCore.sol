// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {IOps} from "../interfaces/IOps.sol";
import "../interfaces/IHandler.sol";
import "../Core/Ownable.sol";

contract HandlerV1 is IHandler,Ownable {
    address public ROUTER_ADDRESS;
    IOps immutable gelatoOps;
    address immutable WRAPPED_NATIVE;
    address public NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _ops, address router_address, address __owner, address _WRAPPED_NATIVE) Ownable(__owner) {
        gelatoOps = IOps(_ops);
        ROUTER_ADDRESS = router_address;
        WRAPPED_NATIVE=_WRAPPED_NATIVE;
    }

    // dont send tokens directly
    receive() external payable {
        require(
            msg.sender != tx.origin,
            "dont send native tokens directly"
        );
    }

    // Need to be invoked in case when Gelato changes their native token address , very unlikely though
    function updateNativeTokenAddress(address newNativeTokenAddress) external onlyOwner {
        NATIVE_TOKEN = newNativeTokenAddress;
    }

    // Transfer native token
    function _transfer(uint256 _fee, address _feeToken, address payable to) internal {
        if (_feeToken == NATIVE_TOKEN) {
            (bool success, ) = to.call{value: _fee}("");
            require(success, "_transfer: NATIVE_TOKEN transfer failed");
        } else {
            IERC20(_feeToken).transfer(address(gelatoOps), _fee);
        }
    }

    // Get transaction fee and feeToken from GelatoOps for the transaction execution
    function _getFeeDetails()
    internal
    view
    returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = gelatoOps.getFeeDetails();
    }

    // Checker for limit order
    function canExecuteLimitOrder(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        bytes calldata swapData
    ) external view returns (bool) {
        // Decode data
        (
        uint96 deadline,
        uint256 minReturn,
        address[] memory pathNativeSwap,
        address[] memory pathTokenSwap,
        uint32[] memory feeNativeSwap,
        uint32[] memory feeTokenSwap
        ) = abi.decode(
            swapData,
            (uint96, uint256, address[], address[], uint32[], uint32[])
        );

        // Check order validity
        if (block.timestamp > deadline) revert("deadline passed");

        // Check if sufficient tokenB will be returned
        require(
            (
            IRouter(ROUTER_ADDRESS).getAmountsOut(
                amountTokenA,
                pathTokenSwap,
                feeTokenSwap
            )
            )[pathTokenSwap.length - 1] >= minReturn,
            "insufficient token B returned"
        );

        // Check if input FeeToken amount is sufficient to cover fees
        (uint256 FEES, address feeToken) = _getFeeDetails();
        if(feeToken == NATIVE_TOKEN) {
            require(pathNativeSwap[pathNativeSwap.length - 1] == NATIVE_TOKEN, "incorrect fee token provided in swap, provide native");
        } else {
            require(feeToken == pathNativeSwap[pathNativeSwap.length - 1],"incorrect fee token provided in swap");
        }

        require(
            (
            IRouter(ROUTER_ADDRESS).getAmountsOut(
                amountFeeToken,
                pathNativeSwap,
                feeNativeSwap
            )
            )[pathNativeSwap.length - 1] >= FEES,
            "insufficient NATIVE_TOKEN returned"
        );

        return true;
    }

    // Executor for limit order
    function executeLimitOrder(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        address _owner,
        bytes calldata _data
    ) external returns(uint256,uint256) {
        // Decode data
        (
        uint96 deadline,
        uint256 minReturn,
        address[] memory pathNativeSwap, // provide empty array if fee token is native
        address[] memory pathTokenSwap,
        uint32[] memory feeNativeSwap,
        uint32[] memory feeTokenSwap
        ) = abi.decode(
            _data,
            (uint96, uint256, address[], address[], uint32[], uint32[])
        );

        // the approve works for wrapped native tokens also using the IERC20 interface
        // approve tokenA to router
        IERC20(pathTokenSwap[0]).approve(ROUTER_ADDRESS, amountTokenA);

        // calculate feeToken amount from native fee
        uint256[] memory feeTokenAmountFromNativeFee;

        // get tx fee
        (uint256 FEES, address feeToken) = _getFeeDetails();

        //todo discuss
        if (pathNativeSwap.length != 0){
            feeTokenAmountFromNativeFee = IRouter(ROUTER_ADDRESS).getAmountsIn(
                FEES,
                pathNativeSwap,
                feeNativeSwap
            );

            require(
                amountFeeToken >= feeTokenAmountFromNativeFee[0],
                "insufficient feeToken amount"
            );

            require(
                IERC20(pathNativeSwap[0]).balanceOf(address(this)) >=
                amountFeeToken,
                "insufficient balance of feeToken in handler"
            );

            // call swap tokenA to native token
            if (feeToken == NATIVE_TOKEN) {
                require(pathNativeSwap[pathNativeSwap.length-1] == WRAPPED_NATIVE, "Incorrect fee path provided");
                IRouter(ROUTER_ADDRESS).swapTokensForExactNative(
                    FEES,
                    feeTokenAmountFromNativeFee[0],
                    pathNativeSwap,
                    feeNativeSwap,
                    address(this),
                    deadline
                );

                // send gelato fees
                (bool success, ) = gelatoOps.gelato().call{value: FEES}("");
                require(success, "_transfer: NATIVE_TOKEN transfer failed");
            } else {
                require(pathNativeSwap[pathNativeSwap.length-1] == feeToken, "Incorrect erc20 fee token path provided");
                IRouter(ROUTER_ADDRESS).swapTokensForExactTokens(
                    FEES,
                    feeTokenAmountFromNativeFee[0],
                    pathNativeSwap,
                    feeNativeSwap,
                    address(this),
                    deadline
                );

                // send gelato fees
                IERC20(feeToken).transfer(gelatoOps.gelato(), FEES);
            }
        } else {
            // send gelato fees directly
            gelatoOps.gelato().call{value:FEES}("");
        }

        // transfer the remaining welle back to owner
        _transfer(amountFeeToken - feeTokenAmountFromNativeFee[0],pathNativeSwap[0],payable(_owner));

        // call swap tokenA to tokenB
        uint256[] memory amounts =
        IRouter(ROUTER_ADDRESS)
        .swapExactTokensForTokens(
            amountTokenA,
            minReturn,
            pathTokenSwap,
            feeTokenSwap,
            _owner,
            deadline
        );

        uint256 bought = amounts[pathTokenSwap.length-1];

        require(
            bought >= minReturn,
            "Insufficient return tokenB"
        );

        return (bought,feeTokenAmountFromNativeFee[0]);
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouterV2} from "../interfaces/IRouterV2.sol";
import {IOps} from "../interfaces/IOps.sol";
import "../interfaces/IHandler.sol";
import "../Core/Ownable.sol";

contract HandlerV2 is IHandler,Ownable {
    address public ROUTER_ADDRESS;
    IOps immutable gelatoOps;
    address immutable WRAPPED_NATIVE;
    address public NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _ops, address router_address, address __owner, address _WRAPPED_NATIVE) Ownable(__owner) {
        gelatoOps = IOps(_ops);
        ROUTER_ADDRESS = router_address;
        WRAPPED_NATIVE=_WRAPPED_NATIVE;
    }

    // dont send tokens directly
    receive() external payable {
        require(
            msg.sender != tx.origin,
            "dont send native tokens directly"
        );
    }

    // Need to be invoked in case when Gelato changes their native token address , very unlikely though
    function updateNativeTokenAddress(address newNativeTokenAddress) external onlyOwner {
        NATIVE_TOKEN = newNativeTokenAddress;
    }

    // Transfer native token
    function _transfer(uint256 _fee, address _feeToken, address payable to) internal {
        if (_feeToken == NATIVE_TOKEN) {
            (bool success, ) = to.call{value: _fee}("");
            require(success, "_transfer: NATIVE_TOKEN transfer failed");
        } else {
            IERC20(_feeToken).transfer(address(gelatoOps), _fee);
        }
    }

    // Get transaction fee and feeToken from GelatoOps for the transaction execution
    function _getFeeDetails()
    internal
    view
    returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = gelatoOps.getFeeDetails();
    }

    // Checker for limit order
    function canExecuteLimitOrder(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        bytes calldata swapData
    ) external view returns (bool) {
        // Decode data
        (
        uint96 deadline,
        uint256 minReturn,
        address[] memory pathNativeSwap,
        address[] memory pathTokenSwap,
        uint32[] memory feeNativeSwap,
        uint32[] memory feeTokenSwap
        ) = abi.decode(
            swapData,
            (uint96, uint256, address[], address[], uint32[], uint32[])
        );

        // Check order validity
        if (block.timestamp > deadline) revert("deadline passed");

        // Check if sufficient tokenB will be returned
        require(
            (
            IRouterV2(ROUTER_ADDRESS).getAmountsOut(
                amountTokenA,
                pathTokenSwap,
                feeTokenSwap
            )
            )[pathTokenSwap.length - 1] >= minReturn,
            "insufficient token B returned"
        );

        // Check if input FeeToken amount is sufficient to cover fees
        (uint256 FEES, address feeToken) = _getFeeDetails();
        if(feeToken == NATIVE_TOKEN) {
            require(pathNativeSwap[pathNativeSwap.length - 1] == NATIVE_TOKEN, "incorrect fee token provided in swap, provide native");
        } else {
            require(feeToken == pathNativeSwap[pathNativeSwap.length - 1],"incorrect fee token provided in swap");
        }

        require(
            (
            IRouterV2(ROUTER_ADDRESS).getAmountsOut(
                amountFeeToken,
                pathNativeSwap,
                feeNativeSwap
            )
            )[pathNativeSwap.length - 1] >= FEES,
            "insufficient NATIVE_TOKEN returned"
        );

        return true;
    }

    // Executor for limit order
    function executeLimitOrder(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        address _owner,
        bytes calldata _data
    ) external returns(uint256,uint256) {
        // Decode data
        (
        uint96 deadline,
        uint256 minReturn,
        address[] memory pathNativeSwap, // provide empty array if fee token is native
        address[] memory pathTokenSwap,
        uint32[] memory feeNativeSwap,
        uint32[] memory feeTokenSwap
        ) = abi.decode(
            _data,
            (uint96, uint256, address[], address[], uint32[], uint32[])
        );

        // the approve works for wrapped native tokens also using the IERC20 interface
        // approve tokenA to router
        IERC20(pathTokenSwap[0]).approve(ROUTER_ADDRESS, amountTokenA);

        // calculate feeToken amount from native fee
        uint256[] memory feeTokenAmountFromNativeFee;

        // get tx fee
        (uint256 FEES, address feeToken) = _getFeeDetails();

        //todo discuss
        if (pathNativeSwap.length != 0){
            feeTokenAmountFromNativeFee = IRouterV2(ROUTER_ADDRESS).getAmountsIn(
                FEES,
                pathNativeSwap,
                feeNativeSwap
            );

            require(
                amountFeeToken >= feeTokenAmountFromNativeFee[0],
                "insufficient feeToken amount"
            );

            require(
                IERC20(pathNativeSwap[0]).balanceOf(address(this)) >=
                amountFeeToken,
                "insufficient balance of feeToken in handler"
            );

            // call swap tokenA to native token
            if (feeToken == NATIVE_TOKEN) {
                require(pathNativeSwap[pathNativeSwap.length-1] == WRAPPED_NATIVE, "Incorrect fee path provided");
                IRouterV2(ROUTER_ADDRESS).swapTokensForExactNative(
                    FEES,
                    feeTokenAmountFromNativeFee[0],
                    pathNativeSwap,
                    feeNativeSwap,
                    address(this),
                    deadline
                );

                // send gelato fees
                (bool success, ) = gelatoOps.gelato().call{value: FEES}("");
                require(success, "_transfer: NATIVE_TOKEN transfer failed");
            } else {
                require(pathNativeSwap[pathNativeSwap.length-1] == feeToken, "Incorrect erc20 fee token path provided");
                IRouterV2(ROUTER_ADDRESS).swapTokensForExactTokens(
                    FEES,
                    feeTokenAmountFromNativeFee[0],
                    pathNativeSwap,
                    feeNativeSwap,
                    address(this),
                    deadline
                );

                // send gelato fees
                IERC20(feeToken).transfer(gelatoOps.gelato(), FEES);
            }
        } else {
            // send gelato fees directly
            gelatoOps.gelato().call{value:FEES}("");
        }

        // transfer the remaining welle back to owner
        _transfer(amountFeeToken - feeTokenAmountFromNativeFee[0],pathNativeSwap[0],payable(_owner));

        uint256 balanceBefore = IERC20(pathTokenSwap[pathTokenSwap.length-1]).balanceOf(_owner);

        // call swap tokenA to tokenB
        IRouterV2(ROUTER_ADDRESS)
        .swapExactTokensForTokens(
            amountTokenA,
            minReturn,
            pathTokenSwap,
            feeTokenSwap,
            _owner,
            deadline
        );

        uint256 bought = IERC20(pathTokenSwap[pathTokenSwap.length-1]).balanceOf(_owner) - balanceBefore;

        require(
            bought >= minReturn,
            "Insufficient return tokenB"
        );

        return (bought,feeTokenAmountFromNativeFee[0]);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

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

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRouter {
    function factory() external view returns (address);

    function WNative() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityNative(
        address token,
        uint32 fee,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountNativeMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountNative, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityNative(
        address token,
        uint32 fee,
        uint liquidity,
        uint amountTokenMin,
        uint amountNativeMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountNative);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactNativeForTokens(uint amountOutMin, address[] calldata path, uint32[] calldata feePath, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactNative(uint amountOut, uint amountInMax, address[] calldata path, uint32[] calldata feePath, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function quoteByTokens(
        uint256 amountA,
        address tokenA,
        address tokenB,
        uint32 fee
    ) external view returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] memory path, uint32[] calldata feePath)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path, uint32[] calldata feePath)
    external
    view
    returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IRouter.sol';

interface IRouterV2 is IRouter {
    // Identical to removeLiquidityNative, but succeeds for tokens that take a fee on transfer.
    function removeLiquidityNativeSupportingFeeOnTransferTokens(
        address token,
        uint32 fee,
        uint liquidity,
        uint amountTokenMin,
        uint amountNativeMin,
        address to,
        uint deadline
    ) external returns (uint amountNative);
    // Identical to swapExactTokensForTokens, but succeeds for tokens that take a fee on transfer.
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint deadline
    ) external;

    // Identical to swapExactNativeForTokens, but succeeds for tokens that take a fee on transfer.
    function swapExactNativeForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint deadline
    ) external payable;

    // Identical to swapExactTokensForNative, but succeeds for tokens that take a fee on transfer.
    function swapExactTokensForNativeSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IWETH{
    // Wrap ETH to WETH
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
}