// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./interfaces/IERC20.sol";

contract StakingWarmup {

    address public immutable staking;
    address public immutable sISA;

    constructor ( address _staking, address _sISA ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _sISA!= address(0) );
        sISA = _sISA;
    }

    function retrieve( address _staker, uint _amount ) external {
        require( msg.sender == staking );
        IERC20( sISA).transfer( _staker, _amount );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5 <=0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}