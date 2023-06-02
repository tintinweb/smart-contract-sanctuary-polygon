// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "IAaveOracle.sol";
import "IPool.sol";

contract LenderBorrower {
    IAaveOracle immutable AAVE_ORACLE;
    IPool immutable POOL;

    uint constant HEALTH_FACTOR = 14;
    address immutable USDC;
    address immutable WETH;

    mapping(address => uint) public totalEthDeposits;
    mapping(address => uint) public totalUsdcBorrows;
    mapping(address => uint) public collateralEthDeposits;

    constructor(
        address _aaveOracle,
        address _pool,
        address _usdc,
        address _weth
    ) {
        AAVE_ORACLE = IAaveOracle(_aaveOracle);
        POOL = IPool(_pool);
        USDC = _usdc;
        WETH = _weth;
    }

    function depositEth() external payable {
        totalEthDeposits[msg.sender] += msg.value;
    }

    /// @param amount to be borrowed, expressed in wei
    function borrowUsdc(uint amount) external {
        require(amount > 0, "Amount must be greater than 0");

        uint ltv = _getUsdcLtv();

        uint collateralRequiredinUsdc = (amount * HEALTH_FACTOR * 1000) / ltv; // wei

        uint ethPrice = 400000000000;

        uint collateralRequiredinEth = (collateralRequiredinUsdc / ethPrice) *
            10 ** 8; // wei

        require(
            totalEthDeposits[msg.sender] > collateralRequiredinEth,
            "Insufficient funds deposited"
        );

        // deposit collateral to aave

        // borrow from aave

        totalUsdcBorrows[msg.sender] += amount;

        // send to user
    }

    function _getEthPrice() private view returns (uint) {
        return AAVE_ORACLE.getAssetPrice(WETH);
    }

    function _getUsdcConfiguration() private view returns (uint data) {
        data = POOL.getConfiguration(USDC);
    }

    function _getUsdcLtv() private view returns (uint ltv) {
        uint configuration = _getUsdcConfiguration();
        ltv = _readBits(configuration);
    }

    function _readBits(uint256 input) private pure returns (uint256) {
        uint256 mask = (1 << 16) - 1; // create a bitmask with the lowest 16 bits set to 1
        return input & mask; // perform bitwise AND operation to extract the 0-15 bits
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IAaveOracle {
    function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IPool {
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function getConfiguration(
        address asset
    ) external view returns (uint256 data);
}