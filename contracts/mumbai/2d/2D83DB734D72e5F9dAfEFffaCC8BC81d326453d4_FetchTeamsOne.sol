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

import "@openzeppelin/contracts/access/Ownable.sol";
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract FetchTeamsOne is Ownable {
    bytes firstPlaceTeam = abi.encode("Qatar");
    bytes secondPlaceTeam = abi.encode("Ecuador");
    bytes thirdPlaceTeam = abi.encode("Senegal");
    bytes fourthPlaceTeam = abi.encode("Netherlands");
    address public worldCupData16Address;
    address public worldCupData8Address;
    address public worldCupData4Address;
    bytes[32] worldCupTeams;

    constructor() {
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


function setFirstPlaceTeam(string memory _teamId) public {
  require(msg.sender == worldCupData16Address || msg.sender == worldCupData8Address || msg.sender == worldCupData4Address, "USER_CANT_CALL_FUNCTION");
   if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('URU'))) {
     firstPlaceTeam =  worldCupTeams[30];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('QAT'))) {
      firstPlaceTeam =  worldCupTeams[0];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MAR'))) {
      firstPlaceTeam =  worldCupTeams[22];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GHA'))) {
      firstPlaceTeam =  worldCupTeams[29];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('TUN'))) {
      firstPlaceTeam =  worldCupTeams[15];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SEN'))) {
      firstPlaceTeam =  worldCupTeams[2];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KSA'))) {
      firstPlaceTeam =  worldCupTeams[9];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KOR'))) {
      firstPlaceTeam = worldCupTeams[31];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('USA'))) {
      firstPlaceTeam =  worldCupTeams[6];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CAN'))) {
      firstPlaceTeam =  worldCupTeams[21];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ECU'))) {
      firstPlaceTeam =  worldCupTeams[1];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MEX'))) {
      firstPlaceTeam = worldCupTeams[10];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('DEN'))) {
      firstPlaceTeam = worldCupTeams[14];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRO'))) {
      firstPlaceTeam =  worldCupTeams[23];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('JPN'))) {
      firstPlaceTeam =  worldCupTeams[19];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRC'))) {
      firstPlaceTeam = worldCupTeams[17];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ARG'))) {
      firstPlaceTeam =  worldCupTeams[8];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ENG'))) {
      firstPlaceTeam =  worldCupTeams[4];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('FRA'))) {
     firstPlaceTeam = worldCupTeams[12];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('IRN'))) {
     firstPlaceTeam =  worldCupTeams[5];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GER'))) {
     firstPlaceTeam =  worldCupTeams[18];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('NED'))) {
     firstPlaceTeam = worldCupTeams[3];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POL'))) {
     firstPlaceTeam = worldCupTeams[11];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POR'))) {
     firstPlaceTeam =  worldCupTeams[28];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BRA'))) {
     firstPlaceTeam =  worldCupTeams[24];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SUI'))) {
     firstPlaceTeam =  worldCupTeams[26];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ESP'))) {
     firstPlaceTeam =  worldCupTeams[16];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('WAL'))) {
     firstPlaceTeam = worldCupTeams[7];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('AUS'))) {
     firstPlaceTeam =  worldCupTeams[13];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BEL'))) {
     firstPlaceTeam =  worldCupTeams[20];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CMR'))) {
     firstPlaceTeam =   worldCupTeams[27];
   }   else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SRB'))) {
     firstPlaceTeam =  worldCupTeams[25];
   }  
}

 function setSecondPlaceTeam(string memory _teamId) public {
  require(msg.sender == worldCupData16Address || msg.sender == worldCupData8Address || msg.sender == worldCupData4Address, "USER_CANT_CALL_FUNCTION");
   if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('URU'))) {
    secondPlaceTeam =  worldCupTeams[30];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('QAT'))) {
     secondPlaceTeam =  worldCupTeams[0];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MAR'))) {
     secondPlaceTeam =  worldCupTeams[22];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GHA'))) {
     secondPlaceTeam =  worldCupTeams[29];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('TUN'))) {
     secondPlaceTeam =  worldCupTeams[15];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SEN'))) {
     secondPlaceTeam =  worldCupTeams[2];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KSA'))) {
     secondPlaceTeam =  worldCupTeams[9];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KOR'))) {
     secondPlaceTeam = worldCupTeams[31];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('USA'))) {
     secondPlaceTeam =  worldCupTeams[6];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CAN'))) {
     secondPlaceTeam =  worldCupTeams[21];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ECU'))) {
     secondPlaceTeam =  worldCupTeams[1];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MEX'))) {
     secondPlaceTeam = worldCupTeams[10];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('DEN'))) {
     secondPlaceTeam = worldCupTeams[14];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRO'))) {
     secondPlaceTeam =  worldCupTeams[23];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('JPN'))) {
     secondPlaceTeam =  worldCupTeams[19];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRC'))) {
     secondPlaceTeam = worldCupTeams[17];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ARG'))) {
     secondPlaceTeam =  worldCupTeams[8];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ENG'))) {
     secondPlaceTeam =  worldCupTeams[4];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('FRA'))) {
    secondPlaceTeam = worldCupTeams[12];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('IRN'))) {
    secondPlaceTeam =  worldCupTeams[5];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GER'))) {
    secondPlaceTeam =  worldCupTeams[18];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('NED'))) {
    secondPlaceTeam = worldCupTeams[3];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POL'))) {
    secondPlaceTeam = worldCupTeams[11];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POR'))) {
    secondPlaceTeam =  worldCupTeams[28];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BRA'))) {
    secondPlaceTeam =  worldCupTeams[24];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SUI'))) {
    secondPlaceTeam =  worldCupTeams[26];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ESP'))) {
    secondPlaceTeam =  worldCupTeams[16];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('WAL'))) {
    secondPlaceTeam = worldCupTeams[7];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('AUS'))) {
    secondPlaceTeam =  worldCupTeams[13];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BEL'))) {
    secondPlaceTeam =  worldCupTeams[20];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CMR'))) {
    secondPlaceTeam =   worldCupTeams[27];
   }   else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SRB'))) {
    secondPlaceTeam =  worldCupTeams[25];
   }  
}

 function setThirdPlaceTeam(string memory _teamId) public {
  require(msg.sender == worldCupData16Address || msg.sender == worldCupData8Address || msg.sender == worldCupData4Address, "USER_CANT_CALL_FUNCTION");
   if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('URU'))) {
    thirdPlaceTeam =  worldCupTeams[30];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('QAT'))) {
     thirdPlaceTeam =  worldCupTeams[0];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MAR'))) {
     thirdPlaceTeam =  worldCupTeams[22];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GHA'))) {
     thirdPlaceTeam =  worldCupTeams[29];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('TUN'))) {
     thirdPlaceTeam =  worldCupTeams[15];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SEN'))) {
     thirdPlaceTeam =  worldCupTeams[2];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KSA'))) {
     thirdPlaceTeam =  worldCupTeams[9];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KOR'))) {
     thirdPlaceTeam = worldCupTeams[31];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('USA'))) {
     thirdPlaceTeam =  worldCupTeams[6];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CAN'))) {
     thirdPlaceTeam =  worldCupTeams[21];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ECU'))) {
     thirdPlaceTeam =  worldCupTeams[1];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MEX'))) {
     thirdPlaceTeam = worldCupTeams[10];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('DEN'))) {
     thirdPlaceTeam = worldCupTeams[14];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRO'))) {
     thirdPlaceTeam =  worldCupTeams[23];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('JPN'))) {
     thirdPlaceTeam =  worldCupTeams[19];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRC'))) {
     thirdPlaceTeam = worldCupTeams[17];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ARG'))) {
     thirdPlaceTeam =  worldCupTeams[8];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ENG'))) {
     thirdPlaceTeam =  worldCupTeams[4];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('FRA'))) {
    thirdPlaceTeam = worldCupTeams[12];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('IRN'))) {
    thirdPlaceTeam =  worldCupTeams[5];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GER'))) {
    thirdPlaceTeam =  worldCupTeams[18];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('NED'))) {
    thirdPlaceTeam = worldCupTeams[3];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POL'))) {
    thirdPlaceTeam = worldCupTeams[11];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POR'))) {
    thirdPlaceTeam =  worldCupTeams[28];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BRA'))) {
    thirdPlaceTeam =  worldCupTeams[24];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SUI'))) {
    thirdPlaceTeam =  worldCupTeams[26];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ESP'))) {
    thirdPlaceTeam =  worldCupTeams[16];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('WAL'))) {
    thirdPlaceTeam = worldCupTeams[7];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('AUS'))) {
    thirdPlaceTeam =  worldCupTeams[13];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BEL'))) {
    thirdPlaceTeam =  worldCupTeams[20];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CMR'))) {
    thirdPlaceTeam =   worldCupTeams[27];
   }   else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SRB'))) {
    thirdPlaceTeam =  worldCupTeams[25];
   }  
}

 function setFourthPlaceTeam(string memory _teamId) public {
  require(msg.sender == worldCupData16Address || msg.sender == worldCupData8Address || msg.sender == worldCupData4Address, "USER_CANT_CALL_FUNCTION");
   if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('URU'))) {
    fourthPlaceTeam =  worldCupTeams[30];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('QAT'))) {
     fourthPlaceTeam =  worldCupTeams[0];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MAR'))) {
     fourthPlaceTeam =  worldCupTeams[22];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GHA'))) {
     fourthPlaceTeam =  worldCupTeams[29];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('TUN'))) {
     fourthPlaceTeam =  worldCupTeams[15];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SEN'))) {
     fourthPlaceTeam =  worldCupTeams[2];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KSA'))) {
     fourthPlaceTeam =  worldCupTeams[9];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KOR'))) {
     fourthPlaceTeam = worldCupTeams[31];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('USA'))) {
     fourthPlaceTeam =  worldCupTeams[6];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CAN'))) {
     fourthPlaceTeam =  worldCupTeams[21];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ECU'))) {
     fourthPlaceTeam =  worldCupTeams[1];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MEX'))) {
     fourthPlaceTeam = worldCupTeams[10];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('DEN'))) {
     fourthPlaceTeam = worldCupTeams[14];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRO'))) {
     fourthPlaceTeam =  worldCupTeams[23];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('JPN'))) {
     fourthPlaceTeam =  worldCupTeams[19];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRC'))) {
     fourthPlaceTeam = worldCupTeams[17];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ARG'))) {
     fourthPlaceTeam =  worldCupTeams[8];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ENG'))) {
     fourthPlaceTeam =  worldCupTeams[4];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('FRA'))) {
    fourthPlaceTeam = worldCupTeams[12];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('IRN'))) {
    fourthPlaceTeam =  worldCupTeams[5];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GER'))) {
    fourthPlaceTeam =  worldCupTeams[18];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('NED'))) {
    fourthPlaceTeam = worldCupTeams[3];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POL'))) {
    fourthPlaceTeam = worldCupTeams[11];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POR'))) {
    fourthPlaceTeam =  worldCupTeams[28];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BRA'))) {
    fourthPlaceTeam =  worldCupTeams[24];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SUI'))) {
    fourthPlaceTeam =  worldCupTeams[26];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ESP'))) {
    fourthPlaceTeam =  worldCupTeams[16];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('WAL'))) {
    fourthPlaceTeam = worldCupTeams[7];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('AUS'))) {
    fourthPlaceTeam =  worldCupTeams[13];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BEL'))) {
    fourthPlaceTeam =  worldCupTeams[20];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CMR'))) {
    fourthPlaceTeam =   worldCupTeams[27];
   }   else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SRB'))) {
    fourthPlaceTeam =  worldCupTeams[25];
   }  
}

function getFirstPlaceTeam() public view returns(bytes memory team) {
  return firstPlaceTeam;
}

function getSecondPlaceTeam() public view returns(bytes memory team) {
  return secondPlaceTeam;
}

function getThirdPlaceTeam() public view returns(bytes memory team) {
  return thirdPlaceTeam;
}

function getFourthPlaceTeam() public view returns(bytes memory team) {
  return fourthPlaceTeam;
}

  function setWorldCupDataAddress(address _worldCupData16Address, address _worldCupData8Address, address _worldCupData4Address) external onlyOwner {
    worldCupData16Address = _worldCupData16Address;
    worldCupData8Address = _worldCupData8Address;
    worldCupData4Address = _worldCupData4Address;
  }
}