// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "Ownable.sol";

contract Race is Ownable {
    uint256 public MAXIMUM_MARBLE;
    uint256 public PRICE_PER_RACE;
    uint256 public fees;

    address public address_test;
    address marbleContractAddress;
    mapping(uint256 => uint256[]) internal tokenIdRegistered;
    mapping(uint256 => uint256[]) internal RaceleaderBoard;

    constructor(uint256 maximumMarble) public {
        changeMarbleContractAddress(0x80AFf21544b6670fCfD813134C83Bb340307c453);
        changePricePerRace(1e18);
        changeFees(3);
        changeMaximumMarble(maximumMarble);
    }

    function changeFees(uint256 _newFees) public onlyOwner {
        fees = _newFees;
    }

    function changePricePerRace(uint256 _newPrice) public onlyOwner {
        PRICE_PER_RACE = _newPrice;
    }

    function changeMaximumMarble(uint256 _maximum) public onlyOwner {
        MAXIMUM_MARBLE = _maximum;
    }

    function changeMarbleContractAddress(address _NewAddress) public onlyOwner {
        marbleContractAddress = _NewAddress;
    }

    function getTokenIdRegisteredIn(uint256 _Id)
        public
        view
        returns (uint256[] memory)
    {
        return tokenIdRegistered[_Id];
    }

    function registerToRace(uint256 raceID, uint256 tokenID) public payable {
        require(tokenIdRegistered[raceID].length < MAXIMUM_MARBLE);
        require(msg.value >= PRICE_PER_RACE, "Need more money");
        tokenIdRegistered[raceID].push(tokenID);
    }

    function ownerOf(uint256 id) internal returns (address) {
        (bool success, bytes memory returndata) = marbleContractAddress.call(
            abi.encodeWithSignature("ownerOf(uint256)", id)
        );
        return abi.decode(returndata, (address));
    }

    function updateRaceLeaderboard(
        uint256 raceID,
        uint256[] memory _leaderboard
    ) public onlyOwner {
        uint256 _balance = address(this).balance;
        RaceleaderBoard[raceID] = _leaderboard;
        // Add owner of
        payable(ownerOf(_leaderboard[0])).transfer((PRICE_PER_RACE * 39) / 10);
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        payable(0xbc641d0c1acc8F85bB53aceAdE03BBC58de693D1).transfer(_balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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