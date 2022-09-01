// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IPoolFactory.sol";
import "./interfaces/IPoolMaster.sol";

contract ClearpoolLens {
    /// @notice PooLFactory contract
    IPoolFactory public factory;

    /// @notice Contract constructor
    /// @param factory_ Address of the PoolFactory contract
    constructor(IPoolFactory factory_) {
        factory = factory_;
    }

    /// @notice Function that calculates poolsize-weighted index of pool supply APRs
    /// @return rate Supply rate (APR) index
    function getSupplyRateIndex() external view returns (uint256 rate) {
        address[] memory pools = factory.getPools();
        uint256 totalPoolSize = 0;
        for (uint256 i = 0; i < pools.length; i++) {
            IPoolMaster pool = IPoolMaster(pools[i]);
            uint256 poolSize = pool.poolSize();

            totalPoolSize += poolSize;
            rate += pool.getSupplyRate() * poolSize;
        }
        rate /= totalPoolSize;
    }

    /// @notice Function that calculates poolsize-weighted index of pool borrow APRs
    /// @return rate Borrow rate (APR) index
    function getBorrowRateIndex() external view returns (uint256 rate) {
        address[] memory pools = factory.getPools();
        uint256 totalPoolSize = 0;
        for (uint256 i = 0; i < pools.length; i++) {
            IPoolMaster pool = IPoolMaster(pools[i]);
            uint256 poolSize = pool.poolSize();

            totalPoolSize += poolSize;
            rate += pool.getBorrowRate() * poolSize;
        }
        rate /= totalPoolSize;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPoolFactory {
    function getPoolSymbol(address currency, address manager)
        external
        view
        returns (string memory);

    function isPool(address pool) external view returns (bool);

    function interestRateModel() external view returns (address);

    function auction() external view returns (address);

    function treasury() external view returns (address);

    function reserveFactor() external view returns (uint256);

    function insuranceFactor() external view returns (uint256);

    function warningUtilization() external view returns (uint256);

    function provisionalDefaultUtilization() external view returns (uint256);

    function warningGracePeriod() external view returns (uint256);

    function maxInactivePeriod() external view returns (uint256);

    function periodToStartAuction() external view returns (uint256);

    function owner() external view returns (address);

    function closePool() external;

    function burnStake() external;

    function getPools() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPoolMaster {
    function manager() external view returns (address);

    function currency() external view returns (address);

    function borrows() external view returns (uint256);

    function insurance() external view returns (uint256);

    function getBorrowRate() external view returns (uint256);

    function getSupplyRate() external view returns (uint256);

    function poolSize() external view returns (uint256);

    enum State {
        Active,
        Warning,
        ProvisionalDefault,
        Default,
        Closed
    }

    function state() external view returns (State);

    function initialize(address manager_, address currency_) external;

    function setRewardPerSecond(uint256 rewardPerSecond_) external;

    function withdrawReward(address account) external returns (uint256);

    function transferReserves() external;

    function processAuctionStart() external;

    function processDebtClaim() external;

    function setManager(address manager_) external;
}