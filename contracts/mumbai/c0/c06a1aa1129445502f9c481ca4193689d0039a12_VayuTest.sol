/**
 *Submitted for verification at polygonscan.com on 2022-05-23
*/

// SPDX-License-Identifier: GPL-3.0



      pragma solidity >=0.7.0 <0.9.0;
      
      
      contract VayuTest{
      
          address owner;
          constructor()  {
             owner = msg.sender;
          }
          modifier onlyOwner {
             require(msg.sender == owner);
             _;
          }
      
          event Data(string latitude,string longitude,string treeId,string nameOnTree,string planteDate,string plantedBy,string beneficiaryName,string projectLocationName);
        string[] data;
        function vayuInteract(string[] memory d)
        public onlyOwner
        { for(uint i=0;i<d.length;i++)
                  {
                      data.push(d[i]);
                      
                  }
                  emit Data(d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7]);
        }
      
          function changeOwner(address newowner) public onlyOwner{
              owner=newowner;
          }
      }