// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;



contract Source {

    address public txOrigin;
    uint    dataU;
    uint256 dataU256;
    bool    dataB;
    address[] public AddressL;

    struct Info{
         uint      num;
         string    str;
    }

    Info handle;
    
    /*
    constructor(Info memory _data) {
            handle=_data;
        }
     */

    constructor() {}
     

    //输出日志
    event msgStruct(address addr,Info _data);
    event msgList(address addr, address[] _data);
    event msgUint(address addr,uint _data);
    event msgB(address addr,bool _data);
   


    //第一种数据模式
    function setUnit (uint _data)  public returns(address,uint) {

         txOrigin = tx.origin;
         dataU=_data+1;

        emit msgUint(txOrigin,_data);

        return (txOrigin,dataU);
    }


    //第二种数据模式  
    function setUnit256 (uint256 _data)  public returns(address,uint256) {

         txOrigin = tx.origin;
         dataU256=_data+1;

         emit msgUint(txOrigin,_data);

         return (txOrigin,dataU256);
    }

    //第三种数据模式
        function setB (bool _data)  public returns(address,bool) {

         txOrigin = tx.origin;
         dataB=_data;

        emit msgB(txOrigin,_data);

         return (txOrigin,dataB);
    }


    //第四种数据模式
    function setaddress (address[] memory _data)  public returns(address,address[] memory) {

         txOrigin = tx.origin;
         AddressL=_data;

         emit msgList(txOrigin,_data);

         return (txOrigin,AddressL);
    }
    

    // 第五种数据方式
        function setStruct (Info memory _data)  public returns(address,Info memory) {

         txOrigin = tx.origin;
         handle=_data;

         emit msgStruct(txOrigin,_data);

         return (txOrigin,handle);
    }
    



}