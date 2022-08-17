// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ProxyAdmin.sol";
import "./TransparentUpgradeableProxy.sol";

contract Logic is Initializable, OwnableUpgradeable {
    function initialize() public initializer {
        __Ownable_init();
    }

    mapping(string => uint256) private logic;

    event logicSetted(string indexed _key, uint256 _value);

    function SetLogic(string memory _key, uint256 _value) external {
        logic[_key] = _value;
        emit logicSetted(_key, _value);
    }

function GetLogic(string memory _key) public view returns (uint256){
        return logic[_key]+9;
    }
    
    function GetInitializeData() public pure returns(bytes memory){
        return abi.encodeWithSignature("initialize()");
    }
}