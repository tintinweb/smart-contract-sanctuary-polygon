/**
 *Submitted for verification at polygonscan.com on 2022-07-03
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)


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


// File contracts/Raffle.sol


contract Raffle is Ownable {

    string public name;
    string public optionsFile;
    uint256 public numberOfOptions;
    uint256[] public winners;

    // id is simply incrementing (first option chosen will have id==1, second will have id==2 and so on..)
    event OptionChosen(uint256 id, uint256 optionNumber);

    constructor(
        address _owner,
        string memory _name,
        string memory _optionsFile,
        uint256 _numberOfOptions
    ) {
        transferOwnership(_owner);
        name = _name;
        optionsFile = _optionsFile;
        numberOfOptions = _numberOfOptions;
    }

    /**
     * Returns a random uint256.
     */
    function _random() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty + gasleft() +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit +
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));
    }

    /**
     * Call this function to *randomly* choose a number in the range 0 to numberOfOptions.
     */
    function chooseOption(uint256 n) public onlyOwner {
        require(winners.length + n <= numberOfOptions, "Can't choose more than numberOfOptions winners.");

        uint256 chosenOption;

        for (uint256 i = 0; i < n; i++) {
            chosenOption = _random() % numberOfOptions;
            winners.push(chosenOption);
            emit OptionChosen(chosenOption, winners.length);
        }

    }
}


// File contracts/RaffleFactory.sol


contract RaffleFactory {

    mapping(address => Raffle[]) public raffleDeployments;
    address[] public raffleDeploymentsKeys;
    mapping(address => bool) public raffleDeploymentsKeyExists;

    event RaffleDeployed(
        address raffleAddress,
        address owner,
        string name,
        string optionsFile,
        uint256 numberOfOptions
    );

    constructor() {}

    function deploy(
        string memory name,
        string memory optionsFile,
        uint256 numberOfOptions
    ) public {
        Raffle raffle = new Raffle(msg.sender, name, optionsFile, numberOfOptions);
        raffleDeployments[msg.sender].push(raffle);
        if (!raffleDeploymentsKeyExists[msg.sender]) {
            raffleDeploymentsKeyExists[msg.sender] = true;
            raffleDeploymentsKeys.push(msg.sender);
        }
        emit RaffleDeployed(address(raffle), msg.sender, name, optionsFile, numberOfOptions);
    }
}