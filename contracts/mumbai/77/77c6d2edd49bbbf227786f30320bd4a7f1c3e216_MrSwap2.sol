// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract MrSwap2 is ReentrancyGuard, Ownable{

    using SafeERC20 for IERC20;

    event TokenPerUSDPriceUpdated(uint256 amount);
    event UsdtToSusdSwapped(address user, uint256 amount);
    event SusdToUsdtSwapped(address user, uint256 amount);
    
    IERC20 public immutable susdAddress;
    IERC20 public immutable usdtAddress;

    uint256 public susdAmountPerUSDT;

    constructor(IERC20 _susdAddress, IERC20 _usdtAddress, uint256 _susdAmountPerUSDT) {
        susdAddress = _susdAddress;
        usdtAddress = _usdtAddress;
        susdAmountPerUSDT = _susdAmountPerUSDT;
    }

    function swapUsdtToSusd(uint256 usdtAmount) external nonReentrant{
        require(usdtAmount > 0, "Invalid token amount");
            uint256 amount = getUsdtToSusdRate(usdtAmount);
            IERC20(usdtAddress).safeTransferFrom(
                msg.sender,
                address(this),
                usdtAmount
            );
        susdAddress.safeTransfer(msg.sender, amount);
        emit UsdtToSusdSwapped(msg.sender, amount);
    }

    function swapSusdToUsdt(uint256 susdAmount) external nonReentrant{
        require(susdAmount > 0, "Invalid token amount");
            uint256 amount = getSusdToUsdtRate(susdAmount);
            IERC20(susdAddress).safeTransferFrom(
                msg.sender,
                address(this),
                susdAmount
            );
        usdtAddress.safeTransfer(msg.sender, amount);
        emit SusdToUsdtSwapped(msg.sender, amount);
    }
    
    function recoverToken(address tokenAddress, address walletAddress, uint256 amount)
        external
        onlyOwner
    {
        require(walletAddress != address(0), "Null address");
        require(amount <= IERC20(tokenAddress).balanceOf(address(this)), "Insufficient amount");
        IERC20(tokenAddress).safeTransfer(
            walletAddress,
            amount
        );
    }
    
    function setSusdPricePerUSDT(uint256 susdAmount)
        external
        onlyOwner
    {
        susdAmountPerUSDT = susdAmount;
        emit TokenPerUSDPriceUpdated(susdAmountPerUSDT);
    }
    
    function getSusdToUsdtRate(uint256 tokenAmount)
        public
        view
        returns (uint256 amount)
    {
        amount = ((tokenAmount * 1e6 / susdAmountPerUSDT) * 1e6)/1e6;
    }

    function getUsdtToSusdRate(uint256 tokenAmount)
        public
        view
        returns (uint256 amount)
    {
        amount = (tokenAmount * susdAmountPerUSDT) / 1e6;
    }

}