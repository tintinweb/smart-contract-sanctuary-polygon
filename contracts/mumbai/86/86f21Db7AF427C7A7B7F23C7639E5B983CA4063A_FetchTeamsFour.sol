import "@openzeppelin/contracts/access/Ownable.sol";
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract FetchTeamsFour is Ownable {
    bytes thirteenthPlaceTeam;
    bytes fourteenthPlaceTeam;
    bytes fifteenthPlaceTeam;
    bytes sixteenthPlaceTeam;
    address worldCupDataAddress;
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


function setThirteenthPlaceTeam(uint _teamId) public {
  require(msg.sender == worldCupDataAddress, "USER_CANT_CALL_FUNCTION");
      /*
    14219 - IC Play-Off 1
    14220 - IC Play-Off 2

    Costa Rica
    Australia
    */
   if(_teamId == 12550) {
    thirteenthPlaceTeam = worldCupTeams[1];
   } else if(_teamId == 3080) {
     thirteenthPlaceTeam =  worldCupTeams[3];
   } else if(_teamId == 12279) {
     thirteenthPlaceTeam = worldCupTeams[0];
   } else if(_teamId == 56) {
     thirteenthPlaceTeam = worldCupTeams[2];
   } else if(_teamId == 12302) {
     thirteenthPlaceTeam = worldCupTeams[4];
   } else if(_teamId == 12396) {
     thirteenthPlaceTeam = worldCupTeams[5];
   } else if(_teamId == 7850) {
     thirteenthPlaceTeam = worldCupTeams[6];
   } else if(_teamId == 14218) {
     thirteenthPlaceTeam = worldCupTeams[7];
   } else if(_teamId == 12502) {
     thirteenthPlaceTeam = worldCupTeams[8];
   } else if(_teamId == 12473) {
      thirteenthPlaceTeam = worldCupTeams[10];
   } else if(_teamId == 3011) {
     thirteenthPlaceTeam = worldCupTeams[11];
   } else if(_teamId == 767) {
     thirteenthPlaceTeam = worldCupTeams[9];
   } else if(_teamId == 3008) {
     thirteenthPlaceTeam = worldCupTeams[14];
   } else if(_teamId == 12300) {
     thirteenthPlaceTeam = worldCupTeams[12];
   } else if(_teamId == 73) {
     thirteenthPlaceTeam = worldCupTeams[15];
   } else if(_teamId == 3017) {
     thirteenthPlaceTeam = worldCupTeams[18];
   } else if(_teamId == 12397) {
     thirteenthPlaceTeam = worldCupTeams[19];
   } else if(_teamId == 3024) {
     thirteenthPlaceTeam = worldCupTeams[16];
   } else if(_teamId == 3054) {
     thirteenthPlaceTeam = worldCupTeams[20];
   } else if(_teamId == 7835) {
     thirteenthPlaceTeam = worldCupTeams[21];
   } else if(_teamId == 3026) {
     thirteenthPlaceTeam = worldCupTeams[23];
   } else if(_teamId == 52) {
     thirteenthPlaceTeam = worldCupTeams[22];
   } else if(_teamId == 12504) {
     thirteenthPlaceTeam = worldCupTeams[24];
   } else if(_teamId == 85) {
     thirteenthPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3036) {
     thirteenthPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3064) {
     thirteenthPlaceTeam = worldCupTeams[26];
  } else if(_teamId == 95) {
     thirteenthPlaceTeam = worldCupTeams[29];
  } else if(_teamId == 755) {
    thirteenthPlaceTeam = worldCupTeams[31];
  } else if(_teamId == 12299) {
    thirteenthPlaceTeam = worldCupTeams[28];
  } else if(_teamId == 12501) {
    thirteenthPlaceTeam = worldCupTeams[30];
  }
}

 function setFourteenthPlaceTeam(uint _teamId) public {
  require(msg.sender == worldCupDataAddress, "USER_CANT_CALL_FUNCTION");
      /*
    14219 - IC Play-Off 1
    14220 - IC Play-Off 2

    Costa Rica
    Australia
    */
   if(_teamId == 12550) {
    fourteenthPlaceTeam =  worldCupTeams[1];
   } else if(_teamId == 3080) {
     fourteenthPlaceTeam=  worldCupTeams[3];
   } else if(_teamId == 12279) {
     fourteenthPlaceTeam = worldCupTeams[0];
   } else if(_teamId == 56) {
     fourteenthPlaceTeam = worldCupTeams[2];
   } else if(_teamId == 12302) {
     fourteenthPlaceTeam = worldCupTeams[4];
   } else if(_teamId == 12396) {
     fourteenthPlaceTeam = worldCupTeams[5];
   } else if(_teamId == 7850) {
     fourteenthPlaceTeam = worldCupTeams[6];
   } else if(_teamId == 14218) {
     fourteenthPlaceTeam = worldCupTeams[7];
   } else if(_teamId == 12502) {
     fourteenthPlaceTeam = worldCupTeams[8];
   } else if(_teamId == 12473) {
      fourteenthPlaceTeam = worldCupTeams[10];
   } else if(_teamId == 3011) {
     fourteenthPlaceTeam = worldCupTeams[11];
   } else if(_teamId == 767) {
     fourteenthPlaceTeam = worldCupTeams[9];
   } else if(_teamId == 3008) {
     fourteenthPlaceTeam = worldCupTeams[14];
   } else if(_teamId == 12300) {
     fourteenthPlaceTeam = worldCupTeams[12];
   } else if(_teamId == 73) {
     fourteenthPlaceTeam = worldCupTeams[15];
   } else if(_teamId == 3017) {
     fourteenthPlaceTeam = worldCupTeams[18];
   } else if(_teamId == 12397) {
     fourteenthPlaceTeam = worldCupTeams[19];
   } else if(_teamId == 3024) {
     fourteenthPlaceTeam = worldCupTeams[16];
   } else if(_teamId == 3054) {
     fourteenthPlaceTeam = worldCupTeams[20];
   } else if(_teamId == 7835) {
     fourteenthPlaceTeam = worldCupTeams[21];
   } else if(_teamId == 3026) {
     fourteenthPlaceTeam = worldCupTeams[23];
   } else if(_teamId == 52) {
     fourteenthPlaceTeam = worldCupTeams[22];
   } else if(_teamId == 12504) {
     fourteenthPlaceTeam = worldCupTeams[24];
   } else if(_teamId == 85) {
     fourteenthPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3036) {
     fourteenthPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3064) {
     fourteenthPlaceTeam = worldCupTeams[26];
  } else if(_teamId == 95) {
     fourteenthPlaceTeam = worldCupTeams[29];
  } else if(_teamId == 755) {
    fourteenthPlaceTeam = worldCupTeams[31];
  } else if(_teamId == 12299) {
    fourteenthPlaceTeam = worldCupTeams[28];
  } else if(_teamId == 12501) {
    fourteenthPlaceTeam = worldCupTeams[30];
  }
}

 function setFifteenthPlaceTeam(uint _teamId) public {
  require(msg.sender == worldCupDataAddress, "USER_CANT_CALL_FUNCTION");
      /*
    14219 - IC Play-Off 1
    14220 - IC Play-Off 2

    Costa Rica
    Australia
    */
   if(_teamId == 12550) {
    fifteenthPlaceTeam  =  worldCupTeams[1];
   } else if(_teamId == 3080) {
     fifteenthPlaceTeam  =  worldCupTeams[3];
   } else if(_teamId == 12279) {
     fifteenthPlaceTeam  = worldCupTeams[0];
   } else if(_teamId == 56) {
     fifteenthPlaceTeam  = worldCupTeams[2];
   } else if(_teamId == 12302) {
     fifteenthPlaceTeam  = worldCupTeams[4];
   } else if(_teamId == 12396) {
     fifteenthPlaceTeam  = worldCupTeams[5];
   } else if(_teamId == 7850) {
     fifteenthPlaceTeam  = worldCupTeams[6];
   } else if(_teamId == 14218) {
     fifteenthPlaceTeam  = worldCupTeams[7];
   } else if(_teamId == 12502) {
     fifteenthPlaceTeam  = worldCupTeams[8];
   } else if(_teamId == 12473) {
      fifteenthPlaceTeam  = worldCupTeams[10];
   } else if(_teamId == 3011) {
     fifteenthPlaceTeam  = worldCupTeams[11];
   } else if(_teamId == 767) {
     fifteenthPlaceTeam  = worldCupTeams[9];
   } else if(_teamId == 3008) {
     fifteenthPlaceTeam  = worldCupTeams[14];
   } else if(_teamId == 12300) {
     fifteenthPlaceTeam  = worldCupTeams[12];
   } else if(_teamId == 73) {
     fifteenthPlaceTeam  = worldCupTeams[15];
   } else if(_teamId == 3017) {
     fifteenthPlaceTeam  = worldCupTeams[18];
   } else if(_teamId == 12397) {
     fifteenthPlaceTeam  = worldCupTeams[19];
   } else if(_teamId == 3024) {
     fifteenthPlaceTeam  = worldCupTeams[16];
   } else if(_teamId == 3054) {
     fifteenthPlaceTeam  = worldCupTeams[20];
   } else if(_teamId == 7835) {
     fifteenthPlaceTeam  = worldCupTeams[21];
   } else if(_teamId == 3026) {
     fifteenthPlaceTeam  = worldCupTeams[23];
   } else if(_teamId == 52) {
     fifteenthPlaceTeam  = worldCupTeams[22];
   } else if(_teamId == 12504) {
     fifteenthPlaceTeam  = worldCupTeams[24];
   } else if(_teamId == 85) {
     fifteenthPlaceTeam  = worldCupTeams[27];
  } else if(_teamId == 3036) {
     fifteenthPlaceTeam  = worldCupTeams[27];
  } else if(_teamId == 3064) {
     fifteenthPlaceTeam  = worldCupTeams[26];
  } else if(_teamId == 95) {
     fifteenthPlaceTeam  = worldCupTeams[29];
  } else if(_teamId == 755) {
    fifteenthPlaceTeam  = worldCupTeams[31];
  } else if(_teamId == 12299) {
    fifteenthPlaceTeam  = worldCupTeams[28];
  } else if(_teamId == 12501) {
    fifteenthPlaceTeam  = worldCupTeams[30];
  }
}

 function setSixteenthPlaceTeam(uint _teamId) public {
  require(msg.sender == worldCupDataAddress, "USER_CANT_CALL_FUNCTION");
      /*
    14219 - IC Play-Off 1
    14220 - IC Play-Off 2

    Costa Rica
    Australia
    */
   if(_teamId == 12550) {
    sixteenthPlaceTeam =  worldCupTeams[1];
   } else if(_teamId == 3080) {
     sixteenthPlaceTeam =  worldCupTeams[3];
   } else if(_teamId == 12279) {
     sixteenthPlaceTeam = worldCupTeams[0];
   } else if(_teamId == 56) {
     sixteenthPlaceTeam = worldCupTeams[2];
   } else if(_teamId == 12302) {
     sixteenthPlaceTeam = worldCupTeams[4];
   } else if(_teamId == 12396) {
     sixteenthPlaceTeam = worldCupTeams[5];
   } else if(_teamId == 7850) {
     sixteenthPlaceTeam = worldCupTeams[6];
   } else if(_teamId == 14218) {
     sixteenthPlaceTeam = worldCupTeams[7];
   } else if(_teamId == 12502) {
     sixteenthPlaceTeam = worldCupTeams[8];
   } else if(_teamId == 12473) {
      sixteenthPlaceTeam = worldCupTeams[10];
   } else if(_teamId == 3011) {
     sixteenthPlaceTeam = worldCupTeams[11];
   } else if(_teamId == 767) {
     sixteenthPlaceTeam = worldCupTeams[9];
   } else if(_teamId == 3008) {
     sixteenthPlaceTeam = worldCupTeams[14];
   } else if(_teamId == 12300) {
     sixteenthPlaceTeam = worldCupTeams[12];
   } else if(_teamId == 73) {
     sixteenthPlaceTeam = worldCupTeams[15];
   } else if(_teamId == 3017) {
     sixteenthPlaceTeam = worldCupTeams[18];
   } else if(_teamId == 12397) {
     sixteenthPlaceTeam = worldCupTeams[19];
   } else if(_teamId == 3024) {
     sixteenthPlaceTeam = worldCupTeams[16];
   } else if(_teamId == 3054) {
     sixteenthPlaceTeam = worldCupTeams[20];
   } else if(_teamId == 7835) {
     sixteenthPlaceTeam = worldCupTeams[21];
   } else if(_teamId == 3026) {
     sixteenthPlaceTeam = worldCupTeams[23];
   } else if(_teamId == 52) {
     sixteenthPlaceTeam = worldCupTeams[22];
   } else if(_teamId == 12504) {
     sixteenthPlaceTeam = worldCupTeams[24];
   } else if(_teamId == 85) {
     sixteenthPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3036) {
     sixteenthPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3064) {
     sixteenthPlaceTeam = worldCupTeams[26];
  } else if(_teamId == 95) {
     sixteenthPlaceTeam = worldCupTeams[29];
  } else if(_teamId == 755) {
    sixteenthPlaceTeam = worldCupTeams[31];
  } else if(_teamId == 12299) {
    sixteenthPlaceTeam = worldCupTeams[28];
  } else if(_teamId == 12501) {
    sixteenthPlaceTeam = worldCupTeams[30];
  }
}

function getThirteenthPlaceTeam() public view returns(bytes memory team) {
  return thirteenthPlaceTeam;
}

function getFourteenthPlaceTeam() public view returns(bytes memory team) {
  return fourteenthPlaceTeam;
}

function getFifteenthPlaceTeam() public view returns(bytes memory team) {
  return fifteenthPlaceTeam;
}

function getSixteenthPlaceTeam() public view returns(bytes memory team) {
  return sixteenthPlaceTeam;
}

  function setWorldCupDataAddress(address _worldCupDataAddress) external onlyOwner {
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