/**
 *Submitted for verification at polygonscan.com on 2022-11-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

interface IStargateReceiver {
    function sgReceive(
        uint16 _srcChainId,              // the remote chainId sending the tokens
        bytes memory _srcAddress,        // the remote Bridge address
        uint256 _nonce,                  
        address _token,                  // the token contract on the local chain
        uint256 amountLD,                // the qty of local _token contract tokens  
        bytes memory payload
    ) external;
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

contract Swap is IStargateReceiver, Ownable {

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ReceivedOnDestination(address token, uint amountLD);
    event Transfer(
        address tokenIn,
        address bridgeToken,
        uint256 tokenInAmount,
        uint256 bridgeTokenAmount,
        uint16 dstChainId, 
        address dstChainTo
    );

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct SwapParams {
        address tokenIn;
        uint256 tokenInAmount;
        uint256 fee;
        address allowanceTarget;
        address router;
        bytes txnCallData;
    }
    
    struct BridgeParams {
        uint16 dstChainId;
        uint16 srcPoolId;
        uint16 dstPoolId;
        uint256 fee;
        address dstChainTo;
        address dstStargateComposed;
        address router;
        address allowanceTarget;
        address dstSwapToken;
        bytes txnCallData;
    }

    /*//////////////////////////////////////////////////////////////
                                  STATE
    //////////////////////////////////////////////////////////////*/

    address public stargateRouterAddress;
    address public bridgeTokenAddress;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/ 

    constructor(address _stargateRouter, address _bridgeToken) Ownable() {
        stargateRouterAddress = _stargateRouter;
        bridgeTokenAddress = _bridgeToken;
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTERS
    //////////////////////////////////////////////////////////////*/

    function setStargateRouter(address _router) external onlyOwner {
        stargateRouterAddress = _router;
    }

    function setBridgeToken(address _token) external onlyOwner {
        bridgeTokenAddress = _token;
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/ 

    /// @param _tokenIn The token user wants to transfer to dstChain 
    /// @param _tokenInAmount The amount of src chain token to transfer to the destination chain  
    /// @param _swapTxnFee The fee for swap transaction
    /// @param _swapAllowanceTarget The address of contract that swaps token in for bridge token
    /// @param _swapRouter The address of contract that swaps token in for bridge token
    /// @param _swapTxnCallData The call data for swap transaction
    function swap(
        address _tokenIn, 
        uint256 _tokenInAmount, 
        uint256 _swapTxnFee, 
        address _swapAllowanceTarget, 
        address _swapRouter, 
        bytes calldata _swapTxnCallData
    ) internal returns (uint256) {

        // TODO: account fo slippage
        // TODO: account for ETH swap
        // TODO: better way to get amount out?

        if (address(_tokenIn) != address(0)) {
            // some tokens (e.g., USDT, KNC) require existing allowance to be 0 before updating
            ERC20(_tokenIn).approve(_swapAllowanceTarget, 0);
            ERC20(_tokenIn).approve(_swapAllowanceTarget, _tokenInAmount);
        }
        
        uint256 previousBridgeTokenBalance = ERC20(bridgeTokenAddress).balanceOf(address(this));
        (bool success, ) = _swapRouter.call{value: _swapTxnFee}(_swapTxnCallData); 
        require(success, "swap transaction failed!");

        uint256 bridgeTokenOutAmount = ERC20(bridgeTokenAddress).balanceOf(address(this)) - previousBridgeTokenBalance; 
        require(bridgeTokenOutAmount > 0, "Aggregator returned 0 tokens to swap");

        return bridgeTokenOutAmount;
    }

    /// @param _bridgeTxn The struct containing the bridge transaction data
    /// @param _bridgeTokenAmount The amount of bridge token to transfer to the destination chain
    function bridge(
        BridgeParams calldata _bridgeTxn,
        uint256 _bridgeTokenAmount
    ) internal {
        // encode payload data to send to destination contract, which it will handle with sgReceive()
        bytes memory data = abi.encode(_bridgeTxn.dstChainTo, _bridgeTxn.router, _bridgeTxn.allowanceTarget, _bridgeTxn.dstSwapToken, _bridgeTxn.txnCallData); //TODO: Put this into a struct?

        // this contract needs to approve the stargateRouter to spend its bridgeToken!
        ERC20(bridgeTokenAddress).approve(address(stargateRouterAddress), _bridgeTokenAmount);

        // Stargate's Router.swap() function sends the tokens to the destination chain.
        IStargateRouter(stargateRouterAddress).swap{value:_bridgeTxn.fee}(
            _bridgeTxn.dstChainId,                            // the destination chain id
            _bridgeTxn.srcPoolId,                             // the source Stargate poolId
            _bridgeTxn.dstPoolId,                             // the destination Stargate poolId
            payable(msg.sender),                              // refund adddress. if msg.sender pays too much msg.value, return extra eth
            _bridgeTokenAmount,                               // total tokens to send to destination chain
            0,                                                // min amount allowed out //TODO: UPDAETE THIS
            IStargateRouter.lzTxObj(200000, 0, "0x"),         // default lzTxObj
            abi.encodePacked(_bridgeTxn.dstStargateComposed), // destination address, the sgReceive() implementer
            data                                              // bytes payload
        );
    }

    /*//////////////////////////////////////////////////////////////
                             EXTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @param _swapTxn The struct containing the swap transaction data
    /// @param _bridgeTxn The struct containing the bridge transaction data
    function transfer(
        SwapParams calldata _swapTxn,
        BridgeParams calldata _bridgeTxn
    ) external payable {

        // TODO: add logic to handle if swapToken is ETH
        // TODO: account for swap slippage

        require(msg.value >= (_swapTxn.fee + _bridgeTxn.fee), "insufficient value for fees");
        require(_swapTxn.tokenInAmount > 0, "transfer amount must be greater than 0");

        uint256 bridgeTokenAmount = _swapTxn.tokenInAmount;

        // transfer _tokenIn to this contract if _tokenIn is not ETH
        if (address(_swapTxn.tokenIn) != address(0)) {
            require(
                ERC20(_swapTxn.tokenIn).allowance(msg.sender, address(this)) >= _swapTxn.tokenInAmount, 
                "ERC 20 approval required by user"
            );

            ERC20(_swapTxn.tokenIn).transferFrom(msg.sender, address(this), _swapTxn.tokenInAmount);
        } 

        // swap _tokenIn for bridgeToken if _tokenIn is not bridgeToken
        if (address(_swapTxn.tokenIn) != bridgeTokenAddress) {
            bridgeTokenAmount = swap(
                _swapTxn.tokenIn, 
                _swapTxn.tokenInAmount, 
                _swapTxn.fee, 
                _swapTxn.allowanceTarget, 
                _swapTxn.router, 
                _swapTxn.txnCallData
            );
        }

        bridge(
            _bridgeTxn,
            bridgeTokenAmount
        );

        emit Transfer(
            _swapTxn.tokenIn, 
            bridgeTokenAddress, 
            _swapTxn.tokenInAmount, 
            bridgeTokenAmount, 
            _bridgeTxn.dstChainId,
            _bridgeTxn.dstChainTo
        );
    }

    /// @param _chainId The remote chainId sending the tokens
    /// @param _srcAddress The remote Bridge address
    /// @param _nonce The message ordering nonce
    /// @param _tokenIn The received token contract on the local chain     
    /// @param amountLD The qty of local _token contract tokens  
    /// @param _payload The bytes containing the toAddress
    function sgReceive(
        uint16 _chainId, 
        bytes memory _srcAddress, 
        uint _nonce, 
        address _tokenIn, 
        uint amountLD, 
        bytes memory _payload
    ) override external {
        require(
            msg.sender == address(stargateRouterAddress), 
            "only stargate router can call sgReceive!"
        );

        emit ReceivedOnDestination(_tokenIn, amountLD);

        (address _toAddr, address _router, address _allowanceTarget, address _tokenOut, bytes memory _txnCallData) = abi.decode(_payload, (address, address, address, address, bytes)); //TODO: Put this into a struct?

        if (_router == address(0)) { //Send router = address(0) if user just wants _tokenIn on dstChain
            ERC20(_tokenIn).transfer(_toAddr, amountLD);
            return;
        }
        
        if (_tokenOut != address(0)) {
            // some tokens (e.g., USDT, KNC) require existing allowance to be 0 before updating
            ERC20(_tokenOut).approve(_allowanceTarget, 0);
            ERC20(_tokenOut).approve(_allowanceTarget, amountLD);
        }

        uint256 previousSwapTokenBalance = ERC20(_tokenOut).balanceOf(address(this));
        (bool success, ) = _router.call(_txnCallData); //TODO: handle router fee

        if (success) {
            uint256 swapTokenOutAmount = ERC20(_tokenOut).balanceOf(address(this)) - previousSwapTokenBalance; 
            ERC20(_tokenOut).transfer(_toAddr, swapTokenOutAmount);
            //TODO: Emit swap success event containing swapTokenOutAmount
        } else {
            ERC20(_tokenIn).transfer(_toAddr, amountLD);
            //TODO: Emit swap failed event 
        }
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable {}
}