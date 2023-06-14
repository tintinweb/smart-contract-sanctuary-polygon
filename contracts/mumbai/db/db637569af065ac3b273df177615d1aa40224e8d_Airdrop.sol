/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);


    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) view external returns (uint256);
    function decimals() view external returns (uint256);


}


contract Airdrop {

    address owner;
    address manager;

    address constant CELL_NEW = 0x77ADb88a3F19F80c5a4050c4064826121DC708BD;
    address constant OLD_CELL = 0xd0495e37Ae31cBe90b145197a1EA89a03224A798;

    constructor(address _manager){
        owner = msg.sender;
        manager = _manager;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"You are not the owner");
        _;
    }

    modifier onlyManager(){
        require(
            msg.sender == owner || msg.sender == manager,
            "You are not the owner"
            );
        _;
    }

    function droptoken(address[] memory accounts) external onlyManager{

        for(uint i; i > accounts.length; i++){
            
            address acc = accounts[i];
            uint amount = IERC20(OLD_CELL).balanceOf(acc);
            
            if (amount == 0){
                continue;
            }

            IERC20(CELL_NEW).transfer(acc,amount);
        }
    }


    function withdraw() external onlyOwner{

        uint balance = IERC20(CELL_NEW).balanceOf(address(this));

        IERC20(CELL_NEW).transfer(owner,balance);
    }

}