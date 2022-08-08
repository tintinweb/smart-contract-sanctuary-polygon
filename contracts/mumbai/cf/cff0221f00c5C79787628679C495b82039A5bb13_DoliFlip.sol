// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DoliFlip is Ownable{
    //3,3% (33 on 1000)
    uint feesPercentage = 33;

    event NewBet(
        address indexed _from,
        uint _value,
        bool hasWon
    );

    struct Bet{
        address from;
        uint _value;
        bool haswon;
    }

    //Array with all bets
    Bet[] bets;

    ////////////////////////////////////////
    function play() external payable { 
        require(msg.value >= 0.001*10**18, "You bet less then the minimum amount of coins");

        uint256 randomNumber = getRandomNumber();
        bool _hasWon = false;
        if (randomNumber < 500){
            _hasWon = true;
            transferPrize(msg.value+(msg.value*feesPercentage/1000), msg.sender);
        } else {
            //lost
        }

        bets.push(Bet(
            msg.sender,
            msg.value,
            _hasWon  
        ));

        emit NewBet(
            msg.sender,
            msg.value,
            _hasWon
        );
    }

    function transferPrize(uint _prize, address _winner) public {     
        //check if contract address can pay the prize and pay him
        require(_prize < address(this).balance, "You got rugged!");

        uint _netPrize = _prize - (_prize*feesPercentage/1000);

        if (_netPrize*2 < address(this).balance){
            payable(_winner).transfer(_netPrize*2);
        }
        else {
            payable(_winner).transfer(_netPrize);
        }
    }

    function withdraw(uint _amount) external onlyOwner {
        require(_amount < address(this).balance, "");
        payable(msg.sender).transfer(_amount);
    }

    function getRandomNumber() private view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
        block.number
        )));
        return (seed - ((seed / 1000) * 1000));
    }

    function changeFeesPercentage(uint value) external onlyOwner {
        feesPercentage = value;
    }

    function getBets() public view returns(Bet[] memory){
        return bets;
    }

    fallback () external payable{
    }

    receive () external payable{
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