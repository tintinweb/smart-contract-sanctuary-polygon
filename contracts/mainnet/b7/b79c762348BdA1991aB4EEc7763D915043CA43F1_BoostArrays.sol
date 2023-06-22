/**
 *Submitted for verification at polygonscan.com on 2023-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IS {
// boostList calls Gas free transactions of individual boosts
       function engageToBeAlive (uint _socialID, address _addr, bytes calldata signature, uint _type, uint _wasGasFree) external;
       function setBoostParameters (address _addr, uint _flips_flipperShare, uint _flips_boostAdminShare, uint _flips_flipper_spotCashBack, uint _flips_usersShare, uint _spot_boostAdminShare, uint _spot_usersShare, uint _spotBusyTime) external;
}
contract BoostArrays {
    address boostFactory;
    address protocol;
    address signer;
    uint lengthBefore=1;
    uint lengthAfter=0;
    uint extendShort =3600;
    uint extendMedium=3600;
    uint extendLong=7200;
    uint maxGasForFree = 1000;
    uint lastContribution = 1814400; //3 weeks or 86 400 sec x 21 days

// array for all Boosts
    struct BoostContracts {
        address boostAdmin;
        address boostContract;
        address ls;
        } 
    mapping(address => BoostContracts[]) public boostList;
    mapping(address => uint)  public boostIndex;

// array for Creatoors Boosts
        struct BoostCreatoors {
        address boostContract;
        uint created;
        }
    mapping (address => BoostCreatoors[]) public creatoor;
    mapping (address => uint) public creatorsIndex;

// array for Users Booosts
    struct EngagedContracts {
        address boostContract;
        uint created;
        }
    mapping (address => EngagedContracts[]) public egagooors;

// array for LeaderBoard
    struct Leaders {
        uint lastContribution;
        string username;
        uint usersRevenue;
        address addr;
        }
    mapping (address => Leaders[]) public leadooors;
    mapping (string => bool) doesCreatorExist; 
    mapping (string => uint) public leadersIndex;

// array for all boosts comming from boost factory
    mapping(address => bool) doesBoostContractExist;

    constructor() {
        protocol = msg.sender;
    }

// change and read last contribution
    function changeLastContribution(uint _lastContribution) external {
        require(msg.sender==protocol, "only owner");
        lastContribution=_lastContribution;
        }
    function getLastContribution() external view returns(uint) {
        return lastContribution;
    }

// Engagement variables
    function setVariables (uint _extendShort, uint _extendMedium, uint _extendLong, uint _maxGasForFree) external {
        require(msg.sender==protocol, "only owner");
        extendShort=_extendShort;
        extendMedium=_extendMedium;
        extendLong=_extendLong;
        maxGasForFree=_maxGasForFree;
    }
// Engagement variables read
    function getExtendShort() external view returns(uint) {
        return extendShort;
    }
     function getExtendMedium() external view returns(uint) {
        return extendMedium;
    }
    function getExtendLong() external view returns(uint) {
        return extendLong;
    }
    function getMaxGasForFree() external view returns(uint) {
        return maxGasForFree;
    }

// Gas free functions
    function engageToBeAlive (address _boostAddress, uint _socialID, address _addr, bytes calldata signature, uint _type, uint _wasGasFree) external {
        IS(_boostAddress).engageToBeAlive (_socialID, _addr, signature, _type, _wasGasFree);
       }
    function setBoostParameters(address _boostAddress, address _addr, uint _flips_flipperShare, uint _flips_boostAdminShare, uint _flips_flipper_spotCashBack, uint _flips_usersShare, uint _spot_boostAdminShare, uint _spot_usersShare, uint _spotBusyTime) external {
        IS(_boostAddress).setBoostParameters(_addr,  _flips_flipperShare,  _flips_boostAdminShare,  _flips_flipper_spotCashBack,  _flips_usersShare,  _spot_boostAdminShare,  _spot_usersShare,  _spotBusyTime);
    }

// Add new engagooors
    function addEngagedBoost(address _addr, address _boostContract, uint _created) external {
        egagooors[_addr].push(EngagedContracts(_boostContract, _created));
    }
// Pop out not active boosts per user
    function popInactiveUserBoosts(address _addr) external {
      EngagedContracts[] storage engage = egagooors[_addr];
      EngagedContracts memory removeMe;
      while (lengthBefore!=lengthAfter) {
          lengthBefore=engage.length;
          for (uint i = 0; i < engage.length; i++) {
          if (engage[i].created + 604800 + extendLong < block.timestamp) { 
          removeMe = engage[i];
          engage[i] = engage[engage.length - 1];
          engage[engage.length - 1] = removeMe; 
          engage.pop();
             }
            }
          lengthAfter=engage.length;
          }
          lengthBefore=1;
          lengthAfter=0;
      }
// get number of Boosts where user was engaged
    function getNoOfContractsPerUser(address _addr) external view returns(uint) {
        EngagedContracts[] storage long = egagooors[_addr];
        return long.length;
    }
// get number of Boosts where Creator is admin
    function getNoOfBoostsPerCreatoor(address _addr) external view returns(uint) {
        BoostCreatoors[] storage long = creatoor[_addr];
        return long.length;
    }
// get number of all Boosts 
    function getNoOfBoosts() external view returns(uint) {
        BoostContracts[] storage long = boostList[address(this)];
        return long.length;
    }

// get list of boosts where User have engaged in order to Batch withdraw
    function readEngagoor(address _addr) external view returns(EngagedContracts[] memory) {
        EngagedContracts[] storage long = egagooors[_addr];
        EngagedContracts[] memory contracts = new EngagedContracts[](long.length);
        for (uint i = 0; i < long.length; i++) {
            EngagedContracts storage c = long[i];
            contracts[i] = c;
        }
        return contracts;
    }
// get list of Creatoor boosts 
    function readCreatoorBoosts(address _addr) external view returns(BoostCreatoors[] memory) {
        BoostCreatoors[] storage long = creatoor[_addr];
        BoostCreatoors[] memory contracts = new BoostCreatoors[](long.length);
        for (uint i = 0; i < long.length; i++) {
            BoostCreatoors storage c = long[i];
            contracts[i] = c;
        }
        return contracts;
    }
//get list of all boosts
    function getAllActiveBoosts() external view returns(BoostContracts[] memory) {
        BoostContracts[] storage boosts = boostList[address(this)];
        BoostContracts[] memory contracts = new BoostContracts[](boosts.length);
        for (uint i = 0; i < boosts.length; i++) {
            BoostContracts storage c = boosts[i];
            contracts[i] = c;
        }
        return contracts;
    }
//Add new boost
    function addBoost(address _boostAdmin, address _boostContract) external {
       require(msg.sender==boostFactory, "not bf");
            boostList[address(this)].push(BoostContracts(_boostAdmin, _boostContract, _boostAdmin));
            BoostContracts[] storage long = boostList[address(this)];
            boostIndex[_boostContract]=long.length-1;
            doesBoostContractExist[_boostContract]=true;
            // add to Boost Creators array as well
            creatoor[_boostAdmin].push(BoostCreatoors(_boostContract, block.timestamp));
            BoostCreatoors[] storage creators = creatoor[_boostAdmin];
            creatorsIndex[_boostContract]=creators.length-1;
            }
// Change of last spot owner
    function changeOwnerOfLastSpot (address _boostContract, address _ls) external {
        require(doesBoostContractExist[msg.sender]==true, "not from bf");
         uint index =  boostIndex[_boostContract];
         boostList[address(this)][index].ls = _ls;
    }
// Set boost to inactive state
    function setBoostInactive (address _boostAdmin, address _boost) external {
    require(doesBoostContractExist[msg.sender]==true, "not from bf");
        uint newIndexForLastBoost = boostIndex[_boost];
        uint newIndexForLastCreatorBoost=creatorsIndex[_boost];
        // remove (pop) inactive boost from BoostCreatoors array
        BoostCreatoors[] storage creator = creatoor[_boostAdmin];
        BoostCreatoors memory removeMe;
          removeMe = creator[newIndexForLastCreatorBoost];
          creator[newIndexForLastCreatorBoost] = creator[creator.length - 1];
          creatorsIndex[creator[creator.length - 1].boostContract]= newIndexForLastCreatorBoost;
          creator[creator.length - 1] = removeMe; 
          creator.pop();
        // remove (pop) inactive boost from BoostContracts array
        BoostContracts[] storage boosts = boostList[address(this)];
        BoostContracts memory removeBoost;
          removeBoost = boosts[newIndexForLastBoost];
          boosts[newIndexForLastBoost] = boosts[boosts.length - 1];
          boostIndex[boosts[boosts.length - 1].boostContract]=newIndexForLastBoost;
          boosts[boosts.length - 1] = removeBoost; 
          boosts.pop();
    }
// Add leaders
    function addLeaderBoard(string memory _username, address _addr, uint _usersRevenue) external {
       require(doesBoostContractExist[msg.sender]==true, "Not from factory");
       if (doesCreatorExist[_username] == false) {
            Leaders memory leader = Leaders(block.timestamp,_username,_usersRevenue, _addr);
            leadooors[address(this)].push(leader);
            doesCreatorExist[_username]=true;
            Leaders[] storage long = leadooors[address(this)];
            leadersIndex[_username]=long.length-1;}
        else {
            leadooors[address(this)][leadersIndex[_username]].lastContribution=block.timestamp;
            leadooors[address(this)][leadersIndex[_username]].usersRevenue+=_usersRevenue;
        }
    }
 // Delete inactive leaders
        uint public lengthBeforeLeaders=1;
        uint public lengthAfterLeaders=0;
    function deleteInactiveLeaders() external {
        Leaders memory removeMe;
        while (lengthBeforeLeaders!=lengthAfterLeaders) {
          Leaders[] storage long = leadooors[address(this)];
          lengthBeforeLeaders=long.length;
          for (uint i = 0; i < long.length; i++) {
          if (long[i].lastContribution < (block.timestamp - lastContribution)) { 
          removeMe = long[i]; 
          long[i] = long[long.length - 1]; 
          leadersIndex[long[long.length - 1].username]=i; 
          long[long.length - 1] = removeMe; 
          long.pop(); 
          doesCreatorExist[long[i].username]=false; 
             }
            }
          lengthAfterLeaders=long.length;
          }
          lengthBeforeLeaders=1;
          lengthAfterLeaders=0;
    }

// get list of Leaders
    function getLeaderBoard() public view returns(Leaders[] memory) {
        Leaders[] storage long = leadooors[address(this)];
        Leaders[] memory list = new Leaders[](long.length);
        for (uint i = 0; i < long.length; i++) {
            Leaders storage c = long[i];
            list[i] = c;
        }
        return list;
    }

// delete Leaders
    function deleteLeaders() external {
        require(msg.sender==boostFactory, '');
        Leaders[] storage leaders = leadooors[address(this)];
        for (uint i = 0; i < leaders.length; i++) {
        leaders.pop(); 
        }
    }


// check if boost was created by boost factory
    function getIsBoostFromFactory(address _addr) view external returns (bool) {
        return doesBoostContractExist[_addr];
    }

// Set Boost Factory
    function setBoostFactory (address _addr) external {
        require(msg.sender == protocol, "not allowed");
        boostFactory = _addr;
      }
//set signer
    function setSigner(address _signer) external {
      require(msg.sender==protocol, 'only protocol');
      signer=_signer;
    }
// Is signature valid
    function isSignatureValid(bytes calldata signature, address _addr) view external returns (bool){
    bytes32 message = prefixed(keccak256(abi.encodePacked(_addr)));
    bool isSigValid=false;
    require(recoverSigner(message, signature) == signer, 'wrong sig');
    isSigValid=true;
    return isSigValid;
   }
// technical functions for signature check
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
      return keccak256(abi.encodePacked(
        '\x19Ethereum Signed Message:\n32', 
        hash
      ));
    }

    function recoverSigner(bytes32 message, bytes memory sig)
      internal
      pure
      returns (address)
    {
      uint8 v;
      bytes32 r;
      bytes32 s;
    
      (v, r, s) = splitSignature(sig);
    
      return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
      internal
      pure
      returns (uint8, bytes32, bytes32)
    {
      require(sig.length == 65);
    
      bytes32 r;
      bytes32 s;
      uint8 v;
    
      assembly {
          // first 32 bytes, after the length prefix
          r := mload(add(sig, 32))
          // second 32 bytes
          s := mload(add(sig, 64))
          // final byte (first byte of the next 32 bytes)
          v := byte(0, mload(add(sig, 96)))
      }
    
      return (v, r, s);
    }
    // end of signature stuff

}