/**
 *Submitted for verification at polygonscan.com on 2023-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bankroll {

    address public currentCorpBank =
        0xcE724Ae32dDf98D99ffE73585A2Bb716393c88b7;
    address public HorsemanLite;

    address[] arrPayAddrTempKeys;
   
    mapping(address => uint256) mapPayAddrTemp;
    uint256 public VRFFees;
    uint256 public Ecosystem;
    uint256 public Wager;
    uint256 public Withdraw;

    constructor() {
        
    }


    modifier isHorsemanLite() {
        require(msg.sender == HorsemanLite, "HorsemanLite Only");
        _;
    }

    modifier isAdmin() {
        require(msg.sender == currentCorpBank, "Admin Only");
        _;
    }

    function updateAdmin(address addr) isAdmin external {
        currentCorpBank = addr;
    }


    function setHorsemanLite(address addr) isAdmin external {
        HorsemanLite = addr;
    }

    function tranform() isAdmin external payable {
        Wager += msg.value;
    }

    function payPlayer(address addr, uint256 val) isHorsemanLite external {
        payable(addr).transfer(val);
    }

    function getNumPay() isHorsemanLite external view returns (uint256) {
        uint256 b;
        for (uint256 i=0; i<arrPayAddrTempKeys.length; i++) 
        {
            b += mapPayAddrTemp[arrPayAddrTempKeys[i]];
        }
        return b;
    }

    function addPayAddrTemp(address _addr, uint256 _val) isHorsemanLite external {
        if (_addr == address(0) || _val == 0) {
            return;
        }

        if (mapPayAddrTemp[_addr] == 0) {
            arrPayAddrTempKeys.push(_addr);
        }
        mapPayAddrTemp[_addr] = mapPayAddrTemp[_addr] + _val;
    }

    function payAddrTempByAddr(address _addr) isHorsemanLite external {
        for (uint256 i = 0; i < arrPayAddrTempKeys.length; i++) {
            if (arrPayAddrTempKeys[i] == _addr) {
                payable(_addr).transfer(mapPayAddrTemp[_addr]);
                delete mapPayAddrTemp[_addr];
                delete arrPayAddrTempKeys[i];
                break;
            }
        }
    }
    
    function addVRFFees(uint256 val) isHorsemanLite external{
        VRFFees += val;
    }

    function addEcosystem(uint256 val) isHorsemanLite external {
        Ecosystem += val;
    }

    function getDataTempByAddr(address _addr) isHorsemanLite external view  returns (uint256){
        return  mapPayAddrTemp[_addr];
    }

    function withdrawFunds() external isAdmin{
        Withdraw += this.totalBalance();
        payable(msg.sender).transfer(this.totalBalance());
    }

    function withdrawFees(uint256 val) external isAdmin{
        require(this.totalBalance() >=  val, "");
        Withdraw += val;
        payable(msg.sender).transfer(val);
    }

    function totalBalance() external view returns (uint256) {
        return payable(address(this)).balance;
    }

    function isAdminAddr(address addr) isHorsemanLite  external view returns (bool) {
        return currentCorpBank == addr;
    }
	
    receive() external payable{
       
    }
}