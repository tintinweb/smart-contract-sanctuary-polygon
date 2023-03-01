/**
 *Submitted for verification at polygonscan.com on 2023-02-28
*/

/*
████████╗ ██████╗ ██████╗  █████╗         ██████╗ ██╗███████╗████████╗██████╗ ██╗██████╗ ██╗   ██╗████████╗██╗ ██████╗ ███╗   ██╗
╚══██╔══╝██╔═══██╗██╔══██╗██╔══██╗        ██╔══██╗██║██╔════╝╚══██╔══╝██╔══██╗██║██╔══██╗██║   ██║╚══██╔══╝██║██╔═══██╗████╗  ██║
   ██║   ██║   ██║██████╔╝███████║        ██║  ██║██║███████╗   ██║   ██████╔╝██║██████╔╝██║   ██║   ██║   ██║██║   ██║██╔██╗ ██║
   ██║   ██║   ██║██╔══██╗██╔══██║        ██║  ██║██║╚════██║   ██║   ██╔══██╗██║██╔══██╗██║   ██║   ██║   ██║██║   ██║██║╚██╗██║
   ██║   ╚██████╔╝██║  ██║██║  ██║        ██████╔╝██║███████║   ██║   ██║  ██║██║██████╔╝╚██████╔╝   ██║   ██║╚██████╔╝██║ ╚████║
   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝        ╚═════╝ ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝    ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
                                                                                                                                                                                                                  
*/

pragma solidity ^0.8.6;

//SPDX-License-Identifier: MIT Licensed

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ToraDistribution{
    IERC20 public TOKEN;

    address payable public  owner;
    uint256 public amount = 10540 ether; 
    uint256 fee = 0.8 ether;
    mapping(address => uint256) public wallets;

    modifier onlyOwner() {
        require(msg.sender == owner, " Not an owner");
        _;
    }

    constructor(address payable _owner, address _TOKEN) {
        owner = payable(_owner);
        TOKEN = IERC20(_TOKEN);
    }
    receive() external payable {}
    function addData(address[] memory wallet)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < wallet.length; i++) {
            wallets[wallet[i]] += amount;
        }
    }

    function Claim() public payable {
        require(wallets[msg.sender]>0, "Boi, you're not Whielisted");
        require(msg.value == fee,"Matic Balance Low");
        TOKEN.transfer(msg.sender, wallets[msg.sender]);
        wallets[msg.sender] = 0;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

      // change amount
    function changeAmount(uint256 _amount) external onlyOwner {
        amount = _amount;
    }

    // change tokens
    function changeToken(address _token) external onlyOwner {
        TOKEN = IERC20(_token);
    }

    // to draw out tokens
    function transferStuckTokens(IERC20 token, uint256 _value)
        external
        onlyOwner
    {
        token.transfer(msg.sender, _value);
    }

       // to draw out tokens
    function transferMatic(uint256 _value)
        external
        onlyOwner
    {
        owner.transfer(_value);
    }
 
}