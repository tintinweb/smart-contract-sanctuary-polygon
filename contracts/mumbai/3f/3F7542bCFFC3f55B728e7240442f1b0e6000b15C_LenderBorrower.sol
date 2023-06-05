// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "IAaveOracle.sol";
import "IPool.sol";
import "IWrappedTokenGatewayV3.sol";

contract LenderBorrower {
    IAaveOracle immutable AAVE_ORACLE;
    IPool immutable POOL;
    IWrappedTokenGatewayV3 immutable WETH_GATEWAY;

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
        address _weth,
        address _wethGateway
    ) {
        AAVE_ORACLE = IAaveOracle(_aaveOracle);
        POOL = IPool(_pool);
        USDC = _usdc;
        WETH = _weth;
        WETH_GATEWAY = IWrappedTokenGatewayV3(_wethGateway);
    }

    /// @param amount USDC amount to be borrowed (6 decimals)
    function borrowUsdc(uint amount) external {
        require(amount > 0, "Amount must be greater than 0");

        uint collateralRequiredinEth = _requiredCollatreal(amount);

        uint collateralPower = _getCollateralPower();

        require(
            collateralPower > collateralRequiredinEth,
            "Insufficient funds deposited"
        );

        _depositCollateral(collateralRequiredinEth);

        _borrowUsdc(amount);

        // send to user
    }

    function depositEth() external payable {
        totalEthDeposits[msg.sender] += msg.value;
    }

    function _borrowUsdc(uint amount) private {
        _borrowUsdcFromAave(amount);
        totalUsdcBorrows[msg.sender] += amount;
    }

    function _borrowUsdcFromAave(uint amount) private {
        uint16 referralCode = 0;
        uint256 interestRateMode = 2; // 1 is stable rate, 2 is variable rate. We will make use of variable rates

        POOL.borrow(
            USDC,
            amount,
            interestRateMode,
            referralCode,
            address(this)
        );
    }

    function _depositCollateral(uint amount) private {
        _depositEthToAave(amount);
        collateralEthDeposits[msg.sender] += amount;
    }

    function _depositEthToAave(uint amount) private {
        uint16 referralCode = 0;

        WETH_GATEWAY.depositETH{value: amount}(
            address(POOL),
            address(this),
            referralCode
        );
    }

    function _getCollateralPower() private view returns (uint collateralPower) {
        uint collateralPower = totalEthDeposits[msg.sender] -
            collateralEthDeposits[msg.sender];
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

    function _requiredCollatreal(
        uint amount
    ) private view returns (uint collateralRequiredinEth) {
        uint ltv = _getUsdcLtv();

        uint collateralRequiredinUsdc = (amount * HEALTH_FACTOR) / ltv;

        uint ethPrice = _getEthPrice();

        collateralRequiredinEth =
            (collateralRequiredinUsdc * 10 ** 23) /
            ethPrice; // wei
    }

    // for testing
    function withdraw() external {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to withdraw!");
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IWrappedTokenGatewayV3 {
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;
}