import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ISetAddresses.sol";
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SetAddresses is Ownable {
   function setTheAddresses(address _predictionAddress, address _worldCupDataAddress, address _fetchTeamOne, address _fetchTeamTwo, address _fetchTeamThree, address _fetchTeamFour, address _mintTeamOneAddress, address _mintTeamTwoAddress, address _evolveAddress, address _randomAndRoundAddress, address _changeOrder) external onlyOwner {
      ISetAddresses(_randomAndRoundAddress).setPredictionAddress(_predictionAddress);
      ISetAddresses(_randomAndRoundAddress).setWorldCupDataAddress(_worldCupDataAddress);
      ISetAddresses(_changeOrder).setPredictionAddress(_predictionAddress);
      ISetAddresses(_evolveAddress).setPredictionAddress(_predictionAddress);
      ISetAddresses(_evolveAddress).setFetchTeamOne(_fetchTeamOne);
      ISetAddresses(_evolveAddress).setFetchTeamTwo(_fetchTeamTwo);
      ISetAddresses(_evolveAddress).setFetchTeamThree(_fetchTeamThree);
      ISetAddresses(_evolveAddress).setFetchTeamFour(_fetchTeamFour);
      ISetAddresses(_evolveAddress).setMintTeamOneAddress(_mintTeamOneAddress);
      ISetAddresses(_evolveAddress).setMintTeamTwoAddress(_mintTeamTwoAddress);
      ISetAddresses(_fetchTeamOne).setWorldCupDataAddress(_worldCupDataAddress);
      ISetAddresses(_fetchTeamTwo).setWorldCupDataAddress(_worldCupDataAddress);
      ISetAddresses(_fetchTeamThree).setWorldCupDataAddress(_worldCupDataAddress);
      ISetAddresses(_fetchTeamFour).setWorldCupDataAddress(_worldCupDataAddress);
      ISetAddresses(_mintTeamOneAddress).setPredictionAddress(_predictionAddress);
      ISetAddresses(_mintTeamOneAddress).setEvolveAddress(_evolveAddress);
      ISetAddresses(_mintTeamOneAddress).setMintTeamTwoAddress(_mintTeamTwoAddress);
      ISetAddresses(_mintTeamTwoAddress).setPredictionAddress(_predictionAddress);
      ISetAddresses(_mintTeamTwoAddress).setEvolveAddress(_evolveAddress);
      ISetAddresses(_mintTeamTwoAddress).setMintTeamOneAddress(_mintTeamOneAddress);
      ISetAddresses(_predictionAddress).setRandomAndRoundAddress(_randomAndRoundAddress);
      ISetAddresses(_predictionAddress).setWorldCupDataAddress(_worldCupDataAddress);
      ISetAddresses(_predictionAddress).setChangeOrderAddress(_changeOrder);
      ISetAddresses(_predictionAddress).setFetchTeamOne(_fetchTeamOne);
      ISetAddresses(_predictionAddress).setMintTeamOneAddress(_mintTeamOneAddress);
      ISetAddresses(_worldCupDataAddress).setRandomAndRoundAddress(_randomAndRoundAddress);
      ISetAddresses(_worldCupDataAddress).setFetchTeamOne(_fetchTeamOne);
      ISetAddresses(_worldCupDataAddress).setFetchTeamTwo(_fetchTeamTwo);
      ISetAddresses(_worldCupDataAddress).setFetchTeamThree(_fetchTeamThree);
      ISetAddresses(_worldCupDataAddress).setFetchTeamFour(_fetchTeamFour);
      ISetAddresses(_worldCupDataAddress).setPredictionAddress(_predictionAddress);
   }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISetAddresses {
    function setPredictionAddress(address _predictionAddress) external;
    function setWorldCupDataAddress(address _worldCupDataAddress) external;
    function setFetchTeamOne(address _fetchTeamOneAddress) external;
    function setFetchTeamTwo(address _fetchTeamTwoAddress) external;
    function setFetchTeamThree(address _fetchTeamTwoAddress) external;
    function setFetchTeamFour(address _fetchTeamTwoAddress) external;
    function setMintTeamOneAddress(address _mintTeamOneAddress) external;
    function setMintTeamTwoAddress(address _mintTeamTwoAddress) external;
    function setEvolveAddress(address _evolveAddress) external;
    function setRandomAndRoundAddress(address _randomNumberAndRoundAddress) external;
    function setChangeOrderAddress(address _changeOrderAddress) external;
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