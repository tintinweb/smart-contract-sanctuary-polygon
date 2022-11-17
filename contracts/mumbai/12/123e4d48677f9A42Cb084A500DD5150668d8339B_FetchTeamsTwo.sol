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


contract FetchTeamsTwo is Ownable {
    bytes fifthPlaceTeam = abi.encode("England");
    bytes sixthPlaceTeam = abi.encode("IR Iran");
    bytes seventhPlaceTeam = abi.encode("USA");
    bytes eighthPlaceTeam = abi.encode("Wales");
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


function setFifthPlaceTeam(string memory _teamId) public {
   require(msg.sender == worldCupData16Address || msg.sender == worldCupData8Address || msg.sender == worldCupData4Address, "USER_CANT_CALL_FUNCTION");
   if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('URU'))) {
    fifthPlaceTeam =  worldCupTeams[30];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('QAT'))) {
     fifthPlaceTeam =  worldCupTeams[0];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MAR'))) {
     fifthPlaceTeam =  worldCupTeams[22];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GHA'))) {
     fifthPlaceTeam =  worldCupTeams[29];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('TUN'))) {
     fifthPlaceTeam =  worldCupTeams[15];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SEN'))) {
     fifthPlaceTeam =  worldCupTeams[2];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KSA'))) {
     fifthPlaceTeam =  worldCupTeams[9];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KOR'))) {
     fifthPlaceTeam = worldCupTeams[31];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('USA'))) {
     fifthPlaceTeam =  worldCupTeams[6];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CAN'))) {
     fifthPlaceTeam =  worldCupTeams[21];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ECU'))) {
     fifthPlaceTeam =  worldCupTeams[1];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MEX'))) {
     fifthPlaceTeam = worldCupTeams[10];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('DEN'))) {
     fifthPlaceTeam = worldCupTeams[14];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRO'))) {
     fifthPlaceTeam =  worldCupTeams[23];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('JPN'))) {
     fifthPlaceTeam =  worldCupTeams[19];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRC'))) {
     fifthPlaceTeam = worldCupTeams[17];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ARG'))) {
     fifthPlaceTeam =  worldCupTeams[8];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ENG'))) {
     fifthPlaceTeam =  worldCupTeams[4];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('FRA'))) {
    fifthPlaceTeam = worldCupTeams[12];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('IRN'))) {
    fifthPlaceTeam =  worldCupTeams[5];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GER'))) {
    fifthPlaceTeam =  worldCupTeams[18];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('NED'))) {
    fifthPlaceTeam = worldCupTeams[3];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POL'))) {
    fifthPlaceTeam = worldCupTeams[11];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POR'))) {
    fifthPlaceTeam =  worldCupTeams[28];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BRA'))) {
    fifthPlaceTeam =  worldCupTeams[24];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SUI'))) {
    fifthPlaceTeam =  worldCupTeams[26];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ESP'))) {
    fifthPlaceTeam =  worldCupTeams[16];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('WAL'))) {
    fifthPlaceTeam = worldCupTeams[7];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('AUS'))) {
    fifthPlaceTeam =  worldCupTeams[13];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BEL'))) {
    fifthPlaceTeam =  worldCupTeams[20];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CMR'))) {
    fifthPlaceTeam =   worldCupTeams[27];
   }   else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SRB'))) {
    fifthPlaceTeam =  worldCupTeams[25];
   }  
}

 function setSixthPlaceTeam(string memory _teamId) public {
   require(msg.sender == worldCupData16Address || msg.sender == worldCupData8Address || msg.sender == worldCupData4Address, "USER_CANT_CALL_FUNCTION");
   if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('URU'))) {
    sixthPlaceTeam =  worldCupTeams[30];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('QAT'))) {
     sixthPlaceTeam =  worldCupTeams[0];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MAR'))) {
     sixthPlaceTeam =  worldCupTeams[22];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GHA'))) {
     sixthPlaceTeam =  worldCupTeams[29];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('TUN'))) {
     sixthPlaceTeam =  worldCupTeams[15];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SEN'))) {
     sixthPlaceTeam =  worldCupTeams[2];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KSA'))) {
     sixthPlaceTeam =  worldCupTeams[9];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KOR'))) {
     sixthPlaceTeam = worldCupTeams[31];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('USA'))) {
     sixthPlaceTeam =  worldCupTeams[6];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CAN'))) {
     sixthPlaceTeam =  worldCupTeams[21];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ECU'))) {
     sixthPlaceTeam =  worldCupTeams[1];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MEX'))) {
     sixthPlaceTeam = worldCupTeams[10];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('DEN'))) {
     sixthPlaceTeam = worldCupTeams[14];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRO'))) {
     sixthPlaceTeam =  worldCupTeams[23];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('JPN'))) {
     sixthPlaceTeam =  worldCupTeams[19];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRC'))) {
     sixthPlaceTeam = worldCupTeams[17];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ARG'))) {
     sixthPlaceTeam =  worldCupTeams[8];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ENG'))) {
     sixthPlaceTeam =  worldCupTeams[4];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('FRA'))) {
    sixthPlaceTeam = worldCupTeams[12];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('IRN'))) {
    sixthPlaceTeam =  worldCupTeams[5];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GER'))) {
    sixthPlaceTeam =  worldCupTeams[18];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('NED'))) {
    sixthPlaceTeam = worldCupTeams[3];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POL'))) {
    sixthPlaceTeam = worldCupTeams[11];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POR'))) {
    sixthPlaceTeam =  worldCupTeams[28];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BRA'))) {
    sixthPlaceTeam =  worldCupTeams[24];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SUI'))) {
    sixthPlaceTeam =  worldCupTeams[26];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ESP'))) {
    sixthPlaceTeam =  worldCupTeams[16];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('WAL'))) {
    sixthPlaceTeam = worldCupTeams[7];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('AUS'))) {
    sixthPlaceTeam =  worldCupTeams[13];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BEL'))) {
    sixthPlaceTeam =  worldCupTeams[20];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CMR'))) {
    sixthPlaceTeam =   worldCupTeams[27];
   }   else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SRB'))) {
    sixthPlaceTeam =  worldCupTeams[25];
   }  
}

 function setSeventhPlaceTeam(string memory _teamId) public {
    require(msg.sender == worldCupData16Address || msg.sender == worldCupData8Address || msg.sender == worldCupData4Address, "USER_CANT_CALL_FUNCTION");
   if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('URU'))) {
    seventhPlaceTeam =  worldCupTeams[30];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('QAT'))) {
     seventhPlaceTeam =  worldCupTeams[0];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MAR'))) {
     seventhPlaceTeam =  worldCupTeams[22];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GHA'))) {
     seventhPlaceTeam =  worldCupTeams[29];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('TUN'))) {
     seventhPlaceTeam =  worldCupTeams[15];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SEN'))) {
     seventhPlaceTeam =  worldCupTeams[2];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KSA'))) {
     seventhPlaceTeam =  worldCupTeams[9];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KOR'))) {
     seventhPlaceTeam = worldCupTeams[31];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('USA'))) {
     seventhPlaceTeam =  worldCupTeams[6];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CAN'))) {
     seventhPlaceTeam =  worldCupTeams[21];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ECU'))) {
     seventhPlaceTeam =  worldCupTeams[1];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MEX'))) {
     seventhPlaceTeam = worldCupTeams[10];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('DEN'))) {
     seventhPlaceTeam = worldCupTeams[14];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRO'))) {
     seventhPlaceTeam =  worldCupTeams[23];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('JPN'))) {
     seventhPlaceTeam =  worldCupTeams[19];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRC'))) {
     seventhPlaceTeam = worldCupTeams[17];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ARG'))) {
     seventhPlaceTeam =  worldCupTeams[8];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ENG'))) {
     seventhPlaceTeam =  worldCupTeams[4];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('FRA'))) {
    seventhPlaceTeam = worldCupTeams[12];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('IRN'))) {
    seventhPlaceTeam =  worldCupTeams[5];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GER'))) {
    seventhPlaceTeam =  worldCupTeams[18];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('NED'))) {
    seventhPlaceTeam = worldCupTeams[3];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POL'))) {
    seventhPlaceTeam = worldCupTeams[11];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POR'))) {
    seventhPlaceTeam =  worldCupTeams[28];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BRA'))) {
    seventhPlaceTeam =  worldCupTeams[24];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SUI'))) {
    seventhPlaceTeam =  worldCupTeams[26];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ESP'))) {
    seventhPlaceTeam =  worldCupTeams[16];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('WAL'))) {
    seventhPlaceTeam = worldCupTeams[7];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('AUS'))) {
    seventhPlaceTeam =  worldCupTeams[13];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BEL'))) {
    seventhPlaceTeam =  worldCupTeams[20];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CMR'))) {
    seventhPlaceTeam =   worldCupTeams[27];
   }   else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SRB'))) {
    seventhPlaceTeam =  worldCupTeams[25];
   }  
}

 function setEigthPlaceTeam(string memory _teamId) public {
   require(msg.sender == worldCupData16Address || msg.sender == worldCupData8Address || msg.sender == worldCupData4Address, "USER_CANT_CALL_FUNCTION");
   if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('URU'))) {
    eighthPlaceTeam =  worldCupTeams[30];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('QAT'))) {
     eighthPlaceTeam =  worldCupTeams[0];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MAR'))) {
     eighthPlaceTeam =  worldCupTeams[22];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GHA'))) {
     eighthPlaceTeam =  worldCupTeams[29];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('TUN'))) {
     eighthPlaceTeam =  worldCupTeams[15];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SEN'))) {
     eighthPlaceTeam =  worldCupTeams[2];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KSA'))) {
     eighthPlaceTeam =  worldCupTeams[9];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('KOR'))) {
     eighthPlaceTeam = worldCupTeams[31];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('USA'))) {
     eighthPlaceTeam =  worldCupTeams[6];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CAN'))) {
     eighthPlaceTeam =  worldCupTeams[21];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ECU'))) {
     eighthPlaceTeam =  worldCupTeams[1];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('MEX'))) {
     eighthPlaceTeam = worldCupTeams[10];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('DEN'))) {
     eighthPlaceTeam = worldCupTeams[14];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRO'))) {
     eighthPlaceTeam =  worldCupTeams[23];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('JPN'))) {
     eighthPlaceTeam =  worldCupTeams[19];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CRC'))) {
     eighthPlaceTeam = worldCupTeams[17];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ARG'))) {
     eighthPlaceTeam =  worldCupTeams[8];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ENG'))) {
     eighthPlaceTeam =  worldCupTeams[4];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('FRA'))) {
    eighthPlaceTeam = worldCupTeams[12];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('IRN'))) {
    eighthPlaceTeam =  worldCupTeams[5];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('GER'))) {
    eighthPlaceTeam =  worldCupTeams[18];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('NED'))) {
    eighthPlaceTeam = worldCupTeams[3];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POL'))) {
    eighthPlaceTeam = worldCupTeams[11];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('POR'))) {
    eighthPlaceTeam =  worldCupTeams[28];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BRA'))) {
    eighthPlaceTeam =  worldCupTeams[24];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SUI'))) {
    eighthPlaceTeam =  worldCupTeams[26];
   } else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('ESP'))) {
    eighthPlaceTeam =  worldCupTeams[16];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('WAL'))) {
    eighthPlaceTeam = worldCupTeams[7];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('AUS'))) {
    eighthPlaceTeam =  worldCupTeams[13];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('BEL'))) {
    eighthPlaceTeam =  worldCupTeams[20];
   }  else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('CMR'))) {
    eighthPlaceTeam =   worldCupTeams[27];
   }   else if(keccak256(abi.encode(_teamId)) == keccak256(abi.encode('SRB'))) {
    eighthPlaceTeam =  worldCupTeams[25];
   }  
}

function getFifthPlaceTeam() public view returns(bytes memory team) {
  return fifthPlaceTeam;
}

function getSixthPlaceTeam() public view returns(bytes memory team) {
  return sixthPlaceTeam;
}

function getSeventhPlaceTeam() public view returns(bytes memory team) {
  return seventhPlaceTeam;
}

function getEighthPlaceTeam() public view returns(bytes memory team) {
  return eighthPlaceTeam;
}

   function setWorldCupDataAddress(address _worldCupData16Address, address _worldCupData8Address, address _worldCupData4Address) external onlyOwner {
    worldCupData16Address = _worldCupData16Address;
    worldCupData8Address = _worldCupData8Address;
    worldCupData4Address = _worldCupData4Address;
  }
}