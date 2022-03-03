// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './interfaces/IERC20.sol';
import './interfaces/IPearlERC20.sol';
import './interfaces/IOtterStaking.sol';

contract OtterStakingPearlHelper {
    IOtterStaking public immutable staking;
    IERC20 public immutable CLAM;
    IERC20 public immutable sCLAM;
    IPearlERC20 public immutable PEARL;

    constructor(
        address _staking,
        address _CLAM,
        address _sCLAM,
        address _PEARL
    ) {
        require(_staking != address(0));
        staking = IOtterStaking(_staking);
        require(_CLAM != address(0));
        CLAM = IERC20(_CLAM);
        require(_sCLAM != address(0));
        sCLAM = IERC20(_sCLAM);
        require(_PEARL != address(0));
        PEARL = IPearlERC20(_PEARL);
    }

    function stake(uint256 _amount) external returns (uint256) {
        CLAM.transferFrom(msg.sender, address(this), _amount);
        CLAM.approve(address(staking), _amount);
        staking.stake(_amount, address(this));
        staking.claim(address(this));
        sCLAM.approve(address(PEARL), _amount);
        uint256 pearlAmount = PEARL.wrap(_amount);
        PEARL.transfer(msg.sender, pearlAmount);
        return pearlAmount;
    }

    function unstake(uint256 _amount) external returns (uint256) {
        PEARL.transferFrom(msg.sender, address(this), _amount);
        uint256 clamAmount = PEARL.unwrap(_amount);
        sCLAM.approve(address(staking), clamAmount);
        staking.unstake(clamAmount, true);
        CLAM.transfer(msg.sender, clamAmount);
        return clamAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IERC20Mintable is IERC20 {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;
}

interface IERC20Burnable is IERC20 {
    function burn(address account_, uint256 ammount_) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './IERC20.sol';

interface IPearlERC20 is IERC20 {
    /**
        @notice wrap sCLAM
        @param _amount uint
        @return uint
     */
    function wrap(uint256 _amount) external returns (uint256);

    /**
        @notice unwrap sCLAM
        @param _amount uint
        @return uint
     */
    function unwrap(uint256 _amount) external returns (uint256);

    /**
        @notice converts PEARL amount to sCLAM
        @param _amount uint
        @return uint
     */
    function pearlTosCLAM(uint256 _amount) external view returns (uint256);

    /**
        @notice converts sCLAM amount to PEARL
        @param _amount uint
        @return uint
     */
    function sCLAMToPEARL(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOtterStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;

    function unstake(uint256 _amount, bool _trigger) external;
}