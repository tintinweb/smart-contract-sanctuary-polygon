/**
 *Submitted for verification at polygonscan.com on 2022-06-10
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// @web3assetmanager:security-contact [email protected]

interface supplyAsset {
      function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) 
      external;
}

interface withdrawAsset {
   function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}


interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

     function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


contract WEB3AM_aave {
    
    address aaveAdd1 = 0x794a61358D6845594F94dc1DB02A252b5b4814aD; // Pool-polygon-mainnet
    supplyAsset sendToken = supplyAsset(aaveAdd1); 
    withdrawAsset redeemToken =  withdrawAsset(aaveAdd1);
   

    function lend(address _asset,
    uint256 _amount,
    address _onBehalfOf,
    uint16 _referralCode) external {
      IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
      IERC20(_asset).approve(aaveAdd1, _amount);
      sendToken.supply(_asset, _amount, _onBehalfOf, _referralCode);
    }

    function redeem(address _asset,
    address _atoken,
    uint256 _amount,
    address _to) external {
      IERC20(_atoken).transferFrom(msg.sender, address(this), _amount);
      IERC20(_atoken).approve(aaveAdd1, _amount);
      redeemToken.withdraw(_asset, _amount, _to);
    }


}