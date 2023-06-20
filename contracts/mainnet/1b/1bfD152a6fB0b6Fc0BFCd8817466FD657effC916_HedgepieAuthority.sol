// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import "../interfaces/IHedgepieAuthority.sol";

abstract contract HedgepieAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IHedgepieAuthority indexed authority);

    // unauthorized error message
    string private _unauthorized = "UNAUTHORIZED"; // save gas

    // paused error message
    string private _paused = "PAUSED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IHedgepieAuthority public authority;

    /* ========== Constructor ========== */
    /**
     * @notice Constructor
     * @param _authority address of authority
     */
    constructor(IHedgepieAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier whenNotPaused() {
        require(!authority.paused(), _paused);
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), _unauthorized);
        _;
    }

    modifier onlyPathManager() {
        require(msg.sender == authority.pathManager(), _unauthorized);
        _;
    }

    modifier onlyAdapterManager() {
        require(msg.sender == authority.adapterManager(), _unauthorized);
        _;
    }

    modifier onlyInvestor() {
        require(msg.sender == authority.hInvestor(), _unauthorized);
        _;
    }

    /* ========== GOV ONLY ========== */
    /**
     * @notice Set new authority
     * @param _newAuthority address of new authority
     */
    /// #if_succeeds {:msg "setAuthority failed"}  authority == _newAuthority;
    function setAuthority(IHedgepieAuthority _newAuthority) external onlyGovernor {
        require(address(_newAuthority) != address(0), "Invalid adddress");
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./HedgepieAccessControlled.sol";
import "../interfaces/IHedgepieAuthority.sol";

contract HedgepieAuthority is IHedgepieAuthority, HedgepieAccessControlled {
    /* ========== STATE VARIABLES ========== */

    // governor address
    address public override governor;

    // path manager address
    address public override pathManager;

    // adapter manager contract address
    address public override adapterManager;

    // investor contract address
    address public override hInvestor;

    // ybnft contract address
    address public override hYBNFT;

    // adapter list contract address
    address public override hAdapterList;

    // path finder contract address
    address public override pathFinder;

    // new governor address
    address public newGovernor;

    // new path manager address
    address public newPathManager;

    // new adapter manager contract address
    address public newAdapterManager;

    // to check protocol is paused or not
    bool public override paused;

    /* ========== Constructor ========== */
    /**
     * @notice Constructor
     * @param _governor  address of Governor
     * @param _pathManager  address of path manager
     * @param _adapterManager  address of adapter manager
     */
    constructor(
        address _governor,
        address _pathManager,
        address _adapterManager
    ) HedgepieAccessControlled(IHedgepieAuthority(address(this))) {
        governor = _governor;
        emit GovernorPushed(address(0), governor, true);
        pathManager = _pathManager;
        emit PathManagerPushed(address(0), pathManager, true);
        adapterManager = _adapterManager;
        emit AdapterManagerPushed(address(0), adapterManager, true);
    }

    /* ========== GOV ONLY ========== */
    /**
     * @notice Push Governor
     * @param _newGovernor address of new governor
     * @param _effectiveImmediately  bool to set immediately or not
     */
    /// #if_succeeds {:msg "pushGovernor failed"}  newGovernor == _newGovernor;
    function pushGovernor(address _newGovernor, bool _effectiveImmediately) external onlyGovernor {
        if (_effectiveImmediately) governor = _newGovernor;
        newGovernor = _newGovernor;
        emit GovernorPushed(governor, newGovernor, _effectiveImmediately);
    }

    /**
     * @notice Push path manager
     * @param _newPathManager address of new path manager
     * @param _effectiveImmediately  bool to set immediately or not
     */
    /// #if_succeeds {:msg "pushPathManager failed"}  newPathManager == _newPathManager;
    function pushPathManager(address _newPathManager, bool _effectiveImmediately) external onlyGovernor {
        if (_effectiveImmediately) pathManager = _newPathManager;
        newPathManager = _newPathManager;
        emit PathManagerPushed(pathManager, newPathManager, _effectiveImmediately);
    }

    /**
     * @notice Push adapter manager
     * @param _newAdapterManager address of new adapter manager
     * @param _effectiveImmediately  bool to set immediately or not
     */
    /// #if_succeeds {:msg "pushAdapterManager failed"}  newAdapterManager == _newAdapterManager;
    function pushAdapterManager(address _newAdapterManager, bool _effectiveImmediately) external onlyGovernor {
        if (_effectiveImmediately) adapterManager = _newAdapterManager;
        newAdapterManager = _newAdapterManager;
        emit AdapterManagerPushed(adapterManager, newAdapterManager, _effectiveImmediately);
    }

    /**
     * @notice Pause contract
     */
    /// #if_succeeds {:msg "pause failed"}  paused == true;
    function pause() external onlyGovernor {
        paused = true;
    }

    /**
     * @notice Unpause contract
     */
    /// #if_succeeds {:msg "unpause failed"}  paused == false;
    function unpause() external onlyGovernor {
        paused = false;
    }

    /**
     * @notice Set Hedgepie Investor
     * @param _hInvestor address of HInvestor
     */
    /// #if_succeeds {:msg "setHInvestor failed"}  hInvestor == _hInvestor;
    function setHInvestor(address _hInvestor) external onlyGovernor {
        emit HInvestorUpdated(hInvestor, _hInvestor);
        hInvestor = _hInvestor;
    }

    /**
     * @notice Set YBNFT
     * @param _hYBNFT address of hedgepie YBNFT
     */
    /// #if_succeeds {:msg "setHYBNFT failed"}  hYBNFT == _hYBNFT;
    function setHYBNFT(address _hYBNFT) external onlyGovernor {
        emit HYBNFTUpdated(hYBNFT, _hYBNFT);
        hYBNFT = _hYBNFT;
    }

    /**
     * @notice Set adapter list
     * @param _hAdapterList address of hedgepie adaper list
     */
    /// #if_succeeds {:msg "setHAdapterList failed"}  hAdapterList == _hAdapterList;
    function setHAdapterList(address _hAdapterList) external onlyGovernor {
        emit HAdapterListUpdated(hAdapterList, _hAdapterList);
        hAdapterList = _hAdapterList;
    }

    /**
     * @notice Set path finder
     * @param _pathFinder address of hedgepie path finder
     */
    /// #if_succeeds {:msg "setPathFinder failed"}  pathFinder == _pathFinder;
    function setPathFinder(address _pathFinder) external onlyGovernor {
        emit PathFinderUpdated(pathFinder, _pathFinder);
        pathFinder = _pathFinder;
    }

    /* ========== PENDING ROLE ONLY ========== */
    /**
     * @notice Pull Governor
     */
    /// #if_succeeds {:msg "pullGovernor failed"}  governor == newGovernor;
    function pullGovernor() external {
        require(msg.sender == newGovernor, "!newGovernor");
        emit GovernorPulled(governor, newGovernor);
        governor = newGovernor;
    }

    /**
     * @notice Pull path manager
     */
    /// #if_succeeds {:msg "pullPathManager failed"}  pathManager == newPathManager;
    function pullPathManager() external {
        require(msg.sender == newPathManager, "!newPathManager");
        emit PathManagerPulled(pathManager, newPathManager);
        pathManager = newPathManager;
    }

    /**
     * @notice Pull adapter manager
     */
    /// #if_succeeds {:msg "pullAdapterManager failed"}  adapterManager == newAdapterManager;
    function pullAdapterManager() external {
        require(msg.sender == newAdapterManager, "!newAdapterManager");
        emit AdapterManagerPulled(adapterManager, newAdapterManager);
        adapterManager = newAdapterManager;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

interface IHedgepieAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PathManagerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event AdapterManagerPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event PathManagerPulled(address indexed from, address indexed to);
    event AdapterManagerPulled(address indexed from, address indexed to);

    event HInvestorUpdated(address indexed from, address indexed to);
    event HYBNFTUpdated(address indexed from, address indexed to);
    event HAdapterListUpdated(address indexed from, address indexed to);
    event PathFinderUpdated(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function pathManager() external view returns (address);

    function adapterManager() external view returns (address);

    function hInvestor() external view returns (address);

    function hYBNFT() external view returns (address);

    function hAdapterList() external view returns (address);

    function pathFinder() external view returns (address);

    function paused() external view returns (bool);
}