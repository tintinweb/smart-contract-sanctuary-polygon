// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPremimumCalculator {
    function calculatePremium(
        string memory _breed,
        uint _ageInMonths,
        string memory _healthCondition,
        string memory _region,
        string memory _policyType
    ) external view returns (uint premium);

    function calculatePayout(uint premiumAmount) external view returns (uint);

    function getDetails() external view returns (uint, uint, uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwhanSurkshaClaimVerifier {
    function getIsClaimable(address policyHolder) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPremimumCalculator.sol";
import "./interfaces/ISwhanSurkshaClaimVerifier.sol";

contract ShwanSurksha {
    mapping(address => bytes32[]) public policyOf;
    // Struct to represent a policy
    struct Policy {
        address owner;
        uint256 premium;
        uint256 payout;
        uint256 startDate;
        uint256 endDate;
        bool claimed;
        string breed;
        uint ageInMonths;
        string healthCondition;
        string region;
        string policyType;
    }

    // Mapping to store policies by their unique ID
    mapping(bytes32 => Policy) policies;

    // Events to emit when policies are added and claimed
    event PolicyAdded(
        bytes32 policyId,
        address owner,
        uint256 premium,
        uint256 payout,
        uint256 startDate,
        uint256 endDate
    );
    event PolicyClaimed(bytes32 policyId, address owner, uint256 payout);
    event PolicyUpdated(bytes32 policyId, address owner, uint256 newEndDate);

    IERC20 usdc;
    IPremimumCalculator premimumCalculator;
    ISwhanSurkshaClaimVerifier verifier;

    address admin;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    function initialize(
        address _usdcTokenAddress,
        address _premimumCalculator,
        address _verifierContractAddress
    ) external onlyAdmin {
        usdc = IERC20(_usdcTokenAddress);
        premimumCalculator = IPremimumCalculator(_premimumCalculator);
        verifier = ISwhanSurkshaClaimVerifier(_verifierContractAddress);
    }

    // Function to add a new policy
    function addPolicy(
        string memory _breed,
        uint _ageInMonths,
        string memory _healthCondition,
        string memory _region,
        string memory _policyType,
        uint256 startDate,
        uint256 endDate
    ) public {
        bytes32 policyId = keccak256(
            abi.encodePacked(
                msg.sender,
                block.timestamp,
                _breed,
                _ageInMonths,
                _healthCondition,
                _region,
                _policyType
            )
        );

        require(
            policies[policyId].owner == address(0),
            "Policy already exists"
        );

        require(startDate > block.timestamp, "Invalid start date");
        require(endDate > startDate, "Invalid end date");

        uint premium = premimumCalculator.calculatePremium(
            _breed,
            _ageInMonths,
            _healthCondition,
            _region,
            _policyType
        );
        uint payout = premimumCalculator.calculatePayout(premium);

        // Approve transfer of premium amount from user's account to the contract
        require(usdc.approve(address(this), premium), "USDC approval failed");
        require(
            usdc.transferFrom(msg.sender, address(this), premium),
            "USDC transfer failed"
        );

        policies[policyId] = Policy(
            msg.sender,
            premium,
            payout,
            startDate,
            endDate,
            false,
            _breed,
            _ageInMonths,
            _healthCondition,
            _region,
            _policyType
        );
        emit PolicyAdded(
            policyId,
            msg.sender,
            premium,
            payout,
            startDate,
            endDate
        );
    }

    function claimPolicy(bytes32 policyId) public {
        Policy storage policy = policies[policyId];

        require(verifier.getIsClaimable(policy.owner), "Verify claim first");

        // Check that the policy exists and is not already claimed
        require(
            policy.owner != address(0) && policy.owner == msg.sender,
            "Policy does not exist"
        );
        require(!policy.claimed, "Policy has already been claimed");

        // Check that the policy end date has passed
        require(block.timestamp > policy.endDate, "Policy has not expired yet");

        // Mark the policy as claimed
        policy.claimed = true;

        // Pay out the policy amount to the policy owner
        require(
            usdc.transfer(policy.owner, policy.payout),
            "USDC transfer failed"
        );

        emit PolicyClaimed(policyId, policy.owner, policy.payout);
    }

    // cancelPolicy
    function cancelPolicy(bytes32 policyId) public {
        Policy storage policy = policies[policyId];

        // Check that the policy exists and is not already claimed
        require(policy.owner != address(0), "Policy does not exist");
        require(!policy.claimed, "Policy has already been claimed");

        // Check that the policy start date has not passed
        require(
            block.timestamp < policy.startDate,
            "Policy has already started"
        );

        // Refund the premium amount to the policy owner
        require(
            usdc.transfer(policy.owner, policy.premium),
            "USDC transfer failed"
        );

        // Delete the policy from the mapping
        delete policies[policyId];
    }

    function updatePolicy(bytes32 policyId, uint256 newEndDate) public {
        Policy storage policy = policies[policyId];

        // Check that the policy exists and is owned by the caller
        require(
            policy.owner == msg.sender,
            "Policy does not exist or you are not the owner"
        );

        // Check that the new end date is greater than the current end date
        require(
            newEndDate > policy.endDate,
            "New end date must be after current end date"
        );

        // Update the policy's end date
        policy.endDate = newEndDate;

        emit PolicyUpdated(policyId, msg.sender, newEndDate);
    }

    // getters
    function getPolicy(
        bytes32 policyId
    )
        public
        view
        returns (
            address owner,
            uint256 premium,
            uint256 payout,
            uint256 startDate,
            uint256 endDate,
            bool claimed,
            string memory breed,
            uint ageInMonths,
            string memory healthCondition,
            string memory region,
            string memory policyType
        )
    {
        Policy storage policy = policies[policyId];
        require(policy.owner != address(0), "Policy does not exist");
        return (
            policy.owner,
            policy.premium,
            policy.payout,
            policy.startDate,
            policy.endDate,
            policy.claimed,
            policy.breed,
            policy.ageInMonths,
            policy.healthCondition,
            policy.region,
            policy.policyType
        );
    }

    function gePolicyOf(
        address _policyHolder
    ) external view returns (bytes32[] memory) {
        require(
            address(_policyHolder) != address(0),
            "invalid policyHolder address"
        );
        return policyOf[_policyHolder];
    }

    function getAllPoliciesOf(
        address _policyHolder
    ) external view returns (bytes32[] memory) {
        require(_policyHolder != address(0), "Invalid Borrower sddress");
        bytes32[] memory _policies = policyOf[_policyHolder];
        return _policies;
    }
}