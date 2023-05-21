// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./IUpdatableStakeInfo.sol";
import "./IAccessControlApplication.sol";

/**
* @title StakeInfo
* @notice StakeInfo
*/
contract StakeInfo is AccessControl, IUpdatableStakes, IAccessControlApplication {

    bytes32 public constant UPDATE_ROLE = keccak256("UPDATE_ROLE");

    struct Stake {
        address operator;
        uint96 amount;
        // TODO: what about undelegations etc?
    }

    constructor(address[] memory updaters){
        for(uint i = 0; i < updaters.length; i++){
            _grantRole(UPDATE_ROLE, updaters[i]);
        }
    }

    mapping(address => Stake) public stakes;
    mapping(address => address) public operatorToProvider;

    function stakingProviderFromOperator(address _operator) external view returns (address){
        return operatorToProvider[_operator];
    }

    function authorizedStake(address _stakingProvider) external view returns (uint96){
        return stakes[_stakingProvider].amount;
    }

    function updateOperator(address stakingProvider, address operator) external onlyRole(UPDATE_ROLE) {
        _updateOperator(stakingProvider, operator);
    }

    function updateAmount(address stakingProvider, uint96 amount) external onlyRole(UPDATE_ROLE) {
        _updateAmount(stakingProvider, amount);
    }

    function _updateOperator(address stakingProvider, address operator) internal {
        Stake storage stake = stakes[stakingProvider];
        address oldOperator = stake.operator;

        if(operator != oldOperator){
            stake.operator = operator;
            // Update operator to provider mapping
            operatorToProvider[oldOperator] = address(0);
            operatorToProvider[operator] = stakingProvider;

            emit UpdatedStakeOperator(stakingProvider, operator);
        }
    }

    function _updateAmount(address stakingProvider, uint96 amount) internal {
        Stake storage stake = stakes[stakingProvider];
        uint256 oldAmount = stake.amount;
        
        if(amount != oldAmount){
            stake.amount = amount;
            emit UpdatedStakeAmount(stakingProvider, amount);
        }
    }

    function batchUpdate(bytes32[] calldata updateInfo) external onlyRole(UPDATE_ROLE) {
        require(updateInfo.length % 2 == 0, "bad length");
        for(uint i = 0; i < updateInfo.length; i += 2){
            bytes32 word0 = updateInfo[i];
            bytes32 word1 = updateInfo[i + 1];
            
            address provider = address(bytes20(word0));
            uint96 amount = uint96(uint256(word0));
            address operator = address(bytes20(word1));

            _updateOperator(provider, operator);
            _updateAmount(provider, amount); 
        }
    }
}