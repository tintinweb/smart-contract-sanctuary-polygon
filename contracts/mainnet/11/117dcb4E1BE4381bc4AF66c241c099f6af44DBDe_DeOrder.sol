// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


import "./interface/IOrderSBT.sol";
import './interface/IWETH9.sol';
import './interface/IPermit2.sol';
import './interface/IOrderVerifier.sol';

import "./DeOrderVerifier.sol";
import "./DeStage.sol";
import './Multicall.sol';



contract DeOrder is DeStage, DeOrderVerifier, Multicall, Ownable, ReentrancyGuard {
    error PermissionsError();
    error ProgressError();
    error UnSupportToken();

    uint private constant FEE_BASE = 10000;
    uint public fee = 500;   // 5%
    address public feeTo;

    address public builderSBT;
    address public issuerSBT;

    IWETH9 public immutable WETH;
    IPermit2 public immutable PERMIT2;
    

    uint public currOrderId;

    // orderId  = > 
    mapping(uint => Order) private orders;

    mapping(address => bool) public supportTokens;

    event OrderCreated(uint indexed taskId, uint indexed orderId,  address issuer, address worker, address token, uint amount);
    event OrderModified(uint indexed orderId, address token, uint amount);
    event OrderStarted(uint indexed orderId, address who, uint payType);
    event OrderAbort(uint indexed orderId, address who, uint stageIndex);
    event Withdraw(uint indexed orderId, uint amount, uint stageIndex);
    event AttachmentUpdated(uint indexed orderId, string attachment);
    event FeeUpdated(uint fee, address feeTo);
    event SupportToken(address token, bool enabled);

    constructor(address _weth, address _permit2) {
        WETH = IWETH9(_weth);
        PERMIT2 = IPermit2(_permit2);

        feeTo = msg.sender;

        supportTokens[_weth] = true;
        supportTokens[address(0)] = true;
    }

    receive() external payable {
        assert(msg.sender == address(WETH)); // only accept ETH via fallback from the WETH contract
    }

    // 1 确定合作意向
    function createOrder(uint _taskId, address _issuer, address _worker, address _token, uint _amount) external payable {
        if(address(0) == _worker || address(0) == _issuer || _worker == _issuer) revert ParamError();
        safe96(_amount);

        if(!supportTokens[_token]) revert UnSupportToken();

        unchecked {
            currOrderId += 1;    
        }
        
        orders[currOrderId] = Order({
            taskId: _taskId,
            issuer: _issuer,
            worker: _worker,
            token: _token,  
            amount: uint96(_amount),
            progress: OrderProgess.Init,
            payType: PaymentType.Unknown,
            startDate: 0,
            payed: 0
        });

        emit OrderCreated(_taskId, currOrderId, _issuer, _worker, _token, _amount);
    }

    function getOrder(uint orderId) public override view returns (Order memory) {
        return orders[orderId];
    }

    function modifyOrder(uint orderId, address token, uint amount) external payable {
        safe96(amount);
        Order storage order = orders[orderId];
        if(order.progress >= OrderProgess.Ongoing) revert ProgressError();
        if(msg.sender != order.issuer) revert PermissionsError();
        if(!supportTokens[token]) revert UnSupportToken();
        

        // if change token , must refund
        if (orders[orderId].token != token && order.payed > 0) {
            refund(orderId, msg.sender, order.payed);
        }
        orders[orderId].token = token;
        orders[orderId].amount = uint96(amount);

        emit OrderModified(orderId, token, amount);
    }

    // 2. 确定规划 （阶段、对应金额）
    function permitStage(uint _orderId, uint[] memory _amounts, uint[] memory _periods,
        PaymentType payType,
        uint nonce,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) public payable {
        
        Order storage order = orders[_orderId];
        if(order.progress >= OrderProgess.Ongoing) revert ProgressError();

        address signAddr = recoverPermitStage(_orderId, _amounts, _periods, uint(payType),
            nonce, deadline, v, r, s);
        
        roleCheck(order, signAddr);

        order.progress = OrderProgess.Staged;
        order.payType = payType;

        setStage(_orderId, _amounts, _periods);
    }

    // 
    function prolongStage(uint _orderId, uint _stageIndex, uint _appendPeriod,
        uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        Order storage order = orders[_orderId];
        if(order.progress != OrderProgess.Ongoing) revert ProgressError();


        address signAddr = recoverProlongStage(_orderId, _stageIndex, _appendPeriod, nonce, deadline, v, r,  s );
        roleCheck(order, signAddr);
        prolongStage(_orderId, _stageIndex, _appendPeriod);
    }

    function appendStage(uint _orderId, uint amount, uint period, uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) external payable {
        safe96(amount);
        Order storage order = orders[_orderId];
        if(order.progress != OrderProgess.Ongoing) revert ProgressError();

        address signAddr = recoverAppendStage(_orderId, amount, period, nonce, deadline, v, r, s);
        roleCheck(order, signAddr);

        order.amount += uint96(amount);
        if(order.payed < order.amount) revert AmountError(1);

        appendStage(_orderId, amount, period);
    }

    function roleCheck(Order storage order, address signAddr) internal {
        if((order.worker == msg.sender && signAddr == order.issuer) ||
            (order.issuer == msg.sender && signAddr == order.worker)) {
        } else {
            revert PermissionsError(); 
        } 
    }

    // 3. 付款 Permit
    function payOrderWithPermit(uint orderId, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        IERC20Permit(orders[orderId].token).permit(msg.sender, address(this), amount, deadline, v, r, s);
        payOrder(orderId, amount);
    }

    // 3. 付款
    // anyone can pay for this order
    function payOrder(uint orderId, uint amount) public payable nonReentrant {
        Order storage order = orders[orderId];
        if (order.amount == 0){
            revert AmountError(0);
        }
        address token = order.token;
        safe96(amount);

        if (token == address(0)) {
            uint b = address(this).balance;
            IWETH9(WETH).deposit{value: b}();
            unchecked {
                order.payed += uint96(b);
            }
        } else {
            if(msg.value > 0) {
                revert AmountError(0);
            }
            
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
            order.payed += uint96(amount);
        }
    }

    // // 3. 付款 Permit2
    function payOrderWithPermit2(
        uint orderId,
        uint256 amount,
        IPermit2.PermitTransferFrom calldata permit,
        bytes calldata signature
    ) external nonReentrant {
        safe96(amount);
        Order storage order = orders[orderId];
        if (permit.permitted.token != order.token || order.token == address(0)) {
            revert UnSupportToken(); 
        }
        
        // Transfer tokens from the caller to this contract.
        PERMIT2.permitTransferFrom(
            permit, // The permit message.
            // The transfer recipient and amount.
            IPermit2.SignatureTransferDetails({
                to: address(this),
                requestedAmount: amount
            }),
            // The owner of the tokens, which must also be
            // the signer of the message, otherwise this call
            // will fail.
            msg.sender,
            // The packed signature that was the result of signing
            // the EIP712 hash of `permit`.
            signature
        );

        order.payed += uint96(amount);
    }


    // 提交交付
    function updateAttachment(uint _orderId, string calldata _attachment) external {
        Order storage order = orders[_orderId];
        if(order.worker != msg.sender && order.issuer != msg.sender) revert PermissionsError();
        emit AttachmentUpdated(_orderId, _attachment);
    }

    //  订单开始
    function startOrder(uint _orderId) external payable {
        Order storage order = orders[_orderId];
        if(order.progress != OrderProgess.Staged || order.payType == PaymentType.Unknown) {
            revert ProgressError();
        }
        
        if(order.amount != stageTotalAmount(_orderId)) revert AmountError(0);
        if(order.payed < order.amount) revert AmountError(1);

        order.progress = OrderProgess.Ongoing;
        order.startDate = uint32(block.timestamp);
        emit OrderStarted(_orderId, msg.sender, uint(order.payType));
        
        startOrderStage(_orderId);
    }

    // 甲方验收
    function confirmDelivery(uint _orderId, uint[] memory _stageIndexs) external {
        Order storage order = orders[_orderId];
        if(order.progress != OrderProgess.Ongoing) revert ProgressError();
        if(msg.sender != order.issuer) revert PermissionsError();

        for (uint i = 0; i < _stageIndexs.length;) {
            confirmDelivery(_orderId, _stageIndexs[i]);
            unchecked{ i++; }
        }
    }

    // Abort And Settle
    function abortOrder(uint _orderId) external nonReentrant {
        Order storage order = orders[_orderId];
        if(order.progress != OrderProgess.Ongoing) revert ProgressError();

        bool issuerAbort;
        if(order.worker == msg.sender) {
        } else if (order.issuer == msg.sender) {
            issuerAbort = true;
        } else {
            revert PermissionsError(); 
        } 

        (uint currStageIndex, uint issuerAmount, uint workerAmount) = 
            abortOrder(_orderId, issuerAbort);

        if (issuerAbort) {
            order.progress = OrderProgess.IssuerAbort;
        } else {
            order.progress = OrderProgess.WokerAbort;
        }

        doTransfer(order.token, order.issuer, issuerAmount);
        if (fee > 0) {
            uint feeAmount;
            unchecked {
                feeAmount = workerAmount * fee / FEE_BASE;
            }
            doTransfer(order.token, feeTo, feeAmount);
            doTransfer(order.token, order.worker, workerAmount - feeAmount);
        } else {
            doTransfer(order.token, order.worker, workerAmount);
        }

        emit OrderAbort(_orderId, msg.sender, currStageIndex);
    }

    function refund(uint _orderId, address _to, uint _amount) payable public nonReentrant {
        Order storage order = orders[_orderId];
        if(msg.sender != order.issuer) revert PermissionsError(); 
        safe96(_amount);
        order.payed -= uint96(_amount);
        if(order.progress >= OrderProgess.Ongoing) {
            if(order.payed < order.amount) revert AmountError(1);
        }

        doTransfer(order.token, _to, _amount);
    }

    // 乙方提款
    // worker withdraw the fee.
    function withdraw(uint _orderId, address to) external nonReentrant {
        Order storage order = orders[_orderId];
        if(order.worker != msg.sender) revert PermissionsError();
        if(order.progress != OrderProgess.Ongoing) revert ProgressError();

        (uint pending, uint nextStage) = pendingWithdraw(_orderId);
        if (pending > 0) {
            if (fee > 0) {
                uint feeAmount;
                unchecked {
                      feeAmount = pending * fee / FEE_BASE;
                }
                doTransfer(order.token, feeTo, feeAmount);
                doTransfer(order.token, to, pending - feeAmount);
                
            } else {
                doTransfer(order.token, to, pending);
            }
            
            withdrawStage(_orderId, nextStage);
        }
        
        if (nextStage > 0) {
            unchecked {
                emit Withdraw(_orderId, pending, nextStage - 1);
            }
        }
        
        if (nextStage >= stagesLength(_orderId)) {
            order.progress = OrderProgess.Done;

            if (builderSBT != address(0)) {
                IOrderSBT(builderSBT).mint(order.worker, _orderId);
            }

            if (issuerSBT != address(0)) {
                IOrderSBT(issuerSBT).mint(order.issuer, _orderId);
            }
        }

    }

    function doTransfer(address _token, address _to, uint _amount) private {
        if (_amount == 0) return;

        if (address(0) == _token) {
            IWETH9(WETH).withdraw(_amount);
            (bool success, ) = _to.call{value: _amount}(new bytes(0));
            require(success, 'ETH transfer failed');
        } else {
            SafeERC20.safeTransfer(IERC20(_token), _to, _amount);
        }
    }

    function setFeeTo(uint _fee, address _feeTo) external onlyOwner {
        fee = _fee;
        feeTo = _feeTo;
        emit FeeUpdated(_fee, _feeTo);
    } 

    function setSBT(address _builder, address _issuer) external onlyOwner {
        builderSBT = _builder;
        issuerSBT = _issuer;
    }

    function setSupportToken(address _token, bool enable) external onlyOwner {
        supportTokens[_token] = enable;
        emit SupportToken(_token, enable);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOrderSBT {
  function mint(address who, uint orderId) external;
}

pragma solidity >=0.8.0;


interface IWETH9 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// Minimal Permit2 interface, derived from
// https://github.com/Uniswap/permit2/blob/main/src/interfaces/ISignatureTransfer.sol

interface IPermit2 {
    // Token and amount in a permit message.
    struct TokenPermissions {
        // Token to transfer.
        address token;
        // Amount to transfer.
        uint256 amount;
    }

    // The permit2 message.
    struct PermitTransferFrom {
        // Permitted token and amount.
        TokenPermissions permitted;
        // Unique identifier for this permit.
        uint256 nonce;
        // Expiration for this permit.
        uint256 deadline;
    }

    // Transfer details for permitTransferFrom().
    struct SignatureTransferDetails {
        // Recipient of tokens.
        address to;
        // Amount to transfer.
        uint256 requestedAmount;
    }

    // Consume a permit2 message and transfer tokens.
    function permitTransferFrom(
        PermitTransferFrom calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOrderVerifier {
    function recoverPermitStage(
        uint256 _orderId,
        uint256[] memory _amounts,
        uint256[] memory _periods,
        uint256 payType,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (address signAddr);

    function recoverProlongStage(
        uint256 _orderId,
        uint256 _stageIndex,
        uint256 _appendPeriod,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (address signAddr);

    function recoverAppendStage(
        uint256 _orderId,
        uint256 amount,
        uint256 period,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (address signAddr);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libs/ECDSA.sol";
import "./interface/IOrder.sol";

abstract contract DeOrderVerifier {

    error NonceError();
    error Expired();

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMITSTAGE_TYPEHASH = keccak256("PermitStage(uint256 orderId,uint256[] amounts,uint256[] periods,uint256 payType,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMITPROSTAGE_TYPEHASH = keccak256("PermitProStage(uint256 orderId,uint256 stageIndex,uint256 period,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMITAPPENDSTAGE_TYPEHASH = keccak256("PermitAppendStage(uint256 orderId,uint256 amount,uint256 period,uint256 nonce,uint256 deadline)");

    mapping(address => mapping(uint => uint)) public nonces;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    // This should match the domain you set in your client side signing.
                    keccak256(bytes("DetaskOrder")),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }


    function recoverPermitStage(uint _orderId, uint[] memory _amounts, uint[] memory _periods,
        uint256 payType,
        uint nonce,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) internal returns (address signAddr) {
            
            bytes32 structHash  = keccak256(abi.encode(PERMITSTAGE_TYPEHASH, _orderId,
                keccak256(abi.encodePacked(_amounts)), keccak256(abi.encodePacked(_periods)), payType, nonce, deadline));
            return recoverVerify(structHash, _orderId, nonce, deadline, v , r, s);
    }

    function recoverProlongStage(uint _orderId, uint _stageIndex, uint _appendPeriod,
        uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) internal returns (address signAddr) {

        bytes32 structHash = keccak256(abi.encode(PERMITPROSTAGE_TYPEHASH, _orderId,
            _stageIndex, _appendPeriod, nonce, deadline));
        return recoverVerify(structHash, _orderId, nonce, deadline, v , r, s);
    }

    function recoverAppendStage(uint _orderId, uint amount, uint period, uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) internal returns (address signAddr) {
        bytes32 structHash = keccak256(abi.encode(PERMITAPPENDSTAGE_TYPEHASH, _orderId,
            amount, period, nonce, deadline));
        return recoverVerify(structHash, _orderId, nonce, deadline, v , r, s);

    }

    function recoverVerify(bytes32 structHash, uint _orderId, uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) internal returns (address signAddr){
        bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);
        signAddr = ECDSA.recover(digest, v, r, s);

        if(nonces[signAddr][_orderId] != nonce) revert NonceError();
        if(deadline < block.timestamp) revert Expired();
        nonces[signAddr][_orderId] += 1;
    }

}

pragma solidity ^0.8.0;

import "./interface/IOrder.sol";

abstract contract DeStage is IOrder {
    error AmountError(uint reason); // 0: amount error, 1: need pay
    error InvalidCaller();
    error ParamError();
    error StatusError();

    uint constant maxStages = 12;

    enum StageStatus {
        Init,
        Accepted,
        Aborted,
        Withdrawed
    }

    //交付阶段
    struct Stage {
        uint96 amount;        // pay amount
        uint32 period;        // second
        StageStatus status;
    }

    // orderId = >
    mapping(uint => Stage[]) private orderStages;

    event ConfirmOrderStage(uint indexed orderId, uint stageIndex);
    event SetStage(uint indexed orderId, uint[] amounts, uint[] periods);
    event ProlongStage(uint indexed orderId, uint stageIndex, uint appendPeriod);
    event AppendStage(uint indexed orderId, uint amount, uint period);

    constructor() internal {
    }

    function getOrder(uint orderId) public override virtual view returns (Order memory);


    function setStage(uint _orderId, uint[] memory _amounts, uint[] memory _periods) internal {

        if(_amounts.length != _periods.length || _amounts.length == 0) revert ParamError();
        if(maxStages < _amounts.length) revert ParamError();

        delete orderStages[_orderId];
        Stage[] storage stages = orderStages[_orderId];

        for ( uint i = 0; i < _periods.length; i++ ) {
            safe96(_amounts[i]);
            safe32(_periods[i]);

            Stage memory pro = Stage ({
                amount: uint96(_amounts[i]),
                period: uint32(_periods[i]),
                status: StageStatus.Init
            });
            stages.push(pro);
        }
        emit SetStage(_orderId, _amounts, _periods);
    }

    function prolongStage(uint _orderId, uint _stageIndex, uint _appendPeriod) internal {
        safe32(_appendPeriod);

        Stage storage stage = orderStages[_orderId][_stageIndex];
        if(stage.status != StageStatus.Init) revert StatusError();
        stage.period += uint32(_appendPeriod);

        emit ProlongStage(_orderId, _stageIndex, _appendPeriod);
    }

    function appendStage(uint _orderId, uint _amount, uint _period) internal {
        safe32(_period);

        Stage[] storage stages = orderStages[_orderId];
        Stage memory pro = Stage ({
            amount: uint96(_amount),
            period: uint32(_period),
            status: StageStatus.Init
        });

        stages.push(pro);
        emit AppendStage(_orderId, _amount, _period);
    }

    function totalStagePeriod(uint orderId) external view returns(uint total) {
        Stage[] storage stages = orderStages[orderId];
        for ( uint i = 0; i < stages.length; i++ ) {
            total += stages[i].period;
        }
    }

    function stageTotalAmount(uint orderId) public view returns(uint total)  {
        Stage[] storage stages = orderStages[orderId];
        for ( uint i = 0; i < stages.length; i++ ) {
            total += stages[i].amount;
        }
    }

    function startOrderStage(uint _orderId) internal {
        Stage[] storage stages = orderStages[_orderId];
        if (stages[0].period == 0) {
            stages[0].status = StageStatus.Accepted;
        }
    }

    function pendingWithdraw(uint _orderId) public view returns (uint pending, uint nextStage) {
        Order memory order = getOrder(_orderId);
        if(order.progress != OrderProgess.Ongoing) revert StatusError();
        uint lastStageEnd = order.startDate;
        bool payByDue = order.payType == PaymentType.Due;

        Stage[] memory stages = orderStages[_orderId];
        uint nowTs = block.timestamp;
        for ( uint i = 0; i < stages.length; i++) {
            Stage memory stage = stages[i];
            if( (stage.status == StageStatus.Accepted) || 
                (payByDue && stage.status == StageStatus.Init &&  nowTs >= lastStageEnd + stage.period)) {
                pending += stage.amount;
                nextStage = i+1;
            }
            lastStageEnd += stage.period;
        }

    }

    function withdrawStage(uint _orderId, uint _nextStage) internal {
        Stage[] storage stages = orderStages[_orderId];

        for ( uint i = 0; i < stages.length && i < _nextStage; i++) {
            if (stages[i].status != StageStatus.Withdrawed) {
                stages[i].status = StageStatus.Withdrawed;
            }
        }
    }

    function abortOrder(uint _orderId, bool issuerAbort) internal returns(uint currStageIndex, uint issuerAmount, uint workerAmount) {
        uint stageStartDate;
        ( currStageIndex, stageStartDate) = ongoingStage(_orderId);
        
        Order memory order = getOrder(_orderId);
        bool payByDue = order.payType == PaymentType.Due;
        Stage[] storage stages = orderStages[_orderId];

        for (uint i = 0; i < currStageIndex; i++) {
            if(stages[i].status != StageStatus.Withdrawed) {
                // passed or accepted , pay to worker.
                if (stages[i].status == StageStatus.Accepted || payByDue) {
                    workerAmount += stages[i].amount;
                    stages[i].status = StageStatus.Withdrawed;
                } else {
                    issuerAmount += stages[i].amount;
                }
            }
        }

        Stage storage stage = stages[currStageIndex];

        if (issuerAbort && payByDue && block.timestamp > stageStartDate) {
            workerAmount += stage.amount * (block.timestamp - stageStartDate) / stage.period;
            issuerAmount += stage.amount * (stageStartDate + stage.period - block.timestamp) / stage.period;
        } else {
            issuerAmount += stage.amount;
        }
        stage.status = StageStatus.Aborted;

        for (uint i = currStageIndex + 1; i < stages.length;) {
            issuerAmount += stages[i].amount;
            stages[i].status = StageStatus.Aborted;
            unchecked {
                i++;
            }
        }
    }

        // confirm must continuous
    function confirmDelivery(uint _orderId, uint _stageIndex) internal {
        StageStatus currStatus = orderStages[_orderId][_stageIndex].status;
        if( currStatus == StageStatus.Withdrawed || currStatus == StageStatus.Aborted ) revert StatusError();

        if (_stageIndex == 0) {
            orderStages[_orderId][_stageIndex].status = StageStatus.Accepted;
        } else {
            StageStatus lastStatus = orderStages[_orderId][_stageIndex-1].status;
            if(lastStatus == StageStatus.Accepted || lastStatus == StageStatus.Withdrawed) {
                orderStages[_orderId][_stageIndex].status = StageStatus.Accepted;
            } else {
                revert StatusError();
            }
        }
        
        emit ConfirmOrderStage(_orderId, _stageIndex);
    }

    function stagesLength(uint orderId) public view returns(uint len)  {
        len = orderStages[orderId].length; 
    }

    function getStages(uint _orderId) external view returns(Stage[] memory stages) {
        stages = orderStages[_orderId];
    }

    function ongoingStage(uint _orderId) public view returns (uint stageIndex, uint stageStartDate) {
        Order memory order = getOrder(_orderId);
        stageStartDate = order.startDate;
        if(order.progress != OrderProgess.Ongoing) revert StatusError();

        Stage[] storage stages = orderStages[_orderId];
        uint nowTs = block.timestamp;
        uint i = 0;
        for (; i < stages.length; i++) {
            Stage storage stage = stages[i];
            if (order.payType == PaymentType.Confirm) {
                if (stage.status == StageStatus.Init) {
                    stageIndex = i;
                    return (stageIndex, stageStartDate);
                }
            } else if (order.payType == PaymentType.Due) {
                if (stage.status == StageStatus.Init && nowTs < stageStartDate + stage.period) {
                    stageIndex = i;
                    return (stageIndex, stageStartDate);
                } 
            }
            stageStartDate += stage.period;
        }
        
        revert StatusError();
    }

    function safe96(uint n) internal pure {
        if(n >= 2**96) revert AmountError(0);
    }

    function safe32(uint n) internal pure {
        if(n >= 2**32) revert AmountError(0);
    }


}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './interface/IMulticall.sol';

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) external payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

pragma solidity ^0.8.4;

library ECDSA {
    error RecoverError(uint season);

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address signer) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
          revert RecoverError(1);  // for InvalidSignatureS
        }
        if (v != 27 && v != 28) {
          revert RecoverError(2);  // for InvalidSignatureV
        }

        // If the signature is valid (and not malleable), return the signer address
        signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
          revert RecoverError(3);  // InvalidSignature
        }
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


enum OrderProgess {
    Init,
    Staged,
    Ongoing,
    IssuerAbort,
    WokerAbort,
    Done
}

enum PaymentType {
    Unknown,
    Due,   // by Due
    Confirm // by Confirm , if has pre pay
}



struct Order {
    uint taskId;
    address issuer;
    uint96 amount;
    
    address worker;
    uint96 payed;

    address token;
    OrderProgess progress;   // PROG_*
    PaymentType payType;
    uint32 startDate;
}

interface IOrder {
    function getOrder(uint orderId) external view returns (Order memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}