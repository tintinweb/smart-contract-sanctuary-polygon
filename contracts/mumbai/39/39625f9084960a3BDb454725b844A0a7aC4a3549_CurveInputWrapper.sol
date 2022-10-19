// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface CurveCalculator {
    function get_dx(
        uint256 n_coins,
        uint256[8] memory balances,
        uint256 amp,
        uint256 fee,
        uint256[8] memory rates,
        uint256[8] memory precisions,
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

interface CurveRegistry {
    function find_pool_for_coins(address fromToken, address toToken)
        external
        view
        returns (address pool);

    function get_coin_indices(
        address pool,
        address fromToken,
        address toToken
    )
        external
        view
        returns (
            int128 fromIndex,
            int128 toIndex,
            bool metaPool
        );

    // def address_provider() -> address: view
    function get_A(address _pool) external view returns (uint256);

    function get_fees(address _pool) external view returns (uint256[2] memory);

    function get_n_coins(address _pool)
        external
        view
        returns (uint256[2] memory);

    function get_balances(address _pool)
        external
        view
        returns (uint256[8] memory);

    function get_underlying_balances(address _pool)
        external
        view
        returns (uint256[8] memory);

    function get_rates(address _pool) external view returns (uint256[8] memory);

    function get_decimals(address _pool)
        external
        view
        returns (uint256[8] memory);

    function get_underlying_decimals(address _pool)
        external
        view
        returns (uint256[8] memory);
}

// return Calculator(calculator).get_dx(n_coins, balances, amp, fee, rates, decimals, i, j, _amount)

contract CurveInputWrapper {
    struct HelperStruct {
        int128 i;
        int128 j;
        bool is_underlying;
        uint256 amp;
        uint256 fee;
        uint256[8] balances;
        uint256[8] rates;
        uint256[8] decimals;
    }
    uint256 constant MAX_COINS = 8;
    CurveRegistry public immutable curveRegistry =
        CurveRegistry(0x094d12e5b541784701FD8d65F11fc0598FBC6332);
    CurveCalculator public immutable curveCalculator =
        CurveCalculator(0xE1Aa33c704d6603c1f7a5961aaE29615744AC973);

    function get_input_amount(
        address pool,
        address from,
        address to,
        uint256 amountOut
    ) external view returns (uint256 amountIn) {
        HelperStruct memory hs;
        (hs.i, hs.j, hs.is_underlying) = curveRegistry.get_coin_indices(
            pool,
            from,
            to
        );
        hs.amp = curveRegistry.get_A(pool);
        hs.fee = curveRegistry.get_fees(pool)[0];

        uint256 n_coins = curveRegistry.get_n_coins(pool)[
            hs.is_underlying ? 1 : 0
        ];

        if (hs.is_underlying) {
            hs.balances = curveRegistry.get_underlying_balances(pool);
            hs.decimals = curveRegistry.get_underlying_decimals(pool);
            for (uint256 counter; counter < n_coins; counter++) {
                hs.rates[counter] = 10**18;
            }
        } else {
            hs.balances = curveRegistry.get_balances(pool);
            hs.decimals = curveRegistry.get_decimals(pool);
            hs.rates = curveRegistry.get_rates(pool);
        }

        amountIn = curveCalculator.get_dx(
            n_coins,
            hs.balances,
            hs.amp,
            hs.fee,
            hs.rates,
            hs.decimals,
            hs.i,
            hs.j,
            amountOut
        );
    }
}