// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IMasterChefV2UserInfo {
    function userInfo(uint256 pid, address account) external view returns (uint256, uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IOpenDAOStaking is IERC20 {
    function getSOSPool() external view returns(uint256);
}

contract OpenDAOCombinedPolygon {
    IMasterChefV2UserInfo public constant _chefV2 = IMasterChefV2UserInfo(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);
    IERC20 public constant _sosWETHPair = IERC20(0x54Ad8907dEdb498235f5A55D73F6A157f731D7B7);
    IERC20 public constant _sosToken = IERC20(0x8c059898ca6274750b6bF1cf38F2848347C490cc);

    uint256 private constant SOS_WETH_POOL_ID = 56;

    function balanceOf(address account) external view returns (uint256) {
        return getBalance(account, _chefV2, _sosToken, _sosWETHPair);
    }

    function getBalance(address account, IMasterChefV2UserInfo chefV2, IERC20 sosToken, IERC20 sosWETHPair) public view returns (uint256) {
        uint256 sosBalance = sosToken.balanceOf(account);

        // LP Provider

        (uint256 lpStakedBalance, ) = chefV2.userInfo(SOS_WETH_POOL_ID, account);
        uint256 lpUnstaked = sosWETHPair.balanceOf(account);
        uint256 lpBalance = lpStakedBalance + lpUnstaked;

        uint256 lpAdjustedBalance = lpBalance * sosToken.balanceOf(address(sosWETHPair)) / sosWETHPair.totalSupply() * 2;

        // Sum them up!

        uint256 combinedSOSBalance = sosBalance + lpAdjustedBalance;
        return combinedSOSBalance;
    }

    function totalSupply() external view returns (uint256) {
        return getSupply(_sosToken, _sosWETHPair);
    }

    function getSupply(IERC20 sosToken, IERC20 sosWETHPair) public view returns (uint256) {
        return sosToken.totalSupply() + sosToken.balanceOf(address(sosWETHPair));
    }

    function name() external pure returns (string memory) { return "cSOS"; }
    function symbol() external pure returns (string memory) { return "OpenDAOCombinedPolygon"; }
    function decimals() external view returns (uint8) { return _sosToken.decimals(); }
    function allowance(address, address) external pure returns (uint256) { return 0; }
    function approve(address, uint256) external pure returns (bool) { return false; }
    function transfer(address, uint256) external pure returns (bool) { return false; }
    function transferFrom(address, address, uint256) external pure returns (bool) { return false; }
}