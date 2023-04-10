// SPDX-License-Identifier: MIT
// FundleSwap v1.0.0
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";

contract FundleSwap is Ownable {
    
    bool private swapPauseStatus;
    uint256 private _blackAddressCounter; 

    struct Fee {
        uint256 numerator;
        uint256 denominator;
    }
    Fee public _orderPublicFeeInfo;


    IERC20 private _fusd;
    IERC20 private _usdt;    
 
    mapping(address => bool) private _blackAddress;

    enum swapType {FUSDtoUSDT, USDTtoFUSD}
    
    constructor() {
        //Fundle token ~ USDT
        _fusd = IERC20(0x8de4E8884f0A9141535D0dDd4515508630866B6F);
        _usdt = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
        _orderPublicFeeInfo = Fee(1,100);
    }

    modifier blackAddressControl(){        
        require(!_blackAddress[msg.sender], "blacklisted address");
        _;
    }    

    //FUSD <=> USDT
    function swap(uint256 _amount, swapType _type) external blackAddressControl payable {
        require(!swapPauseStatus, "Swap is paused");

        if (_type == swapType.FUSDtoUSDT) {    

            require(_fusd.allowance(msg.sender, address(this)) >= _amount, "FUSD allowance too low");            
            uint256 toAmount = _amount - _amount * _orderPublicFeeInfo.numerator / _orderPublicFeeInfo.denominator;
            require(_usdt.balanceOf(address(this)) >= toAmount,"There is not enough USDT in the system for the swap");            
            _safeTransferFrom(_fusd, _amount);
            _safeTransferTo(_usdt,toAmount);            

        } else if(_type == swapType.USDTtoFUSD) {

            require(_usdt.allowance(msg.sender, address(this)) >= _amount, "USDT allowance too low");
            uint256 toAmount = _amount - _amount * _orderPublicFeeInfo.numerator / _orderPublicFeeInfo.denominator;
            require(_fusd.balanceOf(address(this)) >= toAmount,"There is not enough FUSD in the system for the swap");
            _safeTransferFrom(_usdt, _amount);
            _safeTransferTo(_fusd,toAmount);            

        } else {
            require(false, "Invalid swap");
        }        
    }

  
    function _safeTransferFrom(
        IERC20 _token,
        uint256 _amount
    ) private {
        bool response = _token.transferFrom(msg.sender, address(this), _amount);
        require(response, "Token transfer failed");
    }

    function _safeTransferTo(
        IERC20 _token,
        uint256 _amount
    ) private {
        bool response = _token.transfer(msg.sender, _amount);
        require(response, "Token transfer failed");
    }

    function putBlackAddressStatus(address _user, bool _status) external onlyOwner {                
        require(_user != owner(), "Not possible to add owner");             
        _blackAddress[_user] = _status;
        _blackAddressCounter = _status ? _blackAddressCounter++ : _blackAddressCounter--;
    }
    
    function getBackAddressStatus(address _user) external onlyOwner view returns(bool)
    {return _blackAddress[_user];}

    function putSwapAddress(address _fusdAddress, address _usdtAddress) external onlyOwner {        
        _fusd = IERC20(_fusdAddress);
        _usdt = IERC20(_usdtAddress);
    }

    function putSwapFee(uint256 numerator, uint256 denominator) external onlyOwner {        
        _orderPublicFeeInfo.numerator = numerator;
        _orderPublicFeeInfo.denominator = denominator;
    }

    function getSwapInfo() external view returns(Fee memory)
    {return _orderPublicFeeInfo;}

    function putSwapPauseStatus() external onlyOwner {
        swapPauseStatus = !swapPauseStatus;
    }

    function putSwapFeeMultiplier(uint256 _numerator, uint256 _denominator) external onlyOwner {
        require(_denominator != 0, "Invalid request");
        _orderPublicFeeInfo.numerator = _numerator;
        _orderPublicFeeInfo.denominator = _denominator;
    }

    function withdrawTokens(address tokenAddress) external onlyOwner {
        //require(msg.sender == owner, "Only owner can withdraw tokens");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "Failed to transfer tokens");
    }
    
    function putWithdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }   
}