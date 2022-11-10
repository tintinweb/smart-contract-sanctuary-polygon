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

    constructor(address _hookManager) {
        hookManager = _hookManager;
    }

    modifier onlyHookManager() {
        if (msg.sender != hookManager) revert IErrors.PermissionDenied();
        _;
    }

    function startup(
        address sender,
        uint256 senderId,
        bytes memory initialize
    ) external onlyHookManager {}

    function onAction(uint256 calleeId, bytes memory data)
        external
        onlyHookManager
    {}
}