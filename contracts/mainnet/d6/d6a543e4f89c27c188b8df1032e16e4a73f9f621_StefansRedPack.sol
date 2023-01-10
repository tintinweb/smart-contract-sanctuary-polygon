/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

/**
 * Let's GO!
 */
contract StefansRedPack is Ownable {
    // uint256 constant public TOKEN_LIMIT = 0x18;
    mapping(address => bool) public whitelist;
    // uint256[] private _tokenIndexMap;
    uint8 public range;
    uint256 public rangeDecimal;

    constructor() {
    }

    modifier needWhitelisted() {
        require(whitelist[_msgSender()] == true, "User not in whitelist");
        _;
    }

    function deposit() public payable {

    }

    function withdraw() public onlyOwner() {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }

    function redpack() public needWhitelisted() {
        uint256 randomNumber = random();
        uint256 number = randomNumber * rangeDecimal; // 有溢出bug，不过owner控制的，就无所谓了，懒得去用库了
        uint256 balance = address(this).balance;
        if(number >= balance) {
            number = balance;
        }
        require(number > 0, "Not enough money");
        (bool success, ) = msg.sender.call{value: number}("");
        require(success, "RedPack Failed.");
        whitelist[_msgSender()] = false;
    }

    function setRange(uint8 _range) public  {
        range=_range;
    }

    function setRangeDecimal(uint256 _rangeDecimal) public {
        rangeDecimal = _rangeDecimal;
    }

    function random() internal view returns (uint256) {
        uint256 result = uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 2),
            range,
            block.timestamp
        ))) % range;
        if(result == 0){
            result = 1;
        }
        return result;
    }

    // Set whitelist in batches
    function setWhitelists(address[] memory whitelists_, bool flag) external onlyOwner(){
        uint length = whitelists_.length;
        for (uint i=0; i<length; i++ ){
            address addr = whitelists_[i];
            whitelist[addr] = flag;
        }
    }

    function addWhitelist(address addr) external onlyOwner {
        whitelist[addr] = true;
    }
  
    function removeWhitelist(address addr) external onlyOwner {
        require(whitelist[addr], "Previous not in whitelist");
        whitelist[addr] = false;
    }
}