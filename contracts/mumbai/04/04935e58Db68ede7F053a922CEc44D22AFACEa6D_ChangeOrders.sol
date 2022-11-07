import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IPrediction.sol";
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ChangeOrders is Ownable, ReentrancyGuard {
event TeamsSwapped(address predictor, bytes firstTeam, bytes secondTeam, uint indexed round);
address public predictionAddress;
bool paused;
 address public setAddress;
modifier onlyWhenNotPaused {
     require(paused == false, "CONTRACT_IS_PAUSED");
     _;
   }

   constructor(address _setAddress) {
     setAddress = _setAddress;
   }

function setPredictionAddress(address _predictionAddress) public {
  require(msg.sender == setAddress, "USER_CANT_CALL_FUNCTION");
  predictionAddress = _predictionAddress;
}

function setPause(bool _paused) external onlyOwner {
     paused = _paused;
   }

function changeOrderForTop32(uint _scenario) external nonReentrant onlyWhenNotPaused {
    bool isTop32 = IPrediction(predictionAddress).isPhase32();
    bool alreadyMinted = IPrediction(predictionAddress).haveYouMinted(msg.sender);
    bool mintedExtraTwo = IPrediction(predictionAddress).mintedExtraTwo(msg.sender);
    bool changed = IPrediction(predictionAddress).changedOrder(msg.sender, 32);
    bool beenThreeMinutes = IPrediction(predictionAddress).hasItBeenThreeMinutes();
    require(beenThreeMinutes == true, "WAIT_FOR_CONFIRMATION");
    require(isTop32 == true, "INITIAL_MINTING_PHASE_HASNT_FINISHED");
    require(alreadyMinted == true, "MINT_FIRST_FOUR_TEAMS_FIRST");
    require(changed == false, "CANT_CHANGE_TEAMS_TWICE");
    //Conditional statements specify each swapping possibility in swapping different teams for top 32
     if(_scenario == 1) {   
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamTwo);
       IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamTwo, 32);
     } else if(_scenario == 2) {
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamThree);
      IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamThree, 32);
     } else if(_scenario == 3) {
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamFour);
       IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamFour, 32);
     } else if(_scenario == 4) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamFive = IPrediction(predictionAddress).getPrediction(msg.sender, 5);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamFive);
       IPrediction(predictionAddress).setFifthPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamFive, 32);
     } else if(_scenario == 5) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamSix = IPrediction(predictionAddress).getPrediction(msg.sender, 6);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamSix);
       IPrediction(predictionAddress).setSixthPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamSix, 32);
     } else if(_scenario == 6) {
       bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
       bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
       IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamThree);
       IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamTwo);
       emit TeamsSwapped(msg.sender, teamTwo, teamThree, 32);
     } else if(_scenario == 7) {
       bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
       bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
        IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamFour);
        IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamTwo);
       emit TeamsSwapped(msg.sender, teamTwo, teamFour, 32);
     } else if(_scenario == 8) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
       bytes memory teamFive = IPrediction(predictionAddress).getPrediction(msg.sender, 5);
       IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamFive);
       IPrediction(predictionAddress).setFifthPrediction(msg.sender, teamTwo);
       emit TeamsSwapped(msg.sender, teamTwo, teamFive, 32);
     } else if(_scenario == 9) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
       bytes memory teamSix = IPrediction(predictionAddress).getPrediction(msg.sender, 6);
       IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamSix);
       IPrediction(predictionAddress).setSixthPrediction(msg.sender, teamTwo);
       emit TeamsSwapped(msg.sender, teamTwo, teamSix, 32);
     } else if(_scenario == 10) {
       bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
       bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
      IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamFour);
      IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamThree);
       emit TeamsSwapped(msg.sender, teamThree, teamFour, 32);
     } else if(_scenario == 11) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
       bytes memory teamFive = IPrediction(predictionAddress).getPrediction(msg.sender, 5);
        IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamFive);
        IPrediction(predictionAddress).setFifthPrediction(msg.sender, teamThree);
       emit TeamsSwapped(msg.sender, teamThree, teamFive, 32);
     } else if(_scenario == 12) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
       bytes memory teamSix = IPrediction(predictionAddress).getPrediction(msg.sender, 6);
        IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamSix);
        IPrediction(predictionAddress).setSixthPrediction(msg.sender, teamThree);
       emit TeamsSwapped(msg.sender, teamThree, teamSix, 32);
     } else if(_scenario == 13) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
       bytes memory teamFive = IPrediction(predictionAddress).getPrediction(msg.sender, 5);
       IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamFive);
       IPrediction(predictionAddress).setFifthPrediction(msg.sender, teamFour);
       emit TeamsSwapped(msg.sender, teamFour, teamFive, 32);
     } else if(_scenario == 14) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
       bytes memory teamSix = IPrediction(predictionAddress).getPrediction(msg.sender, 6);
        IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamSix);
        IPrediction(predictionAddress).setSixthPrediction(msg.sender, teamFour);
       emit TeamsSwapped(msg.sender, teamFour, teamSix, 32);
     }
     IPrediction(predictionAddress).setOrder(msg.sender, 32);
    } 

    function changeOrderForTop16(uint _scenario) external nonReentrant onlyWhenNotPaused {
    bool isTop16 = IPrediction(predictionAddress).isPhase16();
    bool alreadyMinted = IPrediction(predictionAddress).haveYouMinted(msg.sender);
    bool mintedExtraTwo = IPrediction(predictionAddress).mintedExtraTwo(msg.sender);
    bool changed = IPrediction(predictionAddress).changedOrder(msg.sender, 16);
    bool beenThreeMinutes = IPrediction(predictionAddress).hasItBeenThreeMinutes();
    require(beenThreeMinutes == true, "WAIT_FOR_CONFIRMATION");
    require(isTop16 == true, "TOP_16_HASNT_FINISHED");
    require(alreadyMinted == true, "MINT_FIRST_FOUR_TEAMS_FIRST");
    require(changed == false, "CANT_CHANGE_TEAMS_TWICE");
      if(_scenario == 1) {   
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamTwo);
       IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamTwo, 16);
     } else if(_scenario == 2) {
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamThree);
      IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamThree, 16);
     } else if(_scenario == 3) {
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamFour);
       IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamFour, 16);
     } else if(_scenario == 4) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamFive = IPrediction(predictionAddress).getPrediction(msg.sender, 5);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamFive);
       IPrediction(predictionAddress).setFifthPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamFive, 16);
     } else if(_scenario == 5) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamSix = IPrediction(predictionAddress).getPrediction(msg.sender, 6);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamSix);
       IPrediction(predictionAddress).setSixthPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamSix, 16);
     } else if(_scenario == 6) {
       bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
       bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
       IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamThree);
       IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamTwo);
       emit TeamsSwapped(msg.sender, teamTwo, teamThree, 16);
     } else if(_scenario == 7) {
       bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
       bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
        IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamFour);
        IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamTwo);
       emit TeamsSwapped(msg.sender, teamTwo, teamFour, 16);
     } else if(_scenario == 8) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
       bytes memory teamFive = IPrediction(predictionAddress).getPrediction(msg.sender, 5);
       IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamFive);
       IPrediction(predictionAddress).setFifthPrediction(msg.sender, teamTwo);
       emit TeamsSwapped(msg.sender, teamTwo, teamFive, 16);
     } else if(_scenario == 9) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
       bytes memory teamSix = IPrediction(predictionAddress).getPrediction(msg.sender, 6);
       IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamSix);
       IPrediction(predictionAddress).setSixthPrediction(msg.sender, teamTwo);
       emit TeamsSwapped(msg.sender, teamTwo, teamSix, 16);
     } else if(_scenario == 10) {
       bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
       bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
      IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamFour);
      IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamThree);
       emit TeamsSwapped(msg.sender, teamThree, teamFour, 16);
     } else if(_scenario == 11) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
       bytes memory teamFive = IPrediction(predictionAddress).getPrediction(msg.sender, 5);
        IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamFive);
        IPrediction(predictionAddress).setFifthPrediction(msg.sender, teamThree);
       emit TeamsSwapped(msg.sender, teamThree, teamFive, 16);
     } else if(_scenario == 12) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
       bytes memory teamSix = IPrediction(predictionAddress).getPrediction(msg.sender, 6);
        IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamSix);
        IPrediction(predictionAddress).setSixthPrediction(msg.sender, teamThree);
       emit TeamsSwapped(msg.sender, teamThree, teamSix, 16);
     } else if(_scenario == 13) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
       bytes memory teamFive = IPrediction(predictionAddress).getPrediction(msg.sender, 5);
       IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamFive);
       IPrediction(predictionAddress).setFifthPrediction(msg.sender, teamFour);
       emit TeamsSwapped(msg.sender, teamFour, teamFive, 16);
     } else if(_scenario == 14) {
       require(mintedExtraTwo == true, "DIDNT_MINT_PASS_FOUR_TEAMS");
       bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
       bytes memory teamSix = IPrediction(predictionAddress).getPrediction(msg.sender, 6);
        IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamSix);
        IPrediction(predictionAddress).setSixthPrediction(msg.sender, teamFour);
       emit TeamsSwapped(msg.sender, teamFour, teamSix, 16);
     }
     IPrediction(predictionAddress).setOrder(msg.sender, 16);
    } 
    
  function changeOrderForTop8(uint _scenario) external nonReentrant onlyWhenNotPaused {
    bool isTop8 = IPrediction(predictionAddress).isPhase8();
    bool alreadyMinted = IPrediction(predictionAddress).haveYouMinted(msg.sender);
    bool changed = IPrediction(predictionAddress).changedOrder(msg.sender, 8);
    bool beenThreeMinutes = IPrediction(predictionAddress).hasItBeenThreeMinutes();
    require(beenThreeMinutes == true, "WAIT_FOR_CONFIRMATION");
    require(isTop8 == true, "INITIAL_MINTING_PHASE_HASNT_FINISHED");
    require(alreadyMinted == true, "MINT_FIRST_FOUR_TEAMS_FIRST");
    require(changed == false, "CANT_CHANGE_TEAMS_TWICE");
    //Conditional statements specify each swapping possibility in swapping different teams for top 8
     if(_scenario == 1) {
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamTwo);
       IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamTwo, 8);
     } else if(_scenario == 2) {
      bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamThree);
      IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamThree, 8);
     } else if(_scenario == 3) {
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamFour);
       IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamFour, 8);
     } else if(_scenario == 4) {
       bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
       bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
       IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamThree);
       IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamTwo);
       emit TeamsSwapped(msg.sender, teamTwo, teamThree, 8);
     } else if(_scenario == 5) {
        bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
        bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
        IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamFour);
        IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamTwo);
       emit TeamsSwapped(msg.sender, teamTwo, teamFour, 8);
     } else if(_scenario == 6) {
     bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
     bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
      IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamFour);
      IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamThree);
       emit TeamsSwapped(msg.sender, teamThree, teamFour, 8);
     }
     IPrediction(predictionAddress).setOrder(msg.sender, 8);
    } 
    
    function changeOrderForTop4(uint _scenario) external nonReentrant onlyWhenNotPaused {
    bool isTop4 = IPrediction(predictionAddress).isPhase4();
    bool alreadyMinted = IPrediction(predictionAddress).haveYouMinted(msg.sender);
    bool changed = IPrediction(predictionAddress).changedOrder(msg.sender, 4);
    bool beenThreeMinutes = IPrediction(predictionAddress).hasItBeenThreeMinutes();
    require(beenThreeMinutes == true, "WAIT_FOR_CONFIRMATION");
    require(isTop4 == true, "TOP_4_HASNT_FINISHED");
    require(alreadyMinted == true, "MINT_FIRST_FOUR_TEAMS_FIRST");
    require(changed == false, "CANT_CHANGE_TEAMS_TWICE");
    //Conditional statements specify each swapping possibility in swapping different teams for top 4
     if(_scenario == 1) {
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamTwo);
       IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamTwo, 8);
     } else if(_scenario == 2) {
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamThree);
      IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamThree, 8);
     } else if(_scenario == 3) {
       bytes memory teamOne = IPrediction(predictionAddress).getPrediction(msg.sender, 1);
       bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
       IPrediction(predictionAddress).setFirstPrediction(msg.sender, teamFour);
       IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamOne);
       emit TeamsSwapped(msg.sender, teamOne, teamFour, 8);
     } else if(_scenario == 4) {
       bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
       bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
       IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamThree);
       IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamTwo);
       emit TeamsSwapped(msg.sender, teamTwo, teamThree, 8);
     } else if(_scenario == 5) {
        bytes memory teamTwo = IPrediction(predictionAddress).getPrediction(msg.sender, 2);
        bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
        IPrediction(predictionAddress).setSecondPrediction(msg.sender, teamFour);
        IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamTwo);
       emit TeamsSwapped(msg.sender, teamTwo, teamFour, 8);
     } else if(_scenario == 6) {
     bytes memory teamThree = IPrediction(predictionAddress).getPrediction(msg.sender, 3);
     bytes memory teamFour = IPrediction(predictionAddress).getPrediction(msg.sender, 4);
      IPrediction(predictionAddress).setThirdPrediction(msg.sender, teamFour);
      IPrediction(predictionAddress).setFourthPrediction(msg.sender, teamThree);
       emit TeamsSwapped(msg.sender, teamThree, teamFour, 8);
     }
     IPrediction(predictionAddress).setOrder(msg.sender, 4);
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