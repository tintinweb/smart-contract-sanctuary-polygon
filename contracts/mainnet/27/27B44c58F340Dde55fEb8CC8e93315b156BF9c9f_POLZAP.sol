/**
 *Submitted for verification at polygonscan.com on 2022-06-13
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IZap {
    function zap(address token0, address token1, uint256 amount, uint256 minLiquidity) external;
}

contract POLZAP {
    address public owner;
    address public treasury = 0xF3392cf4af3a2583dB1cB00377Ab7495E00b6D01;
    address public BCT = 0x2F800Db0fdb5223b3C3f354886d907A671414A7F;
    IERC20 public CO2 = IERC20(0xc0eB3503F35E736F6c2861FAfcDe9BafF72A50fF);
    IERC20 public SLP = IERC20(0x7Cc4d64f0B7a06Def2545EE9234170B8E109cc43);
    IZap public Zap = IZap(0x82B66Cf68E377e6F207b97C4C6FA7b43D2204322);

    constructor() {
        CO2.approve(address(Zap), 2 ** 256 - 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    function compoundPOL() external {
        CO2.transferFrom(treasury, address(this), 5 * (10 ** 18));

        Zap.zap(
            address(CO2),
            BCT,
            (5 * (10 ** 18)),
            1
        );

        SLP.transfer(treasury, SLP.balanceOf(address(this)));
    }

    function withdraw(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "GFICompounder: external call failed");
        return result;
    }
}