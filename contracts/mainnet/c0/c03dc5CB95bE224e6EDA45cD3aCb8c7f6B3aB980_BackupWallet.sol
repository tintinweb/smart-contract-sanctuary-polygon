// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BackupWallet {

    address[] _members_;

    constructor(address[] memory _members) {
        _members_ = _members;
    }

    function members() public view returns(address[] memory) {
        return _members_;
    }

    function changeAddr(address newAddr) public {
        address oldAddr = msg.sender;
        uint256 len = _members_.length;
        bool oldAddrExists;
        uint256 oldIndex;
        
        for(uint256 i; i < len; i++) {
            if (oldAddr == _members_[i]) {
                oldIndex = i;
                oldAddrExists = true;
                break;
            }
        }
        require(oldAddrExists, "you are not exist in the contract");

        _members_[oldIndex] = _members_[len-1];
        _members_.pop();
        _members_.push(newAddr);
    }

    function distribute() public {
        uint256 len = _members_.length;
        uint256 fraction = address(this).balance / len;

        for(uint256 i; i < len; i++) {
            payable(_members_[i]).transfer(fraction);
        }
    }

    receive() external payable {}
}