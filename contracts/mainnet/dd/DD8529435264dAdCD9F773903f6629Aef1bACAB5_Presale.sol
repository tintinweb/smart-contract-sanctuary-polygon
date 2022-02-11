/**
 *Submitted for verification at polygonscan.com on 2022-01-31
*/

/**
 *Submitted for verification at FtmScan.com on 2021-10-28
*/

pragma solidity 0.6.0;

interface IErc20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external;
}

contract Presale {
    address payable public owner = msg.sender;
    address public token = 0xA7c008b66BF230B14bd7d4dE9dd998CD41E2E211;
    uint public START_TIME = 1643738400;
    uint public END_TIME = 1643742000;
    uint public price = 6;
    uint public sold;
    
    function buy() external payable {
        require(now >= START_TIME && now <= END_TIME);
        
        uint amount = msg.value / price;
        IErc20(token).transfer(msg.sender, amount);
        owner.transfer(address(this).balance);
        sold += amount;
    }
    
    function returnTokens() public {
        require(msg.sender == owner);
        IErc20(token).transfer(owner, IErc20(token).balanceOf(address(this)));
    }
}