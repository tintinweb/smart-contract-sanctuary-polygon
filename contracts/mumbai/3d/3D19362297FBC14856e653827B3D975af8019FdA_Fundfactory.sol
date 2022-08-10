//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { StringUtils } from "./stringUtils.sol";
import './Clonefactory.sol';
import './Fundme.sol';

contract Fundfactory is CloneFactory{
  Fundme[] public fundChildrenAddresses;
  address public implementationAddress;

  event Fundcreated(address _creator, string _name, string _description, uint256 _goal, uint256 _deadline, address _fundAddress);


  constructor(address _implementationAddress) {
    implementationAddress = _implementationAddress;
  }


  function createFund(string memory _name, 
                string memory _description, 
                string memory _externalSite, 
                uint256 _deadline, 
                uint256 _fundingGoal 
                      ) external {
        Fundme newFund = Fundme(createClone(implementationAddress));
        newFund.initialize(
          _name,
          _description,
          _externalSite,
          _deadline,
          _fundingGoal,
          msg.sender
        );

        fundChildrenAddresses.push(newFund);
        emit Fundcreated(msg.sender,
                         _name,
                         _description,
                         _fundingGoal,
                         _deadline,
                         address(newFund));
  }

  function viewFundProjects() external view returns (Fundme[] memory _addresses){
    _addresses = fundChildrenAddresses;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { StringUtils } from "./stringUtils.sol";


contract Fundme {
    string public name;
    string public description;
    string public externalSite;
    uint256 public deadline;
    uint256 public fundingGoal;
    address payable public owner;
    uint256 private alreadyInitialized;
    

    mapping(address => uint256) public contributors;

    event donated(string successMessage, uint256 amount, address participant, uint256 currentBalance);
    event withdrawn(string successMessage, uint256 amount, address owner, uint256 delta);

    function initialize(string memory _name, 
                string memory _description, 
                string memory _externalSite, 
                uint256 _deadline, 
                uint256 _fundingGoal, 
                address _owner) public {
                    
        require(alreadyInitialized != 1);
        require (StringUtils.strlen(_name) > 0);
        require (StringUtils.strlen(_description) > 0);
        require(_deadline > (1 days + block.timestamp));
        require(_fundingGoal > 0);

        alreadyInitialized = 1;
        name = _name;
        description = _description;
        externalSite = _externalSite;
        deadline = _deadline;
        fundingGoal = _fundingGoal;
        owner = payable(_owner);
    }

    function donate() external payable returns (string memory _contributed) {
        require(msg.value >= .001 ether, 'Your contribution must be greater than 0.001 ETH');
        require(block.timestamp <= deadline, 'The time to contribute to this cause has passed.');
        contributors[msg.sender] += msg.value;
        emit donated('You have successfully donated to this cause.', msg.value, msg.sender, address(this).balance);
        _contributed = 'Your donation was successful';
    }

    function viewOverview() public view returns (string memory _name, 
                                                 string memory _description, 
                                                 string memory _externalSite,
                                                 uint256 _goal, 
                                                 uint256 _bal, 
                                                 uint256 _timeRemaining){
        _name = name;
        _description = description;
        _externalSite = externalSite;
        _goal = fundingGoal;
        _bal = address(this).balance;
        _timeRemaining = deadline - block.timestamp;
    }

    function withDraw() public onlyOwner {
        require(address(this).balance > 0);
        require(block.timestamp > deadline);
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Failed to withdraw donations.");   
    }
     

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}