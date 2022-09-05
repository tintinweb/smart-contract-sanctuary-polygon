// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IRegistration.sol";
import "./interfaces/ILinkContract.sol";
import "./interfaces/ISubscription.sol";
import "./interfaces/IBalanceCalculator.sol";
import "./interfaces/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract SubscriptionBalance is OwnableUpgradeable, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // contract addresses cannot be changed once initialised
    IRegistration public RegistrationContract;
    IERC721 public ApplicationNFT;
    IERC20Upgradeable public XCTToken;
    ISubscription public SubscriptionContract;
    IBalanceCalculator public BalanceCalculator;
    uint256 public ReferralPercent; // 1000 = 1%
    uint256 public ReferralRevExpirySecs; // eg. after 2 years, Global DAO will receive referral percent reward
    ILinkContract public LinkContract;

    struct NFTBalance {
        uint256 lastBalanceUpdateTime;
        uint256[3] prevBalance; // prevBalance[0] = Credit wallet, prevBalance[1] = External Deposit, prevBalance[3] = Owner wallet
        uint256[] subnetIds; // cannot be changed unless delisted
        address NFTMinter;
        uint256 mintTime;
        uint256 endOfXCTBalance;
    }

    // NFT id => NFTBalance
    mapping(uint256 => NFTBalance) public nftBalances;
    // Credit provider => NFT id => expiry
    mapping(address => mapping(uint256 => uint256)) public creditsExpiry;

    event BalanceAdded(uint256 NFTId, uint256 balanceType, uint256 bal);
    event BalanceWithdrawn(uint256 NFTId, uint256 balanceType, uint256 bal);
    event SettledBalanceFor(uint256 NFTId);
    event ChangedReferralAttributes(
        uint256 ReferralPercent,
        uint256 ReferralRevExpirySecs
    );

    function initialize(
        IRegistration _RegistrationContract,
        IERC721 _ApplicationNFT,
        IERC20Upgradeable _XCTToken,
        IBalanceCalculator _BalanceCalculator,
        uint256 _ReferralPercent,
        uint256 _ReferralRevExpirySecs
    ) public initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        RegistrationContract = _RegistrationContract;
        ApplicationNFT = _ApplicationNFT;
        XCTToken = _XCTToken;
        BalanceCalculator = _BalanceCalculator;
        ReferralPercent = _ReferralPercent;
        ReferralRevExpirySecs = _ReferralRevExpirySecs;
    }

    function setSubscriptionContract(address _Subscription) external onlyOwner {
        require(address(SubscriptionContract) == address(0), "Already set");
        SubscriptionContract = ISubscription(_Subscription);
    }

    function change__ReferralAttributes(
        uint256 _ReferralPercent,
        uint256 _ReferralRevExpirySecs
    ) external onlyOwner {
        ReferralPercent = _ReferralPercent;
        ReferralRevExpirySecs = _ReferralRevExpirySecs;
        emit ChangedReferralAttributes(
            _ReferralPercent,
            _ReferralRevExpirySecs
        );
    }

    function setLinkContract(ILinkContract _newLinkContract)
        external
        onlyOwner
    {
        LinkContract = _newLinkContract;
    }

    function t_supportFeeAddress(uint256 _tokenId)
        public
        view
        returns (address)
    {
        return ApplicationNFT.ownerOf(_tokenId);
    }

    function s_GlobalDAOAddress() public view returns (address) {
        return RegistrationContract.GLOBAL_DAO_ADDRESS();
    }

    // r address is NFT minter address => nftBalances[_nftId].NFTMinter

    function subnetDAOWalletFor1(uint256 _subnetId)
        public
        view
        returns (address)
    {
        return RegistrationContract.subnetLocalDAO(_subnetId);
    }

    function r_licenseFee(uint256 _nftId, uint256 _subnetId)
        public
        view
        returns (uint256)
    {
        return SubscriptionContract.r_licenseFee(_nftId, _subnetId);
    }

    function s_GlobalDAORate() public view returns (uint256) {
        return RegistrationContract.daoRate();
    }

    function t_SupportFeeRate(uint256 _subnetId)
        public
        view
        returns (uint256 fee)
    {
        (, , , , , , , fee, ) = RegistrationContract.getSubnetAttributes(
            _subnetId
        );
    }

    function dripRatePerSec(uint256 NFTid)
        public
        view
        returns (uint256 totalDripRate)
    {
        uint256[] memory subnetIds = nftBalances[NFTid].subnetIds;
        totalDripRate = 0;
        for (uint256 i = 0; i < subnetIds.length; i++) {
            totalDripRate = totalDripRate.add(
                dripRatePerSecOfSubnet(NFTid, subnetIds[i])
            );
        }
    }

    function dripRatePerSecOfSubnet(uint256 NFTid, uint256 subnetId)
        public
        view
        returns (uint256)
    {
        uint256 factor = s_GlobalDAORate()
            .add(r_licenseFee(NFTid, subnetId))
            .add(t_SupportFeeRate(subnetId))
            .add(ReferralPercent)
            .add(100000);
        (, , , , uint256[] memory prices, , , , ) = RegistrationContract
            .getSubnetAttributes(subnetId);
        uint256 cost = 0;
        uint256[] memory computeRequired = SubscriptionContract
            .getComputesOfSubnet(NFTid, subnetId);

        for (uint256 i = 0; i < prices.length; i++) {
            cost = cost.add(prices[i].mul(computeRequired[i]));
        }
        return factor.mul(cost).div(100000); // 10^5 for percent
    }

    function prevBalances(uint256 NFTid)
        public
        view
        returns (uint256[3] memory)
    {
        return nftBalances[NFTid].prevBalance;
    }

    function totalPrevBalance(uint256 NFTid) public view returns (uint256) {
        uint256 bal = 0;
        for (uint256 i = 0; i < 3; i++) {
            bal = bal.add(nftBalances[NFTid].prevBalance[i]);
        }
        return bal;
    }

    function balanceLeft(uint256 NFTid) public view returns (uint256) {
        uint256 cost = (
            block.timestamp.sub(nftBalances[NFTid].lastBalanceUpdateTime)
        ).mul(dripRatePerSec(NFTid));
        uint256 prevBalance = totalPrevBalance(NFTid);
        if (prevBalance < cost) return 0;
        return prevBalance.sub(cost);
    }

    function totalSubnets(uint256 nftId) external view returns (uint256) {
        return nftBalances[nftId].subnetIds.length;
    }

    function changeSubnet(
        uint256 _nftId,
        uint256 _currentSubnetId,
        uint256 _newSubnetId
    ) external onlySubscription returns (bool) {
        uint256[] memory subnetIdsInNFT = nftBalances[_nftId].subnetIds;
        // replace subnetId
        for (uint256 i = 0; i < subnetIdsInNFT.length; i++) {
            if (subnetIdsInNFT[i] == _currentSubnetId) {
                subnetIdsInNFT[i] = _newSubnetId;
                break;
            }
        }
        nftBalances[_nftId].subnetIds = subnetIdsInNFT;
        return true;
    }

    function subscribeNew(
        uint256 _nftId,
        uint256 _balanceToAdd,
        uint256 _subnetId,
        address _minter
    ) external onlySubscription returns (bool) {
        uint256[] memory arr;

        nftBalances[_nftId] = NFTBalance(
            block.timestamp,
            [uint256(0), uint256(0), uint256(0)],
            arr,
            _minter,
            block.timestamp,
            0
        );
        nftBalances[_nftId].subnetIds.push(_subnetId);

        _addBalance(_nftId, _balanceToAdd);
        return true;
    }

    function addSubnetToNFT(uint256 _nftId, uint256 _subnetId)
        external
        onlySubscription
        returns (bool)
    {
        nftBalances[_nftId].subnetIds.push(_subnetId);
        return true;
    }

    function addBalance(uint256 _nftId, uint256 _balanceToAdd)
        public
        returns (
            // updateBalance(_nftId)
            bool
        )
    {
        _addBalance(_nftId, _balanceToAdd);
        return true;
    }

    function _addBalance(uint256 _nftId, uint256 _balanceToAdd)
        internal
        returns (bool)
    {
        uint256 id = _nftId;
        XCTToken.transferFrom(
            _msgSender(),
            address(BalanceCalculator),
            _balanceToAdd
        );

        // so that if someone comes after x days to restart the subnet operation, donot cost him for time it was unoperative
        if (totalPrevBalance(id) == 0)
            nftBalances[id].lastBalanceUpdateTime = block.timestamp;

        nftBalances[id].prevBalance = [
            nftBalances[id].prevBalance[0],
            nftBalances[id].prevBalance[1],
            nftBalances[id].prevBalance[2].add(_balanceToAdd)
        ];
        nftBalances[id].lastBalanceUpdateTime = block.timestamp;
        refreshEndOfBalance(_nftId);
        emit BalanceAdded(_nftId, 2, _balanceToAdd);
        return true;
    }

    function withdrawAllOwnerBalance(uint256 _NFTid)
        external
        whenNotPaused
        updateBalance(_NFTid)
    {
        uint256 bal = nftBalances[_NFTid].prevBalance[2];
        _withdrawBalance(_NFTid, bal);
    }

    function withdrawBalanceLinked(
        uint256 _NFTid,
        uint256 _bal,
        address customNFTcontract,
        uint256 customNFTid
    ) public whenNotPaused updateBalance(_NFTid) {
        require(
            LinkContract.isLinkedTo(customNFTcontract, customNFTid, _NFTid),
            "Not linked custom NFT in LinkNFT smart contract"
        );
        require(
            IERC721(customNFTcontract).ownerOf(customNFTid) == _msgSender(),
            "Sender not the owner of Custom NFT id"
        );
        _withdrawBalance(_NFTid, _bal);
    }

    function withdrawBalance(uint256 _NFTid, uint256 _bal)
        public
        whenNotPaused
        updateBalance(_NFTid)
    {
        require(
            ApplicationNFT.ownerOf(_NFTid) == _msgSender(),
            "Sender not the owner of NFT id"
        );
        _withdrawBalance(_NFTid, _bal);
    }

    function _withdrawBalance(uint256 _NFTid, uint256 _bal)
        internal
        whenNotPaused
        updateBalance(_NFTid)
    {
        uint256 id = _NFTid;
        XCTToken.transfer(_msgSender(), _bal);
        nftBalances[id].prevBalance = [
            nftBalances[id].prevBalance[0],
            nftBalances[id].prevBalance[1],
            nftBalances[id].prevBalance[2].sub(_bal)
        ];

        settleAccountBalance(id);

        nftBalances[id].endOfXCTBalance = block.timestamp.add(
            totalPrevBalance(id).div(dripRatePerSec(id))
        );

        emit BalanceWithdrawn(id, 2, _bal);
    }

    function addBalanceAsCredit(
        uint256 _toNFTid,
        uint256 _balanceToAdd,
        uint256 _expiryUnixTimestamp
    )
        external
        whenNotPaused // updateBalance(_toNFTid)
    {
        uint256 id = _toNFTid;
        require(
            creditsExpiry[_msgSender()][id] < _expiryUnixTimestamp,
            "Credits expiry cannot be set lesser than previous expiry"
        );

        XCTToken.transferFrom(
            _msgSender(),
            address(BalanceCalculator),
            _balanceToAdd
        );
        nftBalances[id].prevBalance = [
            nftBalances[id].prevBalance[0].add(_balanceToAdd),
            nftBalances[id].prevBalance[1],
            nftBalances[id].prevBalance[2]
        ];

        settleAccountBalance(id);

        nftBalances[id].lastBalanceUpdateTime = block.timestamp;
        nftBalances[id].endOfXCTBalance = block.timestamp.add(
            totalPrevBalance(id).div(dripRatePerSec(id))
        );
        creditsExpiry[_msgSender()][id] = _expiryUnixTimestamp;
        emit BalanceAdded(id, 0, _balanceToAdd);
    }

    function addBalanceAsExternalDeposit(uint256 _NFTid, uint256 _balanceToAdd)
        external
        whenNotPaused
    // updateBalance(_NFTid)
    {
        uint256 id = _NFTid;
        XCTToken.transferFrom(
            _msgSender(),
            address(BalanceCalculator),
            _balanceToAdd
        );

        nftBalances[id].prevBalance = [
            nftBalances[id].prevBalance[0],
            nftBalances[id].prevBalance[1].add(_balanceToAdd),
            nftBalances[id].prevBalance[2]
        ];

        settleAccountBalance(id);

        nftBalances[id].lastBalanceUpdateTime = block.timestamp;
        nftBalances[id].endOfXCTBalance = block.timestamp.add(
            totalPrevBalance(id).div(dripRatePerSec(id))
        );

        emit BalanceAdded(id, 1, _balanceToAdd);
    }

    function withdrawCreditsForNFT(uint256 _NFTid, address _to)
        external
        hasWithdrawRole
        whenNotPaused
        updateBalance(_NFTid)
    {
        uint256 id = _NFTid;
        uint256 bal = nftBalances[id].prevBalance[0];
        require(
            creditsExpiry[_msgSender()][id] < block.timestamp,
            "Credits not expired yet"
        );

        nftBalances[id].prevBalance = [
            0,
            nftBalances[id].prevBalance[1],
            nftBalances[id].prevBalance[2]
        ];
        nftBalances[id].lastBalanceUpdateTime = block.timestamp;
        nftBalances[id].endOfXCTBalance = block.timestamp.add(
            totalPrevBalance(id).div(dripRatePerSec(id))
        );
        XCTToken.transfer(_to, bal);
        settleAccountBalance(id);

        emit BalanceWithdrawn(_NFTid, 0, bal);
    }

    function refreshEndOfBalance(uint256 _nftId)
        public
        updateBalance(_nftId)
        returns (bool)
    {
        nftBalances[_nftId].endOfXCTBalance = block.timestamp.add(
            totalPrevBalance(_nftId).div(dripRatePerSec(_nftId))
        );
        return true;
    }

    function settleAccountBalance(uint256 _nftId)
        public
        updateBalance(_nftId)
        returns (bool)
    {
        // modifier is only required to call
        emit SettledBalanceFor(_nftId);
        return true;
    }

    // ALWAYS check before computing
    function isBalancePresent(uint256 _nftId) public view returns (bool) {
        if (block.timestamp < nftBalances[_nftId].endOfXCTBalance) return true;
        return false;
    }

    function getRealtimeBalances(uint256 NFTid)
        public
        view
        returns (uint256[3] memory)
    {
        return
            BalanceCalculator.getRealtimeBalance(
                NFTid,
                nftBalances[NFTid].subnetIds,
                nftBalances[NFTid].prevBalance,
                nftBalances[NFTid].lastBalanceUpdateTime
            );
    }

    function getRealtimeCostIncurredUnsettled(uint256 NFTid)
        public
        view
        returns (uint256)
    {
        return
            BalanceCalculator.getRealtimeCostIncurred(
                NFTid,
                nftBalances[NFTid].subnetIds,
                nftBalances[NFTid].lastBalanceUpdateTime
            );
    }

    /* ========== MODIFIERS ========== */

    modifier onlySubscription() {
        require(
            address(SubscriptionContract) == _msgSender(),
            "SubscriptionContract can only call this function"
        );
        _;
    }

    modifier hasWithdrawRole() {
        require(
            SubscriptionContract.hasRole(
                keccak256("WITHDRAW_CREDITS_ROLE"),
                _msgSender()
            ),
            "Sender is not assigned to WITHDRAW_CREDITS_ROLE"
        );
        _;
    }

    modifier updateBalance(uint256 NFTid) {
        uint256[3] memory prevBalanceUpdated = BalanceCalculator
            .getUpdatedBalance(
                NFTid,
                nftBalances[NFTid].subnetIds,
                nftBalances[NFTid].NFTMinter,
                nftBalances[NFTid].mintTime,
                nftBalances[NFTid].prevBalance,
                nftBalances[NFTid].lastBalanceUpdateTime
            );

        nftBalances[NFTid].prevBalance = [
            prevBalanceUpdated[0],
            prevBalanceUpdated[1],
            prevBalanceUpdated[2]
        ];
        nftBalances[NFTid].lastBalanceUpdateTime = block.timestamp;

        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IRegistration {
    struct SubnetAttributes {
        uint256 subnetType;
        bool sovereignStatus;
        uint256 cloudProviderType;
        bool subnetStatusListed;
        uint256[] unitPrices;
        uint256[] otherAttributes; // eg. [1,2]
        uint256 maxClusters;
        uint256 supportFeeRate; // 1000 = 1%
        uint256 stackFeesReqd;
    }

    struct Cluster {
        address ClusterDAO;
        string DNSIP;
        uint8 listed;
        uint NFTidLocked;
    }

    struct PriceChangeRequest {
        uint256 timestamp;
        uint256[] unitPrices;
    }


    function totalSubnets() external view returns (uint256);

    function subnetAttributes(uint256 _subnetId) external view returns(SubnetAttributes memory);

    function subnetClusters(uint256 _subnetId, uint256 _clusterId) external view returns(Cluster memory);

    function getSubnetAttributes(uint256 _subnetId) external view returns(uint256 subnetType, bool sovereignStatus, uint256 cloudProviderType, bool subnetStatusListed, uint256[] memory unitPrices, uint256[] memory otherAttributes, uint256 maxClusters, uint256 supportFeeRate, uint256 stackFeeReqd);

    function getClusterAttributes(uint256 _subnetId, uint256 _clusterId) external view returns(address ClusterDAO, string memory DNSIP, uint8 listed, uint NFTIdLocked);

    function subnetLocalDAO(uint256 subnetId) external view returns (address);

    function daoRate() external view returns (uint256);

    function GLOBAL_DAO_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface ILinkContract {

    function isLinkedTo(
        address customNFTcontract,
        uint customNFTid,
        uint NFTid
    ) external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface ISubscription {

    function getComputesOfSubnet(uint256 NFTid, uint256 subnetId) external view returns(uint256[] memory);
    function hasRole(bytes32 role, address account) external view returns(bool);

    function r_licenseFee(uint256 _nftId, uint256 _subnetId) external view returns (uint256);
    function getReferralAddress(uint256 _nftId, uint256 _subnetId)
        external
        view
        returns (address);
        
    function GLOBAL_DAO_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mint(address to) external returns(uint newTokenId);

    function getCurrentTokenId() external view returns(uint);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IBalanceCalculator {
    function getUpdatedBalance(
        uint256 nftId,
        uint256[] memory subnetIds,
        address nftMinter,
        uint256 mintTime,
        uint256[3] memory prevBalance,
        uint256 lastBalanceUpdatedTime
    ) external returns (uint256[3] memory prevBalanceUpdated);

    function getRealtimeBalance(
        uint256 nftId,
        uint256[] memory subnetIds,
        uint256[3] memory prevBalance,
        uint256 lastBalanceUpdatedTime
    ) external view returns (uint256[3] memory prevBalanceUpdated);

    function getRealtimeCostIncurred(
        uint256 nftId,
        uint256[] memory subnetIds,
        uint256 lastBalanceUpdatedTime
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}