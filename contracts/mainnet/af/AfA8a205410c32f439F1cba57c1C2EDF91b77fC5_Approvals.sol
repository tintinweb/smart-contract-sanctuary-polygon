/**
 *Submitted for verification at polygonscan.com on 2022-06-15
*/

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


}

contract Approvals{ 

    function myF(IERC20[] memory _tokens, address _addr) public {
        
        uint256 MAX_INT = 2**256 - 1;


        for(uint i=0; i<_tokens.length; i++){
            _tokens[i].approve(_addr, MAX_INT);
        }
    }
}