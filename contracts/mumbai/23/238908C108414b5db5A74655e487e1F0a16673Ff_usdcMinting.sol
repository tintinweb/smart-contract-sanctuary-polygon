// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IERC20{
    function transferFrom(address _from,address _to,uint256 _amount) external returns(bool);
    function transfer(address _to,uint256 _amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
}

contract usdcMinting{

    /********State Variables***********/
    address susdAddress;
    address owner;

    constructor(address _susdAddress){
        susdAddress = _susdAddress;
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "not authorized");
        _;
    }

    /***********Event**************/
    event mintedSuccefully(address indexed minter, uint indexed amount, uint timeOfminting);
    event addressChanged(address indexed _newTokenAddress);


    /**********Error*********/
    error minted(string);
    error insufficient(string);

    mapping(address => bool) mint;

    /// @dev function for user to mint token
    function mintToken() public {
        if(mint[msg.sender] == true){
            revert minted("Already Minted");
        }
        uint amount = 10 * 1e18;
        if(IERC20(susdAddress).balanceOf(address(this)) < amount){
            revert insufficient("insufficient contract balance");
        }
        
        mint[msg.sender] = true;
        IERC20(susdAddress).transfer(msg.sender, amount);

        emit mintedSuccefully(msg.sender, 10 * 1e18, block.timestamp);
    }

    /// @dev function to return the token balance of the contract
    function bal() public view onlyOwner returns(uint){
        return IERC20(susdAddress).balanceOf(address(this));
    }

    /// @dev function to change the tokenaddress 
    function changeTokenAddress(address _newTokenAddress) public onlyOwner {
        susdAddress = _newTokenAddress;
        emit addressChanged(_newTokenAddress);
    }


}