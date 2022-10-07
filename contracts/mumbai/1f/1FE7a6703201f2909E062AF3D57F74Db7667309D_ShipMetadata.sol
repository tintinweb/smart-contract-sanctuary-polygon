//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./LibShip.sol";
import "../Managable.sol";

contract ShipMetadata is Managable {
    mapping(uint256 => LibShip.Ship) public ships;

    constructor() {
        _addManager(msg.sender);
    }

    function setShip(uint256 _tokenId, LibShip.Ship calldata _ship) external onlyManager {
        ships[_tokenId] = _ship;
    }

    function getShip(uint256 _tokenId) external view returns(LibShip.Ship memory) {
        return ships[_tokenId];
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibShip {
    struct Ship {
        uint256 genes;
        uint48 id;
        uint48 birthTime;
        uint48 var1;
        uint48 var2;
        uint32 var3;
        uint32 var4;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Managable {
    mapping(address => bool) private managers;
    address[] private managersAddresses;

    event AddedManager(address _address);
    event RemovedManager(address _address);

    modifier onlyManager() {
        require(managers[msg.sender], "caller is not manager");
        _;
    }

    function getManagers() public view returns (address[] memory) {
        return managersAddresses;
    }

    function addManager(address _manager) external onlyManager {
        _addManager(_manager);
    }

    function removeManager(address _manager) external onlyManager {
        uint index;
        for(uint i = 0; i < managersAddresses.length; i++) {
            if(managersAddresses[i] == _manager) {
                index = i;
                break;
            }
        }

        managersAddresses[index] = managersAddresses[managersAddresses.length - 1];
        managersAddresses.pop();

        _removeManager(_manager);
    }

    function _addManager(address _manager) internal {
        managers[_manager] = true;
        managersAddresses.push(_manager);
        emit AddedManager(_manager);
    }

    function _removeManager(address _manager) internal {
        managers[_manager] = false;
        emit RemovedManager(_manager);
    }
}