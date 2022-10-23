// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDcrowd.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Dcrowd is IDcrowd, ReentrancyGuard {
    //----------------------------------------------------- storage

    uint256 private _projectCounter;

    // project ID -> project info
    mapping(uint256 => ProjectInfo) private _projectInfos;

    // funder address -> project ID -> amount funded
    mapping(address => mapping(uint256 => uint256)) private _fundings;

    //----------------------------------------------------- misc functions

    constructor() {
        _projectCounter = 0;
    }

    //----------------------------------------------------- project functions

    function createProject(
        uint64 expires,
        uint256 goal,
        string calldata uri
    ) external payable override returns (uint256) {
        // expires valid
        if (expires < block.timestamp || block.timestamp + 100 days < expires)
            revert Dcrowd_InvalidExpires(expires);

        // store project
        uint256 projectId = _projectCounter++;
        _projectInfos[projectId] = ProjectInfo({
            creator: msg.sender,
            expires: expires,
            funded: false,
            goal: goal,
            balance: msg.value,
            uri: uri
        });

        emit ProjectCreated(projectId, msg.sender, expires, goal, uri);
        return projectId;
    }

    function fundProject(uint256 projectId) external payable override {
        // ETH is sent
        if (msg.value == 0) revert();

        ProjectInfo memory project = _projectInfos[projectId];
        // project exists
        if (project.creator == address(0)) revert Dcrowd_ProjectNotExists(projectId);
        // project not fully funded
        if (project.goal <= project.balance || project.funded)
            revert Dcrowd_ProjectAlreadyFunded(projectId);
        if (project.expires < block.timestamp) revert Dcrowd_ProjectFundingExpired(projectId);

        _projectInfos[projectId].balance += msg.value;
        _fundings[msg.sender][projectId] += msg.value;
        emit ProjectFunded(projectId, msg.sender, msg.value);
    }

    function collectFunds(uint256 projectId) external override nonReentrant {
        ProjectInfo memory project = _projectInfos[projectId];
        // sender is creator
        if (msg.sender != project.creator) revert Dcrowd_NotProjectCreator(msg.sender);
        // project is fully funded
        if (project.balance < project.goal) revert Dcrowd_ProjectNotFunded(projectId);
        // funds have not been already collected
        if (project.funded) revert Dcrowd_ProjectAlreadyFunded(projectId);

        // update storage
        _projectInfos[projectId].funded = true;

        // transfer funds
        (bool success, ) = project.creator.call{value: project.balance, gas: 2300}("");
        if (!success) revert Dcrowd_TransferFailed(project.creator, project.balance);
        emit FundsCollected(projectId, project.creator, project.balance);
    }

    function cancelFunding(uint256 projectId, uint256 amount) external override {
        ProjectInfo memory project = _projectInfos[projectId];
        uint256 funding = _fundings[msg.sender][projectId];
        // project exists
        if (project.creator == address(0)) revert Dcrowd_ProjectNotExists(projectId);
        // project not funded
        if (project.funded) revert Dcrowd_ProjectAlreadyFunded(projectId);
        // has funded
        if (funding == 0) revert();

        // transfer funds
        (bool success, ) = msg.sender.call{value: amount, gas: 2300}("");
        if (!success) revert Dcrowd_TransferFailed(msg.sender, amount);
    }

    //----------------------------------------------------- accessor functions

    function projectCounter() external view override returns (uint256) {
        return _projectCounter;
    }

    function getProjectInfo(uint256 projectId) external view override returns (ProjectInfo memory) {
        return _projectInfos[projectId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error Dcrowd_InvalidExpires(uint256 expires);
error Dcrowd_ProjectNotExists(uint256 projectId);
error Dcrowd_ProjectAlreadyFunded(uint256 projectId);
error Dcrowd_NotProjectCreator(address sender);
error Dcrowd_ProjectNotFunded(uint256 projectId);
error Dcrowd_TransferFailed(address to, uint256 value);
error Dcrowd_ProjectFundingExpired(uint256 projectId);

interface IDcrowd {
    //----------------------------------------------------- structs

    struct ProjectInfo {
        // creator of the project
        address creator;
        // UNIX timestamp, given by `block.timestamp`, end of funding period
        uint64 expires;
        // if the funds have been transferred to the project creator
        bool funded;
        // project funds goal
        uint256 goal;
        // current funds of the project
        uint256 balance;
        // project metadata
        string uri;
    }

    //----------------------------------------------------- events

    event ProjectCreated(
        uint256 indexed projectId,
        address indexed creator,
        uint64 indexed expires,
        uint256 goal,
        string uri
    );

    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);

    event FundsCollected(uint256 indexed projectId, address indexed creator, uint256 funds);

    //----------------------------------------------------- project functions

    /// @param expires UNIX timextamp, end of the funding period of the project.
    /// @return Project ID
    function createProject(
        uint64 expires,
        uint256 goal,
        string calldata uri
    ) external payable returns (uint256);

    function collectFunds(uint256 projectId) external;

    //----------------------------------------------------- funder functions

    function fundProject(uint256 projectId) external payable;

    function cancelFunding(uint256 projectId, uint256 amount) external;

    //----------------------------------------------------- accessor functions

    function projectCounter() external view returns (uint256);

    function getProjectInfo(uint256 projectId) external view returns (ProjectInfo memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}