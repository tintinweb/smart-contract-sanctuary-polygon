// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IPlugin.sol";

contract PluginServer
{
    mapping (string=>address) _plugins;

    modifier pluginExists(string memory guid)
    {
        require(_plugins[guid] != address(0), "Given guid is not registered");
        _;
    }

    function canUsePlugin(string memory guid, address account) pluginExists(guid) public view returns(bool)
    {
        return IPlugin(_plugins[guid]).canUsePlugin(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract IPlugin
{
    function pluginID() external virtual view returns (string memory guid);
    function canUsePlugin(address account) external view virtual returns (bool);
    function getPermission(address account) external view virtual returns (string memory permission);
}