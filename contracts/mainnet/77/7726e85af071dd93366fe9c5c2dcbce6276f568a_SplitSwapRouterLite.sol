// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

/**
Optimal split order router for single swaps with identical markets on uniV2 forks
*/

/// ============ Internal Imports ============
import "./interfaces/IWETH.sol";
import "./libraries/SplitSwapLibraryLite.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

/// @title SplitSwapRouterLite
/// @author Sandy Bradley <@sandybradley>
/// @notice Splits single swap order optimally across 2 uniV2 Dexes
contract SplitSwapRouterLite {
    using SafeTransferLib for ERC20;

    // Custom errors save gas, encoding to 4 bytes
    error Expired();
    error NoTokens();
    error NotPercent();
    error NoReceivers();
    error InvalidPath();
    error TransferFailed();
    error InsufficientBAmount();
    error InsufficientAAmount();
    error TokenIsFeeOnTransfer();
    error ExcessiveInputAmount();
    error ExecuteNotAuthorized();
    error InsufficientAllowance();
    error InsufficientLiquidity();
    error InsufficientOutputAmount();
    error NotYetImplemented();

    /// @dev UniswapV2 pool 4 byte swap selector
    bytes4 internal constant SWAP_SELECTOR = bytes4(keccak256("swap(uint256,uint256,address,bytes)"));
    /// @dev Wrapped native token address
    address internal immutable WETH09;
    /// @dev Sushiswap factory address
    address internal immutable SUSHI_FACTORY;
    /// @dev UniswapV2 factory address
    address internal immutable BACKUP_FACTORY; // uniswap v2 factory
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    /// @dev Sushiswap factory init pair code hash
    bytes32 internal immutable SUSHI_FACTORY_HASH;
    /// @dev UniswapV2 factory init pair code hash
    bytes32 internal immutable BACKUP_FACTORY_HASH;
    uint256 internal constant EST_SWAP_GAS_USED = 150000;
    uint256 internal constant MIN_LIQUIDITY = 1000;

    /// @notice constructor arguments for cross-chain deployment
    /// @param weth wrapped native token address (e.g. Eth mainnet: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
    /// @param sushiFactory Sushiswap factory address (e.g. Eth mainnet: 0xc35DADB65012eC5796536bD9864eD8773aBc74C4)
    /// @param backupFactory Uniswap V2 (or equiv.) (e.g. Eth mainnet: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
    /// @param sushiFactoryHash Initial code hash of sushi factory (e.g. Eth mainnet: 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303)SplitSwapRouter
    /// @param backupFactoryHash Initial code hash of backup (uniV2) factory (e.g. Eth mainnet: 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f)SplitSwapRouter
    constructor(
        address weth,
        address sushiFactory,
        address backupFactory,
        bytes32 sushiFactoryHash,
        bytes32 backupFactoryHash
    ) {
        WETH09 = weth;
        SUSHI_FACTORY = sushiFactory;
        BACKUP_FACTORY = backupFactory;
        SUSHI_FACTORY_HASH = sushiFactoryHash;
        BACKUP_FACTORY_HASH = backupFactoryHash;
    }

    /// @notice reference sushi factory address (IUniswapV2Router compliance)
    function factory() external view returns (address) {
        return SUSHI_FACTORY;
    }

    /// @notice reference wrapped native token address (IUniswapV2Router compliance)
    function WETH() external view returns (address) {
        return WETH09;
    }

    /// @notice Ensures deadline is not passed, otherwise revert. (0 = no deadline)
    /// @dev Modifier has been replaced with a function for gas efficiency
    /// @param deadline Unix timestamp in seconds for transaction to execute before
    function ensure(uint256 deadline) internal view {
        if (deadline < block.timestamp) revert Expired();
    }

    /// @notice Checks amounts for token A and token B are balanced for pool. Creates a pair if none exists
    /// @dev Reverts with custom errors replace requires
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param amountADesired Amount of token A desired to add to pool
    /// @param amountBDesired Amount of token B desired to add to pool
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @return amountA exact amount of token A to be added
    /// @return amountB exact amount of token B to be added
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        address factory0 = SUSHI_FACTORY;
        if (IUniswapV2Factory(factory0).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory0).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = SplitSwapLibraryLite.getReserves(
            factory0,
            tokenA,
            tokenB,
            SUSHI_FACTORY_HASH
        );
        if (_isZero(reserveA) && _isZero(reserveB)) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = SplitSwapLibraryLite.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal > amountBDesired) {
                uint256 amountAOptimal = SplitSwapLibraryLite.quote(amountBDesired, reserveB, reserveA);
                if (amountAOptimal > amountADesired) revert InsufficientAAmount();
                if (amountAOptimal < amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            } else {
                if (amountBOptimal < amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            }
        }
    }

    /// @notice Adds liquidity to an ERC-20⇄ERC-20 pool. msg.sender should have already given the router an allowance of at least amountADesired/amountBDesired on tokenA/tokenB
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param amountADesired Amount of token A desired to add to pool
    /// @param amountBDesired Amount of token B desired to add to pool
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @param to Address to receive liquidity token
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountA exact amount of token A added to pool
    /// @return amountB exact amount of token B added to pool
    /// @return liquidity amount of liquidity token received
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        ensure(deadline);
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = SplitSwapLibraryLite.pairFor(SUSHI_FACTORY, tokenA, tokenB, SUSHI_FACTORY_HASH);
        ERC20(tokenA).safeTransferFrom(msg.sender, pair, amountA);
        ERC20(tokenB).safeTransferFrom(msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    /// @notice Adds liquidity to an ERC-20⇄WETH pool with ETH. msg.sender should have already given the router an allowance of at least amountTokenDesired on token. msg.value is treated as a amountETHDesired. Leftover ETH, if any, is returned to msg.sender
    /// @param token Token in pool
    /// @param amountTokenDesired Amount of token desired to add to pool
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive liquidity token
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountToken exact amount of token added to pool
    /// @return amountETH exact amount of ETH added to pool
    /// @return liquidity amount of liquidity token received
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        ensure(deadline);
        address weth = WETH09;
        (amountToken, amountETH) = _addLiquidity(
            token,
            weth,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = SplitSwapLibraryLite.pairFor(SUSHI_FACTORY, token, weth, SUSHI_FACTORY_HASH);
        ERC20(token).safeTransferFrom(msg.sender, pair, amountToken);
        IWETH(weth).deposit{ value: amountETH }();
        ERC20(weth).safeTransfer(pair, amountETH);
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) SafeTransferLib.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    /// @notice Removes liquidity from an ERC-20⇄ERC-20 pool. msg.sender should have already given the router an allowance of at least liquidity on the pool.
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountA Amount of token A received
    /// @return amountB Amount of token B received
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual returns (uint256 amountA, uint256 amountB) {
        ensure(deadline);
        address pair = SplitSwapLibraryLite.pairFor(SUSHI_FACTORY, tokenA, tokenB, SUSHI_FACTORY_HASH);
        ERC20(pair).safeTransferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0, ) = SplitSwapLibraryLite.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        if (amountA < amountAMin) revert InsufficientAAmount();
        if (amountB < amountBMin) revert InsufficientBAmount();
    }

    /// @notice Removes liquidity from an ERC-20⇄WETH pool and receive ETH. msg.sender should have already given the router an allowance of at least liquidity on the pool.
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountToken Amount of token received
    /// @return amountETH Amount of ETH received
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual returns (uint256 amountToken, uint256 amountETH) {
        address weth = WETH09;
        uint256 balanceBefore = ERC20(token).balanceOf(address(this));
        (amountToken, amountETH) = removeLiquidity(
            token,
            weth,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        // exploit check from fee-on-transfer tokens
        if (amountToken != ERC20(token).balanceOf(address(this)) - balanceBefore) revert TokenIsFeeOnTransfer();
        ERC20(token).safeTransfer(to, amountToken);
        IWETH(weth).withdraw(amountETH);
        SafeTransferLib.safeTransferETH(to, amountETH);
    }

    /// @notice Removes liquidity from an ERC-20⇄ERC-20 pool without pre-approval, thanks to permit.
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1)
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return amountA Amount of token A received
    /// @return amountB Amount of token B received
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair(SplitSwapLibraryLite.pairFor(SUSHI_FACTORY, tokenA, tokenB, SUSHI_FACTORY_HASH)).permit(
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : liquidity,
            deadline,
            v,
            r,
            s
        );
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    /// @notice Removes liquidity from an ERC-20⇄WETTH pool and receive ETH without pre-approval, thanks to permit
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1)
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return amountToken Amount of token received
    /// @return amountETH Amount of ETH received
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 amountToken, uint256 amountETH) {
        IUniswapV2Pair(SplitSwapLibraryLite.pairFor(SUSHI_FACTORY, token, WETH09, SUSHI_FACTORY_HASH)).permit(
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : liquidity,
            deadline,
            v,
            r,
            s
        );
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    /// @notice Identical to removeLiquidityETH, but succeeds for tokens that take a fee on transfer. msg.sender should have already given the router an allowance of at least liquidity on the pool.
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountETH Amount of ETH received
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual returns (uint256 amountETH) {
        address weth = WETH09;
        uint256 balanceBefore = ERC20(token).balanceOf(address(this));
        (, amountETH) = removeLiquidity(token, weth, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        ERC20(token).safeTransfer(to, ERC20(token).balanceOf(address(this)) - balanceBefore);
        IWETH(weth).withdraw(amountETH);
        SafeTransferLib.safeTransferETH(to, amountETH);
    }

    /// @notice Identical to removeLiquidityETHWithPermit, but succeeds for tokens that take a fee on transfer.
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1)
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return amountETH Amount of ETH received
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 amountETH) {
        IUniswapV2Pair(SplitSwapLibraryLite.pairFor(SUSHI_FACTORY, token, WETH09, SUSHI_FACTORY_HASH)).permit(
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : liquidity,
            deadline,
            v,
            r,
            s
        );
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    function _swapSingle(
        bool isReverse,
        address to,
        address pair,
        uint256 amountOut
    ) internal virtual {
        (uint256 amount0Out, uint256 amount1Out) = isReverse ? (amountOut, uint256(0)) : (uint256(0), amountOut);
        _asmSwap(pair, amount0Out, amount1Out, to);
    }

    /// @notice Internal core swap. Requires the initial amount to have already been sent to the first pair.
    /// @param _to Address of receiver
    /// @param swaps Array of user swap data
    function _swap(address _to, SplitSwapLibraryLite.Swap[] memory swaps)
        internal
        virtual
        returns (uint256[] memory amounts)
    {
        uint256 length = swaps.length;
        amounts = new uint256[](_inc(length));
        amounts[0] = swaps[0].amountIn0 + swaps[0].amountIn1;
        for (uint256 i; i < length; i = _inc(i)) {
            address to = i < _dec(length) ? address(this) : _to; // split route requires intermediate swaps route to this address
            if (_isNonZero(swaps[i].amountIn0)) {
                if (_isNonZero(i)) ERC20(swaps[i].tokenIn).safeTransfer(swaps[i].pair0, swaps[i].amountIn0);
                _swapSingle(swaps[i].isReverse, to, swaps[i].pair0, swaps[i].amountOut0);
            }
            if (_isNonZero(swaps[i].amountIn1)) {
                if (_isNonZero(i)) ERC20(swaps[i].tokenIn).safeTransfer(swaps[i].pair1, swaps[i].amountIn1);
                _swapSingle(swaps[i].isReverse, to, swaps[i].pair1, swaps[i].amountOut1);
            }
            amounts[_inc(i)] = swaps[i].amountOut0 + swaps[i].amountOut1;
        }
    }

    /// @notice Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by the path. The first element of path is the input token, the last is the output token, and any intermediate elements represent intermediate pairs to trade through. msg.sender should have already given the router an allowance of at least amountIn on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        SplitSwapLibraryLite.Swap[] memory swaps = SplitSwapLibraryLite.getSwapsOut(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            amountIn,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        if (amountOutMin > swaps[_dec(swaps.length)].amountOut0 + swaps[_dec(swaps.length)].amountOut1)
            revert InsufficientOutputAmount();
        if (_isNonZero(swaps[0].amountIn0))
            ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pair0, swaps[0].amountIn0);
        if (_isNonZero(swaps[0].amountIn1))
            ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pair1, swaps[0].amountIn1);
        amounts = _swap(to, swaps);
    }

    /// @notice Receive an exact amount of output tokens for as few input tokens as possible, along the route determined by the path. msg.sender should have already given the router an allowance of at least amountInMax on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOut Amount of output tokens to receive
    /// @param amountInMax Maximum amount of input tokens
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        SplitSwapLibraryLite.Swap[] memory swaps = SplitSwapLibraryLite.getSwapsIn(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            amountOut,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        if (amountInMax < swaps[0].amountIn0 + swaps[0].amountIn1) revert ExcessiveInputAmount();
        if (_isNonZero(swaps[0].amountIn0))
            ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pair0, swaps[0].amountIn0);
        if (_isNonZero(swaps[0].amountIn1))
            ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pair1, swaps[0].amountIn1);
        amounts = _swap(to, swaps);
    }

    /// @notice Swaps an exact amount of ETH for as many output tokens as possible, along the route determined by the path. The first element of path must be WETH, the last is the output token. amountIn = msg.value
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[0] != weth) revert InvalidPath();
        SplitSwapLibraryLite.Swap[] memory swaps = SplitSwapLibraryLite.getSwapsOut(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            msg.value,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        if (amountOutMin > swaps[_dec(swaps.length)].amountOut0 + swaps[_dec(swaps.length)].amountOut1)
            revert InsufficientOutputAmount();
        IWETH(weth).deposit{ value: msg.value }();
        if (_isNonZero(swaps[0].amountIn0)) ERC20(weth).safeTransfer(swaps[0].pair0, swaps[0].amountIn0);
        if (_isNonZero(swaps[0].amountIn1)) ERC20(weth).safeTransfer(swaps[0].pair1, swaps[0].amountIn1);
        amounts = _swap(to, swaps);
    }

    /// @notice Receive an exact amount of ETH for as few input tokens as possible, along the route determined by the path. The first element of path is the input token, the last must be WETH. msg.sender should have already given the router an allowance of at least amountInMax on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOut Amount of ETH to receive
    /// @param amountInMax Maximum amount of input tokens
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[_dec(path.length)] != weth) revert InvalidPath();
        SplitSwapLibraryLite.Swap[] memory swaps = SplitSwapLibraryLite.getSwapsIn(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            amountOut,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        if (amountInMax < swaps[0].amountIn0 + swaps[0].amountIn1) revert ExcessiveInputAmount();
        if (_isNonZero(swaps[0].amountIn0))
            ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pair0, swaps[0].amountIn0);
        if (_isNonZero(swaps[0].amountIn1))
            ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pair1, swaps[0].amountIn1);
        amounts = _swap(address(this), swaps);
        IWETH(weth).withdraw(amounts[_dec(path.length)]);
        SafeTransferLib.safeTransferETH(to, amounts[_dec(path.length)]);
    }

    /// @notice Swaps an exact amount of tokens for as much ETH as possible, along the route determined by the path. The first element of path is the input token, the last must be WETH.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of ETH that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[_dec(path.length)] != weth) revert InvalidPath();
        SplitSwapLibraryLite.Swap[] memory swaps = SplitSwapLibraryLite.getSwapsOut(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            amountIn,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        if (amountOutMin > swaps[_dec(swaps.length)].amountOut0 + swaps[_dec(swaps.length)].amountOut1)
            revert InsufficientOutputAmount();
        if (_isNonZero(swaps[0].amountIn0))
            ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pair0, swaps[0].amountIn0);
        if (_isNonZero(swaps[0].amountIn1))
            ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pair1, swaps[0].amountIn1);
        amounts = _swap(address(this), swaps);
        uint256 amountOut = amounts[_dec(path.length)];
        IWETH(weth).withdraw(amountOut);
        SafeTransferLib.safeTransferETH(to, amountOut);
    }

    /// @notice Receive an exact amount of tokens for as little ETH as possible, along the route determined by the path. The first element of path must be WETH. Leftover ETH, if any, is returned to msg.sender. amountInMax = msg.value
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOut Amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[0] != weth) revert InvalidPath();
        SplitSwapLibraryLite.Swap[] memory swaps = SplitSwapLibraryLite.getSwapsIn(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            amountOut,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        if (msg.value < swaps[0].amountIn0 + swaps[0].amountIn1) revert ExcessiveInputAmount();
        IWETH(weth).deposit{ value: swaps[0].amountIn0 + swaps[0].amountIn1 }();
        if (_isNonZero(swaps[0].amountIn0)) ERC20(weth).safeTransfer(swaps[0].pair0, swaps[0].amountIn0);
        if (_isNonZero(swaps[0].amountIn1)) ERC20(weth).safeTransfer(swaps[0].pair1, swaps[0].amountIn1);
        amounts = _swap(to, swaps);

        // refund dust eth, if any
        if (msg.value > swaps[0].amountIn0 + swaps[0].amountIn1)
            SafeTransferLib.safeTransferETH(msg.sender, msg.value - swaps[0].amountIn0 - swaps[0].amountIn1);
    }

    //requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokensExecute(
        address pair,
        uint256 amountOutput,
        bool isReverse,
        address to
    ) internal virtual {
        (uint256 amount0Out, uint256 amount1Out) = isReverse ? (amountOutput, uint256(0)) : (uint256(0), amountOutput);
        _asmSwap(pair, amount0Out, amount1Out, to);
    }

    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        uint256 length = path.length;
        for (uint256 i; i < _dec(length); i = _inc(i)) {
            (address tokenIn, address tokenOut) = (path[i], path[_inc(i)]);
            bool isReverse;
            address pair;
            {
                (address token0, address token1) = SplitSwapLibraryLite.sortTokens(tokenIn, tokenOut);
                isReverse = tokenOut == token0;
                pair = SplitSwapLibraryLite._asmPairFor(SUSHI_FACTORY, token0, token1, SUSHI_FACTORY_HASH);
            }
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                uint256 amountInput;
                (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
                (uint112 reserveInput, uint112 reserveOutput) = isReverse ? (reserve1, reserve0) : (reserve0, reserve1);
                amountInput = ERC20(tokenIn).balanceOf(pair) - reserveInput;
                amountOutput = SplitSwapLibraryLite.getAmountOut(amountInput, reserveInput, reserveOutput);
            }

            address to = i < length - 2
                ? SplitSwapLibraryLite.pairFor(SUSHI_FACTORY, tokenOut, path[i + 2], SUSHI_FACTORY_HASH)
                : _to;
            _swapSupportingFeeOnTransferTokensExecute(pair, amountOutput, isReverse, to);
        }
    }

    /// @notice Identical to swapExactTokensForTokens, but succeeds for tokens that take a fee on transfer. msg.sender should have already given the router an allowance of at least amountIn on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual {
        ensure(deadline);
        ERC20(path[0]).safeTransferFrom(
            msg.sender,
            SplitSwapLibraryLite.pairFor(SUSHI_FACTORY, path[0], path[1], SUSHI_FACTORY_HASH),
            amountIn
        );
        uint256 balanceBefore = ERC20(path[_dec(path.length)]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        if (ERC20(path[_dec(path.length)]).balanceOf(to) - balanceBefore < amountOutMin)
            revert InsufficientOutputAmount();
    }

    /// @notice Identical to swapExactETHForTokens, but succeeds for tokens that take a fee on transfer. amountIn = msg.value
    /// @dev Require has been replaced with revert for gas optimization. Attempt to back-run swaps.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual {
        ensure(deadline);
        address weth = WETH09;
        if (path[0] != weth) revert InvalidPath();
        uint256 amountIn = msg.value;
        IWETH(weth).deposit{ value: amountIn }();
        ERC20(weth).safeTransfer(
            SplitSwapLibraryLite.pairFor(SUSHI_FACTORY, path[0], path[1], SUSHI_FACTORY_HASH),
            amountIn
        );
        uint256 balanceBefore = ERC20(path[_dec(path.length)]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        if (ERC20(path[_dec(path.length)]).balanceOf(to) - balanceBefore < amountOutMin)
            revert InsufficientOutputAmount();
    }

    /// @notice Identical to swapExactTokensForETH, but succeeds for tokens that take a fee on transfer.
    /// @dev Require has been replaced with revert for gas optimization. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of ETH that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual {
        ensure(deadline);
        address weth = WETH09;
        if (path[_dec(path.length)] != weth) revert InvalidPath();
        ERC20(path[0]).safeTransferFrom(
            msg.sender,
            SplitSwapLibraryLite.pairFor(SUSHI_FACTORY, path[0], path[1], SUSHI_FACTORY_HASH),
            amountIn
        );
        uint256 balanceBefore = ERC20(weth).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint256 amountOut = ERC20(weth).balanceOf(address(this)) - balanceBefore;
        if (amountOut < amountOutMin) revert InsufficientOutputAmount();
        IWETH(weth).withdraw(amountOut);
        SafeTransferLib.safeTransferETH(to, amountOut);
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure virtual returns (uint256 amountB) {
        return SplitSwapLibraryLite.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure virtual returns (uint256 amountOut) {
        return SplitSwapLibraryLite.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure virtual returns (uint256 amountIn) {
        return SplitSwapLibraryLite.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        virtual
        returns (uint256[] memory amounts)
    {
        return SplitSwapLibraryLite.getAmountsOut(SUSHI_FACTORY, amountIn, SUSHI_FACTORY_HASH, path);
    }

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        virtual
        returns (uint256[] memory amounts)
    {
        return SplitSwapLibraryLite.getAmountsIn(SUSHI_FACTORY, amountOut, SUSHI_FACTORY_HASH, path);
    }

    /// @custom:assembly Efficient single swap call
    /// @notice Internal call to perform single swap
    /// @param pair Address of pair to swap in
    /// @param amount0Out AmountOut for token0 of pair
    /// @param amount1Out AmountOut for token1 of pair
    /// @param to Address of receiver
    function _asmSwap(
        address pair,
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) internal {
        bytes4 selector = SWAP_SELECTOR;
        assembly ("memory-safe") {
            let ptr := mload(0x40) // get free memory pointer
            mstore(ptr, selector) // append 4 byte selector
            mstore(add(ptr, 0x04), amount0Out) // append amount0Out
            mstore(add(ptr, 0x24), amount1Out) // append amount1Out
            mstore(add(ptr, 0x44), to) // append to
            mstore(add(ptr, 0x64), 0x80) // append location of byte list
            mstore(add(ptr, 0x84), 0) // append 0 bytes data
            let success := call(
                gas(), // gas remaining
                pair, // destination address
                0, // 0 value
                ptr, // input buffer
                0xA4, // input length
                0, // output buffer
                0 // output length
            )

            if iszero(success) {
                // 0 size error is the cheapest, but mstore an error enum if you wish
                revert(0x0, 0x0)
            }
        }
    }

    /// @custom:gas Uint256 zero check gas saver
    /// @notice Uint256 zero check gas saver
    /// @param value Number to check
    function _isZero(uint256 value) internal pure returns (bool boolValue) {
        // Stack Only Safety
        assembly ("memory-safe") {
            boolValue := iszero(value)
        }
    }

    /// @custom:gas Uint256 not zero check gas saver
    /// @notice Uint256 not zero check gas saver
    /// @param value Number to check
    function _isNonZero(uint256 value) internal pure returns (bool boolValue) {
        // Stack Only Safety
        assembly ("memory-safe") {
            boolValue := iszero(iszero(value))
        }
    }

    /// @custom:gas Unchecked increment gas saver
    /// @notice Unchecked increment gas saver for loops
    /// @param i Number to increment
    function _inc(uint256 i) internal pure returns (uint256 result) {
        // Stack only safety
        assembly ("memory-safe") {
            result := add(i, 1)
        }
    }

    /// @custom:gas Unchecked decrement gas saver
    /// @notice Unchecked decrement gas saver for loops
    /// @param i Number to decrement
    function _dec(uint256 i) internal pure returns (uint256 result) {
        // Stack Only Safety
        assembly ("memory-safe") {
            result := sub(i, 1)
        }
    }

    /// @notice Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Fallback function is called when msg.data is not empty
    fallback() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13 <0.9.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function pairCodeHash() external pure returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13 <0.9.0;

interface IUniswapV2Pair {
    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

/// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

library Babylonian {
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }
}

/// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

/**
Optimal split order library to support SplitSwapRouterLite
Based on UniswapV2Library: https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
*/

import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "./Babylonian.sol";

/// @title SplitSwapLibraryLite
/// @author Sandy Bradley <[email protected]>, Sam Bacha <[email protected]>
/// @notice Optimal MEV library to support SplitSwapRouterLite
library SplitSwapLibraryLite {
    error Overflow();
    error ZeroAmount();
    error InvalidPath();
    error ZeroAddress();
    error IdenticalAddresses();
    error InsufficientLiquidity();

    struct Swap {
        bool isReverse;
        address tokenIn;
        address tokenOut;
        address pair0;
        address pair1;
        uint256 amountIn0;
        uint256 amountOut0;
        uint256 amountIn1;
        uint256 amountOut1;
    }

    uint256 internal constant MINIMUM_LIQUIDITY = 1000;
    uint256 internal constant EST_SWAP_GAS_USED = 150000;

    /// @custom:assembly Calculates the CREATE2 address for a pair without making any external calls from pre-sorted tokens
    /// @notice Calculates the CREATE2 address for a pair without making any external calls from pre-sorted tokens
    /// @dev Factory passed in directly because we have multiple factories. Format changes for new solidity spec.
    /// @param factory Factory address for dex
    /// @param token0 Pool token
    /// @param token1 Pool token
    /// @param factoryHash Init code hash for factory
    /// @return pair Pair pool address
    function _asmPairFor(
        address factory,
        address token0,
        address token1,
        bytes32 factoryHash
    ) internal pure returns (address pair) {
        // There is one contract for every combination of tokens,
        // which is deployed using CREATE2.
        // The derivation of this address is given by:
        //   address(keccak256(abi.encodePacked(
        //       bytes(0xFF),
        //       address(UNISWAP_FACTORY_ADDRESS),
        //       keccak256(abi.encodePacked(token0, token1)),
        //       bytes32(UNISWAP_PAIR_INIT_CODE_HASH),
        //   )));
        assembly ("memory-safe") {
            let ptr := mload(0x40) // get free memory pointer
            mstore(ptr, shl(96, token0))
            mstore(add(ptr, 0x14), shl(96, token1))
            let salt := keccak256(ptr, 0x28) // keccak256(token0, token1)
            mstore(ptr, 0xFF00000000000000000000000000000000000000000000000000000000000000) // buffered 0xFF prefix
            mstore(add(ptr, 0x01), shl(96, factory)) // factory address prefixed
            mstore(add(ptr, 0x15), salt)
            mstore(add(ptr, 0x35), factoryHash) // factory init code hash
            pair := keccak256(ptr, 0x55)
        }
    }

    /// @custom:assembly Sort tokens, zero address check
    /// @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order
    /// @dev Require replaced with revert custom error
    /// @param tokenA Pool token
    /// @param tokenB Pool token
    /// @return token0 First token in pool pair
    /// @return token1 Second token in pool pair
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) revert IdenticalAddresses();
        bool isZeroAddress;

        assembly ("memory-safe") {
            switch lt(shl(96, tokenA), shl(96, tokenB)) // sort tokens
            case 0 {
                token0 := tokenB
                token1 := tokenA
            }
            default {
                token0 := tokenA
                token1 := tokenB
            }
            isZeroAddress := iszero(token0)
        }
        if (isZeroAddress) revert ZeroAddress();
    }

    /// @notice Calculates the CREATE2 address for a pair without making any external calls
    /// @dev Factory passed in directly because we have multiple factories. Format changes for new solidity spec.
    /// @param factory Factory address for dex
    /// @param tokenA Pool token
    /// @param tokenB Pool token
    /// @return pair Pair pool address
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 factoryHash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = _asmPairFor(factory, token0, token1, factoryHash);
    }

    /// @notice Fetches and sorts the reserves for a pair
    /// @param factory Factory address for dex
    /// @param tokenA Pool token
    /// @param tokenB Pool token
    /// @return reserveA Reserves for tokenA
    /// @return reserveB Reserves for tokenB
    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 factoryHash
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_asmPairFor(factory, token0, token1, factoryHash))
            .getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /// @notice Given some asset amount and reserves, returns an amount of the other asset representing equivalent value
    /// @dev Require replaced with revert custom error
    /// @param amountA Amount of token A
    /// @param reserveA Reserves for tokenA
    /// @param reserveB Reserves for tokenB
    /// @return amountB Amount of token B returned
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        if (_isZero(amountA)) revert ZeroAmount();
        if (_isZero(reserveA) || _isZero(reserveB)) revert InsufficientLiquidity();
        amountB = (amountA * reserveB) / reserveA;
    }

    /// @notice Given an input asset amount, returns the maximum output amount of the other asset (accounting for fees) given reserves
    /// @dev Require replaced with revert custom error
    /// @param amountIn Amount of token in
    /// @param reserveIn Reserves for token in
    /// @param reserveOut Reserves for token out
    /// @return amountOut Amount of token out returned
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        if (_isZero(amountIn)) revert ZeroAmount();
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY) revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 amountInWithFee = amountIn * uint256(997);
            uint256 numerator = amountInWithFee * reserveOut;
            if (reserveOut != numerator / amountInWithFee) revert Overflow();
            uint256 denominator = (reserveIn * uint256(1000)) + amountInWithFee;
            amountOut = numerator / denominator;
        }
    }

    /// @notice Returns the minimum input asset amount required to buy the given output asset amount (accounting for fees) given reserves
    /// @dev Require replaced with revert custom error
    /// @param amountOut Amount of token out wanted
    /// @param reserveIn Reserves for token in
    /// @param reserveOut Reserves for token out
    /// @return amountIn Amount of token in required
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        if (_isZero(amountOut)) revert ZeroAmount();
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY || reserveOut <= amountOut)
            revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 numerator = reserveIn * amountOut * uint256(1000);
            if ((reserveIn * uint256(1000)) != numerator / amountOut) revert Overflow();
            uint256 denominator = (reserveOut - amountOut) * uint256(997);
            amountIn = (numerator / denominator) + 1;
        }
    }

    /// @notice Given an input asset amount and an array of token addresses, calculates all subsequent maximum output token amounts by calling getReserves for each pair of token addresses in the path in turn, and using these to call getAmountOut
    /// @dev Require replaced with revert custom error
    /// @param factory Factory address of dex
    /// @param amountIn Amount of token in
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        bytes32 factoryHash,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        amounts = new uint256[](length);
        amounts[0] = amountIn;
        for (uint256 i; i < _dec(length); i = _inc(i)) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[_inc(i)], factoryHash);
            amounts[_inc(i)] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @notice Fetches swap data for each pair and amounts given a desired output and path
    /// @param factory1 Backup Factory address for dex
    /// @param amountIn Amount in for first token in path
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return swaps Array Swap data for each user swap in path
    function getSwapsOut(
        address factory0,
        address factory1,
        uint256 amountIn,
        bytes32 factoryHash0,
        bytes32 factoryHash1,
        address[] memory path
    ) internal view returns (Swap[] memory swaps) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        swaps = new Swap[](_dec(length));
        for (uint256 i; i < _dec(length); i = _inc(i)) {
            if (_isNonZero(i)) amountIn = swaps[_dec(i)].amountOut0 + swaps[_dec(i)].amountOut1; // gather split swap amounts
            {
                (address token0, address token1) = sortTokens(path[i], path[_inc(i)]);
                swaps[i].pair0 = _asmPairFor(factory0, token0, token1, factoryHash0);
                swaps[i].pair1 = _asmPairFor(factory1, token0, token1, factoryHash1);
                swaps[i].isReverse = path[i] == token1;
            }
            swaps[i].tokenIn = path[i];
            swaps[i].tokenOut = path[_inc(i)];
            uint256 reserveIn0;
            uint256 reserveOut0;
            uint256 reserveIn1;
            uint256 reserveOut1;
            {
                (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(swaps[i].pair0).getReserves();
                (reserveIn0, reserveOut0) = swaps[i].isReverse ? (reserve1, reserve0) : (reserve0, reserve1);
                (reserve0, reserve1, ) = IUniswapV2Pair(swaps[i].pair1).getReserves();
                (reserveIn1, reserveOut1) = swaps[i].isReverse ? (reserve1, reserve0) : (reserve0, reserve1);
            }
            // find optimal route
            (swaps[i].amountIn0, swaps[i].amountOut0, swaps[i].amountIn1, swaps[i].amountOut1) = _optimalRoute(
                amountIn,
                reserveIn0,
                reserveOut0,
                reserveIn1,
                reserveOut1
            );
        }
    }

    /// @notice Given an output asset amount and an array of token addresses, calculates all preceding minimum input token amounts by calling getReserves for each pair of token addresses in the path in turn, and using these to call getAmountIn
    /// @dev Require replaced with revert custom error
    /// @param factory Factory address of dex
    /// @param amountOut Amount of token out wanted
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        bytes32 factoryHash,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        amounts = new uint256[](length);
        amounts[_dec(length)] = amountOut;
        for (uint256 i = _dec(length); _isNonZero(i); i = _dec(i)) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[_dec(i)], path[i], factoryHash);
            amounts[_dec(i)] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @notice Fetches swap data for each pair and amounts given a desired output and path
    /// @param factory1 Factory address for dex
    /// @param amountOut Amount out for last token in path
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return swaps Array Swap data for each user swap in path
    function getSwapsIn(
        address factory0,
        address factory1,
        uint256 amountOut,
        bytes32 factoryHash0,
        bytes32 factoryHash1,
        address[] memory path
    ) internal view returns (Swap[] memory swaps) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        swaps = new Swap[](_dec(length));
        for (uint256 i = _dec(length); _isNonZero(i); i = _dec(i)) {
            if (i < _dec(length)) amountOut = swaps[i].amountIn0 + swaps[i].amountIn1; // gather split swap amounts
            {
                (address token0, address token1) = sortTokens(path[_dec(i)], path[i]);
                swaps[_dec(i)].pair0 = _asmPairFor(factory0, token0, token1, factoryHash0);
                swaps[_dec(i)].pair1 = _asmPairFor(factory1, token0, token1, factoryHash1);
                swaps[_dec(i)].isReverse = path[i] == token0;
            }
            swaps[_dec(i)].tokenIn = path[_dec(i)];
            swaps[_dec(i)].tokenOut = path[i];
            uint256 reserveIn0;
            uint256 reserveOut0;
            uint256 reserveIn1;
            uint256 reserveOut1;
            {
                (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(swaps[_dec(i)].pair0).getReserves();
                (reserveIn0, reserveOut0) = swaps[_dec(i)].isReverse ? (reserve1, reserve0) : (reserve0, reserve1);
                (reserve0, reserve1, ) = IUniswapV2Pair(swaps[_dec(i)].pair1).getReserves();
                (reserveIn1, reserveOut1) = swaps[_dec(i)].isReverse ? (reserve1, reserve0) : (reserve0, reserve1);
            }
            // find optimal route
            (
                swaps[_dec(i)].amountIn0,
                swaps[_dec(i)].amountOut0,
                swaps[_dec(i)].amountIn1,
                swaps[_dec(i)].amountOut1
            ) = _optimalRouteIn(amountOut, reserveIn0, reserveOut0, reserveIn1, reserveOut1);
        }
    }

    function _optimalRoute(
        uint256 amountIn,
        uint256 reserveIn0,
        uint256 reserveOut0,
        uint256 reserveIn1,
        uint256 reserveOut1
    )
        internal
        pure
        returns (
            uint256 amountIn0,
            uint256 amountOut0,
            uint256 amountIn1,
            uint256 amountOut1
        )
    {
        uint256 uniAmountOut = getAmountOut(amountIn, reserveIn1, reserveOut1);
        uint256 sushiAmountOut = getAmountOut(amountIn, reserveIn0, reserveOut0);
        if (uniAmountOut < sushiAmountOut) {
            // sushi (dex0) better price
            amountIn0 = amountIn;
            amountOut0 = sushiAmountOut;
            if (_isNonZero(uniAmountOut)) {
                // split route
                (amountIn0, amountOut0, amountIn1, amountOut1) = _splitRoute(
                    amountIn,
                    sushiAmountOut,
                    reserveIn0,
                    reserveOut0,
                    reserveIn1,
                    reserveOut1
                );
            }
        } else {
            // uni (dex1) better price
            amountIn1 = amountIn;
            amountOut1 = uniAmountOut;
            if (_isNonZero(sushiAmountOut)) {
                // split route
                (amountIn1, amountOut1, amountIn0, amountOut0) = _splitRoute(
                    amountIn,
                    uniAmountOut,
                    reserveIn1,
                    reserveOut1,
                    reserveIn0,
                    reserveOut0
                );
            }
        }
    }

    function _splitRoute(
        uint256 amountIn,
        uint256 amountOutOnePair,
        uint256 reserveIn0,
        uint256 reserveOut0,
        uint256 reserveIn1,
        uint256 reserveOut1
    )
        internal
        pure
        returns (
            uint256 amountIn0,
            uint256 amountOut0,
            uint256 amountIn1,
            uint256 amountOut1
        )
    {
        // set single swap at best rate as default
        amountIn0 = amountIn;
        amountOut0 = amountOutOnePair;
        uint256 amount0 = _amountToSyncPrices(reserveIn0, reserveOut0, reserveIn1, reserveOut1);
        if (amount0 < amountIn - MINIMUM_LIQUIDITY) {
            uint256 amountInFirstPair = amount0 +
                ((amountIn - amount0) * (reserveIn0 + amount0)) /
                (reserveIn0 + amount0 + reserveIn1);
            uint256 amountOutFirstPair = getAmountOut(amountInFirstPair, reserveIn0, reserveOut0);
            uint256 amountOutSecondPair = getAmountOut(amountIn - amountInFirstPair, reserveIn1, reserveOut1);
            if (_isNonZero(amountOutFirstPair + amountOutSecondPair - amountOutOnePair)) {
                // split route better than extra gas cost
                amountIn0 = amountInFirstPair;
                amountIn1 = amountIn - amountInFirstPair;
                amountOut0 = amountOutFirstPair;
                amountOut1 = amountOutSecondPair;
            }
        }
    }

    function _optimalRouteIn(
        uint256 amountOut,
        uint256 reserveIn0,
        uint256 reserveOut0,
        uint256 reserveIn1,
        uint256 reserveOut1
    )
        internal
        pure
        returns (
            uint256 amountIn0,
            uint256 amountOut0,
            uint256 amountIn1,
            uint256 amountOut1
        )
    {
        uint256 uniAmountIn;
        uint256 sushiAmountIn;
        if (_isNonZero(reserveOut1)) uniAmountIn = getAmountIn(amountOut, reserveIn1, reserveOut1);
        if (_isNonZero(reserveOut0)) sushiAmountIn = getAmountIn(amountOut, reserveIn0, reserveOut0);
        if (uniAmountIn > sushiAmountIn && _isNonZero(sushiAmountIn)) {
            // sushi (dex0) better price
            amountOut0 = amountOut;
            amountIn0 = sushiAmountIn;
            if (_isNonZero(uniAmountIn)) {
                // split route
                (amountIn0, amountOut0, amountIn1, amountOut1) = _splitRouteIn(
                    amountOut,
                    sushiAmountIn,
                    reserveIn0,
                    reserveOut0,
                    reserveIn1,
                    reserveOut1
                );
            }
        } else if (_isNonZero(uniAmountIn)) {
            // uni (dex1) better price
            amountIn1 = uniAmountIn;
            amountOut1 = amountOut;
            if (_isNonZero(sushiAmountIn)) {
                // split route
                (amountIn1, amountOut1, amountIn0, amountOut0) = _splitRouteIn(
                    amountOut,
                    uniAmountIn,
                    reserveIn1,
                    reserveOut1,
                    reserveIn0,
                    reserveOut0
                );
            }
        }
    }

    function _splitRouteIn(
        uint256 amountOut,
        uint256 amountInOnePair,
        uint256 reserveIn0,
        uint256 reserveOut0,
        uint256 reserveIn1,
        uint256 reserveOut1
    )
        internal
        pure
        returns (
            uint256 amountIn0,
            uint256 amountOut0,
            uint256 amountIn1,
            uint256 amountOut1
        )
    {
        // set single swap at best rate as default
        amountIn0 = amountInOnePair;
        amountOut0 = amountOut;
        uint256 amount0 = _amountToSyncPrices(reserveIn0, reserveOut0, reserveIn1, reserveOut1);
        if (_isNonZero(amount0) && amount0 < amountInOnePair - MINIMUM_LIQUIDITY) {
            uint256 amountInFirstPair;
            unchecked {
                amountInFirstPair =
                    amount0 +
                    ((amountInOnePair - amount0) * (reserveIn0 + amount0)) /
                    (reserveIn0 + amount0 + reserveIn1);
            }

            uint256 amountOutFirstPair = getAmountOut(amountInFirstPair, reserveIn0, reserveOut0);
            uint256 amountOutSecondPair = amountOut - amountOutFirstPair;
            uint256 amountInSecondPair = getAmountIn(amountOutSecondPair, reserveIn1, reserveOut1);
            if (_isNonZero(amountInOnePair - amountInFirstPair - amountInSecondPair)) {
                // split route better than extra gas cost
                amountIn0 = amountInFirstPair;
                amountIn1 = amountInSecondPair;
                amountOut0 = amountOutFirstPair;
                amountOut1 = amountOutSecondPair;
            }
        }
    }

    function _amountToSyncPrices(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2
    ) internal pure returns (uint256) {
        unchecked {
            return (x1 * (Babylonian.sqrt(9 + ((1000000 * x2 * y1) / (y2 * x1))) - 1997)) / 1994;
        }
    }

    /// @custom:gas Uint256 zero check gas saver
    /// @notice Uint256 zero check gas saver
    /// @param value Number to check
    function _isZero(uint256 value) internal pure returns (bool boolValue) {
        assembly ("memory-safe") {
            boolValue := iszero(value)
        }
    }

    /// @custom:gas Uint256 not zero check gas saver
    /// @notice Uint256 not zero check gas saver
    /// @param value Number to check
    function _isNonZero(uint256 value) internal pure returns (bool boolValue) {
        assembly ("memory-safe") {
            boolValue := iszero(iszero(value))
        }
    }

    /// @custom:gas Unchecked increment gas saver
    /// @notice Unchecked increment gas saver for loops
    /// @param i Number to increment
    function _inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    /// @custom:gas Unchecked decrement gas saver
    /// @notice Unchecked decrement gas saver for loops
    /// @param i Number to decrement
    function _dec(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i - 1;
        }
    }
}