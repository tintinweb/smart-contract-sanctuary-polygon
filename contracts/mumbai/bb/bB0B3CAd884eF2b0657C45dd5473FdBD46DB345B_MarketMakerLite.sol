/**
 *Submitted for verification at polygonscan.com on 2022-07-15
*/

// File: Interfaces.sol

interface IERC20 {
    function transferFrom(
        address sender,
        address to,
        uint256 amount
    ) external;

    function transfer(address recipient, uint256 amount) external;

    function balanceOf(address user) external returns (uint256);
}

interface IPair {
    function slot0()
        external
        view
        returns (
            uint160,
            int24,
            uint16,
            uint16,
            uint16,
            uint8,
            bool
        );

    function tickSpacing() external returns (int24);

    function fee() external returns (uint24);
}

interface INFTManager {
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(
        uint256 indexed tokenId,
        address recipient,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
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

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

interface IMarketMaker {
    // Variables
    struct Position {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    // Functions

    // Events
    event Close(uint256 indexed id);
}

// File: MarketMakerLite.sol

/// ProxyRegistry.sol

// Copyright (C) 2018-2021 Dai Foundation

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

contract MarketMakerLite is IMarketMaker {
    address public feeReceipient;
    address public pair;
    address public token0;
    address public token1;
    INFTManager public NFTManager;
    address public owner;
    uint256 public currentPositionId;
    uint24 public fee;
    int24 public tickSpacing;
    Position public currentPosition;

    constructor() {
        owner = msg.sender;
    }

    function initialize(
        address _feeReceipient,
        address _pair,
        address _token0,
        address _token1,
        address _manager
    ) external onlyOwner {
        feeReceipient = _feeReceipient;
        pair = _pair;
        token0 = _token0;
        token1 = _token1;
        NFTManager = INFTManager(_manager);

        fee = IPair(pair).fee();
        tickSpacing = IPair(pair).tickSpacing();
        mint();
    }

    function getCurrentTick() public view returns (int24 currentTick) {
        (, currentTick, , , , , ) = IPair(pair).slot0();
    }

    function getBalance() public returns (uint256 amount0, uint256 amount1) {
        amount0 = IERC20(token0).balanceOf(address(this));
        amount1 = IERC20(token1).balanceOf(address(this));
    }

    function parsePosition() public view returns (bool canMoveCloser) {
        int24 currentTick = getCurrentTick();

        bool inRange = currentPosition.tickLower <= currentTick &&
            currentPosition.tickUpper >= currentTick;

        if (!inRange) {
            if (currentPosition.tickLower > currentTick) {
                canMoveCloser =
                    currentPosition.tickLower - currentTick > tickSpacing;
            } else {
                canMoveCloser =
                    currentTick - currentPosition.tickUpper > tickSpacing;
            }
        }
    }

    function mint() internal {
        (uint256 amount0, uint256 amount1) = getBalance();
        int24 currentTick = getCurrentTick();
        int24 mod = currentTick % tickSpacing;
        int24 tickHigh;
        int24 tickLow;
        if (amount1 > 0) {
            tickLow = currentTick - mod + tickSpacing;
            tickHigh = tickLow + tickSpacing;
        } else if (amount0 > 0) {
            tickHigh = currentTick - mod;
            tickLow = tickHigh - tickSpacing;
        }

        INFTManager.MintParams memory mintParam = INFTManager.MintParams(
            token0,
            token1,
            fee,
            tickLow,
            tickHigh,
            amount0,
            amount1,
            0,
            0,
            address(this),
            (block.timestamp + 2000)
        );
        (uint256 positionId, , , ) = NFTManager.mint(mintParam);
        updatePosition(positionId);
    }

    function close() internal {
        INFTManager.CollectParams memory collectParams = INFTManager
            .CollectParams(
                currentPositionId,
                feeReceipient,
                2**128 - 1,
                2**128 - 1
            );

        INFTManager.DecreaseLiquidityParams memory params = INFTManager
            .DecreaseLiquidityParams(
                currentPositionId,
                currentPosition.liquidity,
                0,
                0,
                block.timestamp + 2000
            );

        INFTManager.CollectParams memory collectParams2 = INFTManager
            .CollectParams(
                currentPositionId,
                feeReceipient,
                2**128 - 1,
                2**128 - 1
            );

        NFTManager.collect(collectParams);
        NFTManager.decreaseLiquidity(params);
        NFTManager.collect(collectParams2);
    }

    function updatePosition(uint256 positionId) internal {
        currentPositionId = positionId;

        (
            ,
            ,
            address _token0,
            address _token1,
            uint24 _fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = NFTManager.positions(positionId);

        currentPosition = Position(
            _token0,
            _token1,
            _fee,
            tickLower,
            tickUpper,
            liquidity
        );
    }

    function execute() external onlyOwner {
        bool canMoveCloser = parsePosition();

        if (canMoveCloser) {
            close();
            mint();
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}