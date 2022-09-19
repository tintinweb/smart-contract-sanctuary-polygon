/**
 *Submitted for verification at polygonscan.com on 2022-09-19
*/

pragma solidity ^0.8.7; 

contract Gplayv5 {
       event Received(address, uint);
       event Paid(address, uint);
       address owner;
       address GameMaster = 0x60D1b2c4B2960e4ab7d7382D6b18Ee6ab872796B;
       address NFTPOOL = 0x0F3af4Ee0e650097d64f4a78F9166e16E60ceF60;
       mapping(address => uint) public TotalBreadWCollected;
       mapping(address => uint256) public GamesYouPlayed;
       mapping(address => uint256) public GamesYouWon;
       mapping(address => uint256) public GamesYouDraw;

       uint256 GplayPercent = 10;
       uint256 NFTPOOLPercent = 5;
       uint256 PlayerwinPercent = 85;
       uint256 private fromServerCode = 1;

   constructor ()  {
    owner = msg.sender;
   }
      
    modifier onlyOwner(){
           require(msg.sender == owner);
           _;
       }

    function transferowner (address newAddress) onlyOwner public {
        owner = newAddress;
    }  

    function getOwner () public view returns (address) {
        return owner;
    }    

    function ChangePercent (uint256 _GplayPercent , uint256 _NFTPOOLPercent, uint256 _PlayerwinPercent) onlyOwner public {
       NFTPOOLPercent = _NFTPOOLPercent;
       GplayPercent = _GplayPercent;
       PlayerwinPercent  = _PlayerwinPercent;
    }

    function getGplayPercent () public view returns (uint256) {
       return  GplayPercent;
    }

    function getPlayerPercent () public view returns (uint256) {
       return  NFTPOOLPercent;
    }

    function getNFTPOOLAddy () public view returns (address) {
       return NFTPOOL;
    }

    function getGameMasterAddy () public view returns (address) {
       return GameMaster;
    }

    function getNFTPOOLPercent () public view returns (uint256) {
       return  PlayerwinPercent;
    }

    function ChangefromServerCode (uint256 newCode) onlyOwner public {
       fromServerCode = newCode;
    }

    function GetServerCode () onlyOwner public view returns (uint256) {
         return fromServerCode;
    }

   function getContractBalance() public view returns (uint256) { //view amount of ETH the contract contains
       return address(this).balance;
   }

   function ChangeNFTLocation(address newAddy) onlyOwner public {
       NFTPOOL = newAddy;
   }

  function ChangeGameMasterLocation(address newAddy) onlyOwner public {
       GameMaster = newAddy;
   }

   function deposit() external  payable {
   require(msg.value > 0);
   emit Received(msg.sender, msg.value);
   GamesYouPlayed[msg.sender]  += 1;
   }

   function GameEndWithdrawal(address sendPaymentAddress, uint256 value_Stake, uint256 ServerCode ) public payable {
            require(ServerCode == fromServerCode);
            require(GamesYouPlayed[sendPaymentAddress] > 0);

            uint256 GameMasterReward = (value_Stake      * GplayPercent)     /  100;
            uint256 NFTPOOLREWARD =    (value_Stake      * NFTPOOLPercent)   /  100;
            uint256 PlayerReward =     (value_Stake      * PlayerwinPercent) /  100;

            (bool sent, bytes memory data) = sendPaymentAddress.call{value: PlayerReward}("");
             require(sent,  "Failed to send Ether");

            (bool sent1, bytes memory data1) = GameMaster.call{value: GameMasterReward}("");
             require(sent1, "Failed to send Ether");

            (bool sentT, bytes memory dataA) = NFTPOOL.call{value: NFTPOOLREWARD}("");
             require(sentT, "Failed to send Ether");

            TotalBreadWCollected[sendPaymentAddress] += (PlayerReward - (value_Stake / 2));
            GamesYouWon[sendPaymentAddress] += 1;

            emit Paid(msg.sender,  PlayerReward);

   }


  function GameEndDraw(address sendPaymentAddress, uint256 value_Stake, uint256 ServerCode ) public payable {
            require(ServerCode == fromServerCode);
            require(GamesYouPlayed[sendPaymentAddress] > 0);

            uint256 GameMasterReward = (value_Stake * 5) / 100;
            uint256 PlayerReward = (value_Stake * 95)    / 100;

            (bool sent, bytes memory data) = sendPaymentAddress.call{value: PlayerReward}("");
             require(sent,  "Failed to send Ether");

            (bool sent1, bytes memory data1) = GameMaster.call{value: GameMasterReward}("");
             require(sent1, "Failed to send Ether");

            GamesYouDraw[sendPaymentAddress] += 1;

            emit Paid(msg.sender,  PlayerReward);

   }

  function GameSendBack(address sendPaymentAddress, uint256 value_Stake, uint256 ServerCode ) public payable {
            require(ServerCode == fromServerCode);
            require(GamesYouPlayed[sendPaymentAddress] > 0);
            GamesYouPlayed[msg.sender]  -= 1;

            (bool sent, bytes memory data) = sendPaymentAddress.call{value: value_Stake}("");
             require(sent,  "Failed to send Ether");

            emit Paid(msg.sender,  value_Stake);
   }



   fallback() external payable {}
  
   receive() external payable {
       emit Received(msg.sender, msg.value);
   } 

}