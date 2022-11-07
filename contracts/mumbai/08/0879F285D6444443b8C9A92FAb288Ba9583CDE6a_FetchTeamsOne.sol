import "@openzeppelin/contracts/access/Ownable.sol";
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract FetchTeamsOne is Ownable {
    bytes firstPlaceTeam;
    bytes secondPlaceTeam;
    bytes thirdPlaceTeam;
    bytes fourthPlaceTeam;
    address public worldCupDataAddress;
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


function setFirstPlaceTeam(uint _teamId) public {
  require(msg.sender == worldCupDataAddress, "USER_CANT_CALL_FUNCTION");
      /*
    14219 - IC Play-Off 1
    14220 - IC Play-Off 2

    Costa Rica
    Australia
    */
   if(_teamId == 12550) {
    firstPlaceTeam = worldCupTeams[1];
   } else if(_teamId == 3080) {
     firstPlaceTeam =  worldCupTeams[3];
   } else if(_teamId == 12279) {
     firstPlaceTeam = worldCupTeams[0];
   } else if(_teamId == 56) {
     firstPlaceTeam = worldCupTeams[2];
   } else if(_teamId == 12302) {
     firstPlaceTeam = worldCupTeams[4];
   } else if(_teamId == 12396) {
     firstPlaceTeam = worldCupTeams[5];
   } else if(_teamId == 7850) {
     firstPlaceTeam = worldCupTeams[6];
   } else if(_teamId == 14218) {
     firstPlaceTeam = worldCupTeams[7];
   } else if(_teamId == 12502) {
     firstPlaceTeam = worldCupTeams[8];
   } else if(_teamId == 12473) {
      firstPlaceTeam = worldCupTeams[10];
   } else if(_teamId == 3011) {
     firstPlaceTeam = worldCupTeams[11];
   } else if(_teamId == 767) {
     firstPlaceTeam = worldCupTeams[9];
   } else if(_teamId == 3008) {
     firstPlaceTeam = worldCupTeams[14];
   } else if(_teamId == 12300) {
     firstPlaceTeam = worldCupTeams[12];
   } else if(_teamId == 73) {
     firstPlaceTeam = worldCupTeams[15];
   } else if(_teamId == 3017) {
     firstPlaceTeam = worldCupTeams[18];
   } else if(_teamId == 12397) {
     firstPlaceTeam = worldCupTeams[19];
   } else if(_teamId == 3024) {
     firstPlaceTeam = worldCupTeams[16];
   } else if(_teamId == 3054) {
     firstPlaceTeam = worldCupTeams[20];
   } else if(_teamId == 7835) {
     firstPlaceTeam = worldCupTeams[21];
   } else if(_teamId == 3026) {
     firstPlaceTeam = worldCupTeams[23];
   } else if(_teamId == 52) {
     firstPlaceTeam = worldCupTeams[22];
   } else if(_teamId == 12504) {
     firstPlaceTeam = worldCupTeams[24];
   } else if(_teamId == 85) {
     firstPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3036) {
     firstPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3064) {
     firstPlaceTeam = worldCupTeams[26];
  } else if(_teamId == 95) {
     firstPlaceTeam = worldCupTeams[29];
  } else if(_teamId == 755) {
    firstPlaceTeam = worldCupTeams[31];
  } else if(_teamId == 12299) {
    firstPlaceTeam = worldCupTeams[28];
  } else if(_teamId == 12501) {
    firstPlaceTeam = worldCupTeams[30];
  }
}

 function setSecondPlaceTeam(uint _teamId) public {
  require(msg.sender == worldCupDataAddress, "USER_CANT_CALL_FUNCTION");
      /*
    14219 - IC Play-Off 1
    14220 - IC Play-Off 2

    Costa Rica
    Australia
    */
   if(_teamId == 12550) {
    secondPlaceTeam =  worldCupTeams[1];
   } else if(_teamId == 3080) {
     secondPlaceTeam=  worldCupTeams[3];
   } else if(_teamId == 12279) {
     secondPlaceTeam = worldCupTeams[0];
   } else if(_teamId == 56) {
     secondPlaceTeam = worldCupTeams[2];
   } else if(_teamId == 12302) {
     secondPlaceTeam = worldCupTeams[4];
   } else if(_teamId == 12396) {
     secondPlaceTeam = worldCupTeams[5];
   } else if(_teamId == 7850) {
     secondPlaceTeam = worldCupTeams[6];
   } else if(_teamId == 14218) {
     secondPlaceTeam = worldCupTeams[7];
   } else if(_teamId == 12502) {
     secondPlaceTeam = worldCupTeams[8];
   } else if(_teamId == 12473) {
      secondPlaceTeam = worldCupTeams[10];
   } else if(_teamId == 3011) {
     secondPlaceTeam = worldCupTeams[11];
   } else if(_teamId == 767) {
     secondPlaceTeam = worldCupTeams[9];
   } else if(_teamId == 3008) {
     secondPlaceTeam = worldCupTeams[14];
   } else if(_teamId == 12300) {
     secondPlaceTeam = worldCupTeams[12];
   } else if(_teamId == 73) {
     secondPlaceTeam = worldCupTeams[15];
   } else if(_teamId == 3017) {
     secondPlaceTeam = worldCupTeams[18];
   } else if(_teamId == 12397) {
     secondPlaceTeam = worldCupTeams[19];
   } else if(_teamId == 3024) {
     secondPlaceTeam = worldCupTeams[16];
   } else if(_teamId == 3054) {
     secondPlaceTeam = worldCupTeams[20];
   } else if(_teamId == 7835) {
     secondPlaceTeam = worldCupTeams[21];
   } else if(_teamId == 3026) {
     secondPlaceTeam = worldCupTeams[23];
   } else if(_teamId == 52) {
     secondPlaceTeam = worldCupTeams[22];
   } else if(_teamId == 12504) {
     secondPlaceTeam = worldCupTeams[24];
   } else if(_teamId == 85) {
     secondPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3036) {
     secondPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3064) {
     secondPlaceTeam = worldCupTeams[26];
  } else if(_teamId == 95) {
     secondPlaceTeam = worldCupTeams[29];
  } else if(_teamId == 755) {
    secondPlaceTeam = worldCupTeams[31];
  } else if(_teamId == 12299) {
    secondPlaceTeam = worldCupTeams[28];
  } else if(_teamId == 12501) {
    secondPlaceTeam = worldCupTeams[30];
  }
}

 function setThirdPlaceTeam(uint _teamId) public {
  require(msg.sender == worldCupDataAddress, "USER_CANT_CALL_FUNCTION");
      /*
    14219 - IC Play-Off 1
    14220 - IC Play-Off 2

    Costa Rica
    Australia
    */
   if(_teamId == 12550) {
    thirdPlaceTeam  =  worldCupTeams[1];
   } else if(_teamId == 3080) {
     thirdPlaceTeam  =  worldCupTeams[3];
   } else if(_teamId == 12279) {
     thirdPlaceTeam  = worldCupTeams[0];
   } else if(_teamId == 56) {
     thirdPlaceTeam  = worldCupTeams[2];
   } else if(_teamId == 12302) {
     thirdPlaceTeam  = worldCupTeams[4];
   } else if(_teamId == 12396) {
     thirdPlaceTeam  = worldCupTeams[5];
   } else if(_teamId == 7850) {
     thirdPlaceTeam  = worldCupTeams[6];
   } else if(_teamId == 14218) {
     thirdPlaceTeam  = worldCupTeams[7];
   } else if(_teamId == 12502) {
     thirdPlaceTeam  = worldCupTeams[8];
   } else if(_teamId == 12473) {
      thirdPlaceTeam  = worldCupTeams[10];
   } else if(_teamId == 3011) {
     thirdPlaceTeam  = worldCupTeams[11];
   } else if(_teamId == 767) {
     thirdPlaceTeam  = worldCupTeams[9];
   } else if(_teamId == 3008) {
     thirdPlaceTeam  = worldCupTeams[14];
   } else if(_teamId == 12300) {
     thirdPlaceTeam  = worldCupTeams[12];
   } else if(_teamId == 73) {
     thirdPlaceTeam  = worldCupTeams[15];
   } else if(_teamId == 3017) {
     thirdPlaceTeam  = worldCupTeams[18];
   } else if(_teamId == 12397) {
     thirdPlaceTeam  = worldCupTeams[19];
   } else if(_teamId == 3024) {
     thirdPlaceTeam  = worldCupTeams[16];
   } else if(_teamId == 3054) {
     thirdPlaceTeam  = worldCupTeams[20];
   } else if(_teamId == 7835) {
     thirdPlaceTeam  = worldCupTeams[21];
   } else if(_teamId == 3026) {
     thirdPlaceTeam  = worldCupTeams[23];
   } else if(_teamId == 52) {
     thirdPlaceTeam  = worldCupTeams[22];
   } else if(_teamId == 12504) {
     thirdPlaceTeam  = worldCupTeams[24];
   } else if(_teamId == 85) {
     thirdPlaceTeam  = worldCupTeams[27];
  } else if(_teamId == 3036) {
     thirdPlaceTeam  = worldCupTeams[27];
  } else if(_teamId == 3064) {
     thirdPlaceTeam  = worldCupTeams[26];
  } else if(_teamId == 95) {
     thirdPlaceTeam  = worldCupTeams[29];
  } else if(_teamId == 755) {
    thirdPlaceTeam  = worldCupTeams[31];
  } else if(_teamId == 12299) {
    thirdPlaceTeam  = worldCupTeams[28];
  } else if(_teamId == 12501) {
    thirdPlaceTeam  = worldCupTeams[30];
  }
}

 function setFourthPlaceTeam(uint _teamId) public {
  require(msg.sender == worldCupDataAddress, "USER_CANT_CALL_FUNCTION");
      /*
    14219 - IC Play-Off 1
    14220 - IC Play-Off 2

    Costa Rica
    Australia
    */
   if(_teamId == 12550) {
    fourthPlaceTeam =  worldCupTeams[1];
   } else if(_teamId == 3080) {
     fourthPlaceTeam =  worldCupTeams[3];
   } else if(_teamId == 12279) {
     fourthPlaceTeam = worldCupTeams[0];
   } else if(_teamId == 56) {
     fourthPlaceTeam = worldCupTeams[2];
   } else if(_teamId == 12302) {
     fourthPlaceTeam = worldCupTeams[4];
   } else if(_teamId == 12396) {
     fourthPlaceTeam = worldCupTeams[5];
   } else if(_teamId == 7850) {
     fourthPlaceTeam = worldCupTeams[6];
   } else if(_teamId == 14218) {
     fourthPlaceTeam = worldCupTeams[7];
   } else if(_teamId == 12502) {
     fourthPlaceTeam = worldCupTeams[8];
   } else if(_teamId == 12473) {
      fourthPlaceTeam = worldCupTeams[10];
   } else if(_teamId == 3011) {
     fourthPlaceTeam = worldCupTeams[11];
   } else if(_teamId == 767) {
     fourthPlaceTeam = worldCupTeams[9];
   } else if(_teamId == 3008) {
     fourthPlaceTeam = worldCupTeams[14];
   } else if(_teamId == 12300) {
     fourthPlaceTeam = worldCupTeams[12];
   } else if(_teamId == 73) {
     fourthPlaceTeam = worldCupTeams[15];
   } else if(_teamId == 3017) {
     fourthPlaceTeam = worldCupTeams[18];
   } else if(_teamId == 12397) {
     fourthPlaceTeam = worldCupTeams[19];
   } else if(_teamId == 3024) {
     fourthPlaceTeam = worldCupTeams[16];
   } else if(_teamId == 3054) {
     fourthPlaceTeam = worldCupTeams[20];
   } else if(_teamId == 7835) {
     fourthPlaceTeam = worldCupTeams[21];
   } else if(_teamId == 3026) {
     fourthPlaceTeam = worldCupTeams[23];
   } else if(_teamId == 52) {
     fourthPlaceTeam = worldCupTeams[22];
   } else if(_teamId == 12504) {
     fourthPlaceTeam = worldCupTeams[24];
   } else if(_teamId == 85) {
     fourthPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3036) {
     fourthPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3064) {
     fourthPlaceTeam = worldCupTeams[26];
  } else if(_teamId == 95) {
     fourthPlaceTeam = worldCupTeams[29];
  } else if(_teamId == 755) {
    fourthPlaceTeam = worldCupTeams[31];
  } else if(_teamId == 12299) {
    fourthPlaceTeam = worldCupTeams[28];
  } else if(_teamId == 12501) {
    fourthPlaceTeam = worldCupTeams[30];
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

  function setWorldCupDataAddress(address _worldCupDataAddress) public {
    require(msg.sender == setAddress, "USER_CANT_CALL_FUNCTION");
    worldCupDataAddress = _worldCupDataAddress;
  }
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