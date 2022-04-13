/**
 *Submitted for verification at polygonscan.com on 2022-04-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

  
    event Approval(address indexed owner, address indexed spender, uint256 value);

   
    function totalSupply() external view returns (uint256);

   
    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address to, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

  
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract distributeToken {
    bool internal locked;
    address public auth;
    address public auth2;
    IERC20 public token;
    struct UserData {
        address wallet;
        uint256 amt;
        bool claimed;
    }
    

    mapping(address=>UserData) public userData;

    constructor(IERC20 add) {
        token = add;
        auth = msg.sender;
    }
    modifier onlyAuth {
        require(isAuthorized(msg.sender));
        _;
    }

    modifier nonReentrancy() {
        require(!locked, "No reentrancy allowed");

        locked = true;
        _;
        locked = false;
    }

    function isAuthorized(address src) internal view returns (bool) {
        if(src == auth){
            return true;
        } else if (src == auth2) {
            return true;
        } else return false;
    }

    function setAuthority(address auth2_) public onlyAuth {
        auth2 = auth2_;
    }

    function feedData(address wallet_, uint256 amt_) public onlyAuth {
        userData[wallet_] = UserData(
            wallet_,
            amt_,
            false
        );
    }


    function claim() nonReentrancy public {
        require(userData[msg.sender].claimed == false, "Already Claimed");
        userData[msg.sender].claimed = true;
        uint256 useramt = userData[msg.sender].amt;
        token.transfer(msg.sender, useramt);
    }

    function userAmt(address add_) public view returns (uint256) {
        uint256 udata_ = userData[add_].amt;
        return udata_;
    }

    function  userStatus(address add_) public view returns (bool) {
        bool udata_ = userData[add_].claimed;
        return udata_;
    }

}