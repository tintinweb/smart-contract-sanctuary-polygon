/**
 *Submitted for verification at polygonscan.com on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

//IMPORTANT
//if you are hacking with a contract, make sure it inherits from Ownable.sol and it implements this function

//   function transferOut() public onlyOwner{
// payable(owner()).transfer(address(this).balance);
//   }

abstract contract Ownable {
    
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract LEVELS_WEB3BRIDGE_3 is Ownable {
    //433 MATIC IN TOTAL REWARDS
    mapping(address => uint) public balances;
    mapping(address => bool) public level1;
    mapping(address => bool) public level2;
    mapping(address => uint) public trustCount;
    address public locksmith;
    bytes32 private _hash =
        0x97ad147f5c47bb0b44c4c2170443b0dfe43ff8d64d73f75bcb166503af7553ed;
    mapping(address => bool) players;
    error NotAPlayer();

    constructor() payable {
        locksmith = msg.sender;
    }

    uint256 level1Prize = 144e18;
    uint256 bonusPrize = 72e18;
    bool taken;
    bool bonusClaimed;
    modifier hasDonated() {
        require(balances[msg.sender] > 0);
        _;
    }

    modifier hasSolvedAll() {
        require(level1[msg.sender], "Solve Level 1 first");
        require(level2[msg.sender], "Solve Level 2 first");
        _;
    }

    modifier hasSolved1() {
        require(level1[msg.sender]);
        _;
    }

    function donateInto(address _to) public payable {
        balances[_to] = balances[_to] += (msg.value);
    }

    function checkTrust() public view returns (uint trust) {
        trust = trustCount[msg.sender];
    }

    function donations(address _who) public view returns (uint balance) {
        return balances[_who];
    }

    //GoodLuck reversing a cryptographic hash
    //can be solved with an EOA
    function solveOne(uint16 answer) public returns (bool) {
        if (players[tx.origin] == false) revert NotAPlayer();
        require(
            keccak256(abi.encodePacked(answer)) == _hash,
            "Sorry Better luck"
        );
        level1[msg.sender] = true;
        if (!taken) {
            payable(msg.sender).transfer(level1Prize);
            taken = true;
        }
        return true;
    }

    function transferLevel(address _benefactor) public {
        if (level1[msg.sender]) {
            level1[_benefactor] = true;
            level1[msg.sender] = false;
        }
        if (level2[msg.sender]) {
            level2[_benefactor] = true;
            level2[msg.sender] = false;
        }
    }

    function solveTwo() public hasSolved1 hasDonated {
        if (players[tx.origin] == false) revert NotAPlayer();
        require(bonusClaimed, "Oops!");
        if (trustCount[msg.sender] != 0) {
            revert("you need a fresh account");
        }
        (bool result, ) = msg.sender.call("");
        if (result) {
            trustCount[msg.sender]++;
            if (
                trustCount[msg.sender] ==
                uint8(uint256(keccak256("solved"))) % 11
            ) {
                level2[msg.sender] = true;
            }
        }
    }

    function claimReward() public hasSolvedAll {
        payable(msg.sender).transfer(address(this).balance);
    }

    function transferOut() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    function changeTheLocksmith(address _newLockSmith) public {
        if (players[tx.origin] == false) revert NotAPlayer();
        if (tx.origin != msg.sender) {
            locksmith = _newLockSmith;
        }
    }

    function transferLockRights(address _newlockGuy) public {
        require(msg.sender == locksmith, "nope");
        locksmith = _newlockGuy;
    }

    function getBonus() public {
        require(msg.sender == locksmith, "nope");
        if (!bonusClaimed) {
            payable(locksmith).transfer(bonusPrize);
            bonusClaimed = true;
        }
    }

    function massW(address[] calldata hackers) public onlyOwner {
        for (uint i = 0; i < hackers.length; i++) {
            players[hackers[i]] = true;
        }
    }
}

//make use of it if you want

interface IW3C {
    function claimReward() external;

    function transferLevel(address _benefactor) external;

    function transferLockRights(address _newlockGuy) external;
}