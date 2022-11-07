import "../interfaces/IFetchTeams.sol";
import "../interfaces/IMintTeams.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IPrediction.sol";


//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Evolve is Ownable, ReentrancyGuard {
address public fetchTeamOneAddress;
address public fetchTeamTwoAddress;
address public fetchTeamThreeAddress;
address public fetchTeamFourAddress;
address public mintTeamOneAddress;
address public mintTeamTwoAddress;
address public predictionAddress;
address public setAddress;

bool paused;
modifier onlyWhenNotPaused {
     require(paused == false, "CONTRACT_IS_PAUSED");
     _;
   }
   constructor(address _setAddress) {
     setAddress = _setAddress;
   }

function setPause(bool _paused) external onlyOwner {
     paused = _paused;
   }

    function setPredictionAddress(address _predictionAddress) public {
    require(msg.sender == setAddress, "USER_CANT_CALL_FUNCTION");
    predictionAddress = _predictionAddress;
 }


    function getFetchTeamOne(address _fetchTeamOneAddress) public {
      require(msg.sender == setAddress, "USER_CANT_CALL_FUNCTION");
       fetchTeamOneAddress = _fetchTeamOneAddress;
    }

     function getFetchTeamTwo(address _fetchTeamTwoAddress) public {
      require(msg.sender == setAddress, "USER_CANT_CALL_FUNCTION");
       fetchTeamTwoAddress = _fetchTeamTwoAddress;
    }

     function getFetchTeamThree(address _fetchTeamThreeAddress) public {
      require(msg.sender == setAddress, "USER_CANT_CALL_FUNCTION");
       fetchTeamThreeAddress = _fetchTeamThreeAddress;
    }

      function getFetchTeamFour(address _fetchTeamFourAddress) public {
        require(msg.sender == setAddress, "USER_CANT_CALL_FUNCTION");
       fetchTeamFourAddress = _fetchTeamFourAddress;
    }

    function getMintTeamOneAddress(address _mintTeamOneAddress) public {
      require(msg.sender == setAddress, "USER_CANT_CALL_FUNCTION");
      mintTeamOneAddress = _mintTeamOneAddress;
    }

     function getMintTeamTwoAddress(address _mintTeamTwoAddress) public {
      require(msg.sender == setAddress, "USER_CANT_CALL_FUNCTION");
      mintTeamTwoAddress = _mintTeamTwoAddress;
    }
  
  function evolveToLevel2(string calldata _teamName) external nonReentrant onlyWhenNotPaused  {
    bool beenThreeMinutes = IPrediction(predictionAddress).hasItBeenThreeMinutes();
    require(beenThreeMinutes == true, "WAIT_FOR_CONFIRMATION");
    bytes[] memory teams = new bytes[](16);
    bool teamsMatch;
    teams[0] = IFetchTeams(fetchTeamOneAddress).getFirstPlaceTeam();
    teams[1] = IFetchTeams(fetchTeamOneAddress).getSecondPlaceTeam();
    teams[2] = IFetchTeams(fetchTeamOneAddress).getThirdPlaceTeam();
    teams[3] = IFetchTeams(fetchTeamOneAddress).getFourthPlaceTeam();
    teams[4] = IFetchTeams(fetchTeamTwoAddress).getFifthPlaceTeam();
    teams[5] = IFetchTeams(fetchTeamTwoAddress).getSixthPlaceTeam();
    teams[6] = IFetchTeams(fetchTeamTwoAddress).getSeventhPlaceTeam();
    teams[7] = IFetchTeams(fetchTeamTwoAddress).getEighthPlaceTeam();
    teams[8] = IFetchTeams(fetchTeamThreeAddress).getNinthPlaceTeam();
    teams[9] = IFetchTeams(fetchTeamThreeAddress).getTenthPlaceTeam();
    teams[10] = IFetchTeams(fetchTeamThreeAddress).getEleventhPlaceTeam();
    teams[11] = IFetchTeams(fetchTeamThreeAddress).getTwelfthPlaceTeam();
    teams[12] = IFetchTeams(fetchTeamFourAddress).getThirteenthPlaceTeam();
    teams[13] = IFetchTeams(fetchTeamFourAddress).getFourteenthPlaceTeam();
    teams[14] = IFetchTeams(fetchTeamFourAddress).getFifteenthPlaceTeam();
    teams[15] = IFetchTeams(fetchTeamFourAddress).getSixteenthPlaceTeam();
    
    for(uint i = 0; i < teams.length; i++) {
       if(keccak256(abi.encode(_teamName)) == keccak256(teams[i])) {
          teamsMatch = true;
          break;
       }
    }
    if(teamsMatch == false) {
        revert("TEAM_NOT_IN_TOP_16");
    } else {
      IMintTeams(mintTeamOneAddress).claimLevel2Nft(msg.sender, _teamName);
    }
  }

  function evolveToLevel3(string calldata _teamName) external nonReentrant onlyWhenNotPaused  {
    bool beenThreeMinutes = IPrediction(predictionAddress).hasItBeenThreeMinutes();
    require(beenThreeMinutes == true, "WAIT_FOR_CONFIRMATION");
    bytes[] memory teams = new bytes[](8);
    bool teamsMatch;
    teams[0] = IFetchTeams(fetchTeamOneAddress).getFirstPlaceTeam();
    teams[1] = IFetchTeams(fetchTeamOneAddress).getSecondPlaceTeam();
    teams[2] = IFetchTeams(fetchTeamOneAddress).getThirdPlaceTeam();
    teams[3] = IFetchTeams(fetchTeamOneAddress).getFourthPlaceTeam();
    teams[4] = IFetchTeams(fetchTeamTwoAddress).getFifthPlaceTeam();
    teams[5] = IFetchTeams(fetchTeamTwoAddress).getSixthPlaceTeam();
    teams[6] = IFetchTeams(fetchTeamTwoAddress).getSeventhPlaceTeam();
    teams[7] = IFetchTeams(fetchTeamTwoAddress).getEighthPlaceTeam();
    
    for(uint i = 0; i < teams.length; i++) {
       if(keccak256(abi.encode(_teamName)) == keccak256(teams[i])) {
          teamsMatch = true;
          break;
       }
    }
    if(teamsMatch == false) {
        revert("TEAM_NOT_IN_TOP_8");
    } else {
      IMintTeams(mintTeamTwoAddress).claimLevel3Nft(msg.sender, _teamName);
    }
  }

  function evolveToLevel4(string calldata _teamName) external nonReentrant onlyWhenNotPaused  {
    bool beenThreeMinutes = IPrediction(predictionAddress).hasItBeenThreeMinutes();
    require(beenThreeMinutes == true, "WAIT_FOR_CONFIRMATION");
    bytes[] memory teams = new bytes[](4);
    bool teamsMatch;
    teams[0] = IFetchTeams(fetchTeamOneAddress).getFirstPlaceTeam();
    teams[1] = IFetchTeams(fetchTeamOneAddress).getSecondPlaceTeam();
    teams[2] = IFetchTeams(fetchTeamOneAddress).getThirdPlaceTeam();
    teams[3] = IFetchTeams(fetchTeamOneAddress).getFourthPlaceTeam();
    
    for(uint i = 0; i < teams.length; i++) {
       if(keccak256(abi.encode(_teamName)) == keccak256(teams[i])) {
          teamsMatch = true;
          break;
       }
    }
    if(teamsMatch == false) {
        revert("TEAM_NOT_IN_TOP_4");
    } else {
      IMintTeams(mintTeamTwoAddress).claimLevel4Nft(msg.sender, _teamName);
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFetchTeams {
    function setFirstPlaceTeam(uint _teamId) external;
    function setSecondPlaceTeam(uint _teamId) external;
    function setThirdPlaceTeam(uint _teamId) external;
    function setFourthPlaceTeam(uint _teamId) external;
    function setFifthPlaceTeam(uint _teamId) external;
    function setSixthPlaceTeam(uint _teamId) external;
    function setSeventhPlaceTeam(uint _teamId) external;
    function setEighthPlaceTeam(uint _teamId) external;
    function setNinthPlaceTeam(uint _teamId) external;
    function setTenthPlaceTeam(uint _teamId) external;
    function setEleventhPlaceTeam(uint _teamId) external;
    function setTwelfthPlaceTeam(uint _teamId) external;
    function setThirteenthPlaceTeam(uint _teamId) external;
    function setFourteenthPlaceTeam(uint _teamId) external;
    function setFifteenthPlaceTeam(uint _teamId) external;
    function setSixteenthPlaceTeam(uint _teamId) external;
    function getFirstPlaceTeam() external view returns(bytes memory team);
    function getSecondPlaceTeam() external view returns(bytes memory team);
    function getThirdPlaceTeam() external view returns(bytes memory team);
    function getFourthPlaceTeam() external view returns(bytes memory team);
    function getFifthPlaceTeam() external view returns(bytes memory team);
    function getSixthPlaceTeam() external view returns(bytes memory team);
    function getSeventhPlaceTeam() external view returns(bytes memory team);
    function getEighthPlaceTeam() external view returns(bytes memory team);
    function getNinthPlaceTeam() external view returns(bytes memory team);
    function getTenthPlaceTeam() external view returns(bytes memory team);
    function getEleventhPlaceTeam() external view returns(bytes memory team);
    function getTwelfthPlaceTeam() external view returns(bytes memory team);
    function getThirteenthPlaceTeam() external view returns(bytes memory team);
    function getFourteenthPlaceTeam() external view returns(bytes memory team);
    function getFifteenthPlaceTeam() external view returns(bytes memory team);
    function getSixteenthPlaceTeam() external view returns(bytes memory team);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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