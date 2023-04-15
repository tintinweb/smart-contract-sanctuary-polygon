// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
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

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Tokens.sol";

library LibTokensArray {
    function pushValue(uint256[] storage arr, uint256 value) internal returns (uint256 idx) {
        arr.push(value);
        idx = arr.length - 1;
    }

    function removeIdx(uint256[] storage arr, uint256 idx) internal returns (uint256 value) {
        uint256 n = arr.length;
        value = arr[idx];
        if (idx != n - 1) {
            arr[idx] = arr[n - 1];
        }
        arr.pop();
    }
}

abstract contract ERC721F is IERC721 {
    struct TokenInfo {
        address owner;
        uint96 ownerTokenIdx;
    }

    error NotTokenOwnerError();
    error BadRecipientError();
    error NotATokenError();
    error onERC721ReceivedError();
    error UnauthorizedError();
    error OnlyMinterError();

    using LibTokensArray for uint256[];

    uint256 public totalSupply;
    uint256 public immutable q;
    ERC20N public immutable erc20;
    address public minter;
    string public name;
    string public symbol;
    mapping (address => mapping (address => bool)) public isApprovedForAll;
    mapping (uint256 => address) public getApproved;
    mapping (address => uint256[]) private _tokensByOwner;
    mapping (uint256 => TokenInfo) private _tokenInfoByTokenId;

    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert OnlyMinterError();
        }
        _;
    }

    constructor(address minter_, string memory name_, string memory symbol_, uint256 q_) {
        minter = minter_;
        name = name_;
        symbol = symbol_;
        q = q_;
        erc20 = new ERC20N(name, symbol, q_);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _tokensByOwner[owner].length;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = _tokenInfoByTokenId[tokenId].owner;
        if (owner == address(0)) {
            revert NotATokenError();
        }
        return owner;
    }

    function abdicate(address minter_) external onlyMinter {
        minter = minter_;
    }
    
    function mint(address to, uint256 amount) external onlyMinter {
        erc20.mint(to, amount * q);
        _form(to, amount);
    }

    function mintErc20s(address to, uint256 amount) external onlyMinter {
        erc20.mint(to, amount);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0xffffffff || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function setApprovalForAll(address spender, bool isApproved) external {
        isApprovedForAll[msg.sender][spender] = isApproved;
        emit ApprovalForAll(msg.sender, spender, isApproved);
    }

    function approve(address spender, uint256 tokenId) external {
        getApproved[tokenId] = spender;
        emit Approval(msg.sender, spender, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        TokenInfo memory info = _tokenInfoByTokenId[tokenId];
        if (info.owner != from) {
            revert NotTokenOwnerError();
        }
        if (to == address(0) || to == address(this)) {
            revert BadRecipientError();
        }
        _transfer(info, to);
        erc20.adjust(from, to, q);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory receiveData) public {
        TokenInfo memory info = _tokenInfoByTokenId[tokenId];
        if (info.owner != from) {
            revert NotTokenOwnerError();
        }
        _transfer(info, to);
        erc20.adjust(from, to, q);
        _callReceiver(from, to, tokenId, receiveData);
    }

    function _callReceiver(address from, address to, uint256 tokenId, bytes memory receiveData) private {
        if (to.code.length != 0) {
            if (
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    receiveData
                ) != IERC721Receiver.onERC721Received.selector
            ) {
                revert onERC721ReceivedError();
            }
        }
    }

    // TODO: erc20.transfer(..., tokenIdxs[]) -> smash(..., tokenIdxs[])
    function smash(address owner, uint256 tokenCount) external {
        if (msg.sender != address(erc20)) {
            revert UnauthorizedError();
        }
        uint256 n = _tokensByOwner[owner].length;
        // TODO: batch
        for (uint256 i = 0; i < tokenCount && n > i; ++i) {
            _transfer(
                _tokenInfoByTokenId[_tokensByOwner[owner][n - i - 1]],
                address(this)
            );
        }
    }

    function form(address owner, uint256 tokenCount) external {
        if (msg.sender != address(erc20)) {
            revert UnauthorizedError();
        }
        if (minter == address(0)) {
            _form(owner, tokenCount);
        }
    }

    function _form(address owner, uint256 tokenCount) private {
        uint256 n = _tokensByOwner[address(this)].length;
        // TODO: batch
        for (uint256 i = 0; i < tokenCount; ++i) {
            TokenInfo memory info;
            if (n > i) {
                info = _tokenInfoByTokenId[_tokensByOwner[address(this)][n - i - 1]];
            }
            _transfer(info, owner);
        }
    }

    /// @dev plz no reentrancy in here.
    function _transfer(TokenInfo memory info, address to)
        private
    {
        // TODO: this logic is funky
        address from = info.owner;
        uint256 tokenId;
        if (info.ownerTokenIdx >= _tokensByOwner[from].length) {
            tokenId = _mint();
            ++totalSupply;
        } else {
            tokenId = _tokensByOwner[from].removeIdx(info.ownerTokenIdx);
        }
        info.owner = to;
        info.ownerTokenIdx = uint96(_tokensByOwner[to].pushValue(tokenId));
        _tokenInfoByTokenId[tokenId] = info;
        emit Transfer(from, to, tokenId);
    }

    function _mint() internal virtual returns (uint256 tokenId);
}

contract ERC20N is IERC20 {
    error OnlyERC721Error();

    string public name;
    string public symbol;
    uint256 public constant decimals = 18;
    ERC721F public immutable erc721;
    uint256 public immutable q;
    uint256 public totalSupply;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public balanceOf;

    modifier onlyERC721() {
        if (msg.sender != address(erc721)) {
            revert OnlyERC721Error();
        }
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 q_) {
        name = name_;
        symbol = symbol_;
        q = q_;
        erc721 = ERC721F(msg.sender);
    }

    function adjust(address from, address to, uint256 amount) external onlyERC721 {
        _adjust(from, to, amount);
    }

    function mint(address to, uint256 amount) external onlyERC721 {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transferFrom(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _transferFrom(from, to, amount);
        return true;
    }

    function _transferFrom(address from, address to, uint256 amount) private {
        if (msg.sender != from) {
            uint256 a = allowance[from][msg.sender];
            if (a != type(uint256).max) {
                allowance[from][msg.sender] = a - amount;
            }
        }
        _syncSmash(from, balanceOf[from], amount);
        _syncForm(to, balanceOf[to], amount);
        _adjust(from, to, amount);
    }

    function _syncSmash(address owner, uint256 balance, uint256 balanceRemoved) private {
        uint256 d = (balance / q) - (balance - balanceRemoved) / q;
        if (d != 0) {
            erc721.smash(owner, d);
        }
    }

    function _syncForm(address owner, uint256 balance, uint256 balanceAdded) private {
        uint256 d = (balance + balanceAdded) / q - (balance / q);
        if (d != 0) {
            erc721.form(owner, d);
        }
    }

    function _adjust(address from, address to, uint256 amount) private {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Tokens.sol";

interface IWETH9 is IERC20 {
    function deposit() payable external;
    function withdraw(uint256 amount) external;
}

interface IUniswapV3Factory {
    function feeAmountTickSpacing(uint24) external view returns (int24);
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address);
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (IUniswapV3Pool pool);       
}

interface IUniswapV3Pool {
    function initialize(uint160 sqrtPriceX96) external;
}

interface INonfungiblePositionManager is IERC721 {
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    function factory() external view returns (IUniswapV3Factory);
    function WETH9() external view returns (IWETH9);

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC721Events {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

interface IERC721 is IERC721Events {
    function name() external view returns (string memory name);
    function symbol() external view returns (string memory symbol);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function isApprovedForAll(address owner, address spender) external view returns (bool);
    function getApproved(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function setApprovalForAll(address spender, bool isApproved) external;
    function approve(address spender, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory receiveData) external;
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external returns (bytes4);
}

interface IERC20Events {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

interface IERC20 is IERC20Events {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solmate/utils/FixedPointMathLib.sol";
import "./ERC721F.sol";
import "./Ecosystem.sol";

contract UniswapV3Launcher {
    int24 constant MIN_TICK = -887272;
    int24 constant MAX_TICK = -MIN_TICK;

    INonfungiblePositionManager public immutable nfpMgr;
    IWETH9 public immutable weth;
    IUniswapV3Factory public immutable factory;

    constructor(INonfungiblePositionManager nfpMgr_) {
        nfpMgr = nfpMgr_;
        weth = nfpMgr_.WETH9();
        factory = nfpMgr_.factory();
    }

    function launch(ERC721F erc721, address owner, uint24 fee, uint256 maxSupply)
        external
        payable
        returns (IUniswapV3Pool pool, uint256 tokenId)
    {
        ERC20N erc20 = erc721.erc20();
        uint256 q = erc721.q();
        uint256 erc20Amount = maxSupply * q;
        pool = factory.createPool(
            address(erc20),
            address(weth),
            fee
        );
        erc721.mintErc20s(address(this), erc20Amount);
        erc20.approve(address(nfpMgr), erc20Amount);
        INonfungiblePositionManager.MintParams memory mintParams;
        (mintParams.token0 , mintParams.token1) = address(erc20) < address(weth)
            ? (address(erc20), address(weth))
            : (address(weth), address(erc20));
        (mintParams.amount0Desired , mintParams.amount1Desired) = address(erc20) < address(weth)
            ? (erc20Amount, msg.value)
            : (msg.value, erc20Amount);
        mintParams.fee = fee;
        {
            int24 tickSpacing = nfpMgr.factory().feeAmountTickSpacing(fee);
            mintParams.tickLower = (MIN_TICK / tickSpacing) * tickSpacing;
            mintParams.tickUpper = (MAX_TICK / tickSpacing) * tickSpacing;
        }
        mintParams.amount0Min = 0;
        mintParams.amount1Min = 0;
        mintParams.recipient = owner;
        mintParams.deadline = block.timestamp;
        pool.initialize(uint160(
            (FixedPointMathLib.sqrt(mintParams.amount1Desired) << 96) /
            FixedPointMathLib.sqrt(mintParams.amount0Desired)));
        (tokenId,,,) = nfpMgr.mint{value: msg.value}(mintParams);
        erc721.abdicate(address(0));
        // TODO: refund unused ERC20.
    }
}