/**
 *Submitted for verification at polygonscan.com on 2022-06-21
*/

// SPDX-License-Identifier: GPL-3.0
  pragma solidity >=0.7.0 <0.9.0;
      
      
      contract noobliensupplychain{
      
          address owner;
          constructor()  {
             owner = msg.sender;
          }
          modifier onlyOwner {
             require(msg.sender == owner);
             _;
          }

        struct dataS{
            string latitude;
            string longitude;
            string treeId;
            string nameOnTree;
            string planteDate;
            string plantedBy;
            string beneficiaryName;
            string projectLocationName;
            string latitude1;
            string longitude2;
            string treeId3;
            string nameOnTree4;
            string planteDate5;
            string plantedBy6;
            string beneficiaryName7;
            string projectLocationName8;
        }

        event Data(dataS);
        dataS[] data;
        function vayuInteract(dataS memory d)public onlyOwner{ 
            data.push(d);
            emit Data(d);
        }
      
        function changeOwner(address newowner) public onlyOwner{
            owner=newowner;
        }
      }