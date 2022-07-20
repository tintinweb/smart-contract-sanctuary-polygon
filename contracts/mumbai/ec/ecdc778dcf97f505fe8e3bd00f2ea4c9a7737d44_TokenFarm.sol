/**
 *Submitted for verification at polygonscan.com on 2022-07-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract TokenFarm {		
	string public name = "Dapp Token Farm";
	address public owner;
	IERC20Token public happyToken;
	IERC20Token public daiToken;	

    uint256 month = 2629743;


    struct Staker {

        uint8 timestamp;
    }

	address[] public stakers;
	mapping(address => uint) public stakingBalance;
	mapping(address => bool) public hasStaked;
	mapping(address => bool) public isStaking;
    mapping(address => Staker) public stakes;

   

  


	constructor(IERC20Token _happyToken, IERC20Token _daiToken) public {
		happyToken = _happyToken;
		daiToken = _daiToken;
		owner = msg.sender;
	}

    event Stake(address indexed owner, uint256 id, uint256 amount, uint256 time);
    event UnStake(address indexed owner, uint256 id, uint256 amount, uint256 time, uint256 rewardTokens);

	/* Stakes Tokens (Deposit): An investor will deposit the DAI into the smart contracts
	to starting earning rewards.
		
	Core Thing: Transfer the DAI tokens from the investor's wallet to this smart contract. */
	function stakeTokens(uint _amount) public {				
		// transfer Mock DAI tokens to this contract for staking
		daiToken.transferFrom(msg.sender, address(this), _amount);

		// update staking balance
		stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;		

		// add user to stakers array *only* if they haven't staked already
		if(!hasStaked[msg.sender]) {
			stakers.push(msg.sender);
		}

		// update stakng status
		isStaking[msg.sender] = true;
		hasStaked[msg.sender] = true;

        
	}


    function calculateRate() private view returns(uint8) {
        uint256 time = stakes[msg.sender].timestamp;
        if(block.timestamp - time < month) {
            return 100;
        } else if(block.timestamp - time <  month * 2 ) {
            return 150;
        } else if(block.timestamp - time < 3 * month) {
            return 175;
        } else {
            return 200;
        }
    }

	// Unstaking Tokens (Withdraw): Withdraw money from DApp.
	function unstakeTokens() public {
		// fetch staking balance
		uint balance = stakingBalance[msg.sender];

		// require amount greter than 0
		require(balance > 0, "staking balance cannot be 0");

		// transfer Mock Dai tokens to this contract for staking
		daiToken.transfer(msg.sender, balance);

		// reset staking balance
		stakingBalance[msg.sender] = 0;

		// update staking status
		isStaking[msg.sender] = false;
	}

	/* Issuing Tokens: Earning interest which is issuing tokens for people who stake them.
	Core Thing: Distribute DApp tokens as interes and also allow the investor to unstake their tokens
	from the app so give them interest using the app. */
	function issueTokens() public {
		// only owner can call this function
		require(msg.sender == owner, "caller must be the owner");

		// issue tokens to all stakers
		for (uint i=0; i<stakers.length; i++) {
			address recipient = stakers[i];
			uint balance = stakingBalance[recipient];
			if(balance > 0) {
				happyToken.transfer(recipient, balance);
            
        
			}	
            		
		}
	}

}

interface IERC20Token {
function totalSupply() external returns (uint);
function balanceOf(address tokenlender) external returns (uint balance);
function allowance(address tokenlender, address spender) external returns (uint remaining);
function transfer(address to, uint tokens) external returns (bool success);
function approve(address spender, uint tokens) external returns (bool success);
function transferFrom(address from, address to, uint tokens) external returns (bool success);
event Transfer(address indexed from, address indexed to, uint tokens);
event Approval(address indexed tokenlender, address indexed spender, uint tokens);

}