// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "./Ownable.sol";
import {ERC20} from "./ERC20.sol";
import {IHoneySiumToken} from "./IHoneySiumToken.sol";

/**
 * @title HoneySium (HSM)
 * @notice
                                        :aabba}                  
                                        !qa1    |a                  
                                    Car.      qz                  
                                |k/         ,a:                  
                                Jv          ,a;                   
                                uc           hi                    
                !,            O+          p)                     
            ^Or`Jbc           o          p>                      
            `]!1x  r          a        .h:    .`^^               
                ?U b          p       Ik' lnhn1^ >rhq(!          
                    p:J          p      ]Y YkI          `iZabJ      
                ,Jaaaaak!      C     c]b/                   Qa+   
                ,dwoaaaaaaaa^    X    XC<                      ra.  
            ;a!  Uaaaaaaan "1{"> ,h`                      /hk^   
            aav. OaaaaaaaYCaaQ   <bi            .I_-tbahUx.      
            aaaaaaaLaaaaa1aa/   laaaui/jrt1?----<:               
            IaaaaabQaaaa!aw    laaaa!                            
                LaUlaaa01p(     maaaai   <m                        
                            _paaaab`   Iaap                       
                        `aaaaaaaad-    !aaaaj                      
                        .kaaaO1      0aaaad                       
                                    ;baaaaak.                       
                            -}Caaaaaaaad.                         
                            ibaaaaaa('    -U                     
                                        `aaU                     
                                    ^1waaaaY                     
                                        raaaaa`                     
                                        ?aaam                      
                                        .aaa|                      
                                        vab                       
                                        'a>                       
                                        '-                        
 */
contract HoneySium is ERC20, Ownable, IHoneySiumToken {
    uint256 private immutable _SUPPLY_CAP = 500000000 * 10**uint(decimals());

    /**
     * @notice Constructor
     * @param _premintReceiver address that receives the premint
     */
    constructor(address _premintReceiver) 
    ERC20("HoneySium", "HSM") {
        uint256 _premintAmount = 2500000 * 10**uint(decimals());
        // Transfer the sum of the premint to address
        _mint(_premintReceiver, _premintAmount);
    }

    /**
     * @notice Mint HSM tokens
     * @param account address to receive tokens
     * @param amount amount to mint
     * @return status true if mint is successful, false if not
     */
    function mint(address account, uint256 amount) external override onlyOwner returns (bool status) {
        require(_SUPPLY_CAP > totalSupply() + amount, "HSM: amount is greater than cap");
        if (totalSupply() + amount <= _SUPPLY_CAP) {
            _mint(account, amount);
            return true;
        }
        return false;
    }

    /**
     * @notice View supply cap
     */
    function SUPPLY_CAP() external view override returns (uint256) {
        return _SUPPLY_CAP;
    }
}