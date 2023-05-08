// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";

contract CrowdFundingSolNew {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        bool withdrawn;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;
    address public admin;
    address public tokenAddress = 0x699590709E626a65479d9a3365a6326F4E1E5B32; // 指定代币合约地址

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        campaign.owner = msg.sender;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.withdrawn = false;

        numberOfCampaigns++;
        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id, uint256 _amount) public {
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");

        Campaign storage campaign = campaigns[_id];

        require(campaign.deadline >= block.timestamp, "The campaign has already ended.");
        require(campaign.amountCollected < campaign.target, "The campaign has already reached its target.");
        require(!campaign.withdrawn, "The campaign has already been withdrawn.");

        campaign.amountCollected += _amount;
    }

    function withdraw(uint256 _id) public onlyAdmin {
        Campaign storage campaign = campaigns[_id];

        uint256 minimumTarget = campaign.target * 99 / 100; // 计算 99% 的目标金额

        require(block.timestamp > campaign.deadline || campaign.amountCollected >= minimumTarget, "The campaign has not reached its minimum target or deadline has not passed yet.");

        uint256 amount = campaign.amountCollected;
        campaign.amountCollected = 0;
        campaign.withdrawn = true;

        IERC20 token = IERC20(tokenAddress);
        token.transfer(admin, amount);
    }


    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

    function searchCampaigns(string memory _searchTerm) public view returns (Campaign[] memory) {
        Campaign[] memory matchingCampaigns = new Campaign[](numberOfCampaigns);
        uint256 matchingCampaignsCount = 0;
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage campaign = campaigns[i];

            if (bytes(campaign.title).length > 0 && bytes(_searchTerm).length > 0 && 
                containsIgnoreCase(campaign.title, _searchTerm)) {
                                matchingCampaigns[matchingCampaignsCount] = campaign;
                matchingCampaignsCount++;
            }
        }

        Campaign[] memory result = new Campaign[](matchingCampaignsCount);
        for (uint256 i = 0; i < matchingCampaignsCount; i++) {
            result[i] = matchingCampaigns[i];
        }

        return result;
    }

    function containsIgnoreCase(string memory _str, string memory _substr) internal pure returns (bool) {
        bytes memory strBytes = bytes(_str);
        bytes memory substrBytes = bytes(_substr);
        uint256 strLen = strBytes.length;
        uint256 substrLen = substrBytes.length;

        for (uint256 i = 0; i <= strLen - substrLen; i++) {
            bool ismatch = true;
            for (uint256 j = 0; j < substrLen; j++) {
                if (lowercase(strBytes[i + j]) != lowercase(substrBytes[j])) {
                    ismatch = false;
                    break;
                }
            }
            if (ismatch) {
                return true;
            }
        }

        return false;
    }

    function lowercase(bytes1 _b) internal pure returns (bytes1) {
        if (_b >= 0x41 && _b <= 0x5a) {
            return bytes1(uint8(_b) + 32);
        }
        return _b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}