/**
 *Submitted for verification at polygonscan.com on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract staking {
    // Structure to store the data of user
    struct UserData {
        uint256 amount;
        uint256 stakeTime;
        uint256 stakePeriod;
        IERC20 tokenStaked;
        uint256 interst;
    }
    //  mapping in done according to the user wallet address
    mapping(address => UserData) public userData;

    // Stake function to stake to token in the smart contract
    // amount: Token to be hold in for staking in *18
    // tokenAddress: Address of token which has to be staked
    // period: Time period to stake 
    //         1 Week = 604800
    //         2 Week = 1209600
    //         1 month = 2419200
    function stake(uint amount, IERC20 tokenAddress, uint period) external  {
        require(tokenAddress.balanceOf(msg.sender) >= amount, "Balance of token is less");
        UserData storage user = userData[msg.sender];
        user.amount = amount;
        user.stakeTime = block.timestamp;
        user.stakePeriod = period;
        user.tokenStaked = tokenAddress;
        tokenAddress.transferFrom(msg.sender, address(this), amount);

    }

    // Internal function to calculate intrest rate
    function multiplier(address callUser) internal {
            UserData storage user = userData[callUser];
            if(user.stakePeriod >= 604800){
                user.interst = 1000000000000000000;
            }
            if(user.stakePeriod >= 1209600){
                user.interst = 1500000000000000000;
            }
            if(user.stakePeriod >= 604800){
                user.interst = 3000000000000000000;
            }
            
    }

    function unStake( IERC20 tokenAddress ) external {
        multiplier(msg.sender);
        UserData storage user = userData[msg.sender];
        if(user.stakeTime + user.stakePeriod < block.timestamp) {
            uint256 calculatedAmount = user.amount  * user.interst / 100 ** 18;
            tokenAddress.transfer(msg.sender, user.amount + calculatedAmount) ;
        }
        if(user.stakeTime + user.stakePeriod > block.timestamp) {
            uint256 calculatedAmount = user.amount / 1e18 * 10 / 100;
            tokenAddress.transfer(msg.sender, user.amount - calculatedAmount ** 18) ;
        }
        
    }

}