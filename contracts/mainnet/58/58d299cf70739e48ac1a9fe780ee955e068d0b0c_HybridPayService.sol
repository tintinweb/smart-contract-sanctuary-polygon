/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

// File: contracts/libraries/VWCode.sol


pragma solidity 0.8.7;

/**
 * Library containing utility functions for working with VirtualWallet code.
 */
library VWCode {
    /// @notice  Packing (nonce: 128, time: 32, srcChainId 32, dstChainId 32, action: 16, flag: 16)
    /**
     * @dev Generates a unique code for a blockchain transaction based on its input parameters.
     * @param nonce Unique identifier for the transaction
     * @param time A timestamp used to ensure the expiration time
     * @param srcChainId The identifier of the source blockchain
     * @param dstChainId The identifier of the destination blockchain
     * @param action Type of operation being performed as part of the transaction
     * @param flag Set of flags or options for the transaction, If flag is equal to 1, then the delegatecall function must be successful for the transaction to proceed.
     * @return code Unique code for the transaction based on its input parameters
     */
    function genCode(
        uint128 nonce,
        uint32 time,
        uint32 srcChainId,
        uint32 dstChainId,
        uint16 action,
        uint16 flag
    ) internal pure returns (uint256 code) {
        code =
            (uint256(nonce) << 128) +
            (uint256(time) << 96) +
            (uint256(srcChainId) << 64) +
            (uint256(dstChainId) << 32) +
            (uint256(action) << 16) +
            uint256(flag);
    }

    /**
     *@dev Extracts dstChainId, srcChainId, and time values from a given code parameter
     *@param code uint value
     *@return dstChainId The destination chain ID
     *@return srcChainId The source chain ID
     *@return time The expiration time
     */
    function chainidsAndExpTime(uint256 code)
        internal
        pure
        returns (
            uint256 dstChainId,
            uint256 srcChainId,
            uint256 time
        )
    {
        dstChainId = (code >> 32) & ((1 << 32) - 1);
        srcChainId = (code >> 64) & ((1 << 32) - 1);
        time = (code >> 96) & ((1 << 32) - 1);
    }

    /**
     *@dev Extracts the srcChainId and action values from a given code parameter
     *@param code uint value
     *@return srcChainId The source chain ID
     *@return action The action
     */
    function splitCode(uint256 code)
        internal
        pure
        returns (uint256 srcChainId, uint256 action)
    {
        action = (code >> 16) & ((1 << 16) - 1);
        srcChainId = (code >> 64) & ((1 << 32) - 1);
    }

    /**
     *@dev Extracts the flag value from a given code parameter
     *@param code uint value
     *@return flag The flag extracted from code If flag is equal to 1, then the delegatecall function must be successful for the transaction to proceed
     */
    function getFlag(uint256 code) internal pure returns (uint256 flag) {
        flag = (code) & ((1 << 16) - 1);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/libraries/TransferHelper.sol


pragma solidity 0.8.7;


library TransferHelper {
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    // Check balance after transfer.So deflationary token is not supported.
    function safeTransferFrom2(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        uint256 balanceBefore = IERC20(token).balanceOf(to);

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');

        uint256 balanceAfter = IERC20(token).balanceOf(to);
        require(balanceBefore + value <= balanceAfter, 'No deflationary token');
    }

    function safeTransferFrom3(
        address token,
        address from,
        address to,
        uint256 value
    ) internal returns (uint){
        uint256 balanceBefore = IERC20(token).balanceOf(to);

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
        uint256 balanceAfter = IERC20(token).balanceOf(to);
        require(balanceBefore <= balanceAfter, 'No deflationary token');
        return (balanceAfter - balanceBefore);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }

    function safeTransfer2(address token, address to, uint256 value) internal {
        if (token != address(0)) {
            safeTransfer(token, to, value);
        } else {
            safeTransferETH(to, value);
        }
    }
}

// File: contracts/libraries/HeaderLibrary.sol


pragma solidity >=0.7.6;

library HeaderLibrary {
    struct CommonParam {
        address feeToken;
        uint88 fee;
        uint8 action;
    }

    function encodeFeeHeader(address feeToken, uint88 fee, uint8 action) internal pure returns (bytes memory res){
        res = abi.encodePacked(feeToken, fee, action);
    }

    function decodeFeeHeader(bytes memory data) internal pure returns (address feeToken1, uint88 fee, uint8 action){
        assembly {
            feeToken1 := mload(add(data, 20))
            fee := mload(add(data, 31))
            action := mload(add(data, 32))
        }
    }

    struct BatchParam {
        address feeToken;
        uint88 fee;
        uint8 numServices;
    }

    function encodeBatchParam(address feeToken, uint88 fee, uint8 numServices) internal pure returns (bytes memory res){
        res = abi.encodePacked(feeToken, fee, numServices);
    }

    function decodeBatchParam(bytes memory data) internal pure returns (BatchParam memory p){
        address feeToken;
        uint88 fee;
        uint8 numServices;
        assembly {
            feeToken := mload(add(data, 20))
            fee := mload(add(data, 31))
            numServices := mload(add(data, 32))
        }
        (p.feeToken, p.fee, p.numServices) = (feeToken, fee, numServices);
    }

    struct ServiceParam {
        address service;
        uint48 begin;
        uint48 end;
    }

    function encodeServiceParam(address service, uint48 begin, uint48 end) internal pure returns (bytes memory res){
        res = abi.encodePacked(service, begin, end);
    }

    function decodeServiceParam(bytes memory data) internal pure returns (ServiceParam memory p){
        address service;
        uint48 begin;
        uint48 end;
        assembly {
            service := mload(add(data, 20))
            begin := mload(add(data, 26))
            end := mload(add(data, 32))
        }
        (p.service, p.begin, p.end) = (service, begin, end);
    }

}

// File: contracts/core/interfaces/IPayDB.sol


pragma solidity 0.8.7;

interface IPayDB {
    struct ExeOrderParam {
        uint256 amountOut;
        address tokenOut;
        address receiver;
        uint256 payOrderId;
        uint256 code;
        // The address of wallet(Owner when receiver is 0 address.)
        address wallet;
        address service;
        address gasToken;
        uint256 gasTokenPrice;
        uint256 priorityFee;
        uint256 gasLimit;
        bytes32[] proof;
        address manager;
        address feeReceiver;
        bool isGateway;
    }

    struct CreateOrderParam {
        uint256 amountIn;
        uint256 amountOut;
        uint256 payOrderId;
        uint256 fee;
        address tokenIn;
        address tokenOut;
        // The address to receive token.
        // Address(0) means the receiver is the newly created wallet and wallet is the owner's address.
        address receiver;
        address node;
    }

    struct SwapParam {
        address tokenIn;
        uint256 amountIn;
        address node;
    }

    event OrderCreated(
        address indexed node,
        uint256 amountIn,
        address tokenIn,
        uint256 amountOut,
        address tokenOut,
        address receiver,
        uint256 indexed payOrderId,
        address indexed sender,
        uint256 code,
        bytes32 wfHash
    );

    event OrderCancelled(address indexed node, uint256 payOrderId);

    event OrderExecuted(
        address indexed executor,
        uint256 amountOut,
        address tokenOut,
        address receiver,
        uint256 indexed payOrderId,
        bytes32 wfHash
    );

    event IsolateOrderExecuted(
        address indexed executor,
        uint256 amountOut,
        address tokenOut,
        address receiver
    );

    function createSrcOrder(
        CreateOrderParam[] memory cparam,
        uint256 code,
        address wallet,
        address service,
        bytes calldata data
    ) external;

    function createSrcOrderETH(
        CreateOrderParam[] calldata cparam,
        uint256 code,
        address service,
        address wallet,
        bytes calldata data
    ) external payable;

    function executeDstOrderETH(
        ExeOrderParam[] calldata eparam,
        bytes calldata data,
        bytes calldata serviceSignature
    ) external payable;

    function executeDstOrder(
        ExeOrderParam[] calldata eparam,
        bytes calldata data,
        bytes calldata serviceSignature
    ) external;

    function cancelOrderETH(
        CreateOrderParam[] calldata cparam,
        address from,
        bytes32[] calldata workFlowHashs
    ) external payable;

    function cancelOrder(
        CreateOrderParam[] calldata cparam,
        address from,
        bytes32[] calldata workFlowHashs
    ) external;

    function executeIsolateOrder(
        ExeOrderParam[] calldata eparam,
        bytes calldata data,
        bytes calldata serviceSignature
    ) external;

    function executeIsolateOrderETH(
        ExeOrderParam[] calldata eparam,
        bytes calldata data,
        bytes calldata serviceSignature
    ) external payable;
}

// File: contracts/core/interfaces/IService.sol


pragma solidity 0.8.7;

interface IService {
    function execute(uint code, bytes calldata data, address node) external;
}

// File: contracts/peripherals/common/HybridPayService.sol


pragma solidity 0.8.7;







contract HybridPayService is IService {
    struct PayCommonParam {
        uint256 code;
        uint256 fee;
        address wallet;
        address service;
        address feeToken;
        uint32 action; //2
    } // 4 bytes32

    function encodePayHeader(
        uint256 code,
        uint256 fee,
        address wallet,
        address service,
        address feeToken,
        uint32 action
    ) external pure returns (bytes memory res) {
        res = abi.encodePacked(code, fee, wallet, service, feeToken, action);
    }

    function decodeOrderParamsLen(bytes memory data)
        public
        pure
        returns (uint16 len)
    {
        assembly {
            len := mload(add(data, 2))
        }
    }

    function decodePayHeader(bytes memory data)
        public
        pure
        returns (PayCommonParam memory p)
    {
        // Sector 1
        {
            uint256 _uint1;
            uint256 _uint2;
            assembly {
                _uint1 := mload(add(data, 32))
                _uint2 := mload(add(data, 64))
            }
            (p.code, p.fee) = (_uint1, _uint2);
        }

        // Sector 2
        {
            address wallet;
            address service;
            address feeToken;
            uint32 action;
            //2
            assembly {
                wallet := mload(add(data, 84))
                service := mload(add(data, 104))
                feeToken := mload(add(data, 124))
                action := mload(add(data, 128))
            }
            (p.wallet, p.service, p.feeToken, p.action) = (
                wallet,
                service,
                feeToken,
                action
            );
        }
    }

    struct PackedCreateOrderParam {
        uint128 amountIn;
        uint128 amountOut;
        uint256 payOrderId;
        uint128 fee;
        address tokenIn;
        address tokenOut;
        address receiver;
        address node; //3
    } // 5 bytes32

    function encodeCreateOrderParam(
        uint128 amountIn,
        uint128 amountOut,
        uint128 fee,
        address tokenIn,
        address tokenOut,
        address receiver,
        address node,
        uint256 payOrderId
    ) external pure returns (bytes memory res) {
        res = abi.encodePacked(
            amountIn,
            amountOut,
            payOrderId,
            fee,
            tokenIn,
            tokenOut,
            receiver,
            node
        );
    }

    function decodeCreateOrderParam(bytes memory data)
        public
        pure
        returns (IPayDB.CreateOrderParam memory p)
    {
        // Sector 1
        {
            uint128 _uint1;
            uint128 _uint2;
            uint256 _uint3;
            assembly {
                _uint1 := mload(add(data, 16))
                _uint2 := mload(add(data, 32))
                _uint3 := mload(add(data, 64))
            }
            (p.amountIn, p.amountOut) = (_uint1, _uint2);
            p.payOrderId = _uint3;
        }

        // Sector 2
        {
            uint128 fee;
            address tokenIn;
            address tokenOut;
            address receiver;
            address node;
            assembly {
                fee := mload(add(data, 80))
                tokenIn := mload(add(data, 100))
                tokenOut := mload(add(data, 120))
                receiver := mload(add(data, 140))
                node := mload(add(data, 160))
            }
            (p.fee, p.tokenIn, p.tokenOut, p.receiver, p.node) = (
                fee,
                tokenIn,
                tokenOut,
                receiver,
                node
            );
        }
    }

    // event LogCreateOrderParam(IPayDB.CreateOrderParam);
    // event LogUint16(uint16);
    function execute(
        uint256 code,
        bytes calldata data,
        address node
    ) external override {
        // TODO: Change the address when deploying.

        address payDB = 0x8F6E984edD89BD10b9e98ed085A0fa2a98D0E2Ab;

        (uint256 dstChainId, , ) = VWCode.chainidsAndExpTime(code);
        require(block.chainid == dstChainId);

        PayCommonParam memory p = decodePayHeader(data[:128]);
        uint16 cparamsLen = decodeOrderParamsLen(data[128:130]);

        IPayDB.CreateOrderParam[]
            memory cparams = new IPayDB.CreateOrderParam[](uint256(cparamsLen));

        uint256 dataP = 130;
        for (uint16 i = 0; i < cparamsLen; i++) {
            cparams[i] = decodeCreateOrderParam(data[dataP:dataP + 160]);
            dataP = dataP + 160;
            if (p.action == 1) {
                IERC20(cparams[i].tokenIn).approve(payDB, type(uint256).max);
            }
        }

        IPayDB(payDB).createSrcOrder(
            cparams,
            p.code,
            p.wallet,
            p.service,
            data[dataP:]
        );
        p.wallet = node;
    }
}