import "@openzeppelin/contracts/access/Ownable.sol";
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract FetchTeamsThree is Ownable {
    bytes ninthPlaceTeam;
    bytes tenthPlaceTeam;
    bytes eleventhPlaceTeam;
    bytes twelfthPlaceTeam;
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


function setNinthPlaceTeam(uint _teamId) public {
  require(msg.sender == worldCupDataAddress, "USER_CANT_CALL_FUNCTION");
      /*
    14219 - IC Play-Off 1
    14220 - IC Play-Off 2

    Costa Rica
    Australia
    */
   if(_teamId == 12550) {
    ninthPlaceTeam = worldCupTeams[1];
   } else if(_teamId == 3080) {
     ninthPlaceTeam =  worldCupTeams[3];
   } else if(_teamId == 12279) {
     ninthPlaceTeam = worldCupTeams[0];
   } else if(_teamId == 56) {
     ninthPlaceTeam = worldCupTeams[2];
   } else if(_teamId == 12302) {
     ninthPlaceTeam = worldCupTeams[4];
   } else if(_teamId == 12396) {
     ninthPlaceTeam = worldCupTeams[5];
   } else if(_teamId == 7850) {
     ninthPlaceTeam = worldCupTeams[6];
   } else if(_teamId == 14218) {
     ninthPlaceTeam = worldCupTeams[7];
   } else if(_teamId == 12502) {
     ninthPlaceTeam = worldCupTeams[8];
   } else if(_teamId == 12473) {
      ninthPlaceTeam = worldCupTeams[10];
   } else if(_teamId == 3011) {
     ninthPlaceTeam = worldCupTeams[11];
   } else if(_teamId == 767) {
     ninthPlaceTeam = worldCupTeams[9];
   } else if(_teamId == 3008) {
     ninthPlaceTeam = worldCupTeams[14];
   } else if(_teamId == 12300) {
     ninthPlaceTeam = worldCupTeams[12];
   } else if(_teamId == 73) {
     ninthPlaceTeam = worldCupTeams[15];
   } else if(_teamId == 3017) {
     ninthPlaceTeam = worldCupTeams[18];
   } else if(_teamId == 12397) {
     ninthPlaceTeam = worldCupTeams[19];
   } else if(_teamId == 3024) {
     ninthPlaceTeam = worldCupTeams[16];
   } else if(_teamId == 3054) {
     ninthPlaceTeam = worldCupTeams[20];
   } else if(_teamId == 7835) {
     ninthPlaceTeam = worldCupTeams[21];
   } else if(_teamId == 3026) {
     ninthPlaceTeam = worldCupTeams[23];
   } else if(_teamId == 52) {
     ninthPlaceTeam = worldCupTeams[22];
   } else if(_teamId == 12504) {
     ninthPlaceTeam = worldCupTeams[24];
   } else if(_teamId == 85) {
     ninthPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3036) {
     ninthPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3064) {
     ninthPlaceTeam = worldCupTeams[26];
  } else if(_teamId == 95) {
     ninthPlaceTeam = worldCupTeams[29];
  } else if(_teamId == 755) {
    ninthPlaceTeam = worldCupTeams[31];
  } else if(_teamId == 12299) {
    ninthPlaceTeam = worldCupTeams[28];
  } else if(_teamId == 12501) {
    ninthPlaceTeam = worldCupTeams[30];
  }
}

 function setTenthPlaceTeam(uint _teamId) public {
  require(msg.sender == worldCupDataAddress, "USER_CANT_CALL_FUNCTION");
      /*
    14219 - IC Play-Off 1
    14220 - IC Play-Off 2

    Costa Rica
    Australia
    */
   if(_teamId == 12550) {
    tenthPlaceTeam =  worldCupTeams[1];
   } else if(_teamId == 3080) {
     tenthPlaceTeam=  worldCupTeams[3];
   } else if(_teamId == 12279) {
     tenthPlaceTeam = worldCupTeams[0];
   } else if(_teamId == 56) {
     tenthPlaceTeam = worldCupTeams[2];
   } else if(_teamId == 12302) {
     tenthPlaceTeam = worldCupTeams[4];
   } else if(_teamId == 12396) {
     tenthPlaceTeam = worldCupTeams[5];
   } else if(_teamId == 7850) {
     tenthPlaceTeam = worldCupTeams[6];
   } else if(_teamId == 14218) {
     tenthPlaceTeam = worldCupTeams[7];
   } else if(_teamId == 12502) {
     tenthPlaceTeam = worldCupTeams[8];
   } else if(_teamId == 12473) {
      tenthPlaceTeam = worldCupTeams[10];
   } else if(_teamId == 3011) {
     tenthPlaceTeam = worldCupTeams[11];
   } else if(_teamId == 767) {
     tenthPlaceTeam = worldCupTeams[9];
   } else if(_teamId == 3008) {
     tenthPlaceTeam = worldCupTeams[14];
   } else if(_teamId == 12300) {
     tenthPlaceTeam = worldCupTeams[12];
   } else if(_teamId == 73) {
     tenthPlaceTeam = worldCupTeams[15];
   } else if(_teamId == 3017) {
     tenthPlaceTeam = worldCupTeams[18];
   } else if(_teamId == 12397) {
     tenthPlaceTeam = worldCupTeams[19];
   } else if(_teamId == 3024) {
     tenthPlaceTeam = worldCupTeams[16];
   } else if(_teamId == 3054) {
     tenthPlaceTeam = worldCupTeams[20];
   } else if(_teamId == 7835) {
     tenthPlaceTeam = worldCupTeams[21];
   } else if(_teamId == 3026) {
     tenthPlaceTeam = worldCupTeams[23];
   } else if(_teamId == 52) {
     tenthPlaceTeam = worldCupTeams[22];
   } else if(_teamId == 12504) {
     tenthPlaceTeam = worldCupTeams[24];
   } else if(_teamId == 85) {
     tenthPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3036) {
     tenthPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3064) {
     tenthPlaceTeam = worldCupTeams[26];
  } else if(_teamId == 95) {
     tenthPlaceTeam = worldCupTeams[29];
  } else if(_teamId == 755) {
    tenthPlaceTeam = worldCupTeams[31];
  } else if(_teamId == 12299) {
    tenthPlaceTeam = worldCupTeams[28];
  } else if(_teamId == 12501) {
    tenthPlaceTeam = worldCupTeams[30];
  }
}

 function setEleventhPlaceTeam(uint _teamId) public {
  require(msg.sender == worldCupDataAddress, "USER_CANT_CALL_FUNCTION");
      /*
    14219 - IC Play-Off 1
    14220 - IC Play-Off 2

    Costa Rica
    Australia
    */
   if(_teamId == 12550) {
    eleventhPlaceTeam  =  worldCupTeams[1];
   } else if(_teamId == 3080) {
     eleventhPlaceTeam  =  worldCupTeams[3];
   } else if(_teamId == 12279) {
     eleventhPlaceTeam  = worldCupTeams[0];
   } else if(_teamId == 56) {
     eleventhPlaceTeam  = worldCupTeams[2];
   } else if(_teamId == 12302) {
     eleventhPlaceTeam  = worldCupTeams[4];
   } else if(_teamId == 12396) {
     eleventhPlaceTeam  = worldCupTeams[5];
   } else if(_teamId == 7850) {
     eleventhPlaceTeam  = worldCupTeams[6];
   } else if(_teamId == 14218) {
     eleventhPlaceTeam  = worldCupTeams[7];
   } else if(_teamId == 12502) {
     eleventhPlaceTeam  = worldCupTeams[8];
   } else if(_teamId == 12473) {
      eleventhPlaceTeam  = worldCupTeams[10];
   } else if(_teamId == 3011) {
     eleventhPlaceTeam  = worldCupTeams[11];
   } else if(_teamId == 767) {
     eleventhPlaceTeam  = worldCupTeams[9];
   } else if(_teamId == 3008) {
     eleventhPlaceTeam  = worldCupTeams[14];
   } else if(_teamId == 12300) {
     eleventhPlaceTeam  = worldCupTeams[12];
   } else if(_teamId == 73) {
     eleventhPlaceTeam  = worldCupTeams[15];
   } else if(_teamId == 3017) {
     eleventhPlaceTeam  = worldCupTeams[18];
   } else if(_teamId == 12397) {
     eleventhPlaceTeam  = worldCupTeams[19];
   } else if(_teamId == 3024) {
     eleventhPlaceTeam  = worldCupTeams[16];
   } else if(_teamId == 3054) {
     eleventhPlaceTeam  = worldCupTeams[20];
   } else if(_teamId == 7835) {
     eleventhPlaceTeam  = worldCupTeams[21];
   } else if(_teamId == 3026) {
     eleventhPlaceTeam  = worldCupTeams[23];
   } else if(_teamId == 52) {
     eleventhPlaceTeam  = worldCupTeams[22];
   } else if(_teamId == 12504) {
     eleventhPlaceTeam  = worldCupTeams[24];
   } else if(_teamId == 85) {
     eleventhPlaceTeam  = worldCupTeams[27];
  } else if(_teamId == 3036) {
     eleventhPlaceTeam  = worldCupTeams[27];
  } else if(_teamId == 3064) {
     eleventhPlaceTeam  = worldCupTeams[26];
  } else if(_teamId == 95) {
     eleventhPlaceTeam  = worldCupTeams[29];
  } else if(_teamId == 755) {
    eleventhPlaceTeam  = worldCupTeams[31];
  } else if(_teamId == 12299) {
    eleventhPlaceTeam  = worldCupTeams[28];
  } else if(_teamId == 12501) {
    eleventhPlaceTeam  = worldCupTeams[30];
  }
}

 function setTwelfthPlaceTeam(uint _teamId) public {
  require(msg.sender == worldCupDataAddress, "USER_CANT_CALL_FUNCTION");
      /*
    14219 - IC Play-Off 1
    14220 - IC Play-Off 2

    Costa Rica
    Australia
    */
   if(_teamId == 12550) {
    twelfthPlaceTeam =  worldCupTeams[1];
   } else if(_teamId == 3080) {
     twelfthPlaceTeam =  worldCupTeams[3];
   } else if(_teamId == 12279) {
     twelfthPlaceTeam = worldCupTeams[0];
   } else if(_teamId == 56) {
     twelfthPlaceTeam = worldCupTeams[2];
   } else if(_teamId == 12302) {
     twelfthPlaceTeam = worldCupTeams[4];
   } else if(_teamId == 12396) {
     twelfthPlaceTeam = worldCupTeams[5];
   } else if(_teamId == 7850) {
     twelfthPlaceTeam = worldCupTeams[6];
   } else if(_teamId == 14218) {
     twelfthPlaceTeam = worldCupTeams[7];
   } else if(_teamId == 12502) {
     twelfthPlaceTeam = worldCupTeams[8];
   } else if(_teamId == 12473) {
      twelfthPlaceTeam = worldCupTeams[10];
   } else if(_teamId == 3011) {
     twelfthPlaceTeam = worldCupTeams[11];
   } else if(_teamId == 767) {
     twelfthPlaceTeam = worldCupTeams[9];
   } else if(_teamId == 3008) {
     twelfthPlaceTeam = worldCupTeams[14];
   } else if(_teamId == 12300) {
     twelfthPlaceTeam = worldCupTeams[12];
   } else if(_teamId == 73) {
     twelfthPlaceTeam = worldCupTeams[15];
   } else if(_teamId == 3017) {
     twelfthPlaceTeam = worldCupTeams[18];
   } else if(_teamId == 12397) {
     twelfthPlaceTeam = worldCupTeams[19];
   } else if(_teamId == 3024) {
     twelfthPlaceTeam = worldCupTeams[16];
   } else if(_teamId == 3054) {
     twelfthPlaceTeam = worldCupTeams[20];
   } else if(_teamId == 7835) {
     twelfthPlaceTeam = worldCupTeams[21];
   } else if(_teamId == 3026) {
     twelfthPlaceTeam = worldCupTeams[23];
   } else if(_teamId == 52) {
     twelfthPlaceTeam = worldCupTeams[22];
   } else if(_teamId == 12504) {
     twelfthPlaceTeam = worldCupTeams[24];
   } else if(_teamId == 85) {
     twelfthPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3036) {
     twelfthPlaceTeam = worldCupTeams[27];
  } else if(_teamId == 3064) {
     twelfthPlaceTeam = worldCupTeams[26];
  } else if(_teamId == 95) {
     twelfthPlaceTeam = worldCupTeams[29];
  } else if(_teamId == 755) {
    twelfthPlaceTeam = worldCupTeams[31];
  } else if(_teamId == 12299) {
    twelfthPlaceTeam = worldCupTeams[28];
  } else if(_teamId == 12501) {
    twelfthPlaceTeam = worldCupTeams[30];
  }
}

function setNinthPlaceTeam() public view returns(bytes memory team) {
  return ninthPlaceTeam;
}

function setTenthPlaceTeam() public view returns(bytes memory team) {
  return tenthPlaceTeam;
}

function setEleventhPlaceTeam() public view returns(bytes memory team) {
  return eleventhPlaceTeam;
}

function setTwelfthPlaceTeam() public view returns(bytes memory team) {
  return twelfthPlaceTeam;
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