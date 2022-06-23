// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOracleSimple {
    function update() external;

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}

interface IChainlinkFeed {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract OracleUSD {
    IOracleSimple public twapOracleCkie;
    IOracleSimple public twapSugarDollarOracle;

    address public immutable wmatic;
    address public immutable cookie;
    address public immutable sugarDollar;

    // 0xfe4a8cc5b5b2366c1b58bea3858e81843581b2f7
    IChainlinkFeed public immutable chainlinkUsdcUsd;
    // 0xab594600376ec9fd91f8e885dadf0ce036862de0
    IChainlinkFeed public immutable chainlinkMaticUsd;

    constructor(
        IOracleSimple _twapOracleCkie,
        IOracleSimple _twapSugarDollarOracle,
        address _sugarDollar,
        address _wmatic,
        address _cookie,
        IChainlinkFeed _chainlinkUsdcUsd,
        IChainlinkFeed _chainlinkMaticUsd
    ) {
        twapOracleCkie = _twapOracleCkie;
        twapSugarDollarOracle = _twapSugarDollarOracle;
        sugarDollar = _sugarDollar;
        wmatic = _wmatic;
        cookie = _cookie;
        chainlinkUsdcUsd = _chainlinkUsdcUsd;
        chainlinkMaticUsd = _chainlinkMaticUsd;
    }

    /// @notice This is the price of 1 USDC in USD, base 1e8
    /// @return Usdc price in USD, base 1e8
    function USDCPrice() public view returns (uint256) {
        (, int256 price, , , ) = chainlinkUsdcUsd.latestRoundData();
        return uint256(price);
    }

    /// @notice This is the price of 1 CKIE in USD, base 1e8
    /// @dev To calculate USD price of a CKIE use the twap oracle an then the
    ///      MATIC-USD chainlink price fee
    /// @return uint256 CKIE price in USD, base 1e8
    function cookieUSDPrice() external returns (uint256) {
        twapOracleCkie.update();
        (, int256 price, , , ) = chainlinkMaticUsd.latestRoundData();

        // load price from Oracle
        return (twapOracleCkie.consult(cookie, 1 ether) * uint256(price)) / 1 ether;
    }

    /// @notice This is the price of 1 sUSD in USD, base 1e8
    /// @dev To calculate USD price of a sUSD use the twap oracle an then the
    ///      USDC-USD chainlink price fee
    /// @return uint256 sUSD price in USD, base 1e8
    function sugarDollarPrice() external returns (uint256) {
        twapSugarDollarOracle.update();
        // twapSugarDollarOracle.consult(sugarDollar, 1 ether) = usdc val (1e6)
        return
            (twapSugarDollarOracle.consult(sugarDollar, 1 ether) *
                USDCPrice()) / 1e6;
    }

    function info()
        external
        view
        returns (
            uint256 price,
            uint256 cookieUSD,
            uint256 susdUSD
        )
    {
        price = USDCPrice();
        (, int256 priceMaticUSD, , , ) = chainlinkMaticUsd.latestRoundData();

        // load price from Oracle
        cookieUSD =
            (twapOracleCkie.consult(cookie, 1 ether) * uint256(priceMaticUSD)) /
            1 ether;

        susdUSD =
            (twapSugarDollarOracle.consult(sugarDollar, 1 ether) *
                uint256(price)) /
            1e6;
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