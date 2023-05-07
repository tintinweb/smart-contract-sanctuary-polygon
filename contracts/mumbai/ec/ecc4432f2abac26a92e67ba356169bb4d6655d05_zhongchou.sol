/**
 *Submitted for verification at polygonscan.com on 2023-05-07
*/

//SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.7.0 <0.8.9;

contract zhongchou{
    //投资者投资记录：投资目标，投资金额
    struct toMoney{
        address payable addressReceiptor;
        uint money;
    }
    //投资者基本信息：地址，是否被激活，总投资金额，投资次数，映射记录投资记录
    struct funder{
        address payable addressfunder;
        bool isActive;
        uint totalMoney;
        uint numberGive;
        mapping(uint=>toMoney)expMap;
    }
    //众筹合约：合约创建者，是否被激活，金额总需求，已投资金额，投资人数量，映射记录投资人
    struct needMoneyContract{
        address payable addressNeeder;
        // payable address addressContract;
        bool isActive;
        uint totalMoney;
        uint giveMoney;
        uint amountFunder;
        mapping (uint=>funder)mapFunder;
    }
    //众筹发起者：地址，激活状态，需求总金额，已经被投资的金额，发起的众筹的数量，映射记录投资合约
    struct needer{
        address addressNeeder;
        bool isActive;
        uint amountMoneyNeed;
        uint amountHasFunded;
        uint numberContract;
        mapping(uint=>needMoneyContract)expMap;
    }
    //记录众筹合约总数，合约地址（资金池地址）
    uint amountContract;
    address payable public addressFinance; 
    //三方数组
    mapping(address=>funder)funderMap;
    mapping(uint=>needMoneyContract)contractMap;
    mapping(address=>needer)neederMap;
    
    constructor(){
        addressFinance=payable(msg.sender);
    }
    //创建一个众筹发起者
    function createNeeder()public returns(bool){
        //需要判定是否已经被激活
        if(neederMap[msg.sender].isActive){
            return false;
        }
        else{
            address _addressNeeder=msg.sender;
            //0.8.0后不允许直接创建一个包含映射的结构体。需要通过引用的方式，先创建一个storage类型的结构体（与目标是引用关系），再对新变量进行操作即可。
            needer storage tmp1=neederMap[_addressNeeder];
            tmp1.addressNeeder=_addressNeeder;
            tmp1.isActive=true;
            tmp1.amountMoneyNeed=0;
            tmp1.amountHasFunded=0;
            tmp1.numberContract=0;
            return true;
        }
    }
    
    function createContract(
        uint _amountMoneyNeed
    )public returns(bool){
        address _addressNeeder=msg.sender;
        uint tmpNum=amountContract++;
        needMoneyContract storage tmp2=contractMap[tmpNum];
        tmp2.addressNeeder=payable(_addressNeeder);
        tmp2.isActive=true;
        tmp2.totalMoney=_amountMoneyNeed;
        tmp2.giveMoney=0;
        tmp2.amountFunder=0;
        uint tmpContract=neederMap[_addressNeeder].numberContract++;
        neederMap[_addressNeeder].amountMoneyNeed+=_amountMoneyNeed;
        needMoneyContract storage tmp3=neederMap[_addressNeeder].expMap[tmpContract];
        needMoneyContract storage tmp4=contractMap[tmpNum];
        tmp3=tmp4;
        return true;
    }
    
    function createFunder()public returns(bool){
        if(funderMap[msg.sender].isActive){
            return false;
        }
        else{
            address _address=msg.sender;
            funder storage tmpfund=funderMap[_address];
            tmpfund.addressfunder=payable(_address);
            tmpfund.isActive=true;
            tmpfund.totalMoney=0;
            tmpfund.numberGive=0;
            return true;
        }
    }
    
    function donateMoney(
        uint money,
        uint idContract,
        address addressNeeder
    ) public payable returns(bool){
        require(contractMap[idContract].isActive==true);
        require(money==msg.value);
        require(contractMap[idContract].addressNeeder==addressNeeder);
        // payable address adressDonate=msg.sender;
        address tmpfunder=msg.sender;
        funderMap[tmpfunder].totalMoney+=money;
        toMoney storage tmpMoney=funderMap[tmpfunder].expMap[funderMap[tmpfunder].numberGive];
        tmpMoney.addressReceiptor=payable(addressNeeder);
        tmpMoney.money=money;
        funderMap[tmpfunder].numberGive++;
        contractMap[idContract].giveMoney+=money;
        funder storage tmpfund1=contractMap[idContract].mapFunder[contractMap[idContract].amountFunder++];
        funder storage tmpfund2=funderMap[tmpfunder];
        tmpfund1=tmpfund2;
        return true;
    }
    
    function isComplete(uint idContract)public payable returns(bool){
        require(contractMap[idContract].isActive==true);
        require(contractMap[idContract].addressNeeder==msg.sender);
        require(contractMap[idContract].totalMoney<=contractMap[idContract].giveMoney);
        needMoneyContract storage tmptrans=contractMap[idContract];
        tmptrans.isActive=false;
        address tmpaddr=msg.sender;
        uint getMoney=tmptrans.giveMoney;
        neederMap[tmpaddr].amountHasFunded+=getMoney;
        tmptrans.addressNeeder.transfer(getMoney);
        return true;
    }
}