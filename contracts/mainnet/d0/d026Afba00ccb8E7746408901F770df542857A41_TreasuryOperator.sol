// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "ITreasury.sol";

contract TreasuryOperator {

    function initialize(
        address treasury,
        address token,
        address share,
        address oracle,
        address boardroom,
        uint256 start_time
    ) internal {
        ITreasury(treasury).initialize(token, share, oracle, boardroom, start_time);
    }

    function doubleInitialize(
        address treasury1,
        address treasury2,

        address token1,
        address token2,

        address oracle1,
        address oracle2,

        address boardroom1,
        address boardroom2,

        address share,
        uint256 start_time
    ) external {
        initialize(treasury1, token1, share, oracle1, boardroom1, start_time);
        initialize(treasury2, token2, share, oracle2, boardroom2, start_time);
    }

    function allocate(address treasury1, address treasury2) external {
        try ITreasury(treasury1).allocateSeigniorage() {
        }catch{}

        try ITreasury(treasury2).allocateSeigniorage() {
        }catch{}
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ITreasury {
    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;

    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getTokenPrice() external view returns (uint256);

    function getRealtimeTokenIndexPrice() external view returns (uint256);

    function initialize(address token, address share, address oracle, address boardroom, uint256 start_time) external;

    function allocateSeigniorage() external;
}