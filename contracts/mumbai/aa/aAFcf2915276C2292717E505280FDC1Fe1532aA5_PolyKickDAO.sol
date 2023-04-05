/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.19;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.19;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.19;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// File: contracts/PolyKickDAO.sol



pragma solidity 0.8.19;



contract PolyKickDAO is Ownable {
    address public financeWallet;

    struct Partner {
        uint256 id;
        address account;
        string name;
        uint256 sharePercentage;
    }

    enum ApprovalType {
        ADD,
        UPDATE,
        REMOVE
    }

    struct ApprovalRequest {
        ApprovalType approvalType;
        uint256 partnerId;
        string name;
        address account;
        uint256 sharePercentage;
        uint256 approvals;
        mapping(address => bool) approvedBy;
    }

    struct ProfitDistributionRequest {
        address token;
        uint256 toFinance;
        uint256 approvals;
        mapping(address => bool) approvedBy;
    }

    mapping(uint256 => ApprovalRequest) public approvalRequests;
    mapping(uint256 => Partner) public partners;
    mapping(uint256 => address) public emergencyAddressChangeApprovals;
    mapping(uint256 => bool) public ownerEmergencyAddressChangeApproval;
    mapping(uint256 => ProfitDistributionRequest)
        public profitDistributionRequests;

    uint256 public partnerCount;
    uint256 public reservedShares;

    event PartnerAdded(
        uint256 indexed partnerId,
        string name,
        address account,
        uint256 sharePercentage
    );
    event PartnerRemoved(uint256 indexed partnerId);
    event PartnerShareUpdated(
        uint256 indexed partnerId,
        uint256 newSharePercentage
    );
    event PartnerApproval(
        uint256 indexed partnerId,
        address indexed approver,
        ApprovalType indexed approvalType
    );
    event ApprovalReceived(address indexed approver, uint256 indexed partnerId);
    event EmergencyAddressChangeApproval(
        uint256 indexed partnerId,
        address indexed approver
    );
    event PartnerAddressUpdated(
        uint256 indexed partnerId,
        address indexed oldAddress,
        address indexed newAddress
    );
    event OwnerEmergencyAddressChangeApproval(
        uint256 indexed partnerId,
        address indexed owner
    );

    constructor(
        //address _owner,
        // address partner1,
        // address partner2,
        // address partner3,
        //address _financeWallet
    ) {
        financeWallet = 0x4177720ecC9741D247bd10b20902fE73Ea127C5f;
        transferOwnership(msg.sender);
        addPrePartner(
            "CryptoHalal",
            0x3e6275f3AbC45b508d7f70De11d3950a4A04e26F,
            47
        );
        addPrePartner(
            "TokenBench",
            0xb6B8EcE610c1543E112F8cEc5f2404d785b803d9,
            43
        );
        addPrePartner(
            "MetaIdentity",
            0xc9362C3b93706B3E4ee6d32a2b2310129E5B3C9e,
            10
        );
    }

    function initiateProfitDistributionRequest(
        address _token,
        uint256 toFinance
    ) external {
        ProfitDistributionRequest storage request = profitDistributionRequests[
            1
        ];
        require(
            request.approvals == 0,
            "Existing profit distribution request in progress"
        );

        request.token = _token;
        request.toFinance = toFinance;

        _approveProfitDistributionRequest();
    }

    function _approveProfitDistributionRequest() internal {
        ProfitDistributionRequest storage request = profitDistributionRequests[
            1
        ];

        if (request.approvedBy[msg.sender] == false) {
            request.approvals++;
            request.approvedBy[msg.sender] = true;
        }

        // Check if the change has been approved by the admin and a partner with at least 35% shares
        if (request.approvedBy[owner()] && request.approvals >= 2) {
            distributeProfits(request.token, request.toFinance);

            // Reset the approval request
            delete profitDistributionRequests[1];
        }
    }

    function claimExpenses(address _token, uint256 _amount) internal {
        require(
            IERC20(_token).transfer(financeWallet, _amount),
            "Expenses transfer failed"
        );
    }

    function distributeProfits(address _token, uint256 toFinance) internal {
        require(_token != address(0x0), "zero address");
        require(toFinance != 0, "Finance can not be zero");
        claimExpenses(_token, toFinance);

        uint256 totalBalance = IERC20(_token).balanceOf(address(this)) -
            toFinance;
        uint256 distributedAmount = 0;

        for (uint256 i = 1; i <= partnerCount; i++) {
            Partner storage partner = partners[i];
            uint256 partnerShare = (totalBalance * partner.sharePercentage) /
                100;
            distributedAmount += partnerShare;
            require(
                IERC20(_token).transfer(partner.account, partnerShare),
                "Partner transfer failed"
            );
        }

        // Any remaining amount should be transferred back to the finance wallet
        uint256 remainingAmount = totalBalance - distributedAmount;
        if (remainingAmount > 0) {
            require(
                IERC20(_token).transfer(financeWallet, remainingAmount),
                "Remaining transfer failed"
            );
        }
    }

    function addPrePartner(
        string memory name,
        address account,
        uint256 sharePercentage
    ) internal {
        partnerCount++;
        Partner storage newPartner = partners[partnerCount];
        newPartner.id = partnerCount;
        newPartner.account = account;
        newPartner.name = name;
        newPartner.sharePercentage = sharePercentage;

        emit PartnerAdded(partnerCount, name, account, sharePercentage);
    }

    function addPartner(
        string memory name,
        address account,
        uint256 sharePercentage,
        uint256[] memory updatedPartnerIds,
        uint256[] memory updatedSharePercentages
    ) internal {
        // Redistribute shares among existing partners
        for (uint256 i = 0; i < updatedPartnerIds.length; i++) {
            uint256 partnerId = updatedPartnerIds[i];
            require(partnerId <= partnerCount, "Invalid partner ID");
            partners[partnerId].sharePercentage = updatedSharePercentages[i];
        }

        // Use reserved shares from the vault if available
        if (reservedShares > 0) {
            require(
                reservedShares >= sharePercentage,
                "Not enough reserved shares"
            );
            reservedShares -= sharePercentage;
        }

        partnerCount++;
        Partner storage newPartner = partners[partnerCount];
        newPartner.id = partnerCount;
        newPartner.account = account;
        newPartner.name = name;
        newPartner.sharePercentage = sharePercentage;

        emit PartnerAdded(partnerCount, name, account, sharePercentage);
    }

    function removePartner(uint256 partnerId) internal {
        require(partnerId <= partnerCount, "Invalid partner ID");

        // Move removed partner's shares to the vault
        reservedShares += partners[partnerId].sharePercentage;
        delete partners[partnerId];

        emit PartnerRemoved(partnerId);
    }

    function updatePartnerShare(uint256 partnerId, uint256 newSharePercentage)
        internal
    {
        require(partnerId <= partnerCount, "Invalid partner ID");

        uint256 oldSharePercentage = partners[partnerId].sharePercentage;
        uint256 totalShares = getTotalShares();

        // Check if the updated share percentage keeps total shares at 100
        require(
            totalShares - oldSharePercentage + newSharePercentage <= 100,
            "Total shares must not exceed 100"
        );

        // Use reserved shares from the vault if needed
        if (newSharePercentage > oldSharePercentage) {
            uint256 extraSharesNeeded = newSharePercentage - oldSharePercentage;
            require(
                reservedShares >= extraSharesNeeded,
                "Not enough reserved shares"
            );
            reservedShares -= extraSharesNeeded;
        } else {
            reservedShares += oldSharePercentage - newSharePercentage;
        }

        partners[partnerId].sharePercentage = newSharePercentage;
        emit PartnerShareUpdated(partnerId, newSharePercentage);
    }

    function getPartner(uint256 partnerId)
        external
        view
        returns (Partner memory)
    {
        require(partnerId <= partnerCount, "Invalid partner ID");
        return partners[partnerId];
    }

    function getTotalShares() public view returns (uint256) {
        uint256 totalShares = 0;
        for (uint256 i = 1; i <= partnerCount; i++) {
            totalShares += partners[i].sharePercentage;
        }
        return totalShares;
    }

    function initiateApprovalRequest(
        ApprovalType approvalType,
        uint256 partnerId,
        string memory name,
        address account,
        uint256 sharePercentage,
        uint256[] memory updatedPartnerIds,
        uint256[] memory updatedSharePercentages
    ) external {
        ApprovalRequest storage request = approvalRequests[partnerId];
        require(
            request.approvals == 0,
            "Existing approval request in progress"
        );

        request.approvalType = approvalType;
        request.partnerId = partnerId;
        request.name = name;
        request.account = account;
        request.sharePercentage = sharePercentage;

        _approveRequest(partnerId, updatedPartnerIds, updatedSharePercentages);
    }

    function approveRequest(
        uint256 partnerId,
        uint256[] memory updatedPartnerIds,
        uint256[] memory updatedSharePercentages
    ) external {
        _approveRequest(partnerId, updatedPartnerIds, updatedSharePercentages);
    }

    function _approveRequest(
        uint256 partnerId,
        uint256[] memory updatedPartnerIds,
        uint256[] memory updatedSharePercentages
    ) internal {
        ApprovalRequest storage request = approvalRequests[partnerId];
        require(request.approvals < 3, "No approval request to approve");

        if (request.approvedBy[msg.sender] == false) {
            request.approvals++;
            request.approvedBy[msg.sender] = true;
        }

        emit PartnerApproval(partnerId, msg.sender, request.approvalType);

        // Check if the change has been approved by at least two partners and the owner
        if (request.approvals >= 3) {
            if (request.approvalType == ApprovalType.ADD) {
                addPartner(
                    request.name,
                    request.account,
                    request.sharePercentage,
                    updatedPartnerIds,
                    updatedSharePercentages
                );
            } else if (request.approvalType == ApprovalType.UPDATE) {
                updatePartnerShare(partnerId, request.sharePercentage);
            } else if (request.approvalType == ApprovalType.REMOVE) {
                removePartner(partnerId);
            }

            // Reset the approval request
            delete approvalRequests[partnerId];
        }
    }

    function emergencyUpdatePartnerAddress(
        uint256 partnerId,
        address newAddress
    ) external {
        require(partnerId <= partnerCount, "Invalid partner ID");
        require(newAddress != address(0), "Invalid new address");

        Partner storage partner = partners[partnerId];
        require(partner.account != newAddress, "Same address provided");

        if (msg.sender == owner()) {
            ownerEmergencyAddressChangeApproval[partnerId] = true;
            emit OwnerEmergencyAddressChangeApproval(partnerId, msg.sender);
            return;
        }

        Partner storage approver = partners[getPartnerIdByAddress(msg.sender)];
        require(
            approver.sharePercentage >= 35,
            "Insufficient share percentage to approve"
        );

        require(
            ownerEmergencyAddressChangeApproval[partnerId],
            "Owner approval required"
        );

        address oldAddress = partner.account;
        partner.account = newAddress;

        delete emergencyAddressChangeApprovals[partnerId];
        delete ownerEmergencyAddressChangeApproval[partnerId];

        emit PartnerAddressUpdated(partnerId, oldAddress, newAddress);
    }

    function getPartnerIdByAddress(address partnerAddress)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 1; i <= partnerCount; i++) {
            if (partners[i].account == partnerAddress) {
                return i;
            }
        }
        return 0;
    }
}