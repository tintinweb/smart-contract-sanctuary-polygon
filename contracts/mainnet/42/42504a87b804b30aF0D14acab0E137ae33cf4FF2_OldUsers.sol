// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MultiPort {

    address factory;

    constructor(address _factoryAddr) {
        factory = _factoryAddr;
    }

    function distribute(address[] calldata members, uint256[] calldata fractions) public {
        require(msg.sender == factory, "only Factory can distribute");
        uint256 balance = address(this).balance;
        uint256 len = members.length;
        for(uint256 i; i < len; i++) {
            payable(members[i]).transfer(balance * fractions[i]/1000);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MultiPort.sol";

contract OldUsers {

    MultiPort[] _ports_;

    address[] _members_;
    mapping(address => uint256) _fractions_;


    constructor(address[] memory _members, uint256[] memory _fractions, uint256 numPorts) {
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

        for(uint256 i; i < numPorts; i++) {
            _ports_.push(newPort());
        }
    }

    function ports() public view returns(address[] memory temp) {
        uint256 len = _ports_.length;
        temp = new address[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = address(_ports_[i]);
        }
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

    function newPort() private returns(MultiPort mp) {
        mp = new MultiPort(address(this));
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

        _fractions_[newAddr] = _fractions_[oldAddr];
        delete _fractions_[oldAddr];
    }

    function distribute() public {
        uint256 portsLen = _ports_.length;

        address[] memory _members = _members_; 
        uint256 membersLen = _members_.length;
        uint256[] memory _fractions = new uint256[](membersLen);

        for(uint256 i; i < membersLen; i++) {
            _fractions[i] = _fractions_[_members[i]];
        }

        for(uint256 i; i < portsLen; i++) {
            _ports_[i].distribute(_members, _fractions);
        }
    }
}