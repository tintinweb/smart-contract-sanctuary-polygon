// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../access/Governable.sol";
import "../peripherals/interfaces/ITimelock.sol";

contract RewardManager is Governable {
    bool public isInitialized;

    ITimelock public timelock;
    address public rewardRouter;

    address public mvlpManager;

    address public stakedMvxTracker;
    address public bonusMvxTracker;
    address public feeMvxTracker;

    address public feeMvlpTracker;
    address public stakedMvlpTracker;

    address public stakedMvxDistributor;
    address public stakedMvlpDistributor;

    address public esMvx;
    address public bnMvx;

    address public mvxVester;
    address public mvlpVester;

    function initialize(
        ITimelock _timelock,
        address _rewardRouter,
        address _mvlpManager,
        address _stakedMvxTracker,
        address _bonusMvxTracker,
        address _feeMvxTracker,
        address _feeMvlpTracker,
        address _stakedMvlpTracker,
        address _stakedMvxDistributor,
        address _stakedMvlpDistributor,
        address _esMvx,
        address _bnMvx,
        address _mvxVester,
        address _mvlpVester
    ) external onlyGov {
        require(!isInitialized, "RewardManager: already initialized");
        isInitialized = true;

        timelock = _timelock;
        rewardRouter = _rewardRouter;

        mvlpManager = _mvlpManager;

        stakedMvxTracker = _stakedMvxTracker;
        bonusMvxTracker = _bonusMvxTracker;
        feeMvxTracker = _feeMvxTracker;

        feeMvlpTracker = _feeMvlpTracker;
        stakedMvlpTracker = _stakedMvlpTracker;

        stakedMvxDistributor = _stakedMvxDistributor;
        stakedMvlpDistributor = _stakedMvlpDistributor;

        esMvx = _esMvx;
        bnMvx = _bnMvx;

        mvxVester = _mvxVester;
        mvlpVester = _mvlpVester;
    }

    function updateEsMvxHandlers() external onlyGov {
        timelock.managedSetHandler(esMvx, rewardRouter, true);

        timelock.managedSetHandler(esMvx, stakedMvxDistributor, true);
        timelock.managedSetHandler(esMvx, stakedMvlpDistributor, true);

        timelock.managedSetHandler(esMvx, stakedMvxTracker, true);
        timelock.managedSetHandler(esMvx, stakedMvlpTracker, true);

        timelock.managedSetHandler(esMvx, mvxVester, true);
        timelock.managedSetHandler(esMvx, mvlpVester, true);
    }

    function enableRewardRouter() external onlyGov {
        timelock.managedSetHandler(mvlpManager, rewardRouter, true);

        timelock.managedSetHandler(stakedMvxTracker, rewardRouter, true);
        timelock.managedSetHandler(bonusMvxTracker, rewardRouter, true);
        timelock.managedSetHandler(feeMvxTracker, rewardRouter, true);

        timelock.managedSetHandler(feeMvlpTracker, rewardRouter, true);
        timelock.managedSetHandler(stakedMvlpTracker, rewardRouter, true);

        timelock.managedSetHandler(esMvx, rewardRouter, true);

        timelock.managedSetMinter(bnMvx, rewardRouter, true);

        timelock.managedSetMinter(esMvx, mvxVester, true);
        timelock.managedSetMinter(esMvx, mvlpVester, true);

        timelock.managedSetHandler(mvxVester, rewardRouter, true);
        timelock.managedSetHandler(mvlpVester, rewardRouter, true);

        timelock.managedSetHandler(feeMvxTracker, mvxVester, true);
        timelock.managedSetHandler(stakedMvlpTracker, mvlpVester, true);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITimelock {
    function setAdmin(address _admin) external;
    function enableLeverage(address _vault) external;
    function disableLeverage(address _vault) external;
    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled) external;
    function signalSetGov(address _target, address _gov) external;
    function managedSetHandler(address _target, address _handler, bool _isActive) external;
    function managedSetMinter(address _target, address _minter, bool _isActive) external;
}