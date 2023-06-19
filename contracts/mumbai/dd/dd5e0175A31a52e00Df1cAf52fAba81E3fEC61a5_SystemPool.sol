// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SystemPool {
    
    address[] _members_;
    mapping(address => uint256) _fractions_;

    constructor (address[] memory _members, uint256[] memory _fractions) {
        require(
            _members.length == _fractions.length, 
            "_fractions_ and _members_ length difference"
        );
        uint256 denom;
        for(uint256 i; i < _fractions.length; i++) {
            denom += _fractions[i];
            _fractions_[_members[i]] = _fractions[i];
        }
        require(denom == 1000, "wrong denominator sum");
        _members_ = _members;
    }

    function members() public view returns(address[] memory temp) {
        uint256 len = _members_.length;
        temp = new address[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = _members_[i];
        }
    }

    function fractions() public view returns(uint256[] memory temp) {
        uint256 len = _members_.length;
        temp = new uint256[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = _fractions_[_members_[i]];
        }
    }
    
    function distribute() external {
        uint256 membersLen = _members_.length;
        uint256 balance = address(this).balance;
        address member;

        for(uint256 i; i < membersLen; i++) {
            member = _members_[i];
            payable(member).transfer(balance * _fractions_[member]/1000);
        }
    }

    receive() external payable {}
}