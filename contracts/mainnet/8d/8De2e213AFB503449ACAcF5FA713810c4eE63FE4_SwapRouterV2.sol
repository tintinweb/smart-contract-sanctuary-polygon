// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product

        // todo unchecked
        unchecked {
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (~denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }

            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.

            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IBasePoolV2 {
    event Paused(address account);
    event Unpaused(address account);

    function poolManager() external view returns (address);
    function collateralToken() external view returns (address);
    function collateralReserve() external view returns (uint256);
    function tradeFeeRate() external view returns (uint16); // 1 means 1/10000
    function tradeFactor() external view returns (uint8);
    function getReserves() external view returns (uint256[] memory);
    function getTradingTokenId(uint8 option) external view returns (uint256);
    function paused() external view returns (bool);

    function buy(address to, uint8 option) external returns (uint256 shares);
    function sell(address to, uint8 option) external returns (uint256 amount);
    
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IBasePoolV2.sol";

interface IFixedCryptoPoolV2 is IBasePoolV2 {
    event Buy(
        address indexed sender, 
        address indexed to, 
        uint8 indexed option, 
        uint256 amount, 
        uint256 fee, 
        uint256 shares, 
        uint256 round, 
        uint256[] reserves
    );
    event Sell(
        address indexed sender, 
        address indexed to, 
        uint8 indexed option, 
        uint256 amount, 
        uint256 fee, 
        uint256 shares, 
        uint256 round, 
        uint256[] reserves
    );
    event Claim(address indexed sender, address indexed to, uint256[] rounds, uint256[] amounts);
    event StartPriceSet(address indexed sender, uint256 round, int256 startPrice, uint256 oracleRoundIdOfStartPrice);
    event EndPriceSet(address indexed sender, uint256 round, int256 endPrice, uint256 oracleRoundIdOfEndPrice);
    event LiquidityRemoved(address indexed sender, uint256 round, uint256 amount);
    event NewRoundStarted(uint256 round, uint256 option0TokenId, uint256 tradeStartTime, uint256 tradeEndTime, uint256 roundEndTime);
    event TotalRoundsUpdated(uint32 oldTotalRounds, uint32 newTotalRounds);

    struct RoundData {
        uint256 option0TokenId;
        uint256 tradeStartTime;
        uint256 tradeEndTime;
        uint256 roundEndTime;
        int256 startPrice;
        int256 endPrice;
        uint256 oracleRoundIdOfStartPrice;
        uint256 oracleRoundIdOfEndPrice;
    }

    function priceOracle() external view returns (address);
    function roundGap() external view returns (uint32);
    function tradeDuration() external view returns (uint32);
    function priceDuration() external view returns (uint32);
    function totalRounds() external view returns (uint32);
    function currentRound() external view returns (uint256);
    function totalClaimable() external view returns (uint256);
    function initReserve() external view returns (uint256);
    function getRoundData(uint256 round) external view returns (
        uint256 option0TokenId,
        uint256 tradeStartTime,
        uint256 tradeEndTime,
        uint256 roundEndTime,
        int256 startPrice,
        int256 endPrice,
        uint256 oracleRoundIdOfStartPrice,
        uint256 oracleRoundIdOfEndPrice
    ); 
    function getClaimable(
        address user, 
        uint256[] memory rounds
    ) external view returns (uint256[] memory tokenIds, uint256[] memory shares);

    function claim(address to, uint256[] calldata rounds) external returns (uint256[] memory amounts);

    function updateTotalRounds(uint32 newTotalRounds) external;
    function setStartPrice() external;
    function endCurrentRound() external;
    function startNewRound(uint256 tradeStartTime, uint256 option0TokenId) external;

    function initialize(
        address collateralToken_,
        address priceOracle_,
        uint256 initReserve_,
        uint32 roundGap_,
        uint32 tradeDuration_,
        uint32 priceDuration_,
        uint32 totalRounds_,
        uint16 tradeFeeRate_,
        uint8 tradeFactor_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IBasePoolV2.sol";

interface IGeneralPoolV2 is IBasePoolV2 {
    event AddLiquidity(uint256 amount, uint256[] reserves);
    event RemoveLiquidity(address indexed to, uint256 amount);
    event Buy(
        address indexed sender, 
        address indexed to, 
        uint8 indexed option, 
        uint256 amount, 
        uint256 fee, 
        uint256 shares, 
        uint256[] reserves
    );
    event Sell(
        address indexed sender, 
        address indexed to, 
        uint8 indexed option, 
        uint256 amount, 
        uint256 fee, 
        uint256 shares, 
        uint256[] reserves
    );
    event Claim(address indexed sender, address indexed to, uint256 amount);
    event ClaimTimeUpdated(uint256 oldClaimTime, uint256 newClaimTime);
    event SubmitResult(string description, uint8 option, uint256 totalShares);

    function collateralReserve() external view returns (uint256);
    function resultDescription() external view returns (string memory);
    function resultOption() external view returns (uint8);
    function resultOpened() external view returns (bool);
    function tradeStartTime() external view returns (uint256);
    function tradeEndTime() external view returns (uint256);
    function claimTime() external view returns (uint256);
    function question() external view returns (string memory);
    function options(uint256 index) external view returns (string memory);
    function getClaimable(address user) external view returns (uint256 tokenId, uint256 shares);

    function updateClaimTime(uint256 newClaimTime) external;
    function submitResult(uint8 option, string calldata description) external;
    function initialize(
        address collateralToken_,
        uint16 tradeFeeRate_,
        uint8 tradeFactor_,
        uint256 tradeStartTime_,
        uint256 tradeEndTime_,
        uint256 claimTime_,
        uint256 option0TokenId_,
        string memory question_,
        string[] memory options_
    ) external;

    function addLiquidity(uint256 reserve0) external;
    function removeLiquidity() external returns (uint256 amount);
    function claim(address to) external returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IPoolManagerV2 {
    event PoolPaused(bytes32 poolId);
    event PoolUnpaused(bytes32 poolId);
    event GeneralPoolCreated(
        bytes32 poolId,
        address pool,
        uint256 option0TokenId,
        uint256 tradeStartTime,
        uint256 tradeEndTime,
        uint256 claimTime,
        string question,
        string[] options,
        string tag
    );
    event FixedCryptoPoolCreated(
        bytes32 poolId,
        address pool,
        address priceOracle,
        uint256 initReserve,
        uint32 roundGap,
        uint32 tradeDuration,
        uint32 priceDuration,
        uint32 totalRounds,
        string tag
    );

    function collateralToken() external view returns (address);
    function generalPoolTemplate() external view returns (address);
    function fixedCryptoPoolTemplate() external view returns (address);
    function tradeFeeRate() external view returns (uint16);
    function tradeFactor() external view returns (uint8);
    function getPool(bytes32 poolId) external view returns (address pool, uint8 poolType);
    function isBuilder(address) external view returns (bool);
    function isKeeper(address) external view returns (bool);

    function updateGeneralPoolTemplate(address newTemplate) external;
    function updateFixedCryptoPoolTemplate(address newTemplate) external;
    function updateTradeFeeRate(uint16 newFeeRate) external;
    function updateTradeFactor(uint8 newFactor) external;
    function setBuilder(address builder, bool state) external;
    function setKeeper(address keeper, bool state) external;
    function withdraw(address token, address to, uint256 amount) external;

    function createAndInitializeGeneralPool(
        uint256 collateralAmount,
        uint256 reserve0,
        uint256 tradeStartTime,
        uint256 tradeEndTime,
        uint256 claimTime,
        string memory question,
        string[] memory options,
        string memory tag
    ) external returns (address pool);
    function updateClaimTimeForGeneral(bytes32 poolId, uint256 newClaimTime) external;
    function submitResultForGeneral(bytes32 poolId, uint8 option, string calldata description) external;
    function removeLiquidityForGeneral(bytes32 poolId) external;

    function createAndInitializeFixedCryptoPool(
        address priceOracle,
        uint256 initReserve,
        uint256 tradeStartTime,
        uint32 roundGap,
        uint32 tradeDuration,
        uint32 priceDuration,
        uint32 totalRounds,
        string memory tag
    ) external returns (address pool);
    function updateTotalRounds(bytes32 poolId, uint32 newTotalRounds) external;
    function setStartPrice(bytes32 poolId) external;
    function endCurrentRound(bytes32 poolId) external;
    function startNewRound(bytes32 poolId, uint256 tradeStartTime) external;
    function endCurrentAndStartNewRound(bytes32 poolId) external;
    
    function pause(bytes32 poolId) external;
    function unpause(bytes32 poolId) external;

    function mint(address to, uint256 tokenId, uint256 shares) external;
    function burn(uint256 tokenId, uint256 shares) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ISwapRouterV2 {
    function poolManager() external view returns (address);

    function buy(
        bytes32 poolId,  
        address to,
        uint8 option, 
        uint256 amount,
        uint256 minShares,
        uint256 deadline
    ) external returns (uint256 shares);

    function sell(
        bytes32 poolId, 
        address to, 
        uint8 option, 
        uint256 shares,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256 amount);

    function claimGeneralPool(bytes32 poolId, address to) external returns (uint256 amount);

    function claimFixedPool(
        bytes32 poolId, 
        address to,
        uint256[] calldata rounds
    ) external returns (uint256[] memory amounts);

    function estimateBuy(
        bytes32 poolId,  
        uint8 option, 
        uint256 amount
    ) external view returns (uint256 shares, uint256[] memory newReserves);

    function estimateSell(
        bytes32 poolId,  
        uint8 option, 
        uint256 shares
    ) external view returns (uint256 amount, uint256[] memory newReserves);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interfaces/ISwapRouterV2.sol";
import "./interfaces/IPoolManagerV2.sol";
import "./interfaces/IBasePoolV2.sol";
import "./interfaces/IGeneralPoolV2.sol";
import "./interfaces/IFixedCryptoPoolV2.sol";
import "../v1/libraries/FullMath.sol";
import "../v1/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract SwapRouterV2 is ISwapRouterV2 {
    using FullMath for uint256;

    address public immutable override poolManager;

    modifier checkDeadline(uint deadline) {
        require(deadline >= block.timestamp, 'expired');
        _;
    }

    constructor(address poolManager_) {
        poolManager = poolManager_;
    }

    function buy(
        bytes32 poolId,
        address to,
        uint8 option,
        uint256 amount,
        uint256 minShares,
        uint256 deadline
    ) external override checkDeadline(deadline) returns (uint256 shares) {
        (address pool, ) = IPoolManagerV2(poolManager).getPool(poolId);
        require(pool != address(0), "pool not found");
        address collateralToken = IBasePoolV2(pool).collateralToken();
        TransferHelper.safeTransferFrom(
            collateralToken,
            msg.sender,
            pool,
            amount
        );
        shares = IBasePoolV2(pool).buy(to, option);
        require(shares >= minShares, "insufficient shares");
    }

    function sell(
        bytes32 poolId,
        address to,
        uint8 option,
        uint256 shares,
        uint256 minAmount,
        uint256 deadline
    ) external override checkDeadline(deadline) returns (uint256 amount) {
        (address pool, ) = IPoolManagerV2(poolManager).getPool(poolId);
        require(pool != address(0), "pool not found");
        uint256 tokenId = IBasePoolV2(pool).getTradingTokenId(option);
        IERC1155(poolManager).safeTransferFrom(msg.sender, pool, tokenId, shares, "");
        amount = IBasePoolV2(pool).sell(to, option);
        require(amount >= minAmount, "insufficient amount");
    }

    function claimGeneralPool(bytes32 poolId, address to) external override returns (uint256 amount) {
        (address pool, ) = IPoolManagerV2(poolManager).getPool(poolId);
        require(pool != address(0), "pool not found");
        (uint256 tokenId, uint256 shares) = IGeneralPoolV2(pool).getClaimable(msg.sender);
        IERC1155(poolManager).safeTransferFrom(msg.sender, pool, tokenId, shares, "");
        amount = IGeneralPoolV2(pool).claim(to);
    }

    function claimFixedPool(
        bytes32 poolId,
        address to,
        uint256[] calldata rounds
    ) external override returns (uint256[] memory amounts) {
        (address pool, ) = IPoolManagerV2(poolManager).getPool(poolId);
        require(pool != address(0), "pool not found");
        (uint256[] memory tokenIds, uint256[] memory shares) = IFixedCryptoPoolV2(pool).getClaimable(msg.sender, rounds);
        IERC1155(poolManager).safeBatchTransferFrom(msg.sender, pool, tokenIds, shares, "");
        amounts = IFixedCryptoPoolV2(pool).claim(to, rounds);
    }

    function estimateBuy(
        bytes32 poolId,
        uint8 option,
        uint256 amount
    )
        external
        view
        override
        returns (uint256 shares, uint256[] memory newReserves)
    {
        (address pool, ) = IPoolManagerV2(poolManager).getPool(poolId);
        require(pool != address(0), "pool not found");
        require(option <= 1, "wrong option");
        uint16 tradeFeeRate = IBasePoolV2(pool).tradeFeeRate();
        uint8 tradeFactor = IBasePoolV2(pool).tradeFactor();
        uint256[] memory reserves = IBasePoolV2(pool).getReserves();

        uint256 amountWithoutFee = amount - amount * uint256(tradeFeeRate) / 10000;
        newReserves = new uint256[](2);
        if (option == 0) {
            newReserves[1] = amountWithoutFee * tradeFactor + reserves[1];
            newReserves[0] = reserves[0].mulDiv(reserves[1], newReserves[1]);
            shares = amountWithoutFee.mulDiv(newReserves[0] + newReserves[1], newReserves[1]);
        } else {
            newReserves[0] = amountWithoutFee * tradeFactor + reserves[0];
            newReserves[1] = reserves[0].mulDiv(reserves[1], newReserves[0]);
            shares = amountWithoutFee.mulDiv(newReserves[0] + newReserves[1], newReserves[0]);
        }
    }

    function estimateSell(
        bytes32 poolId,
        uint8 option,
        uint256 shares
    )
        external
        view
        override
        returns (uint256 amount, uint256[] memory newReserves)
    {
        (address pool, ) = IPoolManagerV2(poolManager).getPool(poolId);
        require(pool != address(0), "pool not found");
        require(option <= 1, "wrong option");
        uint256[] memory reserves = IBasePoolV2(pool).getReserves();
        newReserves = new uint256[](2);
        if (option == 0) {
            newReserves[0] = reserves[0] + shares;
            newReserves[1] = reserves[0].mulDiv(reserves[1], newReserves[0]);
            amount = shares.mulDiv(newReserves[1], newReserves[0] + newReserves[1]);
        } else {
            newReserves[1] = reserves[1] + shares;
            newReserves[0] = reserves[0].mulDiv(reserves[1], newReserves[1]);
            amount = shares.mulDiv(newReserves[0], newReserves[0] + newReserves[1]);
        }
        uint16 tradeFeeRate = IBasePoolV2(pool).tradeFeeRate();
        amount -= (amount * tradeFeeRate) / 10000;
    }
}