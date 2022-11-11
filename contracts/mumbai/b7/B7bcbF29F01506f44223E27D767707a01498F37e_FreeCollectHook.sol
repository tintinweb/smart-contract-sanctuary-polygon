/**
 *Submitted for verification at polygonscan.com on 2022-11-11
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
interface IHookUtils {
    function isFollowing(uint256 userA, uint256 userB)
        external
        view
        returns (bool);
}

// 
contract FreeCollectHook {
    address public hookManager;
    address public hookUtils;

    enum CollectAllow {
        everyone,
        followers
    }

    struct CollectControl {
        CollectAllow allow;
        uint256 supply;
        uint256 actSupply;
    }

    //Content Owner Id => CollectControl
    mapping(uint256 => mapping(uint256 => CollectControl))
        public collectControls;

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
    ) external onlyHookManager {
        uint256 contentId = abi.decode(extraData, (uint256));
        (uint8 allow, uint256 supply) = abi.decode(initData, (uint8, uint256));
        collectControls[ownerId][contentId] = CollectControl({
            allow: CollectAllow(allow),
            supply: supply,
            actSupply: 0
        });
    }

    function onAction(uint256 calleeId, bytes memory data)
        external
        onlyHookManager
    {
        (
            ,
            uint256 collectorId,
            uint256 collectedId,
            ,
            uint256 contentId,
            ,
            ,

        ) = abi.decode(
                data,
                (
                    address,
                    uint256,
                    uint256,
                    address,
                    uint256,
                    address,
                    uint256,
                    bytes
                )
            );

        require(collectedId == calleeId, "unexpected auction data");

        CollectControl storage collectControl = collectControls[calleeId][
            contentId
        ];

        if (collectControl.allow == CollectAllow.followers) {
            require(
                IHookUtils(hookUtils).isFollowing(collectorId, collectedId),
                "only followers"
            );
        }

        if (collectControl.supply != type(uint256).max)
            require(
                collectControl.supply > collectControl.actSupply,
                "not shares to collect"
            );
        collectControl.actSupply = collectControl.actSupply + 1;
    }
}