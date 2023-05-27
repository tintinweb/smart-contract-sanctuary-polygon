/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//资金池合约
contract Bankroll {

    //管理员账号
    address private currentCorpBank =
        0xcE724Ae32dDf98D99ffE73585A2Bb716393c88b7;

    // 记录所有玩家地址
    address[] arrPayAddrTempKeys;
    // 记录玩家以获得资金
    mapping(address => uint256) mapPayAddrTemp; //(address => payVal)
    uint256 public VRFFees; //VRF收取总费用
    uint256 public Ecosystem;//基金总收入
    uint256 public Wager;//总投入


    constructor() {}

    //向资金池转账方法
    function tranform() external payable {
        Wager += msg.value;
    }
    //向用户转账
    function payPlayer(address addr, uint256 val) external {
        payable(addr).transfer(val);
    }
    //向管理账户转账
    function payCorp(uint256 val) external {
        payable(currentCorpBank).transfer(val);
    }

    //获取玩家已经获得的奖金
    function getNumPay() external view returns (uint256) {
        uint256 b;
        for (uint256 i=0; i<arrPayAddrTempKeys.length; i++) 
        {
            b += mapPayAddrTemp[arrPayAddrTempKeys[i]];
        }
        return b;
    }

    //存玩家奖金数据
    function addPayAddrTemp(address _addr, uint256 _val) external payable {
        if (_addr == address(0)) {
            return;
        }
        if (_val == 0) {
            return;
        }
        if (mapPayAddrTemp[_addr] != 0) {
            mapPayAddrTemp[_addr] = mapPayAddrTemp[_addr] + _val;
        } else {
            mapPayAddrTemp[_addr] = _val;
            arrPayAddrTempKeys.push(_addr);
        }
    }

    //玩家提取自己资金
    function payAddrTempByAddr(address _addr) external {
        for (uint256 i = 0; i < arrPayAddrTempKeys.length; i++) {
            if (arrPayAddrTempKeys[i] == _addr) {
                payable(_addr).transfer(mapPayAddrTemp[_addr]);
                delete mapPayAddrTemp[_addr];
                delete arrPayAddrTempKeys[i];
                break;
            }
        }
    }
    
    //计算以收取的VRF费用
    function addVRFFees(uint256 val) external{
        VRFFees += val;
    }
    //计算生态基金总额
    function addEcosystem(uint256 val) external {
        Ecosystem += val;
    }
    //获取账户以获得金额
    function getDataTempByAddr(address _addr) external view  returns (uint256){
        return  mapPayAddrTemp[_addr];
    }
    //提取余额
    function withdrawFunds() external withdrawAddressOnly {
        payable(msg.sender).transfer(this.totalBalance());
    }
    //提取一定余额
    function withdrawFees(uint256 val) external withdrawAddressOnly {
        require(this.totalBalance() >=  val, "");
        payable(msg.sender).transfer(val);
    }

    function totalBalance() external view returns (uint256) {
        return payable(address(this)).balance;
    }

    function getCurrentCorpBank() external view returns (address) {
        return currentCorpBank;
    }

    modifier withdrawAddressOnly() {
        require(msg.sender == currentCorpBank, "only withdrawer can call this");
        _;
    }

    receive() external payable{
       
    }

    //transfer
    struct PayAddr {
        address addr;
        uint256 val;
    }
}