// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./Ownable.sol";
import "./Context.sol";


contract SPYC is ERC20, Ownable {
    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) public controllers;

     uint256 public constant SPYC_Coin_TotalSupply = 10000000000 ether;

uint256 public constant inital_liquidity = 10000 ether;
    // Minted amount
    uint256 public totalStakingSupply;
 

    constructor() ERC20("SPYC Token", "SPYC") {}

    /**
     * mints $SPYC from staking supply to a recipient
     * @param to the recipient of the $SPYC
     * @param amount the amount of $SPYC to mint
     */
    function stakingMint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        require(
            totalStakingSupply + amount <= SPYC_Coin_TotalSupply,
            "Maximum staking supply exceeded"
        );
        _mint(to, amount);
        totalStakingSupply += amount;
    }


function initalliquidityadd(address to, uint256 amount) public {
       
        require(
            totalStakingSupply + amount <= inital_liquidity,
            "Max Inital liqudity added"
        );
        _mint(to, amount);
        totalStakingSupply += amount;
    }

    

    /**
     * burns $SPYC from a holder
     * @param from the holder of the $SPYC
     * @param amount the amount of $SPYC to burn
     */
    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }

    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disable
     */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}