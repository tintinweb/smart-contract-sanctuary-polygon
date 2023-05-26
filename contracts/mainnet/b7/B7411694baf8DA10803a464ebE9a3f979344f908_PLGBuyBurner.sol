/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IUnlocker {
    function updateVIPBlockWithPermit(address account,uint256 timer) external returns (bool);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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

contract PLGBuyBurner is permission {
    
    address public owner;
    address public PLG = 0x919A5712057173C7334cc60E7657791fF9ca6E8d;
    address public reward_pool = 0x9aCCd8D9D0DDc42cB2DDad985B0Fdf0e0bFB81fC;
    address public quick_router = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public refreward = 0x5EEddE12d4F65af99a29c27Dcbb9389732ddAC4a;

    uint256 public unlockdeeplevel_cost = 30 * 1e18;

    IDEXRouter router;

    bool locked;
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
        router = IDEXRouter(quick_router);
    }

    function buyUnlimitDeepLevel(address account) public payable noReentrant() returns (bool) {
        require(msg.value==unlockdeeplevel_cost,"Revert by MATIC cost");
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = PLG;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: msg.value }(
            0,
            path,
            address(0xdead),
            block.timestamp
        );
        IUnlocker(refreward).updateVIPBlockWithPermit(account,type(uint256).max);
        return true;
    }

    function buyBurnPLG() public payable noReentrant() returns (bool) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = PLG;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: msg.value }(
            0,
            path,
            address(0xdead),
            block.timestamp
        );
        return true;
    }

    function updateUnlockerCost(uint256 amount) public forRole("owner") returns (bool) {
        unlockdeeplevel_cost = amount;
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