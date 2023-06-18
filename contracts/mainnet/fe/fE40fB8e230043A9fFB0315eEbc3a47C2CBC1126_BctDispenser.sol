/**
 *Submitted for verification at polygonscan.com on 2023-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract BctDispenser {
    struct Claim {
        bool claimed;
        uint256 bgcId;
    }

    mapping(uint256 => Claim) public existingClaims;

    ERC721 bgcContract = ERC721(0x07E7b044aD966a45605ccBff64d16d0DCB1f79dF);
    ERC20 bctContract = ERC20(0xc4004dd97b343111B1D6ffE403f9c1Af8453E352);

    bool paused = false;
    address deployer;
    uint256 amount = 10000 * 1 ether;

    event Dispense(uint256 amount, uint256 bgcId);

    constructor() {
        deployer = msg.sender;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer);
        _;
    }

    modifier pauseable() {
        require(paused == false, "contract is paused");
        _;
    }

    function pause() public onlyDeployer {
        paused = true;
    }

    function unpause() public onlyDeployer {
        paused = false;
    }

    function setAmount(uint256 newAmount) public onlyDeployer pauseable {
        amount = newAmount;
    }

    function withdraw(uint256 withdrawAmount) public onlyDeployer pauseable {
        bctContract.transfer(msg.sender, withdrawAmount);
    }
    
    function claimBct(uint256 bgcId) public pauseable {
        Claim memory claim = existingClaims[bgcId];
        require(
            claim.claimed == false,
            "tokens have already been claimed for this Barbarius"
        );

        address bgcOwner = bgcContract.ownerOf(bgcId);
        require(msg.sender == bgcOwner, "caller is not owner of this BGC");

        existingClaims[bgcId] = Claim(true, bgcId);
        bctContract.transfer(msg.sender, amount);

        emit Dispense(amount, bgcId);
    }
    
    function multiClaimBct(uint256[] memory bgcIds) public pauseable {
        for(uint i = 0; i < bgcIds.length; i++) {
            claimBct(bgcIds[i]);
        }
    }
}

abstract contract ERC721 {
    function ownerOf(uint256 id) public virtual returns (address);
}

abstract contract ERC20 {
    function transfer(address to, uint256 value) public virtual;
}