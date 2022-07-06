//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8;

import "./IERC20Permit.sol";

contract Vault {

    constructor() {

    }

    /*
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    */
    function depositWithPermit(address _token, address _owner, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        IERC20Permit token = IERC20Permit(_token);
        token.permit(_owner, address(this), amount, deadline, v, r, s);
        token.transferFrom(_owner, address(this), amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8;

interface IERC20Permit {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}