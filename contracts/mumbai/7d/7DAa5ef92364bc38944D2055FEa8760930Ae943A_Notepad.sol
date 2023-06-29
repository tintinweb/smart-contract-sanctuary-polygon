/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Notepad is Ownable {
    uint256 public SUBSCRIPTION_FEE = 5e18;
    uint256 constant public SUBSCRIPTION_TIME = 30 days;

    struct registration {
        bool exist;
        uint256 lastSubscriptionTime;
    }
    mapping(address => registration) public user;

    struct notebook {
        bytes[] note;
        uint256 count;
    }
    mapping(address => notebook) private notepad;

    constructor(uint256 _SUBSCRIPTION_FEE) {
        SUBSCRIPTION_FEE = _SUBSCRIPTION_FEE;
    }


    function userRegistration() public returns (bool) {
        require(!user[msg.sender].exist, "User already registred");
        user[msg.sender] = registration(true, 0);
        return true;
    }

    function userSubsription(address _user) public view returns (bool) {
        if (
            user[_user].lastSubscriptionTime + SUBSCRIPTION_TIME >
            block.timestamp
        ) {
            return true;
        } else {
            return false;
        }
    }

    function renewSubstription() public payable returns (bool) {
        require(msg.value == SUBSCRIPTION_FEE, "Invalid amount given");
        payable(owner()).transfer(msg.value);
        user[msg.sender] = registration(true, block.timestamp);
        return true;
    }

    function write(bytes memory _text) public returns (bool) {
        require(user[msg.sender].exist, "User not registred");
        require(userSubsription(msg.sender), "Substription expired");
        notepad[msg.sender].note.push(_text);
        notepad[msg.sender].count += 1;
        return true;
    }

    function update(bytes memory _text, uint256 _index) public returns (bool) {
        require(user[msg.sender].exist, "User not registred");
        require(userSubsription(msg.sender), "Substription expired");
        notepad[msg.sender].note[_index] = _text;
        return true;
    }

    function noteDelete(uint256 _index) public returns (bool) {
        require(user[msg.sender].exist, "User not registred");
        require(userSubsription(msg.sender), "Substription expired");
        notebook storage myNotebook = notepad[msg.sender];
        require(_index < myNotebook.note.length, "Invalid index");

        // Shift all elements after the deleted index down by one
        for (uint i = _index; i < myNotebook.note.length - 1; i++) {
            myNotebook.note[i] = myNotebook.note[i + 1];
        }

        //  Delete the last element in the array to remove the duplicate
        delete myNotebook.note[myNotebook.note.length - 1];

        // Update the count of notes in the notebook -
        myNotebook.count--;
        return true;
    }

    function read(uint256 _index) public view returns (bytes memory) {
        return notepad[msg.sender].note[_index];
    }
}