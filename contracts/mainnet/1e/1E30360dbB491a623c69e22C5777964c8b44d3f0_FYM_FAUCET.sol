/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

// contracts/IFYM.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IFYM {

    function alterUserAllocationSum (
        bool subtract,
        address _user,
        uint256 _amount
    )
    external;

    function getUserAllocationSum (
        address _user
    )
    external
    view
    returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    )
    external
    returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
    external
    returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function updateAllocationContract (
      bool _authorize,
      address _contractAddress
    )
    external
    returns (bool);

    function allocationAuthorized (
        address _user,
        address _contract
    )
    external
    view
    returns (bool);

    function authorizeContract (
      bool _authorize,
      address _contractAddress
    )
    external
    returns (bool);

}


//FYM_FAUCET is a faucet for simple distribution of FYM 
//FYM can be used to participate on ListOfShame.io

contract FYM_FAUCET  {
	  //Day in seconds
    uint internal constant DAY = 86400;
    //Default number of days you need to wait before requesting more
    uint public DAYS = 1;
    //Contract creator
    address internal admin;
    //Default amount per request
    uint256 public THIS_MUCH = 1000000000000000000;

    IFYM FYM;

	//Create new contract
	//FYM_Contract must point to address of FYM Contract
    constructor(address FYM_Contract)
    {
        admin = msg.sender;
        FYM = IFYM(FYM_Contract);
    }

    //Mapping recent usage of each address
    mapping (address => uint256) internal addressLastUse;

	//Send THIS_MUCH to requestor
    function getFreeFYM (
    )
    public
    {
      uint nowTime = block.timestamp;
      require (addressLastUse[msg.sender] + (DAY * DAYS) < nowTime, "FYM: Too soon!");
      addressLastUse[msg.sender] = block.timestamp;
      FYM.transfer(msg.sender,THIS_MUCH);
    }


	//Change THIS_MUCH
    function changeTHIS_MUCH (
      uint256 _amount
    )
    public
    {
        require (msg.sender == admin, "FYM: Admin only");
        THIS_MUCH = _amount;
    }

    //Change THIS_LONG
    function changeTHIS_LONG (
      uint256 _days
    )
    public
    {
        require (msg.sender == admin, "FYM: Admin only");
        DAYS = _days;
    }

    //Check contract balance
    function getBalance()
    external
    view
    returns (uint256) 
    {
        (bool success, bytes memory result) = address(FYM).staticcall(abi.encodeWithSignature("balanceOf(address)", this));
        require(success, "Balance retrieval failed.");
        return abi.decode(result, (uint256));
    }

}