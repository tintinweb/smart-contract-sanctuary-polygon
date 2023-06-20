// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IYBNFT.sol";
import "../interfaces/IPathFinder.sol";
import "../interfaces/IHedgepieInvestor.sol";
import "../interfaces/IHedgepieAuthority.sol";

import "./HedgepieAccessControlled.sol";

abstract contract BaseAdapter is HedgepieAccessControlled {
    struct UserAdapterInfo {
        uint256 amount; // Staking token amount
        uint256 userShare1; // First rewardTokens' share
        uint256 userShare2; // Second rewardTokens' share
        uint256 rewardDebt1; // Reward Debt for first reward token
        uint256 rewardDebt2; // Reward Debt for second reward token
        uint256 invested; // invested lp token amount
    }

    struct AdapterInfo {
        uint256 accTokenPerShare1; // Accumulated per share for first reward token
        uint256 accTokenPerShare2; // Accumulated per share for second reward token
        uint256 totalStaked; // Total staked staking token
    }

    // LP pool id - should be 0 when stakingToken is not LP
    uint256 public pid;

    // staking token
    address public stakingToken;

    // first reward token
    address public rewardToken1;

    // second reward token - optional
    address public rewardToken2;

    // repay token which we will receive after deposit - optional
    address public repayToken;

    // strategy where we deposit staking token
    address public strategy;

    // router address for LP token
    address public router;

    // swap router address for ERC20 token swap
    address public swapRouter;

    // wbnb address
    address public wbnb;

    // adapter name
    string public name;

    // adapter info having totalStaked and 1st, 2nd share info
    AdapterInfo public mAdapter;

    // adapter info for each nft
    // nft id => UserAdapterInfo
    mapping(uint256 => UserAdapterInfo) public userAdapterInfos;

    /** @notice Constructor
     * @param _hedgepieAuthority  address of authority
     */
    constructor(address _hedgepieAuthority) HedgepieAccessControlled(IHedgepieAuthority(_hedgepieAuthority)) {}

    /** @notice get user staked amount */
    function getUserAmount(uint256 _tokenId) external view returns (uint256 amount) {
        return userAdapterInfos[_tokenId].amount;
    }

    /**
     * @notice deposit to strategy
     * @param _tokenId YBNFT token id
     */
    function deposit(uint256 _tokenId) external payable virtual returns (uint256 amountOut) {}

    /**
     * @notice withdraw from strategy
     * @param _tokenId YBNFT token id
     * @param _amount amount of staking tokens to withdraw
     */
    function withdraw(uint256 _tokenId, uint256 _amount) external payable virtual returns (uint256 amountOut) {}

    /**
     * @notice claim reward from strategy
     * @param _tokenId YBNFT token id
     */
    function claim(uint256 _tokenId) external payable virtual returns (uint256 amountOut) {}

    /**
     * @notice Remove funds
     * @param _tokenId YBNFT token id
     */
    function removeFunds(uint256 _tokenId) external payable virtual returns (uint256 amountOut) {}

    /**
     * @notice Update funds
     * @param _tokenId YBNFT token id
     */
    function updateFunds(uint256 _tokenId) external payable virtual returns (uint256 amountOut) {}

    /**
     * @notice Get pending token reward
     * @param _tokenId YBNFT token id
     */
    function pendingReward(uint256 _tokenId) external view virtual returns (uint256 reward, uint256 withdrawable) {}

    /**
     * @notice Charge Fee and send BNB to investor
     * @param _tokenId YBNFT token id
     */
    function _chargeFeeAndSendToInvestor(uint256 _tokenId, uint256 _amount, uint256 _reward) internal {
        bool success;
        if (_reward != 0) {
            _reward = (_reward * IYBNFT(authority.hYBNFT()).performanceFee(_tokenId)) / 1e4;

            // 20% to treasury
            (success, ) = payable(IHedgepieInvestor(authority.hInvestor()).treasury()).call{value: _reward / 5}("");
            require(success, "Failed to send bnb to Treasury");

            // 80% to fund manager
            (success, ) = payable(IYBNFT(authority.hYBNFT()).ownerOf(_tokenId)).call{value: _reward - _reward / 5}("");
            require(success, "Failed to send bnb to Treasury");
        }

        (success, ) = payable(msg.sender).call{value: _amount - _reward}("");
        require(success, "Failed to send bnb");
    }

    receive() external payable {}
}

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

import "../interfaces/IAdapter.sol";
import "../interfaces/IHedgepieAuthority.sol";

import "./HedgepieAccessControlled.sol";

contract HedgepieAdapterList is HedgepieAccessControlled {
    struct AdapterInfo {
        address addr; // adapter address
        string name; // adapter name
        address stakingToken; // staking token of adapter
        bool status; // adapter contract status
    }

    // list of adapters
    AdapterInfo[] public adapterList;

    // existing status of adapters
    mapping(address => bool) public adapterActive;

    /// @dev events
    event AdapterAdded(address indexed adapter);
    event AdapterActivated(address indexed strategy);
    event AdapterDeactivated(address indexed strategy);

    /**
     * @notice Construct
     * @param _hedgepieAuthority HedgepieAuthority address
     */
    constructor(address _hedgepieAuthority) HedgepieAccessControlled(IHedgepieAuthority(_hedgepieAuthority)) {}

    /// @dev modifier for active adapters
    modifier onlyActiveAdapter(address _adapter) {
        require(adapterActive[_adapter], "Error: Adapter is not active");
        _;
    }

    /**
     * @notice Get a list of adapters
     */
    function getAdapterList() external view returns (AdapterInfo[] memory) {
        return adapterList;
    }

    /**
     * @notice Get adapter infor
     * @param _adapterAddr address of adapter that need to get information
     */
    function getAdapterInfo(
        address _adapterAddr
    ) external view returns (address adapterAddr, string memory name, address stakingToken, bool status) {
        for (uint256 i; i < adapterList.length; i++) {
            if (adapterList[i].addr == _adapterAddr && adapterList[i].status) {
                adapterAddr = adapterList[i].addr;
                name = adapterList[i].name;
                stakingToken = adapterList[i].stakingToken;
                status = adapterList[i].status;

                break;
            }
        }
    }

    /**
     * @notice Get strategy address of adapter contract
     * @param _adapter  adapter address
     */
    function getAdapterStrat(
        address _adapter
    ) external view onlyActiveAdapter(_adapter) returns (address adapterStrat) {
        adapterStrat = IAdapter(_adapter).strategy();
    }

    // ===== AdapterManager functions =====
    /**
     * @notice Add adapters
     * @param _adapters  array of adapter address
     */
    /// #if_succeeds {:msg "addAdapters failed"} _adapters.length > 0 ? (adapterList.length == old(adapterList.length) + _adapters.length && adapterActive[_adapters[_adapters.length - 1]] == true) : true;
    function addAdapters(address[] memory _adapters) external onlyAdapterManager {
        for (uint256 i = 0; i < _adapters.length; i++) {
            require(!adapterActive[_adapters[i]], "Already added");
            require(_adapters[i] != address(0), "Invalid adapter address");

            adapterList.push(
                AdapterInfo({
                    addr: _adapters[i],
                    name: IAdapter(_adapters[i]).name(),
                    stakingToken: IAdapter(_adapters[i]).stakingToken(),
                    status: true
                })
            );
            adapterActive[_adapters[i]] = true;

            emit AdapterAdded(_adapters[i]);
        }
    }

    /**
     * @notice Remove adapter
     * @param _adapterId  array of adapter id
     * @param _status  array of adapter status
     */
    /// #if_succeeds {:msg "setAdapters failed"} _status.length > 0 ? (adapterList[_adapterId[_status.length - 1]].status == _status[_status.length - 1]) : true;
    function setAdapters(uint256[] memory _adapterId, bool[] memory _status) external onlyAdapterManager {
        require(_adapterId.length == _status.length, "Invalid array length");

        for (uint256 i = 0; i < _adapterId.length; i++) {
            require(_adapterId[i] < adapterList.length, "Invalid adapter address");

            if (adapterList[_adapterId[i]].status != _status[i]) {
                adapterList[_adapterId[i]].status = _status[i];

                if (_status[i]) emit AdapterActivated(adapterList[_adapterId[i]].addr);
                else emit AdapterDeactivated(adapterList[_adapterId[i]].addr);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IWrap.sol";
import "../base/BaseAdapter.sol";

interface IAdapter {
    function stakingToken() external view returns (address);

    function repayToken() external view returns (address);

    function strategy() external view returns (address);

    function name() external view returns (string memory);

    function rewardToken1() external view returns (address);

    function rewardToken2() external view returns (address);

    function router() external view returns (address);

    function swapRouter() external view returns (address);

    function authority() external view returns (address);

    function userAdapterInfos(uint256 _tokenId) external view returns (BaseAdapter.UserAdapterInfo memory);

    function mAdapter() external view returns (BaseAdapter.AdapterInfo memory);

    /**
     * @notice deposit to strategy
     * @param _tokenId YBNFT token id
     */
    function deposit(uint256 _tokenId) external payable returns (uint256 amountOut);

    /**
     * @notice withdraw from strategy
     * @param _tokenId YBNFT token id
     * @param _amount amount of staking tokens to withdraw
     */
    function withdraw(uint256 _tokenId, uint256 _amount) external payable returns (uint256 amountOut);

    /**
     * @notice claim reward from strategy
     * @param _tokenId YBNFT token id
     */
    function claim(uint256 _tokenId) external payable returns (uint256 amountOut);

    /**
     * @notice Get pending token reward
     * @param _tokenId YBNFT token id
     */
    function pendingReward(uint256 _tokenId) external view returns (uint256 amountOut, uint256 withdrawable);

    /**
     * @notice Remove funds
     * @param _tokenId YBNFT token id
     */
    function removeFunds(uint256 _tokenId) external payable returns (uint256 amount);

    /**
     * @notice Update funds
     * @param _tokenId YBNFT token id
     */
    function updateFunds(uint256 _tokenId) external payable returns (uint256 amount);

    /**
     * @notice get user staked amount
     */
    function getUserAmount(uint256 _tokenId) external view returns (uint256 amount);
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IHedgepieInvestor {
    function treasury() external view returns (address);

    /**
     * @notice Update funds for token id
     * @param _tokenId YBNFT token id
     */
    function updateFunds(uint256 _tokenId) external;

    /**
     * @notice Deposit with BNB
     * @param _tokenId  YBNft token id
     */
    function deposit(uint256 _tokenId) external;

    /**
     * @notice Withdraw by BNB
     * @param _tokenId  YBNft token id
     */
    function withdraw(uint256 _tokenId) external;

    /**
     * @notice Claim
     * @param _tokenId  YBNft token id
     */
    function claim(uint256 _tokenId) external;

    /**
     * @notice pendingReward
     * @param _tokenId  YBNft token id
     * @param _account  user address
     */
    function pendingReward(
        uint256 _tokenId,
        address _account
    ) external returns (uint256 amountOut, uint256 withdrawable);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IPathFinder {
    /**
     * @notice Get Path
     * @param _router swap router address
     * @param _inToken input token address
     * @param _outToken output token address
     */
    function getPaths(address _router, address _inToken, address _outToken) external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IWrap {
    // get wrapper token
    function deposit(uint256 amount) external;

    // get native token
    function withdraw(uint256 share) external;

    function deposit() external payable;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

interface IYBNFT {
    struct AdapterParam {
        uint256 allocation;
        address addr;
        bool isCross;
    }

    struct UpdateInfo {
        uint256 tokenId; // YBNFT tokenID
        uint256 value; // traded amount
        address account; // user address
        bool isDeposit; // deposit or withdraw
    }

    function exists(uint256) external view returns (bool);

    function getCurrentTokenId() external view returns (uint256);

    function ownerOf(uint256) external view returns (address);

    function performanceFee(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Get adapter parameters
     * @param tokenId  YBNft token id
     */
    function getTokenAdapterParams(uint256 tokenId) external view returns (AdapterParam[] memory);

    /**
     * @notice Mint nft
     * @param _adapterParams  parameters of adapters
     * @param _performanceFee  performance fee
     * @param _tokenURI  token URI
     */
    function mint(AdapterParam[] memory _adapterParams, uint256 _performanceFee, string memory _tokenURI) external;

    /**
     * @notice Update profit info
     * @param _tokenId  YBNFT tokenID
     * @param _value  amount of profit
     */
    function updateProfitInfo(uint256 _tokenId, uint256 _value) external;

    /**
     * @notice Update TVL, Profit, Participants info
     * @param param  update info param
     */
    function updateInfo(UpdateInfo memory param) external;
}