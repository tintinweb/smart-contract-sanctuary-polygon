import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPrediction.sol";
import "../interfaces/IMintTeams.sol";

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MintTeamsTwo is Ownable {
    event LevelUp(address account, uint indexed tokenId, uint256 indexed level);
    address public evolveAddress;
    address public predictionAddress;
    address public  mintTeamsOneAddress;
    address public setAddress;
   bytes[32] worldCupTeams;
   constructor(address _setAddress) {
      setAddress = _setAddress;
      //Group A
         worldCupTeams[0] = abi.encode("Qatar");
         worldCupTeams[1] = abi.encode("Ecuador");
         worldCupTeams[2] = abi.encode("Senegal");
         worldCupTeams[3] = abi.encode("Netherlands");

        //Group B
         worldCupTeams[4] = abi.encode("England");
         worldCupTeams[5] = abi.encode("IR Iran");
         worldCupTeams[6] = abi.encode("USA");
         worldCupTeams[7] = abi.encode("Wales");

         //Group C
         worldCupTeams[8] = abi.encode("Argentina");
         worldCupTeams[9] = abi.encode("Saudi Arabia");
         worldCupTeams[10] = abi.encode("Mexico");
         worldCupTeams[11] = abi.encode("Poland");

         //Group D
         worldCupTeams[12] = abi.encode("France");
         worldCupTeams[13] = abi.encode("Australia");
         worldCupTeams[14] = abi.encode("Denmark");
         worldCupTeams[15] = abi.encode("Tunisia");

         //Group E
         worldCupTeams[16] = abi.encode("Spain");
         worldCupTeams[17] = abi.encode("Costa Rica");
         worldCupTeams[18] = abi.encode("Germany");
         worldCupTeams[19] = abi.encode("Japan");

         //Group F
         worldCupTeams[20] = abi.encode("Belgium");
         worldCupTeams[21] = abi.encode("Canada");
         worldCupTeams[22] = abi.encode("Morocco");
         worldCupTeams[23] = abi.encode("Croatia");

         //Group G
         worldCupTeams[24] = abi.encode("Brazil");
         worldCupTeams[25] = abi.encode("Serbia");
         worldCupTeams[26] = abi.encode("Switzerland");
         worldCupTeams[27] = abi.encode("Cameroon");

         //Group H
         worldCupTeams[28] = abi.encode("Portugal");
         worldCupTeams[29] = abi.encode("Ghana");
         worldCupTeams[30] = abi.encode("Uruguay");
         worldCupTeams[31] = abi.encode("Korea Republic");
   }
    function setPredictionAddress(address _predictionAddress) public {
      require(msg.sender == setAddress, "USER_CANT_CALL_FUNCTION");
       predictionAddress = _predictionAddress;
    }

    function setEvolveAddress(address _evolveAddress) public {
      require(msg.sender == setAddress, "USER_CANT_CALL_FUNCTION");
       evolveAddress = _evolveAddress;
    }

     function setMintTeamOneAddress(address _mintTeamsOneAddress) public {
      require(msg.sender == setAddress, "USER_CANT_CALL_FUNCTION");
      mintTeamsOneAddress = _mintTeamsOneAddress;
    }

     function claimLevel3Nft(address _predictor, string calldata _teamName) public {
      require(msg.sender == evolveAddress, "USER_CANT_CALL_FUNCTION");
      bool isTop8 = IPrediction(predictionAddress).isPhase8();
      require(isTop8 == true, "TOP_8_HASNT_FINISHED");
      if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[0])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 1, 1);
         IMintTeams(mintTeamsOneAddress).mint(_predictor, 2, 1, "");
        emit LevelUp(_predictor, 2, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[1])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 5, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 6, 1, "");
         emit LevelUp(_predictor, 6, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[2])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 9, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 10, 1, "");
         emit LevelUp(_predictor, 10, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[3])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 13, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 14, 1, "");
          emit LevelUp(_predictor, 14, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[4])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 17, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 18, 1, "");
         emit LevelUp(_predictor, 18, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[5])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 21, 1);
           IMintTeams(mintTeamsOneAddress).mint(_predictor, 22, 1, "");
         emit LevelUp(_predictor, 22, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[6])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 25, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 26, 1, "");
         emit LevelUp(_predictor, 26, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[7])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 29, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 30, 1, "");
         emit LevelUp(_predictor, 30, 3);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[8])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 33, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 34, 1, "");
         emit LevelUp(_predictor, 34, 3);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[9])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 37, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 38, 1, "");
         emit LevelUp(_predictor, 38, 3);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[10])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 41, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 42, 1, "");
         emit LevelUp(_predictor, 42, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[11])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 45, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 46, 1, "");
         emit LevelUp(_predictor, 46, 3);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[12])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 49, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 50, 1, "");
         emit LevelUp(_predictor, 50, 3);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[13])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 53, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 54, 1, "");
         emit LevelUp(_predictor, 54, 3);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[14])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 57, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 58, 1, "");
         emit LevelUp(_predictor, 58, 3);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[15])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 61, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 62, 1, "");
         emit LevelUp(_predictor, 62, 3);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[16])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 65, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 66, 1, "");
         emit LevelUp(_predictor, 66, 3);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[17])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 69, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 70, 1, "");
         emit LevelUp(_predictor, 70, 3);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[18])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 73, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 74, 1, "");
         emit LevelUp(_predictor, 74, 3);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[19])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 77, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 78, 1, "");
         emit LevelUp(_predictor, 78, 3);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[20])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 81, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 82, 1, "");
         emit LevelUp(_predictor, 82, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[21])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 85, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 86, 1, "");
         emit LevelUp(_predictor, 86, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[22])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 89, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 90, 1, "");
         emit LevelUp(_predictor, 90, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[23])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 93, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 94, 1, "");
         emit LevelUp(_predictor, 94, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[24])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 97, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 98, 1, "");
         emit LevelUp(_predictor, 98, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[25])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 101, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 102, 1, "");
         emit LevelUp(_predictor, 102, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[26])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 105, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 106, 1, "");
         emit LevelUp(_predictor, 106, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[27])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 109, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 110, 1, "");
         emit LevelUp(_predictor, 110, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[28])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 113, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 114, 1, "");
         emit LevelUp(_predictor, 114, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[29])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 117, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 118, 1, "");
         emit LevelUp(_predictor, 118, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[30])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 121, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 122, 1, "");
         emit LevelUp(_predictor, 122, 3);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[31])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 125, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 126, 1, "");
         emit LevelUp(_predictor, 126, 3);
      }
    } 

     function claimLevel4Nft(address _predictor, string calldata _teamName) public {
      require(msg.sender == evolveAddress, "USER_CANT_CALL_FUNCTION");
      bool isTop4 = IPrediction(predictionAddress).isPhase4();
      require(isTop4 == true, "TOP_4_HASNT_FINISHED");
      if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[0])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 2, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 3, 1, "");
        emit LevelUp(_predictor, 3, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[1])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 6, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 7, 1, "");
         emit LevelUp(_predictor, 7, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[2])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 10, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 11, 1, "");
         emit LevelUp(_predictor, 11, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[3])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 14, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 15, 1, "");
          emit LevelUp(_predictor, 15, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[4])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 18, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 19, 1, "");
         emit LevelUp(_predictor, 19, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[5])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 22, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 23, 1, "");
         emit LevelUp(_predictor, 23, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[6])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 26, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 27, 1, "");
         emit LevelUp(_predictor, 27, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[7])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 30, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 31, 1, "");
         emit LevelUp(_predictor, 31, 4);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[8])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 34, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 35, 1, "");
         emit LevelUp(_predictor, 35, 4);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[9])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 38, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 39, 1, "");
         emit LevelUp(_predictor, 39, 4);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[10])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 42, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 43, 1, "");
         emit LevelUp(_predictor, 43, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[11])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 46, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 47, 1, "");
         emit LevelUp(_predictor, 47, 4);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[12])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 50, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 51, 1, "");
         emit LevelUp(_predictor, 51, 4);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[13])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 54, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 55, 1, "");
         emit LevelUp(_predictor, 55, 4);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[14])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 58, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 59, 1, "");
         emit LevelUp(_predictor, 59, 4);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[15])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 62, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 63, 1, "");
         emit LevelUp(_predictor, 63, 4);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[16])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 66, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 67, 1, "");
         emit LevelUp(_predictor, 67, 4);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[17])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 70, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 71, 1, "");
         emit LevelUp(_predictor, 71, 4);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[18])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 74, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 75, 1, "");
         emit LevelUp(_predictor, 75, 4);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[19])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 78, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 79, 1, "");
         emit LevelUp(_predictor, 79, 4);
      }  else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[20])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 82, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 83, 1, "");
         emit LevelUp(_predictor, 83, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[21])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 86, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 87, 1, "");
         emit LevelUp(_predictor, 87, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[22])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 90, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 91, 1, "");
         emit LevelUp(_predictor, 91, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[23])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 94, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 95, 1, "");
         emit LevelUp(_predictor, 95, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[24])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 98, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 99, 1, "");
         emit LevelUp(_predictor, 99, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[25])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 102, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 103, 1, "");
         emit LevelUp(_predictor, 103, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[26])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 106, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 107, 1, "");
         emit LevelUp(_predictor, 107, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[27])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 110, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 111, 1, "");
         emit LevelUp(_predictor, 111, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[28])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 114, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 115, 1, "");
         emit LevelUp(_predictor, 115, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[29])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 118, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 119, 1, "");
         emit LevelUp(_predictor, 119, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[30])) {
          IMintTeams(mintTeamsOneAddress).burn(_predictor, 122, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 123, 1, "");
         emit LevelUp(_predictor, 123, 4);
      } else if(keccak256(abi.encode(_teamName)) == keccak256(worldCupTeams[31])) {
         IMintTeams(mintTeamsOneAddress).burn(_predictor, 126, 1);
          IMintTeams(mintTeamsOneAddress).mint(_predictor, 127, 1, "");
         emit LevelUp(_predictor, 127, 4);
      }
    } 
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IPrediction {
   function changeThePhase() external;
   function setFirstPrediction(address _predictor, bytes memory _team) external;
   function setSecondPrediction(address _predictor, bytes memory _team) external;
   function setThirdPrediction(address _predictor, bytes memory _team) external;
   function setFourthPrediction(address _predictor, bytes memory _team) external;
   function setFifthPrediction(address _predictor, bytes memory _team) external;
   function setSixthPrediction(address _predictor, bytes memory _team) external;
   function getPrediction(address _predictor, uint _num) external view returns(bytes memory team);
   function isPhase32() external view returns(bool);
   function isPhase16() external view returns(bool);
   function isPhase8() external view returns(bool);
   function isPhase4() external view returns(bool);
   function haveYouMinted(address _predictor) external view returns(bool);
   function mintedExtraTwo(address _predictor) external view returns(bool);
   function changedOrder(address _predictor, uint _num) external view returns(bool);
   function setOrder(address _predictor, uint _num) external;
   function hasItBeenThreeMinutes() external view returns(bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMintTeams {
    function claimLevel1Nft(address _predictor, string calldata _teamName) external;
    function claimLevel2Nft(address _predictor, string calldata _teamName) external;
    function claimLevel3Nft(address _predictor, string calldata _teamName) external;
    function claimLevel4Nft(address _predictor, string calldata _teamName) external;
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address from, uint id, uint amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}