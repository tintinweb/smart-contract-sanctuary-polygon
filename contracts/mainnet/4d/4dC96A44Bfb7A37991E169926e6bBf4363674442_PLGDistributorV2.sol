/**
 *Submitted for verification at polygonscan.com on 2023-06-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGFactory {
    function getAddr(string memory key) external view returns (address);
}

interface IPLGAllsale {
    function addMaticReward() external payable returns (bool);
}

interface IPLGSwap {
    function buyPLG(address account,uint256 slippage,uint256 denominator) external payable returns (bool);
}

contract permission {
    mapping(address => mapping(string => bytes32)) private permit;

    function newpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode(adr,str))); }

    function clearpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode("null"))); }

    function checkpermit(address adr,string memory str) public view returns (bool) {
        if(permit[adr][str]==bytes32(keccak256(abi.encode(adr,str)))){ return true; }else{ return false; }
    }

    modifier forRole(string memory str) {
        require(checkpermit(msg.sender,str),"Permit Revert!");
        _;
    }
}

contract PLGDistributorV2 is permission {
    
    address public owner;

    IPLGFactory factory;

    uint256 public slippage = 960;
    uint256 public denominator = 1000;

    bool locked;
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor(address _factory) {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
        factory = IPLGFactory(_factory);
    }

    fallback() external payable {
        _distribute();
    }

    function manual() public returns (bool) {
        _distribute();
        return true;
    }

    function manualWithETH() public payable returns (bool) {
        _distribute();
        return true;
    }

    function _distribute() internal noReentrant {
        uint256 spenderAmount = address(this).balance;
        (bool success0,) = factory.getAddr("plg_marketingwallet").call{ value: spenderAmount * 30 / 150 }("");
        (bool success1,) = factory.getAddr("plg_reservewallet").call{ value: spenderAmount * 30 / 150 }("");
        (bool success2,) = factory.getAddr("plg_treasurywallet").call{ value: spenderAmount * 30 / 150 }("");
        (bool success3,) = factory.getAddr("plg_pool").call{ value: spenderAmount * 20 / 150 }("");
        IPLGAllsale(factory.getAddr("plg_allsale")).addMaticReward{ value: spenderAmount * 30 / 150 }();
        IPLGSwap(factory.getAddr("plg_depositPLG")).buyPLG{ value: spenderAmount * 10 / 150 }(address(0),slippage,denominator);
        require(
            success0 &&
            success1 &&
            success2 &&
            success3, "Failed to send ETH"
        );
    }

    function updateSlippage(uint256 _slippage,uint256 _denominator) public forRole("owner") returns (bool) {
        slippage = _slippage;
        denominator = _denominator;
        return true;
    }

    function factoryAddressSetting(address _factory) public forRole("owner") returns (bool) {
        factory = IPLGFactory(_factory);
        return true;
    }

    function purgeETH() public forRole("owner") returns (bool) {
      _clearStuckBalance(owner);
      return true;
    }

    function _clearStuckBalance(address receiver) internal {
      (bool success,) = receiver.call{ value: address(this).balance }("");
      require(success, "!fail to send eth");
    }

    function grantRole(address adr,string memory role) public forRole("owner") returns (bool) {
        newpermit(adr,role);
        return true;
    }

    function revokeRole(address adr,string memory role) public forRole("owner") returns (bool) {
        clearpermit(adr,role);
        return true;
    }

    function transferOwnership(address adr) public forRole("owner") returns (bool) {
        newpermit(adr,"owner");
        clearpermit(msg.sender,"owner");
        owner = adr;
        return true;
    }

    receive() external payable {}
}