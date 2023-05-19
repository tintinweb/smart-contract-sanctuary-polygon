// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IKeeperRegistry2_0 {
  function cancelUpkeep(uint256 id) external;

  function pauseUpkeep(uint256 id) external;

  function unpauseUpkeep(uint256 id) external;
  function addFunds(uint256 id, uint96 amount) external;
  function withdrawFunds(uint256 id, address to) external ;
}

/*
 * @Author: Wmengti [email protected]
 * @LastEditTime: 2023-05-18 19:31:04
 * @Description: 
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IKeeperRegistry2_0.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
contract KeeperManager{
    IKeeperRegistry2_0 immutable public i_registry;
    LinkTokenInterface public immutable i_link;

    event pauseUpkeep(uint256 upkeepID);
    event cancelUpkeep(uint256 upkeepID);
    event addFoundUpkeep(uint256 upkeepID,uint256 amount);
    event unpauseUpkeep(uint256 upkeepID);
    event withdrawFundsUpkeep(uint256 upkeepID,address to);

    error UpkeepIDNotFound();
    error NotEoughtLink();



    constructor(IKeeperRegistry2_0 _registry,LinkTokenInterface _link) {
      i_registry = _registry;
      i_link = _link;
    }

    function pause(uint256 _upkeepID) external {
        if(_upkeepID !=0){
            i_registry.pauseUpkeep(_upkeepID);
            emit pauseUpkeep(_upkeepID);
        }else{
            revert UpkeepIDNotFound();
        }
   
        
    }
    
    function cancel(uint256 _upkeepID) external {
        if(_upkeepID !=0){
            i_registry.cancelUpkeep(_upkeepID);
            emit cancelUpkeep(_upkeepID);
        }else{
            revert UpkeepIDNotFound();
        }
  
    }

    function addFound(uint256 amount,uint256 _upkeepID) external {
        if(i_link.balanceOf(address(this))<amount){
            revert NotEoughtLink();
        }
        if(_upkeepID !=0){
            i_link.transferAndCall(address(i_registry), amount, abi.encode(_upkeepID));
            emit addFoundUpkeep(_upkeepID,amount);
        }else{
            revert UpkeepIDNotFound();
        }
    }

    function unpause(uint256 _upkeepID) external {
        if(_upkeepID !=0){
            i_registry.unpauseUpkeep(_upkeepID);
            emit unpauseUpkeep(_upkeepID);
        }else{
            revert UpkeepIDNotFound();
        }
    }

    function withdrawFunds(uint256 _upkeepID,address _to) external {
        if(_upkeepID !=0){
            i_registry.withdrawFunds(_upkeepID,_to);
            emit withdrawFundsUpkeep(_upkeepID,_to);
        }else{
            revert UpkeepIDNotFound();
        }
    }


}