/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.9;



interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract HuskoAirdrop {
    
    bool public is_active = true;
    address public token_address;
    address public owner;
    
    uint256 public airdropAmount = 100;
  
    mapping (address => uint256) public _claimed;
	mapping(address => bool) public AirdropClaimed;
    

    
    
    event TokensReceived(address _sender, uint256 _amount);
    event OwnershipChanged(address _new_owner);

    modifier onlyOwner() {
        require(msg.sender == owner,"Not Allowed");
        _;
    }

    constructor () {
        owner = msg.sender;
        token_address = 0xEc62AA55F5Aac3d2b57126a3851954072763caDB;
    }

    function change_owner(address _owner) onlyOwner public {
        owner = _owner;
        emit OwnershipChanged(_owner);
    }
    
    function setTokensaddress(address _address) onlyOwner public {
        token_address = _address;
    }

    function change_state() onlyOwner public {
        is_active = !is_active;
    }


    function get_balance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
    function change_airdropAmount(uint256 newAmount) public onlyOwner {
        airdropAmount = newAmount;
    }
    
    function claimTokens() public  {
        require(is_active, "This contract is Paused");
    

        IERC20 token = IERC20(token_address);
        uint256 decimal_multiplier = (10 ** token.decimals());
        uint256 tokensToSend = airdropAmount * decimal_multiplier;
        require(token.balanceOf(address(this)) >= tokensToSend, "Insufficient Tokens in stock");
        token.transfer(msg.sender, tokensToSend);
		AirdropClaimed[msg.sender] = true;
    }
   

    // global receive function
    receive() external payable {
        emit TokensReceived(msg.sender,msg.value);
    }    
    
    function withdraw_token(address token) public onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer( msg.sender, balance);
        }
    } 
    function sendValueTo(address to_, uint256 value) internal {
        address payable to = payable(to_);
        (bool success, ) = to.call{value: value}("");
        require(success, "Transfer failed.");
    }
    function withdraw_bnb() public onlyOwner {
        sendValueTo(msg.sender, address(this).balance);
    }
    
    fallback () external payable {}
    
}