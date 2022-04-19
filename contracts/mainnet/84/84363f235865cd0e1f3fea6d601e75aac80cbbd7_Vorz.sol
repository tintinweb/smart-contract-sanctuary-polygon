/**
 ______  ______  ______  ______  ______  ______  ______  ______ 
|______||______||______||______||______||______||______||______|
 


██╗░░░██╗░█████╗░██████╗░███████╗
██║░░░██║██╔══██╗██╔══██╗╚════██║
╚██╗░██╔╝██║░░██║██████╔╝░░███╔═╝
░╚████╔╝░██║░░██║██╔══██╗██╔══╝░░
░░╚██╔╝░░╚█████╔╝██║░░██║███████╗
░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝╚══════╝


 ______  ______  ______  ______  ______  ______  ______  ______ 
|______||______||______||______||______||______||______||______|


█▄─▄▄─█▄─▀█▄─▄█─▄─▄─█▄─▄▄─█▄─▄▄▀█─▄─▄─██▀▄─██▄─▄█▄─▀█▄─▄█▄─▀█▀─▄█▄─▄▄─█▄─▀█▄─▄█─▄─▄─█
██─▄█▀██─█▄▀─████─████─▄█▀██─▄─▄███─████─▀─███─███─█▄▀─███─█▄█─███─▄█▀██─█▄▀─████─███
▀▄▄▄▄▄▀▄▄▄▀▀▄▄▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▀▄▄▀▀▄▄▄▀▀▄▄▀▄▄▀▄▄▄▀▄▄▄▀▀▄▄▀▄▄▄▀▄▄▄▀▄▄▄▄▄▀▄▄▄▀▀▄▄▀▀▄▄▄▀▀

█▄─▀█▀─▄█▄─▄▄─█─▄─▄─██▀▄─██▄─█─▄█▄─▄▄─█▄─▄▄▀█─▄▄▄▄█▄─▄▄─█
██─█▄█─███─▄█▀███─████─▀─███▄▀▄███─▄█▀██─▄─▄█▄▄▄▄─██─▄█▀█
▀▄▄▄▀▄▄▄▀▄▄▄▄▄▀▀▄▄▄▀▀▄▄▀▄▄▀▀▀▄▀▀▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀


t.me/vorzofficial
twitter.com/vorzapp
facebook.com/vorzapp
instagram.com/vorzapp  
reddit.com/r/vorz                 

 ______  ______  ______  ______  ______  ______  ______  ______ 
|______||______||______||______||______||______||______||______|
  																		
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Ownable} from "./Ownable.sol";
import {ERC20} from "./ERC20.sol";
import {IERC20} from "./IERC20.sol";


contract Vorz is ERC20, Ownable{

    mapping(address => bool) public isExempt;

    bool public tradingStarted;

    uint256 private maxTxAmount;

    address public teamWallet;


    constructor() ERC20("VORZ", "VORZ"){
        isExempt[msg.sender] = true;
        isExempt[teamWallet] = true;
        maxTxAmount = 100e9 * 10**8;
        _mint(msg.sender, 100e9 * 10**8);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function _transfer(address from, address to, uint256 amount) internal override{
        if(!isExempt[from] && !isExempt[to]){
            require(tradingStarted, "Trading not started yet");
            require(amount <= maxTxAmount, "You are exceeding maxTxAmount");
        }

        super._transfer(from, to, amount);
    }

    function startTrading() external onlyOwner{
        tradingStarted = true;
    }

    function setMaxTxAmount(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10**8;
    }

    function setTeamWallet(address newWallet) external onlyOwner{
        teamWallet = newWallet;
    }

    function setIsExempt(address account, bool state) external onlyOwner{
        isExempt[account] = state;
    }

    function rescueWronglySentTokens(address tokenAddress, uint256 amount) external onlyOwner{
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }

    function getMaxTxAmount() external view returns(uint256){
        return maxTxAmount / 10**8;
    }

}