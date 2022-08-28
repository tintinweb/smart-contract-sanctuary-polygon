/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

//SPDX-License-Identifier: MIT;
pragma solidity ^0.8.7;

//import "./DisasterData.sol";

interface DisasterDatai{
    function setSeverity(string memory district, uint newSeverity) external;
    function getSeverityData(string memory district, uint day) external view returns (uint); 
    function getDistricts() external pure returns (string memory) ;
    function getAccumulatedSeverity(string memory district) external view returns (uint) ;
    function cumulSeverity() external view returns(uint);
}


contract InsurPrem {

    uint public totpool=0;//total amount collected
    uint public totfarmers=0;
    uint public totclc=0;
    bool public trigflag;//if the function is triggered or not
    address public claimacc;

    struct Farmer{
        uint dep;
        uint timed;
        string name;
        string dist;
        bool acc;
        address addr;
        uint clc;
    }


    mapping(address =>Farmer) private farmers;

    DisasterDatai DI=DisasterDatai(0xCdE8F3E097B900C4B00cd302bCAF400a5386836e);
    
    // uint public avgsev=DI.cumulSeverity()/36;

    function newAccount(string memory _name,string memory _dist,address _addr) public{
        farmers[_addr].addr=msg.sender;      
        farmers[_addr].timed=block.timestamp;       
        farmers[_addr].acc=true;
        farmers[_addr].name=_name;
        farmers[_addr].dist=_dist;
        farmers[_addr].dep=0;
        
        totfarmers+=1;
    }

    function deposit(address _addr,uint _dep)public payable{
        require(_addr==msg.sender);
        require(trigflag==false);
        
        farmers[_addr].dep+=_dep;
        totpool+=_dep;

        uint tc=(_dep*100000)/((block.timestamp)/5 minutes);  //deposit to be more and time to be less
        farmers[_addr].clc+=tc;
        totclc+=tc;

    }

    function getName(address _addr)public view returns (string memory){
        return farmers[_addr].name;
    }

    function getDistrict(address _addr) public view returns (string memory){
        return farmers[_addr].dist;
    }

    function getBal(address _addr) public view returns (uint ){
        return farmers[_addr].dep;
    }

    function accExists(address _addr) public view returns(bool ){
        return farmers[_addr].acc;
    }

    function getTime(address _addr) public view returns(uint){
        return farmers[_addr].timed;
    }

    function getClc(address _addr) public view returns(uint){
        return farmers[_addr].clc;
    }
    function claimIns(address _addr) public returns(uint){
        
        require(trigflag==true);
        claimacc=_addr;
        // uint distsev=DI.getAccumulatedSeverity(farmers[_addr].dist);
        uint finval;
        // uint compenfactrs=(farmers[_addr].dep/totpool)*(distsev/avgsev)*(farmers[_addr].clc);
        
        // if(distsev>avgsev){
        //     finval=farmers[_addr].dep+(farmers[_addr].dep)*compenfactrs;
        // }

        // finval=(farmers[_addr].dep)*compenfactrs;

        return finval;
    }

    // function compClaim(address _addr) view {

    // }

    

    function TrigInsur()public payable {
        // require(DI.cumulSeverity()>70);
        require(totpool>5000);
        //add no. of farmers suffering 
        trigflag=true;
    }
    

    
}