//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./ERC20.sol";

// import to make contract ownable
import "./Ownable.sol";

// import to set max supply
import "./ERC20PresetFixedSupply.sol";

// Console log functionality
import "./console.sol";

contract Squarium is ERC20PresetFixedSupply("Squarium", "SQR", 2000000 * 10**18, msg.sender), Ownable{

    uint256 constant MAX_INTERACTIONS =  1;
    mapping(address => uint256) dMintInteractionCount;
    mapping(address => uint256) aDropInteractionCount;
    uint256 constant aDropSupplyLimit = 72000000; 
    uint256 totalADropped = 0;

//Creating limit modifier of 1 for Dev Mint 
    modifier dMintLimit {
        require(dMintInteractionCount[msg.sender] < MAX_INTERACTIONS);
        dMintInteractionCount[msg.sender]++;
        _;
    }
//Creating limit modifier of 1 for AirDrop 
    modifier aDropLimit {
        require(aDropInteractionCount[msg.sender] < MAX_INTERACTIONS);
        aDropInteractionCount[msg.sender]++;
        _;
    }
//Creating limit modifier of 72000000 for airdrop
    modifier aDropSupply {
        require(totalADropped < aDropSupplyLimit);
        totalADropped += 1000000;
        _;
    }

// Function to mint 4.2 million tokens to dev team. Can only call once and only by owner. ("UPDATE ADDRESSES BEFORE DEPLOY")
    function devMint() onlyOwner external dMintLimit {
        _mint(0x2B3955B0B4eAB36f78D7D8B9a54D45842750B109, 2000000 * 10**18); // dev1
        _mint(0x56Ce9eCE67DB57f0b7D3BCfB8DE9a717D2C52559, 2000000 * 10**18); // dev2
        _mint(0xc9c81Af14eC5d7a4Ca19fdC9897054e2d033bf05, 2000000 * 10**18); // dev3
        _mint(0x4025ccdCf4774D9C148F273BBc6BFF9d9b24e180, 2000000 * 10**18); // dev4
        _mint(0xC4a4c57167556fb60cC13d196e17a158D0388acD, 2000000 * 10**18); // dev5
    }

// Airdrop of 1.000.000 tokens to any address, limit of 1 drop per address. Max supply = 84.000.000.
    function airDrop() public aDropLimit aDropSupply{
        _mint(msg.sender, 1000000 * 10**18);
    }
}