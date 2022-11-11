/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

pragma solidity ^0.8.12;


// 
interface IErrors {
    error InvalidInitialParams();
    error NotAmoserOrBlacklisted();
    error HookAlreadyRegistered();
    error HookDoesNotRegistered();
    error PermissionDenied();
    error CollectNotEnabled();
    error CollectNFTAlreadyExist();
    error InvalidContentId();
    error Following();
    error NotFollowing();
    error DeployForInvalidTag();
    error InvalidProxyFlags();
    error DeployForInvalidBeacon();
    error InvalidParams();
    error UnexpectedArrayLength();
    error HookWantsToAbort();
    error NotHaveFollower();
    error NotHaveCollector();
}

// 
contract FreeCollectHook {
    address public hookManager;
    address public hookUtils;

    constructor(address _hookManager, address _hookUtils) {
        hookManager = _hookManager;
        hookUtils = _hookUtils;
    }

    modifier onlyHookManager() {
        if (msg.sender != hookManager) revert IErrors.PermissionDenied();
        _;
    }

    function startup(
        address owner,
        uint256 ownerId,
        bytes memory extraData,
        bytes memory initData
    ) external onlyHookManager {}

    function onAction(uint256 calleeId, bytes memory data)
        external
        onlyHookManager
    {}
}